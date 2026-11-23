<#
    .SYNOPSIS

    This function provides the logging functionality of the script.

    .DESCRIPTION

    Logging

    .PARAMETER string

    The string to be written to the log file.

    .PARAMETER isError

    Boolean value to signify exception / log it / terminate script.

	.OUTPUTS

    Logs all activities and backs up all original data to the log folder directory.

    .EXAMPLE

    Out-LogFile -string "MESSAGE" -isError BOOLEAN

    #>
    Function Out-LogFile
     {
        [cmdletbinding()]

        Param
        (
            [Parameter(Mandatory = $true)]
            $String
        )

        #Define a mutex so that we can do bulk operations.

        $mtx = $null

        try
        {
            $mutexName = "Global\LogMutex"
            $mtx = New-Object System.Threading.Mutex($false, $mutexName)
            $hasHandle = $false
        
            # Get the current date

            [string]$date = Get-Date -Format G
        
            # Build output string
            #In this case since I abuse the function to write data to screen and record it in log file
            #If the input is not a string type do not time it just throw it to the log.

            if ($string.gettype().name -eq "String")
            {
                [string]$logstring = ( "[" + $date + "] - " + $string)
            }
            else 
            {
                $logString = $String
            }
            
            # Write everything to our log file and the screen

            try
            {
                $hasHandle = $mtx.WaitOne(1000)
            }
            catch [System.Threading.AbandonedMutexException]
            {
                $hasHandle = $true
            }

            if ($hasHandle)
            {
                $logstring | Out-File -FilePath $global:LogFile -Append
            }
            else
            {
                write-warning "Log operation skipped - no access to log file."
            }

            if ($hasHandle)
            {
                $mtx.ReleaseMutex()
            }
            
            #Write to the screen the information passed to the log.

            if ($string.gettype().name -eq "String")
            {
                Write-Host $logString
            }
            else 
            {
                write-host $logString | select-object -expandProperty *
            }

            #If the output to the log is terminating exception - throw the same string.
        }
        finally
        {
            if ($mtx)
            {
                $mtx.Dispose()
            }
        }
    }