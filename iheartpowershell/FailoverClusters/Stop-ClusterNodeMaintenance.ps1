#Requires -Module FailoverClusters

[CmdletBinding()]
param
(
    [Parameter(ValueFromPipelineByPropertyName = $true)]
    [string] $Name = $ENV:COMPUTERNAME
)

Resume-ClusterNode -Name $Name -Cluster $Name