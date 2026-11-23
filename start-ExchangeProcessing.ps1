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
        process {
            $global:logfile = $using:logFile
            $function = $using:myFunction
            $counter = $using:counter
            $exoCredentials = $using:exoCredentials
            
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
                connect-exchangeonline -credential $exoCredential[$credentialCounter] -errorAction STOP
            }
            catch
            {
                out-logfile -string ($threadCounter.tostring() + ":Thread attempting exchange online connection.")
                out-logfile -string ($threadCounter.tostring() + ":" + $_.exception.message)
                exit
            }

            out-logfile -string ($threadCounter.tostring() + ":Disconnecting from Exchange Online.")

            try
            {
                disconnect-exchangeonline -errorAction Stop
            }
            catch
            {
                out-logfile -string ($threadCounter.tostring() + ":Thread attempting to disconect exchange online connection.")
                out-logfile -string ($threadCounter.tostring() + ":" + $_.exception.message)
                exit
            }

        }
    } -throttleLimit ($exoCredentials.count)
}