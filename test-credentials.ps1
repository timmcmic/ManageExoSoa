<#
    .SYNOPSIS

    This function validates the parameters within the script.  Paramter validation is shared across functions.
    
    .DESCRIPTION

    This function validates the parameters within the script.  Paramter validation is shared across functions.

    #>
    Function test-credentials
    {
        [cmdletbinding()]

        Param
        (
            [Parameter(Mandatory = $true)]
            $credentialsToTest
        )

        #Start function processing.

        Out-logfile -string "Entering test-credentials"

        foreach ($credential in $credentialsToTest)
        {
            if ($credential.gettype().name -eq "PSCredential")
            {
                out-logfile -string ("Tested credential: "+$credential.userName)
            }
            else 
            {
                out-logfile -string "EXCEPTION_CREDENTIAL_NOT_PSCREDENTIAL_TYPE:  All specified credentials must be PSCredential Types" -isError:$TRUE    
            }
        }
         
        out-logfile -string "Exiting test-credentials"
    }