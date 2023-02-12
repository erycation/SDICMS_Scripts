-- Author:		Eric Malekutu
-- Create date: 31 January 2023
-- Description:	Display dashboard for cases

--exec PCM_MobileDashboard 8

CREATE PROCEDURE [dbo].[PCM_MobileDashboard]
	
	@UserId INT

AS
	DECLARE @NewRecordStatusId INT;
	DECLARE @AcceptedRecordStatusId INT;
	DECLARE @NewPropationOfficerInbox INT;
	DECLARE @NewWorklist INT;
	DECLARE @ReassignCases INT;
BEGIN

	SET NOCOUNT ON;

	SET @NewRecordStatusId = (SELECT PCM_Record_Status_Id FROM apl_PCM_Record_Status WITH(NOLOCK) WHERE Description = 'New');
	SET @AcceptedRecordStatusId = (SELECT PCM_Record_Status_Id FROM apl_PCM_Record_Status WITH(NOLOCK) WHERE Description = 'Accepted');

	SET @NewPropationOfficerInbox = (SELECT COUNT(*) AS NewInbox FROM PCM_EndPoint_PO_Inbox WITH(NOLOCK)
					 WHERE Case_Allocated_To = @UserId AND Endpoint_Record_Status_Id = @NewRecordStatusId)
	SET @NewWorklist = (SELECT COUNT(*) AS NewWorklist FROM PCM_WorkList WITH(NOLOCK)
						WHERE PCM_Record_Status_Id = @NewRecordStatusId AND Accepted_By = @UserId)
	SET @ReassignCases = (SELECT COUNT(*) AS ReAssigned FROM PCM_EndPoint_PO_Inbox WITH(NOLOCK)
						WHERE Allocated_ByS = @UserId AND Endpoint_Record_Status_Id = @NewRecordStatusId)

	SELECT @NewPropationOfficerInbox AS NewPropationOfficerInbox, @NewWorklist AS NewWorklist, @ReassignCases AS ReAssignedCases


END
