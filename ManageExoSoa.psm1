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