
/****** Object:  StoredProcedure [dbo].[PCM_CreateWorkList]    Script Date: 2023/01/31 11:37:17 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- Author:		Eric Malekutu
-- Create date: 30 January 2023
-- Description:	Create worklist, accept inbox item, intake assessment


CREATE PROCEDURE [dbo].[PCM_CreateWorkList]
	@EndPointPOIId INT,
	@UserId INT,
	@DateDue DATETIME
AS
	DECLARE @Allocated_By INT;
	DECLARE @PersonId INT;
	DECLARE @ClientId INT;
	DECLARE @NewRecordStatusId INT;
	DECLARE @AcceptedRecordStatusId INT;
	DECLARE @CreatedBy VARCHAR(50);
	DECLARE @PoliceName VARCHAR(50);
	DECLARE @assignToProvinceId INT = -1;
	DECLARE @ProvinceAbbreviation VARCHAR(50);
	DECLARE @ClientRefNumber VARCHAR(50);
	DECLARE @ServiceOfficeId INT;
	DECLARE @IntakeAssessmentId INT;	
	DECLARE @CaseNumber VARCHAR(50);
	DECLARE @ArrestDate DATETIME;	
	DECLARE @ArrestTime VARCHAR(50);

BEGIN

BEGIN TRANSACTION
	BEGIN TRY
		SET NOCOUNT ON;

		SET @CreatedBy = (SELECT user_name FROM apl_User WITH(NOLOCK) WHERE User_Id = @UserId);
		SET @NewRecordStatusId = (SELECT PCM_Record_Status_Id FROM apl_PCM_Record_Status WITH(NOLOCK) WHERE Description = 'New');
		SET @AcceptedRecordStatusId = (SELECT PCM_Record_Status_Id FROM apl_PCM_Record_Status WITH(NOLOCK) WHERE Description = 'Accepted');
		SELECT @PersonId = Person_Id, @Allocated_By = Allocated_ByS,
				@PoliceName = PoliceName, @CaseNumber = CAS_No,
				@ArrestDate = ArrestDate, @ArrestTime = ArrestTime
				FROM PCM_EndPoint_PO_Inbox WITH(NOLOCK) WHERE End_Point_POD_Id = @EndPointPOIId;
		SET @ClientId = (SELECT TOP(1) c.Client_Id FROM int_Client c WITH(NOLOCK) 
					     INNER JOIN int_Person p WITH(NOLOCK) ON (p.Person_Id = c.Person_Id));
		SET @ServiceOfficeId = (SELECT TOP(1) Service_Office_Id FROM apl_Employee WITH(NOLOCK) WHERE User_Id = @UserId);
		
		UPDATE PCM_EndPoint_PO_Inbox SET Endpoint_Record_Status_Id = @AcceptedRecordStatusId, 
				Date_Modified = GETDATE(),Modified_By = @UserId WHERE End_Point_POD_Id = @EndPointPOIId;	
		
		IF @ClientId IS NULL
			BEGIN

			SET @assignToProvinceId =(SELECT TOP(1) d.Province_Id FROM apl_User u WITH(NOLOCK) 
				INNER JOIN apl_Employee e WITH(NOLOCK) ON (u.User_Id = e.User_Id)
				INNER JOIN apl_Service_Office so WITH(NOLOCK) ON (e.Service_Office_Id = so.Service_Office_Id)
				INNER JOIN apl_Local_Municipality lm WITH(NOLOCK) ON (lm.Local_Municipality_Id = so.Local_Municipality_Id)
				INNER JOIN apl_District d WITH(NOLOCK) ON (d.District_Id = lm.Local_Municipality_Id));

			SET @ProvinceAbbreviation = (SELECT TOP(1) Abbreviation FROM apl_Province WITH(NOLOCK) WHERE Province_Id = @assignToProvinceId);
			
			INSERT INTO int_Client(Person_Id, Date_Created, Created_By, Is_Active, Is_Deleted, Reference_Number)
			VALUES(@PersonId, GETDATE(), @CreatedBy, 1, 0, @ClientRefNumber);

			INSERT INTO apl_AuditTrial(username, taskperformed,module, datecaptured )
			VALUES( @CreatedBy, 'Assign Client Reference No. ' + @ClientRefNumber, 'Intake', GETDATE())

			SET @ClientId = (SELECT TOP(1) c.Client_Id FROM int_Client c WITH(NOLOCK) 
							  INNER JOIN int_Person p WITH(NOLOCK) ON (p.Person_Id = c.Person_Id));

			SET @ClientRefNumber = 'INT/' + @ProvinceAbbreviation + '/' +@ClientId + '/' + YEAR(GETDATE());
			UPDATE int_Client SET Reference_Number = @ClientRefNumber WHERE Client_Id = @ClientId;

		 END

		 --Verify if worklist is created, avoid duplication
		 IF NOT EXISTS(SELECT * FROM PCM_WorkList WITH(NOLOCK) WHERE End_Point_POD_Id = @EndPointPOIId)
			BEGIN
				--Intake Assessment
				INSERT INTO int_Intake_Assessment(Client_Id, Assessment_Date, Assessed_By_Id, Case_Manager_Supervisor_Id, Case_Manager_Id, Preliminary_Assessment, Presenting_Problem,
					Problem_Sub_Category_Id, Is_Priority_Intervention, Is_Referred_For_Assessment,Is_Referred_To_Other_Service_Provider, Is_Closed,
					Case_Background, Supervisor_Comments,	Social_Worker_Comments, Case_Allocation_Comments,
					Date_Allocated,Date_Due, Is_Active,Is_Deleted, Created_By, Date_Created, Case_Service_Office_Id)
				VALUES(@ClientId, GETDATE(), @UserId, @Allocated_By, @Allocated_By,'Child inconflict with the law', 'Child inconflict with the law',
					22, 1,0,
					0,0, 'Case was reported at ' + @PoliceName,'The child need to be assessed within 24 hours.','I hereby acknowledge received case details','I hereby acknowledge received case details.',
					GETDATE(),@dateDue, 1,0,@CreatedBy, GETDATE(),@ServiceOfficeId)

				SELECT @IntakeAssessmentId = @@IDENTITY; 
	
				INSERT INTO PCM_WorkList(Allocated_By, Date_Accepted, Accepted_By, End_Point_POD_Id,PCM_Record_Status_Id, Intake_Assessment_Id)
				VALUES(@Allocated_By, GETDATE(), @UserId, @EndPointPOIId,@NewRecordStatusId,@IntakeAssessmentId);

				--Case Details
				IF NOT EXISTS(SELECT * FROM PCM_Case_Details WITH(NOLOCK) WHERE Intake_Assessment_Id = @IntakeAssessmentId AND Is_Active = 1)
				BEGIN
					INSERT INTO PCM_Case_Details(Intake_Assessment_Id, Date_Created,Date_Arrested,Time_Arrested, CAS_No,Is_Active, Is_Deleted, Arresting_Officer_Name)
					VALUES(@IntakeAssessmentId, GETDATE(),@ArrestDate,CAST(@ArrestTime AS DATE),@CaseNumber,1,0,@PoliceName)
				END

				--Tracking Case
				IF NOT EXISTS(SELECT * FROM PCM_CaseTracking WITH(NOLOCK) WHERE Intake_Assessment_Id = @IntakeAssessmentId)
				BEGIN
					INSERT INTO PCM_CaseTracking(Created_By, Date_Created, PCM_Module_Level_Id,PCM_Module_subLevel_Id,Intake_Assessment_Id)
					VALUES(@Allocated_By,GETDATE(),1,2,@IntakeAssessmentId)
				END	

				SELECT 0 AS ReturnCode, 'Worklist successfully created.'  AS ReturnMessage
			END
		ELSE
			BEGIN
				SELECT 1 AS ReturnCode, 'Worklist already created.'  AS ReturnMessage
			END		
	
		COMMIT TRANSACTION;

	END TRY  
	BEGIN CATCH  
		SELECT 1 AS ReturnCode, 'Failed to create worklist.' AS ReturnMessage
		ROLLBACK TRANSACTION;
	END CATCH;  

END
