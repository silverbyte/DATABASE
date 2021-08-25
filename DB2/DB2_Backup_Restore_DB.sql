-- prevent users/services from connecting remotely 
Db2set DB2COMM=NULL
-- ALLOW TCPIP connections remotely 
Db2set DB2COMM=TCPIP


----------------- BACKUP PROCEDURE ------------------------------
db2 deactivate database TRANSPLU

-- Force close all users and connections 
Db2 force applications all

/* quiesce db (so no one can connect to DB: redundant but services stay connected and connected so you can’t do online/offline backup */
Db2 quiesce database immediate force connections

-- make offline backup
Db2 backup database ISC4 to D:\DB2Backups\Offline

-- make offline backup with compress
Db2 backup database TRANSPLU to D:\ compress without prompting

-- unquiesce Database
db2 unquiesce db

----------------- RESTORE PROCEDURE ------------------------------
/* restore DB into new database TMW2020 */
RESTORE DATABASE TRANSPLU FROM \\tpbackup\DATABASE\DB2 taken at 20210325020258 ON D: INTO TMW2020 WITH 2 BUFFERS BUFFER 1024 WITHOUT PROMPTING


/* Restore Database name from location taken at time to destination into newdbname with options */
DB2 RESTORE DATABASE TRANSPLU FROM "D:\DB2BACKUPS\Offline" TAKEN AT 20160408173744 TO "D:\TEST" INTO TMW2014 WITH 2 BUFFERS BUFFER 1024 PARALLELISM 1 WITHOUT PROMPTING


/*
restore database live from E:\DB2Backup\Online taken at 20180530144416 on d: into TEST0424 NEWLOGPATH DEFAULT with 2 buffers buffer 1024 without prompting
*/

restore database TRANSPLU from D:\ taken at 20180609165752 on D:\ into TRANSPLU NEWLOGPATH DEFAULT with 2 buffers buffer 1024 without prompting

/* upgrade database to upgrade version */
--old--UPDATE DB CFG FOR ISC4 USING DBHEAP 2400
--old--UPDATE DB CFG FOR TMW2020 USING DBHEAP 2400

--SQL EXECUTE -> DB2 Configs -> TMW2020 or ISC4 
UPDATE DB CFG FOR ISC4 USING APPLHEAPSZ 32000
UPDATE DB CFG FOR TMW2020 USING APPLHEAPSZ 32000
migrate database ISC4
migrate database TMW2020


----------------- RESTORE ONLINE BACKUP ------------------------------
--restore
restore database TRANSPLU from D:\ taken at 20181213110118 TO D:\ into TMW2017 LOGTARGET c:\temp with 2 buffers buffer 1024 without prompting

--rollforward
rollforward db TMW2017 to end of logs AND COMPLETE OVERFLOW LOG PATH (C:\temp) NORETRIEVE

List db
