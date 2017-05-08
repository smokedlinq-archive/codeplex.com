#Requires -Version 3.0

<#
	.SYNOPSIS
	Called when a connector space entry is disconnected during an import operation. This method determines whether the metaverse entry that is connected to the disconnecting connector space entry should be deleted.

	.PARAMETER csentry
	Contains a CSEntry object that represents the connector space entry that has been disconnected.

	.PARAMETER mventry
	Contains an MVEntry object that represents the metaverse entry that will be deleted if this method returns true.

	.OUTPUTS
	Returns true if the connected metaverse entry should be deleted, or false if it should not be deleted.

	.NOTES
	A connector space entry will be disconnected during an import operation when the connector space entry is deleted from the connected directory. The disconnection can also occur when Forefront Identity Manager Synchronization Service (FIM Synchronization Service) determines that the connector space entry should be a disconnector, which means the object should not be connected.

	The ConnectionState property is not available in this method. Accessing this property in this method results in an exception.

	.LINK
	http://msdn.microsoft.com/en-us/library/microsoft.metadirectoryservices.imvsynchronization.shoulddeletefrommv(v=vs.100).aspx
#>
[CmdletBinding()]
param(
	[Parameter(Mandatory)]
	[ValidateNotNull()]
	[csentry] $csentry,
	
	[Parameter(Mandatory)]
	[ValidateNotNull()] 
	[mventry] $mventry
)

begin {
	$ShouldDeleteFromMV = $false
}

process {
}

end {
	$ShouldDeleteFromMV
}