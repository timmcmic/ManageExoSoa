function test-exoCredentials
{
     Param
    (
        #Define other mandatory parameters
        [Parameter(Mandatory = $true)]
        [array]$exoCredentials
    )

    $success = @()
   
    out-logfile -string "Testing each EXO credential for successful authentication to Exchange Online."
    out-logfile -string "If you are prompted to authenticate or provide MFA something is broken - cancel the window."

    foreach ($credential in $exoCredentials)
    {
        $functionObject = New-Object PSObject -Property @{
            UserName = ""
            Success = ""
            ConnectionID = ""
            ErrorMessage = "None"
        }

        out-logfile -string ("Testing credential: "+$credential.username)
        try
        {
            $functionObject.username = $credential.username
            connect-exchangeOnline -credential $credential -disableWAM -errorAction STOP
            $functionObject.success = "SUCCESS"

            out-logfile -string "Obtain the connection id for Exchange Online session."

            try
            {
                $connectionID = (get-ConnectionInformation -errorAction STOP).connectionID
                out-logfile -string $connectionID.tostring()
                $functionObject.connectionID = $connectionID
            }
            catch
            {
                out-logfile -string "Unable to obtain the connection id."
                out-logfile -string $_
            }
        }
        catch
        {
            out-logfile -string $_
            $functionObject.success = "FAILED"
            $functionObject.errorMessage = $_
        }

        $success += $functionObject

        out-logfile -string "If connection was successful disconnect connection."

        if ($functionObject.success -eq "SUCCESS")
        {
            try
            {
                Disconnect-ExchangeOnline -confirm:$FALSE -errorAction STOP -connectionID $connectionID
                out-logfile -string "Exchange disconnected successfully."
            }
            catch
            {
                out-logfile -string $_ -isError:$TRUE
            }
        }
        else
        {
            out-logfile -string "Connection was not successful - skipping."
        }
    }

    foreach ($object in $success)
    {
        out-logfile -string $object.username
        out-logfile -string $object.success
        out-logfile -string $object.connectionID
        out-logfile -string $object.errorMessage
    }

    if ($success.success.contains("FAILED"))
    {
        out-logfile -string "One or more exo credentials failed to connect - see logs." -isError:$TRUE
    }
}