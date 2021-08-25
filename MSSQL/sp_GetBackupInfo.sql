/*
Here are two scripts designed for backup purposes -- the first returns the last date a database was backed up and the second reports on backup activity for all databases, sorted by date of backup. 

The Get Last Backup script allows you to report the last date of backup for all databases on a server, or you can pass in a specific database name and the script will report the date the database was last backed up. 

In addition to providing all database backup activity, the Get Backup Info script will also allow you to filter by a specific database name as well. 

*/

/**********************************************************
  sp_GetBackupInfo
**********************************************************/


if
  exists
  (
    select * from SysObjects
      where ID = Object_ID('sp_GetBackupInfo')
        and ObjectProperty(ID, 'IsProcedure') = 1
  )
begin
  drop procedure sp_GetBackupInfo
end
go

create procedure sp_GetBackupInfo
  @Name varchar(100) = '%'
with Encryption
as
  set NoCount on

  declare 
    @result int

  --try

    select 
        (substring ( database_name, 1, 32)) as Database_Name,
        abs(DateDiff(day, GetDate(), backup_finish_date)) as DaysSinceBackup,
        backup_finish_date
      from msdb.dbo.backupset
      where Database_Name like @Name
      order by Database_Name, backup_finish_date desc

  --finally
    SuccessProc:
    return 0  /* success */

  --except
    ErrorProc:
    return 1 /* failure */
  --end
go

grant execute on sp_GetBackupInfo to Public
go



/*

sp_GetBackupInfo 'hgp'

*/





/**********************************************************
  sp_GetLastBackup
**********************************************************/

if
  exists
  (
    select * from SysObjects
      where ID = Object_ID('sp_GetLastBackup')
        and ObjectProperty(ID, 'IsProcedure') = 1
  )
begin
  drop procedure sp_GetLastBackup
end
go

create procedure sp_GetLastBackup
  @Name varchar(100) = '%'
with Encryption
as
  set NoCount on

  declare 
    @result int

  --try

    select 
        (substring ( database_name, 1, 32)) as Database_Name,
        abs(DateDiff(day, GetDate(), Max(backup_finish_date))) as DaysSinceBackup,
        Max(backup_finish_date)
      from msdb.dbo.backupset
      where Database_Name like @Name
      group by Database_Name
      order by Database_Name

  --finally
    SuccessProc:
    return 0  /* success */

  --except
    ErrorProc:
    return 1 /* failure */
  --end
go

grant execute on sp_GetLastBackup to Public
go



/*

sp_GetLastBackup 'hgp'

*/