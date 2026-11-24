function start-manageExoSoa
{
    Param
    (
        #Define other mandatory parameters
        [Parameter(Mandatory = $true)]
        [string]$logFolderPath,
        [Parameter(Mandatory = $true)]
        [array]$mailboxes,
        [Parameter(Mandatory = $true)]
        [string]$mailboxHeaderName,
        [Parameter(Mandatory = $true)]
        [array]$exoCredentials,
        [Parameter(Mandatory = $false)]
        [boolean]$enable=$TRUE,
        [Parameter(Mandatory =$FALSE)]
        [boolean]$allowTelemetryCollection=$TRUE
    )

    $global:htmlTime = @{}
    $global:htmlTime['StartTime']=Get-Date

    $telemetryStartTime = get-universalDateTime

    #Set the window title.

    $windowTitle = ("Start-ManageExoSOA")
    $host.ui.RawUI.WindowTitle = $windowTitle

    #Define exports.

    $exportNames = @{}
    $exportNames['importedData']="ImportedData"
    $exportNames['Success']="Success"
    $exportNames['Errors']="Errors"

    #Create telemetry values.

    $telemetryValues = @{}
    $telemetryValues['telemetryManageExoSOAVersion']="None"
    $telemetryValues['telemetryExchangeOnlineVersion']="None"
    $telemetryValues['telemetryEventName']="Start-M365DomainManagement"

    #Define modules utilized in this script.

    $moduleNames = @{}
    $moduleNames['ManageExoSoa']="ManageExoSoa"
    $moduleNames['ExchangeOnline']="ExchangeOnlineManagement"

    #Define random variables.

    $maxCredentialCount = 5
    $threadSafeList = [System.Collections.Concurrent.ConcurrentBag[psObject]]::new()
    $chunks = [System.Collections.Generic.List[psCustomObject]]::New()

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

    out-xmlFile -itemToExport $Mailboxes -itemNameToExport $exportNames['importedData']

    if ($allowTelemetryCollection -eq $TRUE)
    {
        start-telemetryConfiguration -allowTelemetryCollection $allowTelemetryCollection -appInsightAPIKey $appInsightAPIKey -traceModuleName $traceModuleName
    }

    #Test and record powershell module versions.

    $global:htmlTime['PowerShellVersionTest']=Get-Date

    $telemetryValues['telemetryManageExoSOAVersion']=test-PowerShellModule -powershellModuleName $moduleNames.manageExoSoa -powershellVersionTest:$TRUE
    $telemetryValues['telemetryExchangeOnlineVersion']=test-PowerShellModule -powershellModuleName $moduleNames.ExchangeOnline -powershellVersionTest:$TRUE

    #Test that each credential provided is a pscredential.

    $global:htmlTime['TestExoCredentials']=Get-Date

    if ($exoCredentials.count -gt $maxCredentialCount)
    {
        out-logfile -string "EXCEPTION_MAX_CREDS_EXCEEDED: Maximum number of supported credentials is 5." -isError:$TRUE
    }

    foreach ($credential in $exoCredentials)
    {
        test-credentials -credentialsToTest $credential
    }

    $global:htmlTime['TestEXOConnections']=Get-Date

    test-exoCredentials -exoCredentials $exoCredentials

    $global:htmlTime['StartBatchProcessing']=Get-Date

    $chunks = get-ChunkList -listToChunk $mailboxes -userBatchSize 100

    out-logfile -string "Clearing mailboxes memory."
    $mailboxes = $null

    $global:htmlTime['StartExchangeProcessing']=Get-Date

    $threadSafeList = start-ExchangeProcessing -chunks $chunks -enable $enable -mailboxHeaderName $mailboxHeaderName -exoCredentials $exoCredentials -outputStorage $threadSafeList

    $global:htmlTime['StartHTMLProcess']=Get-Date

    generate-htmlReport -threadSafeList $threadSafeList

    $global:htmlTime['ExportFinalInfo']=Get-Date

    wait-debugger

    $success = $threadSafeList | where {$_.errorMessage -eq "none"}
    $errors = $threadSafeList | where {$_.errorMessage -ne "none"}

    out-xmlfile -itemToExport ($thredSafeList | where {$_.errorMessage -eq "None"}) -itemNameToExport $exportNames ['Success']
    out-xmlfile -itemToExport ($thredSafeList | where {$_.errorMessage -ne "None"}) -itemNameToExport $exportNames ['Errors']

    $telemetryEndTime = get-universalDateTime

    [double]$telemetryElapsedSeconds = get-elapsedTime -startTime $telemetryStartTime -endTime $telemetryEndTime

    $telemetryEventProperties = @{
        M365DomainMGMT = "Start-ManageExoSOA"
        M365DomainMGMTVersion = $telemetryValues.telemetryM365DomainMgmtVersion
        ExchangeOnline = $telemetryValues.telemetryExchangeOnlineVersion
    }

    $telemetryEventMetrics = @{
            TotalTime = $telemetryElapsedSeconds  
    }

    send-TelemetryEvent -traceModuleName $traceModuleName -eventName $telemetryValues.telemetryEventName -eventMetrics $telemetryEventMetrics -eventProperties $telemetryEventProperties
}