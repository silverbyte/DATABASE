/*
LIST NODE DIRECTORY
LIST DB DIRECTORY
*/

-- catalog NODE (remote connection to DB)
catalog tcpip node NODEJC remote 192.168.0.1 server 50000 

-- catalog DB as NAME (uses remote connection to DB) 
catalog db TRANSPLU as TMW2014 at node NODEJC

--uncatalog database dbname
uncatalog database TMW2014 

--UNCATALOG NODE node-name
uncatalog node NODEJC
 
catalog tcpip node NODEJOE remote 10.1.1.215 server 50010 

catalog db TRANSPLU as DB10_5 at node NODEJC 
catalog db ISC4 as ISC4 at node NODEJOEremote


--Test connection
connect to transplu user db2admin using <password>
Select * from ar_tx_types
