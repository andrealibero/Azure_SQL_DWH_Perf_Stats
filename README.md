# Azure SQL DWH Perf Stats 1.0.0

Azure SQL DWH Perf Stats is a PowerShell script to make Azure SQL Data Warehouse performance troubleshooting easier.

The script (Azure_SQL_DWH_Perf_Stats.ps1) allows to capture several DMV outputs related to
running queries in a loop: the user can provide the number of iterations and the sleep time between them. 

Additionally the script captures useful data in a single final snapshot, including table data skew, statistics last update time, running and complete queries and much more.

## Prerequirements
SQLPS PowerShell module or SQLServer PowerShell module (required to Azure Active Directory Password authentication)

> SQLServer PowerShell module is available from SQL Server Management Studio 2016 July 2016 release on.

## Installation
The tool doesn't have any setup. Just make sure you download the following files:
- Azure_SQL_DWH_Perf_Stats.ps1
- config.xml

## Instructions
In order to run the script, you need:
  - Azure SQL DW server name (format: <server_name>.database.windows.net)
  - Azure SQL DW database name
  - Username and password (the user must have db_owner role)

To create AAD user and add to db_owner role:  
```sh
CREATE USER [user@domain.com] FROM EXTERNAL PROVIDER;
EXEC sp_addrolemember 'db_owner', 'user@domain.com';
 ```
  
### SYNTAX

    C:\Azure_SQL_DWH_Perf_Stats\Azure_SQL_DWH_Perf_Stats.ps1 [-Servername] <String> [-Databasename] <String> [-Username] <String> [[-Password] <String>] [-iterations <Int32>] [-sleepInterval <Int32>] [-Stats] [-NoStatsSnapshot] [-AADAuth] [-Output <String>] [<CommonParameters>]
	
### PARAMETERS

    -Servername <String>
        Specifies the Azure SQL Server name (i.e. server_name.database.windows.net)

    -Databasename <String>
        Specifies the Azure SQL Data Warehouse instance name.

    -Username <String>
        Specifies the Azure SQL Data Warehouse server username

    -Password <String>
        Specifies the Azure SQL Data Warehouse server password.

    -iterations <Int32>
        Specifies the number of iterations. Meaningful if Stat switch is present.

    -sleepInterval <Int32>
        Specifies the sleep time between iterations. Meaningful if Stat switch is present.

    -Stats [<SwitchParameter>]
        Specifies if collecting performance statistics about running queries in a loop.

    -NoStatsSnapshot [<SwitchParameter>]
        Disable performance statistics collection in the final snapshot. The final snapshot collect data regarding
        complete and running queries.

    -AADAuth [<SwitchParameter>]
        Specifies if using Active Directory Password (requires July 2016 update for SSMS).

    -Output <String>
        Specifies output folder. Default value is the current folder.

		
## Examples

### Command line with default values

 ```sh
PS c:\Azure_SQL_DW_Perf_Stats> .\Azure_SQL_DWH_Perf_Stats.ps1 server_name.database.windows.net dwdbname username password
 ```
 
 The above command line will capture a performance statistics shapshot including the following info:
 - Clustered Columnstore index health: statistics about the number of rows for each rowgroup (OPEN, CLOSED, COMPRESSED) for each CCI. For further details on CCI in Azure SQL DW, see  [Indexing tables in SQL Data Warehouse](https://azure.microsoft.com/en-us/documentation/articles/sql-data-warehouse-tables-index/)
 - Table data skew: provides with data skew percentage for each distributed table. See [Distributing tables in SQL Data Warehouse](https://azure.microsoft.com/en-us/documentation/articles/sql-data-warehouse-tables-distribute/)
 - Statistic last update date for user-defined statistics: not updated statistics impacts on query execution plans which in turn affect performance.
 - Workload roles: user list for smallrc, mediumrc, largerc and xlargerc resource classes.
 - Several DMV query results: sys.dm_pdw_waits, sys.dm_pdw_resource_waits, sys.dm_pdw_wait_stats, sys.dm_pdw_exec_sessions, sys.dm_pdw_exec_requests, sys.dm_pdw_request_steps, sys.dm_pdw_sql_requests, sys.dm_pdw_dms_workers, sys.pdw_loader_backup_runs, sys.pdw_loader_backup_run_detail, sys.dm_pdw_errors, sys.database_service_objectives, sys.dm_operation_status, others.

Output is saved as different .csv files, one for each information category or DMV.

 
### Command line with DMV collection loop

 ```sh
PS c:\Azure_SQL_DWH_Perf_Stats> .\Azure_SQL_DWH_Perf_Stats.ps1 server_name.database.windows.net dwdbname username password -Stats -iterations 10 -sleepInterval 60 
 ```
The above command leverages the "Stats" switch that allows to run a DMV query set filtered on currently running workload several times: the number of iterations is given by the "iterations" parameter value. After each iteration the script waits for a number of seconds specified through the "sleepInterval" parameter value.
Once the capture loop ends, a final snaphost (the same as the one captures by command line with default values) is taken.
This option is thought for troubleshooting long running operations, such as backup/loads, concurrency slot exhaustion scenarios, CTAS causing heavy data movements, locking issues, ...
The output is saved as a single text file, reporting begin and end markers for each iteration output.

### Command line with DMV collection loop only

```sh
PS c:\Azure_SQL_DWH_Perf_Stats> .\Azure_SQL_DWH_Perf_Stats.ps1 server_name.database.windows.net dwdbname username password -Stats -iterations 10 -sleepInterval 60  -NoStatsSnapshot
 ```
 
 If you are not interested in the final snaphost and want to only capture the DMV collection loop, you may want to add the NoStatsSnapshot switch.
 
 
 ### Command line with Azure Active Directory Password authentication
 
 ```sh
PS c:\Azure_SQL_DWH_Perf_Stats> .\Azure_SQL_DWH_Perf_Stats.ps1 server_name.database.windows.net dwdbname username@customdomain.com password -Stats -iterations 10 -sleepInterval 60  -AADAuth
 ```
 
 By adding the AADAuth switch, you can take advantage of the Azure Active Directory Password authentication method. 
 
 > AAD Auth requires SQLServer PowerShell module, available from SQL Server Management Studio 2016 July 2016 release on. refer to [SQL Server blog](https://blogs.technet.microsoft.com/dataplatforminsider/2016/06/30/sql-powershell-july-2016-update/) for further details.

This project has adopted the [Microsoft Open Source Code of Conduct](https://opensource.microsoft.com/codeofconduct/).
For more information see the [Code of Conduct FAQ](https://opensource.microsoft.com/codeofconduct/faq/) or
contact [opencode@microsoft.com](mailto:opencode@microsoft.com) with any additional questions or comments.
 
