#Requires -Version 3.0

<#
	.SYNOPSIS
	Called to determine whether a new connector space object should be projected to a new metaverse object when the connector space object does not join to an existing metaverse object.

	.PARAMETER csentry
	Contains a CSEntry object that represents the new connector space entry.

	.OUTPUTS
	A String object that, on output, receives the name of the metaverse class to which the connector space entry should be projected.

	.LINK
	http://msdn.microsoft.com/en-us/library/microsoft.metadirectoryservices.imasynchronization.shouldprojecttomv(v=vs.100).aspx
#>
[CmdletBinding()]
param(
	[Parameter(Mandatory)]
	[ValidateNotNull()]
	[csentry] $csentry
)
