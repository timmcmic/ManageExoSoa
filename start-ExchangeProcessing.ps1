function start-ExchangeProcessing
{
    Param
    (
        #Define other mandatory parameters
        [Parameter(Mandatory = $true)]
        $chunks,
        [Parameter(Mandatory = $true)]
        [string]$mailboxHeaderName,
        [Parameter(Mandatory = $true)]
        [array]$exoCredentials,
        [Parameter(Mandatory = $false)]
        [boolean]$enable=$TRUE,
        [Parameter(Mandatory = $false)]
        $outputStorage
    )

    out-logfile -string "Entering start-ExchangeProcessing"

    $myFunction = ${function:out-logfile}.tostring()
    $counter = [System.Collections.Concurrent.ConcurrentDictionary[string,int]]::new()

    $counter['Count'] = 0

    $chunks | foreach-object -Parallel {
        $global:logfile = $using:logFile
        $function = $using:myFunction
        $counter = $using:counter
        $exoCredentials = $using:exoCredentials
        $headerValue = $using:mailboxHeaderName
        $enable = $using:enable
        
        $scriptblock = [scriptblock]::Create($function)

        set-item -path "Function:\Out-Logfile" -value $scriptBlock

        out-logfile -string "Increment the thread counter."

        $threadCounter = $counter.addOrUpdate('Count',1,[Func[string,int,int]] { param($key, $value) $value + 1 })
        $credentialCounter = $threadCounter % $exoCredentials.count

        out-logfile -string ("This is the current thread counter: "+$threadCounter.tostring())
        out-logfile  -string ("This is the current credential counter: "+$credentialCounter.tostring())

        out-logfile -string ($threadCounter.tostring() + ":Thread attempting exchange online connection.")

        try
        {
            connect-exchangeonline -credential $exoCredentials[$credentialCounter] -disableWAM -errorAction STOP
        }
        catch
        {
            out-logfile -string ($threadCounter.tostring() + ":Thread attempting exchange online connection.")
            out-logfile -string ($threadCounter.tostring() + ":" + $_.exception.message)
            exit
        }

        out-logfile -string ($threadCounter.tostring() + ":Obtain the Exchange Online Connection ID.")

         try
        {
            $connectionID = (get-ConnectionInformation -errorAction STOP).connectionID
            out-logfile -string ($threadCounter.tostring() + ":ConnectionID:"+$connectionID.tostring())
        }
        catch
        {
            out-logfile -string "Unable to obtain the connection id."
            out-logfile -string $_
            exit
        }

        out-logfile -string ($threadCounter.tostring() + ":Using header: " + $headerValue)
        out-logfile -string ($_.count.tostring())

        foreach ($id in $psitem.($headerValue))
        {
            $functionObject = New-Object PSObject -Property @{
                ID = "None"
                PreviousState = "None"
                NewState = "None"
                ErrorMessage = "None"
            }

            out-logfile -string ($threadCounter.tostring() + ":Processing ID: " + $id)
            $functionObject.id = $id

            out-logfile -string ($threadCounter.tostring() + ":Processing ID: " + $id + " gathering mailbox info...")

            try
            {
                $mailbox = get-mailbox -identity $id -errorAction Stop | select-object isExchangeCloudManaged
                $functionObject.previousState = $mailbox.isExchangeCloudManaged
                out-logfile -string ($threadCounter.tostring() + ":Processing ID: " + $id + ":isExchangeCloudManaged:"+$mailbox.isExchangeCloudManaged)
            }
            catch
            {
                out-logfile -string ($threadCounter.tostring() + ":Processing ID: " + $id + "Failed to obtain isExchangeCloudManaged.")
                out-logfile -string ($threadCounter.tostring() + ":Processing ID: " + $id + ":"+$_)
            }
        }

        out-logfile -string ($threadCounter.tostring() + ":Disconnecting from Exchange Online.")

        try
        {
            disconnect-exchangeonline -confirm:$FALSE -connectionID $connectionID -errorAction Stop
        }
        catch
        {
            out-logfile -string ($threadCounter.tostring() + ":Thread attempting to disconect exchange online connection.")
            out-logfile -string ($threadCounter.tostring() + ":" + $_.exception.message)
            exit
        }
    } -throttleLimit ($exoCredentials.count)
}