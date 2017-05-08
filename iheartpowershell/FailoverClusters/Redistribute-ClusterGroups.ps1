#Requires -Module FailoverClusters

[CmdletBinding()]
param
(
    [string] $Cluster = '.'
)

Get-ClusterGroup -Cluster $Cluster | Get-ClusterOwnerNode |? { $_.OwnerNodes } |% {
    Move-ClusterGroup -Name $_.ClusterObject.Name -Cluster $Cluster -Node ($_.OwnerNodes | Select-Object -First 1).Name
}