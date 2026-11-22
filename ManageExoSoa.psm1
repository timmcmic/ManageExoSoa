function start-manageExoSoa
{
    Param
    (
        #Define other mandatory parameters
        [Parameter(Mandatory = $true)]
        [string]$logFolderPath,
        [Parameter(Mandatory = $true)]
        [string]$mailboxes,
        [Parameter(Mandatory = $true)]
        [array]$exoCredentials,
        [Parameter(Mandatory =$FALSE)]
        [boolean]$allowTelemetryCollection=$TRUE
    )
}

$global:htmlTime = @{}
$global:htmlTime['StartTime']=Get-Date

$telemetryStartTime = get-universalDateTime

#Set the window title.

$windowTitle = ("Start-ManageExoSOA")
$host.ui.RawUI.WindowTitle = $windowTitle

#Define telemetry values.

#Create telemetry values.

$telemetryValues = @{}
$telemetryValues['telemetryManageExoSOAVersion']="None"
$telemetryValues['telemetryExchangeOnlineVersion']="None"
$telemetryValues['telemetryEventName']="Start-M365DomainManagement"

#Define modules utilized in this script.

$moduleNames = @{}
$moduleNames['ManageExoSoa']="ManageExoSoa"
$moduleNames['ExchangeOnline']="ExchangeOnlineManagement"

#Initialize telemetry collection.

$appInsightAPIKey = "63d673af-33f4-401c-931e-f0b64a218d89"
$traceModuleName = "M365DomainMgmt"

#Define Logging

#Variables for logging and start log file.

$global:logFile=$NULL
$logFileName = "ManageExoSoa_"+(Get-Date -Format FileDateTime)

new-logfile -logFileName $logFileName -logFolderPath $logFolderPath

out-logfile -string "*****************************************************"
out-logfile -string "Entering Start-ManageExoSoa"
out-logfile -string "*****************************************************"

if ($allowTelemetryCollection -eq $TRUE)
{
    start-telemetryConfiguration -allowTelemetryCollection $allowTelemetryCollection -appInsightAPIKey $appInsightAPIKey -traceModuleName $traceModuleName
}

#Test and record powershell module versions.

$global:htmlTime['PowerShellVersionTest']=Get-Date

$telemetryValues['telemetryManageExoSOAVersion']=test-PowerShellModule -powershellModuleName $moduleNames.manageExoSoa -powershellVersionTest:$TRUE
$telemetryValues['telemetryExchangeOnlineVersion']=test-PowerShellModule -powershellModuleName $moduleNames.ExchangeOnline -powershellVersionTest:$TRUE







$telemetryEndTime = get-universalDateTime

[double]$telemetryElapsedSeconds = get-elapsedTime -startTime $telemetryStartTime -endTime $telemetryEndTime

$telemetryEventProperties = @{
    M365DomainMGMT = "Start-M365DomainManagement"
    M365DomainMGMTVersion = $telemetryValues.telemetryM365DomainMgmtVersion
    ExchangeOnline = $telemetryValues.telemetryExchangeOnlineVersion
    OperationSelected = $domainOperation
}

$telemetryEventMetrics = @{
        TotalTime = $telemetryElapsedSeconds  
}
