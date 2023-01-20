--Child notification database

--Query to be modified

 begin transaction
	update [PoliceStation_Supervisor] set Username = 'Tchele'
	select * from [PoliceStation_Supervisor] with(nolock)
	rollback transaction