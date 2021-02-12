/*ENABLING DB CHAINNING PERMISSIONS AT SERVER LEVEL*/
USE master;
GO
EXECUTE sp_configure 'cross db ownership chaining', 1;
RECONFIGURE;
/*Set the owner login to the database to the same user*/
ALTER AUTHORIZATION ON DATABASE::RPS2012Real TO RPSUser
ALTER AUTHORIZATION ON DATABASE::Ausolan TO RPSUser
/*
Management steps
-Create a login
-Create a user in the Ausolan (S) DB with read permission for the login created just before
-Create a user in RPS2012Real (C) DB without permission for the login created just before
-Now the login can read on database (S) and cannot connecto to database (C)

Result:
When the login reads a view of DB (S) that uses tables of table (C) permission chainning enters and
alows the user to perform the select.
Without this Select permissions must be granted on C database
*/