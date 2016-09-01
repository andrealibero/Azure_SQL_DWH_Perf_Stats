#* FileName: Azure_SQL_DWH_Perf_Stats.ps1
#*=============================================
#* Script Name: Azure_SQL_DWH_Perf_Stats.ps1
#* Created: [06/24/2016]
#* Author: Andrea Liberatore
#* Company: Microsoft
#* Email: andreal@microsoft.com
#* Requirements:
#*
#* Keywords:
#*=============================================
#* Purpose: Collect performance statistics from 
#* Azure SQL Data Warehouse 
#*=============================================

#*=============================================
#* REVISION HISTORY
#*=============================================
#* Date: 8/30/2016
#* Time: 
#* Issue:
#* Solution:
#*
#*=============================================


<#
           .SYNOPSIS 
           Collect performance statistics on Azure SQL Data Warehouse.

           .DESCRIPTION
           The Azure_SQL_DWH_Perf_Stats script produces performance statistics on Azure SQL Data Warehouse instance.

           .PARAMETER Servername
           Specifies the Azure SQL Server name (i.e. server_name.database.windows.net)

           .PARAMETER Databasename
           Specifies the Azure SQL Data Warehouse instance name.

           .PARAMETER Username
           Specifies the Azure SQL Data Warehouse server username

           .PARAMETER Password
           Specifies the Azure SQL Data Warehouse server password.

           .PARAMETER iterations
           Specifies the number of iterations. Meaningful if Stat switch is present.

           .PARAMETER sleepInterval
           Specifies the sleep time between iterations. Meaningful if Stat switch is present.

           .PARAMETER Stats
           Specifies if collecting performance statistics about running queries in a loop.

           .PARAMETER NoStatsSnapshot
           Disable performance statistics collection in the final snapshot. The final snapshot collect data regarding complete and running queries.

           .PARAMETER AADAuth
           Specifies if using Active Directory Password (requires July 2016 update for SSMS).

		   .PARAMETER Output
           Specifies output folder. Default value is the current folder.
                          
           .INPUTS
           None. You cannot pipe objects to Azure_SQL_DWH_Perf_Stats.ps1.

           .OUTPUTS
           Azure_SQL_DWH_Perf_Stats produces a folder containing performance statistics.

           .EXAMPLE
           C:\PS> .\Azure_SQL_DWH_Perf_Stats.ps1 "csssupporttest.database.windows.net" "csssupporttest" "username" "123abc"  -iterations 3 -sleepInterval 5 -Stats -NoStatsSnapshot 
		
		   .NOTES 
		    AUTHOR: Andrea Liberatore
			LASTEDIT: Aug 29, 2016 

          #>


[CmdletBinding()] 
Param(
        [Parameter(Mandatory=$True,Position=1)][string]$Servername,
        [Parameter(Mandatory=$True,Position=2)][string]$Databasename,
        [Parameter(Mandatory=$True,Position=3)][string]$Username,
        [Parameter(Position=4)][string]$Password,
        [int]$iterations, 
        [int]$sleepInterval,
        [switch]$Stats,
        [switch]$NoStatsSnapshot,
        [switch]$AADAuth,
		[string]$Output)

if(!$Password)
{
    $securePassword = Read-Host "Password" -AsSecureString
	$P = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($securePassword))
}
else
{
    $P=$Password;
}
$masterConnectionstring = "Server=tcp:" + $Servername + ",1433;Initial Catalog=master;Persist Security Info=False;User ID=" + $Username + ";Password=" + $P + ";MultipleActiveResultSets=False;Encrypt=True;TrustServerCertificate=False;Authentication=""Active Directory Password"""  
$userDBConnectionString = "Server=tcp:" + $Servername + ",1433;Initial Catalog=" + $Databasename + ";Persist Security Info=False;User ID=" + $Username + ";Password=" + $P + ";MultipleActiveResultSets=False;Encrypt=True;TrustServerCertificate=False;Authentication=""Active Directory Password"""  

#Write-host "`nServername: $Servername"
#Write-host "`nUsername: $Username"
#Write-host "`nPassword: $Password"
#Write-host "`nP: $P"
#Write-host "`nDatabasename: $Databasename"
#Write-host "`nmasterConnectionstring: $masterConnectionstring"
#Write-host "`nuserDBConnectionString: $userDBConnectionString"
#Write-host "`niterations: $iterations"
#Write-host "`nsleepInterval: $sleepInterval"
#Write-host "`nStats: $Stats"
#Write-host "`nNoStatsSnapshot: $NoStatsSnapshot"
#Write-host "`nAADAuth: $AADAuth"


