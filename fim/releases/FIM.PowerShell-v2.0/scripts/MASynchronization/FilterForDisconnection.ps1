#Requires -Version 3.0

<#
	.SYNOPSIS
	Determines whether a connector CSEntry object will be disconnected. A connector space or CSEntry object is disconnected when a delta export matches a filter, or if the filter rules are changed and the new filter criteria for disconnecting an object are met.

	.PARAMETER csentry
	Contains the CSEntry object to which this method applies.

	.OUTPUTS
	Returns true if the object will be disconnected, or false if the object will not be disconnected.

	.LINK
	http://msdn.microsoft.com/en-us/library/microsoft.metadirectoryservices.imasynchronization.filterfordisconnection(v=vs.100).aspx
#>
[CmdletBinding()]
param(
	[Parameter(Mandatory)]
	[ValidateNotNull()]
	[csentry] $csentry
)

begin {
	$FilterForDisconnection = $false
}

process {
}

end {
	$FilterForDisconnection
}