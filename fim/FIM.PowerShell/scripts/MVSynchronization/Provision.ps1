#Requires -Version 3.0

<#
	.SYNOPSIS
	Evaluates connected objects in response to a change to a metaverse object.

	.PARAMETER mventry
	Contains an MVEntry object that represents the metaverse object that has changed.

	.LINK
	http://msdn.microsoft.com/en-us/library/microsoft.metadirectoryservices.imvsynchronization.provision(v=vs.100).aspx
#>
[CmdletBinding()]
param(
	[Parameter(Mandatory)]
	[ValidateNotNull()]
	[mventry] $mventry
)
