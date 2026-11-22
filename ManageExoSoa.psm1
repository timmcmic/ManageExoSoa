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

#Initialize telemetry collection.

$appInsightAPIKey = "63d673af-33f4-401c-931e-f0b64a218d89"
$traceModuleName = "M365DomainMgmt"

if ($allowTelemetryCollection -eq $TRUE)
{
    start-telemetryConfiguration -allowTelemetryCollection $allowTelemetryCollection -appInsightAPIKey $appInsightAPIKey -traceModuleName $traceModuleName
}