$scriptInvocation = (Get-Variable MyInvocation).Value
$rootPath = Split-Path $scriptInvocation.MyCommand.Path                                       


function Stats_Collection
{
	#try catch around everything to make sure we catch anything we missed
	try
	{
		$startTime= get-date

		#Load SQL PowerShell module
		Write-Host -ForegroundColor Cyan "`nLoading SQL PowerShell Module...`n"
		LoadSqlPowerShell
			
	    #Read config.xml file into variable
	    if (test-path $rootPath\config.xml){[xml]$inputFile = Get-Content $rootPath\config.xml}
	    else 
	    {
		    write-error "Not able to find input file: .\config.xml"
	    }

	    #set up the output directory
		if (!$Output)
		{
		    $outputDir = $rootPath + "\Output_$(get-date -f yyyy-MM-dd_hhmmss)"
		}
		else
		{
			$outputDir = $Output + "\Output_$(get-date -f yyyy-MM-dd_hhmmss)"
		}
	    mkdir $outputDir -Force | Out-Null
		
		if (!(test-path $outputDir))
		{
			write-error "Output Path $outputDir could not be found"
		}
		
		Write-host "`nOutput Directory set to $outputdir"
	
	    if($Stats)
	    {
            if($iterations -ne 0) 
            {
                $maxloop = $iterations
            }
            else
            {
                $maxloop = 30
            }

            if($sleepInterval -ne 0) 
            {
                $sleeptime = $sleepInterval
            }
            else
            {
                $sleeptime = 30
            }

            Write-Host "Running iterations: $maxloop"
            Write-Host "Sleep time: $sleeptime"
            
            Write-Host "`nPress 'q' to terminate"
            $i = 0
            $outputPath = $outputDir + '\' + $Servername + '_Azure_SQL_DWH_Perf_Stats.out'
            while ($i -lt $maxloop) 
			{
                $iternationTime= get-date
                Write-Host "`nIteration #$i started at $iternationTime" 
                "`n---------------> ITERATION #$i started at $iternationTime" | Out-File $outputPath -Append

				foreach ($menuAction in ($inputFile.options.option | ? {$_.name -eq "PerfStats"}).action)
				{
                    ExecuteAction "PerfStats" $menuAction.title $outputPath 
    			}

                "`n|-------------------------------------------------------------------------|`n" | Out-File $outputPath -Append

                if ($Host.UI.RawUI.KeyAvailable -and ("q" -eq $Host.UI.RawUI.ReadKey("IncludeKeyUp,NoEcho").Character)) {
                    Write-Host "Exiting...." -Background DarkRed
                    break;
                }
                Write-Host -ForegroundColor Cyan "Sleeping $sleeptime sec."
                Start-Sleep -Seconds $sleeptime
                $i=$i+1  
			}
        }

	    if(!$NoStatsSnapshot)
	    {
            $snapshotTime = get-date
            Write-Host "`nTaking snapshot at $snapshotTime"
            #$outputPath = $outputDir + '\' + $Servername + '_Azure_SQL_DWH_Perf_Stats_Snapshot.out'
            foreach ($menuAction in ($inputFile.options.option | ? {$_.name -eq "PerfStatsSnapshot"}).action)
			{
                $outputPath = $outputDir + '\' + $menuAction.name + '_Azure_SQL_DWH_Perf_Stats_Snapshot.csv'
                ExecuteAction "PerfStatsSnapshot" $menuAction.title $outputPath 
    		}

            $outputPath = $outputDir + '\' + $Servername + '_Azure_SQL_DWH_Perf_Stats_Snapshot_Server.out'
            foreach ($menuAction in ($inputFile.options.option | ? {$_.name -eq "Server"}).action)
			{
                ExecuteAction "Server" $menuAction.title $outputPath "master"
    		}
        }
        
        Write-Host "`nDiagnostics Output located under: $outputDir"
        $endTime = get-date
        $TimeSpan = $endTime-$starttime
		write-host "`nEnd Time:   $endTime - Start Time: $starttime - Duration: ($TimeSpan)"
	}
	catch
	{
		Write-Error -ErrorAction continue "ERROR OCCURED DURING EXECUTION - PRESS ENTER TO CLOSE WINDOW`n`n$_"
		Read-Host
	}
}


