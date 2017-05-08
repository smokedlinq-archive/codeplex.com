#Requires -Version 3.0

<#
	.SYNOPSIS
	Called when a metaverse entry is deleted and the connector space entries that are connected to the metaverse entry become disconnector objects.

	.PARAMETER csentry
	Contains a CSEntry object that represents the connector space entry that was connected to the deleted metaverse entry.

	.OUTPUTS
	Returns one of the DeprovisionAction values that determines which action should be taken on the connector space entry.

	.LINK
	http://msdn.microsoft.com/en-us/library/microsoft.metadirectoryservices.imasynchronization.deprovision(v=vs.100).aspx
#>
[CmdletBinding()]
param(
	[Parameter(Mandatory)]
	[ValidateNotNull()]
	[csentry] $csentry
)

begin {
	$Action = [DeprovisionAction]::Disconnect
}

process {
}

end {
	$Action
}