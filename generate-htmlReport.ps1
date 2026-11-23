function generate-HTMLReport
{
    Param
    (
        [Parameter(Mandatory = $true)]
        $threadSafeList
    )

    $functionHTMLSuffix = "html"
    $global:functionHTMLFile = $global:LogFile.replace("log","$functionHTMLSuffix")

    out-logfile -string "Entering generate-HTMLReport"
    out-logfile -string $global:functionHTMLFile

    $headerString = "EXO SOA Change Report"

     new-HTML -TitleText "EXO SOA Change Report" -FilePath $global:functionHTMLFile{
        New-HTMLHeader{
            New-HTMLText -Text $headerString -FontSize 24 -Color White -BackGroundColor Black -Alignment center
        }
        New-HTMLMain {
            New-HTMLTableOption -DataStore JavaScript
            New-HTMLSection -HeaderText "Summary Success"  {
                new-htmlTable -DataTable ($threadSafeList | where {$_.errorMessage -eq "None"} | Select-Object ID,PreviousState,NewState) -Filtering {
                } -AutoSize
            }-HeaderTextAlignment "Left" -HeaderTextSize "16" -HeaderTextColor "White" -HeaderBackGroundColor "Black"  -CanCollapse -BorderRadius 10px -collapsed
            New-HTMLSection -HeaderText "Summary ERRORS"  {
                new-htmlTable -DataTable ($threadSafeList | where {$_.errorMessage -ne "None"} | Select-Object ID,PreviousState,NewState,ErrorMessage) -Filtering {
                } -AutoSize
            }-HeaderTextAlignment "Left" -HeaderTextSize "16" -HeaderTextColor "Red" -HeaderBackGroundColor "Black"  -CanCollapse -BorderRadius 10px -collapsed
        } 
    }-online -ShowHTML

    out-logfile -string "Exiting generate-HTMLReport"
}