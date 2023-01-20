
--uncomment hours condition when going to live

USE [Child_Notification]
GO
/****** Object:  StoredProcedure [dbo].[Get_NotificationCasesBySupervisor]    Script Date: 2023/01/20 11:31:26 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/*
	Author:		 Malekutu Eric
	Create date: 05 Dec 2022
	Description: Display cases information by supervisor
*/

--exec Get_NotificationCasesBySupervisor 'Tchele'

CREATE PROCEDURE [dbo].[Get_NotificationCasesBySupervisor]
	
	@SupervisorName varchar(50)

AS
BEGIN

SELECT Distinct F.CaseInformationID,H.NotificacationId,H.MessageRefNumber,'NotAssigned' AS CaseStatus, 
			H.MessageSourceName, H.MessageSource, H.NotificationDate, H.Timestamp, H.NotificationTypeVersion, 
			NULL AS EmployeeDetailsId, '' AS Surname, '' AS FirstName,'' AS PersalNo, 
			'' AS ContactNumber, A.PoliceStationId,
			A.PoliceStationName,F.CasNumber,48 - DATEDIFF(hour, H.NotificationDate, GETDATE()) AS HoursLeft, 
			B.SupervisorId,H.RespondStatus,E.SAPSInfoId,E.[PoliceName] + ' ' + E.[PoliceSurName] AS PoliceFullNames
			,E.[PoliceUnitName],E.[ContactDetailsText] AS PoliceOfficerContact,E.[ComponentCode],R.RankDescription,'' AS [POName],'' AS [POSurname],
			G.ChildInformationID,G.PersonName + ' ' + G.PersonLastName AS [ChildName], G.PersonDateOfBirth AS [ChildDateOfBirth],
			F.ProbationOfficerAllocatedDate AS [OfficerAssignedDate],[ArrestDate],[ArrestTime], F.OffenseType
			FROM [apl_PoliceStation] A WITH(NOLOCK)
				INNER JOIN PoliceStation_Supervisor B WITH(NOLOCK) ON B.PoliceStationId = A.PoliceStationId
				INNER JOIN SAPSInfo E WITH(NOLOCK) ON E.PoliceStatitionId=A.PoliceStationId
				LEFT OUTER JOIN apl_SAPSOfficialRank R WITH(NOLOCK) ON E.SAPSOfficialRankId = R.SAPSOfficialRankId
				INNER JOIN CaseInformation F WITH(NOLOCK) ON F.SAPSInfoId = E.SAPSInfoId
				INNER JOIN ChildInformation G WITH(NOLOCK) ON G.ChildInformationID=F.ChildInformationID
				INNER JOIN [Notification] H WITH(NOLOCK) ON H.NotificacationId= F.NotificacationId
				INNER JOIN Module I WITH(NOLOCK) ON I.ModuleId = H.ModuleId
				WHERE B.Username = @SupervisorName AND H.RespondStatus = 1 
				--AND (48 - DATEDIFF(hour, H.NotificationDate, GETDATE()) > 0)
				Order by HoursLeft DESC
				

END