function ExecuteAction([string]$Option, [string]$Action, [string]$outputpath, [string]$Database)
{
	$QueryObject = ($inputFile.options.option | ? {$_.name -eq $Option}).action | ? {$_.title -eq $Action}

    if (!$Database)
    {
        $Database = $Databasename
    }

	$Error.clear()
	
	Write-Host -ForegroundColor Cyan "EXECUTING: $($QueryObject.title)"
                 		
	#Run query against Azure DWH
	try
	{
        $executionTime = get-date
        if ($outputpath.toLower().EndsWith('.csv'))
        {
            if ($AADAuth -eq $false)
            {
                if ($($QueryObject.output) -eq "Y")
				{
					invoke-sqlcmd -query $($QueryObject.value) -serverInstance $Servername -username $Username -password $P -Database $Database | Export-Csv -NoTypeInformation -Delimiter "," -path $outputPath
				}
				else
				{
					invoke-sqlcmd -query $($QueryObject.value) -serverInstance $Servername -username $Username -password $P -Database $Database
				}
            }
            else
            {
                if ($Database -eq "master")
                {
					if ($($QueryObject.output) -eq "Y")
					{
						invoke-sqlcmd -query $($QueryObject.value) -connectionstring $masterConnectionstring | Export-Csv -NoTypeInformation -Delimiter "," -path $outputPath
					}
					else
					{ 
						invoke-sqlcmd -query $($QueryObject.value) -connectionstring $masterConnectionstring
					}
                }
                else
                {
					if ($($QueryObject.output) -eq "Y")
					{
						invoke-sqlcmd -query $($QueryObject.value) -connectionstring $userDBConnectionstring | Export-Csv -NoTypeInformation -Delimiter "," -path $outputPath
					}
					else
					{
						invoke-sqlcmd -query $($QueryObject.value) -connectionstring $userDBConnectionstring
					}
                }
            }
        }
        else
        {
			"`nExecution time: $executionTime - Title: $($QueryObject.title) - Query: $($QueryObject.value)" | Out-File $outputPath -Append
            "`nNote: you might notice some not expected additional columns included in the query result: RowError, RowState, Table, ItemArray, and HasErrors.`nYou may want to ignore it. Check https://connect.microsoft.com/SQLServer/feedback/details/415790/invoke-sqlcmd-showing-additional-properties-in-powershell-v2-ctp3 for further details." | Out-File $outputPath -Append
            if ($AADAuth -eq $false)
            {
				if ($($QueryObject.output) -eq "Y")
				{
					invoke-sqlcmd -query $($QueryObject.value) -serverInstance $Servername -username $Username -password $P -Database $Database | Format-Table -Property * | Out-File $outputPath -Append -Width 1024;
				}
				else
				{
					invoke-sqlcmd -query $($QueryObject.value) -serverInstance $Servername -username $Username -password $P -Database $Database
				}

            }
            else
            {
				if ($($QueryObject.output) -eq "Y")
				{
					invoke-sqlcmd -query $($QueryObject.value) -connectionstring $userDBConnectionstring | Format-Table -Property * | Out-File $outputPath -Append -Width 1024;
				}
				else
				{
					invoke-sqlcmd -query $($QueryObject.value) -connectionstring $userDBConnectionstring
				}
            }
        }
	}
	catch
	{
		Write-Output "Error Encountered during Query: `'$($QueryObject.name)`'`n`n$_" >> $outputpath
		Write-Error "Error Executing $($QueryObject.name)`n$($_.FullyQualifiedErrorId)" -ErrorAction Continue
	}
}

Function LoadSqlPowerShell
{
	Push-Location

    If ($AADAuth -eq $true)
    {
        # New SQL PowerShell module enables AAD authentication support thanks to new Invoke-SqlCmd ConnectionString parameter.
		# Check https://blogs.technet.microsoft.com/dataplatforminsider/2016/06/30/sql-powershell-july-2016-update/  and https://blogs.msdn.microsoft.com/sqlreleaseservices/announcing-sql-server-management-studio-july-2016-release/ for further details.

		$SQLPS = Get-Module -name SQLPS
		if ($SQLPS)
		{
			Remove-Module -name SQLPS -ErrorAction Continue 
			Write-Debug "Removed SQLPS PowerShell module"
		}
		try
		{
			Import-Module SQLServer -DisableNameChecking
		}
		catch
		{
			write-error "Error importing SQLServer PowerShell module. AADAuth requires SSMS 2016 >= July 16 update" -ErrorAction Stop
		}
    }
    else
    {
		$SQLServer = Get-Module -name SQLServer
		if ($SQLServer)
		{
			Remove-Module -name SQLServer -ErrorAction Continue
			Write-Debug "Removed SQLServer PowerShell module"
		}

	    Import-Module SQLPS -DisableNameChecking
    }
    
	Pop-Location
}


. Stats_Collection