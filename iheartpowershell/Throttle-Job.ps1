[CmdletBinding()]
param
(
	[ValidateRange(1, [int]::MaxValue)]
    [int]      $Concurrent = $((Get-WmiObject -Class Win32_ComputerSystem -Property NumberOfLogicalProcessors | Select-Object -ExpandProperty NumberOfLogicalProcessors) * 4),
    [TimeSpan] $Interval   = [TimeSpan]::FromMilliseconds(250),
    [switch]   $PassThru   = $false
)

if ($PassThru) {
	$_
}

while ( (Get-Job -State Running | Measure-Object).Count -gt $Concurrent ) {
    Start-Sleep -Milliseconds $Interval.TotalMilliseconds
}