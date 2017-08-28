$Output = New-object PSObject -Property @{
    Exitcode = 3
    Returnstring = 'UNKNOWN: Please debug the script...'
}

Try {
    Import-Module PSYaml   
} 
catch {
    $Output.ReturnString = 'UNKNOWN: Unable to import module PSYaml'
    $Output.Exitcode = 3
    return
}

function Convert-UnixTimeToDateTime([int]$UnixTime)
{
    (New-Object DateTime(1970, 1, 1, 0, 0, 0, 0, [DateTimeKind]::Utc)).AddSeconds($UnixTime)
}

$disablelock = get-content C:\ProgramData\PuppetLabs\puppet\var\state\agent_disabled.lock -ErrorAction SilentlyContinue
$Yaml = ConvertFrom-Yaml -path C:\ProgramData\PuppetLabs\puppet\var\state\last_run_summary.yaml
$lastrun = Convert-UnixTimeToDateTime $Yaml.time.last_run
$timespan = new-timespan -hours 5

if ($disablelock) {
    $Output.Returnstring = "WARNING: Puppet disabled $($disablelock)"
    $Output.ExitCode = 1
}

Elseif ($yaml.events.failure -gt 0) {
    $Output.Returnstring = "WARNING: Last puppet run had $($yaml.events.failure) failure "
    $Output.ExitCode = 1
}

Elseif (((get-date) - $lastrun) -gt $timespan) {
    $Output.Returnstring = "WARNING: Puppet last run over two hours old"
    $Output.ExitCode = 1
} 

Else{
    $Output.Returnstring = 'OK: Last puppet run had no failure'
    $Output.ExitCode = 0
}

Write-Output "$($Output.Returnstring)
Puppet version $($yaml.version.puppet) 
Last puppet run was $($lastrun.ToString("yyyy-MM-dd HH:mm"))
Changes $($yaml.changes.total)"

Exit $Output.ExitCode