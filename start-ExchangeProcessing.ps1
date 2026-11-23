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

    $chunks | foreach-object -Parallel {
        begin {
            $threadCounter = 0 ; $credentialCounter = 0
        } 
        process {
            $threadCounter++
            out-logfile -string ("This is the current thread counter: "+$threadCounter.tostring())
            out-logfile -string ("This is the current credential counter: "+$credentialCounter.tostring())

            if ($credentialCounter -eq 4)
            {
                $credentialCounter = 0
            }
            else
            {
                $credentialCounter++
            }
        }
    } -throttleLimit ($exoCredentials.count)
}