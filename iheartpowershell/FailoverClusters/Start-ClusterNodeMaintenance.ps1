#Requires -Module FailoverClusters

[CmdletBinding()]
param
(
    [Parameter(ValueFromPipelineByPropertyName = $true)]
    [string] $Name = $ENV:COMPUTERNAME
)

Suspend-ClusterNode -Name $Name -Cluster $Name
Get-ClusterNode -Name $Name -Cluster $Name | Get-ClusterGroup | Move-ClusterGroup