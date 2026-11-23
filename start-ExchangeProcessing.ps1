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

    $counter['Count'] = -1

    $chunks | foreach-object -Parallel {
        $global:logfile = $using:logFile
        $function = $using:myFunction
        $counter = $using:counter
        $exoCredentials = $using:exoCredentials
        $headerValue = $using:mailboxHeaderName
        $enable = $using:enable
        $outputStorage = $using:outputStorage
        
        $scriptblock = [scriptblock]::Create($function)

        set-item -path "Function:\Out-Logfile" -value $scriptBlock

        $iHadAnIssue = ""
        $updateSuccess = $FALSE

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
            $iHadAnIssue = "EXCEPION_EXCHANGE_ONLINE_CONNECTION_FAILED"
        }

        if ($iHadAnIssue -eq "")
        {
            out-logfile -string ($threadCounter.tostring() + ":Obtain the Exchange Online Connection ID")

            try
            {
                $connectionID = (get-ConnectionInformation -errorAction STOP | where {$_.userPrincipalName -eq $exoCredentials[$credentialCounter].userName}).connectionID
                out-logfile -string ($threadCounter.tostring() + ":ConnectionID:"+$connectionID.tostring())
            }
            catch
            {
                out-logfile -string "Unable to obtain the connection id."
                out-logfile -string $_
                $iHadAnIssue = "EXCEPTION_EXCHANGE_ONLINE_CONNECTION_INFO_NOT_AVAILABLE"
            }
        }
        else
        {
            out-logfile -string ($threadCounter.tostring() + ":No connection information obtained - previous failure")
        }
        
        out-logfile -string ($threadCounter.tostring() + ":Using header: " + $headerValue)
        out-logfile -string ($_.count.tostring())

        $itemCounter = 0

        foreach ($id in $psitem.($headerValue))
        {
            $functionObject = New-Object PSObject -Property @{
                ID = "None"
                PreviousState = "None"
                NewState = "None"
                ErrorMessage = "None"
            }

            out-logfile -string ($threadCounter.tostring() + ":Processing ID:" + $id)
            out-logfile -string ($threadCounter.tostring() + ":Processing ID:" + $id + ":Item Number:"+$itemCounter)
            $itemCounter++
            $functionObject.id = $id

            if ($iHadAnIssue -ne "")
            {
                out-logfile -string ($threadCounter.tostring() + ":Processing ID: " + $id +":Processing Exception:"+$iHadAnIssue)
                $functionObject.errorMessage = $iHadAnIssue
                $functionObject.PreviousState = "ERROR"
                $functionObject.NewState = "ERROR"
            }
            else
            {
                out-logfile -string ($threadCounter.tostring() + ":Processing ID: " + $id + ":Gathering Mailbox Info")

                try
                {
                    $mailbox = get-mailbox -identity $id -errorAction Stop | select-object isExchangeCloudManaged
                    $functionObject.previousState = $mailbox.isExchangeCloudManaged
                    out-logfile -string ($threadCounter.tostring() + ":Processing ID: " + $id + ":isExchangeCloudManaged:"+$mailbox.isExchangeCloudManaged)
                }
                catch
                {
                    out-logfile -string ($threadCounter.tostring() + ":Processing ID: " + $id + ":Failed to obtain isExchangeCloudManaged.")
                    out-logfile -string ($threadCounter.tostring() + ":Processing ID: " + $id + ":"+$_)
                }

                out-logfile -string ($threadCounter.tostring() + ":Processing ID: " + $id + ":Updating IsExchangeCloudManaged")

               
                out-logfile -string ($threadCounter.tostring() + ":Processing ID: " + $id + ":Updating IsExchangeCloudManaged:"+$enable)

                try
                {
                    set-mailbox -identity $id -isExchangeCloudManaged:$enable -errorAction STOP
                    out-logfile -string ($threadCounter.tostring() + ":Processing ID: " + $id + ":Updating IsExchangeCloudManaged Success"+$enable)
                    $updateSuccess = $TRUE
                }
                catch
                {
                    out-logfile -string ($threadCounter.tostring() + ":Processing ID: " + $id + ":Updating IsExchangeCloudManaged ERROR"+$enable)
                    $functionObject.errorMessage = $_
                }

                if ($updateSuccess -eq $TRUE)
                {
                    out-logfile -string ($threadCounter.tostring() + ":Processing ID: " + $id + ":Gathering Mailbox Info Post Update")
                    
                    try
                    {
                        $mailbox = get-mailbox -identity $id -errorAction Stop | select-object isExchangeCloudManaged
                        $functionObject.newState = $mailbox.isExchangeCloudManaged
                        out-logfile -string ($threadCounter.tostring() + ":Processing ID: " + $id + ":isExchangeCloudManaged Post Update:"+$mailbox.isExchangeCloudManaged)
                    }
                    catch
                    {
                        out-logfile -string ($threadCounter.tostring() + ":Processing ID: " + $id + ":Failed to obtain isExchangeCloudManaged.")
                        out-logfile -string ($threadCounter.tostring() + ":Processing ID: " + $id + ":"+$_)
                        $functionObject.newState = "ERROR"
                    }
                }
                else
                {
                    $functionObject.newState = "ERROR"
                }
            }

            $outputStorage.add($functionObject)
        }

        if ($iHadAnIssue -eq "")
        {
            out-logfile -string ($threadCounter.tostring() + ":Disconnecting from Exchange Online.")

            if ($connectionID.count -gt 0)
            {
                foreach ($connection in $connectionID)
                {
                    try
                    {
                        out-logfile -string ($threadCounter.tostring() + ":Disconnecting from Exchange Online:"+$connection)
                        disconnect-exchangeonline -confirm:$FALSE -connectionID $connectionID -errorAction Stop
                        start-sleep -seconds (Get-Random -minimum 5 -maximum 10)
                    }
                    catch
                    {
                        out-logfile -string ($threadCounter.tostring() + ":Thread attempting to disconect exchange online connection.")
                        out-logfile -string ($threadCounter.tostring() + ":" + $_.exception.message)
                    }
                }
            }
            else
            {
                try
                {
                    out-logfile -string ($threadCounter.tostring() + ":Disconnecting from Exchange Online:"+$connectionID)
                    disconnect-exchangeonline -confirm:$FALSE -connectionID $connectionID -errorAction Stop
                    start-sleep -seconds (Get-Random -minimum 5 -maximum 10)
                }
                catch
                {
                    out-logfile -string ($threadCounter.tostring() + ":Thread attempting to disconect exchange online connection.")
                    out-logfile -string ($threadCounter.tostring() + ":" + $_.exception.message)
                }
            }
        }
        else
        {
            out-logfile -string ($threadCounter.tostring() + ":Disconnection not necessary - previous issue encountered.")
        }
    } -throttleLimit ($exoCredentials.count)

    return ,$outputStorage
}