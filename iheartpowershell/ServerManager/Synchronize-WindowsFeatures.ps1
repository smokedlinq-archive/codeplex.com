[CmdletBinding()]
param
(
    [Parameter(Mandatory = $true)]
    [string] $Source

	[Parameter(Mandatory = $true)]
    [string] $Destination = $ENV:COMPUTERNAME
)

$Features = Invoke-Command -ComputerName $Source -ScriptBlock {  
    Import-Module ServerManager
    Get-WindowsFeature
}

Invoke-Command -ComputerName $Destination -ArgumentList @($Features) -ScriptBlock {
	param($Features)
	
	$Features |? { $_.Installed -and $_.SubFeatures.Count -eq 0} | Add-WindowsFeature
	$Features |? { !$_.Installed } | Remove-WindowsFeature
}