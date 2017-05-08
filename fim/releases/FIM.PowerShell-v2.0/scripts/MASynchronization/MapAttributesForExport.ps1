#Requires -Version 3.0

<#
	.SYNOPSIS
	Called to map attributes from a metaverse entry to a connector space entry.

	.PARAMETER FlowRuleName
	Contains the name of the flow rule. You must use only alphanumeric characters for the FlowRuleName parameter; otherwise, you can encounter problems in a rules extension.

	.PARAMETER mventry
	Contains a CSEntry object that represents the source metaverse entry.

	.PARMAETER csentry
	Contains a CSEntry object that represents the destination connector space entry.

	.NOTES
	Flow rules are not executed in the order shown in Synchronization Service Manager. Forefront Identity Manager Synchronization Service (FIM Synchronization Service) uses these rules according to the state of the metaverse object. Configure your rules based on the state of the object instead of the rules that are called in a predetermined order.

	This method is called when:
		- The export flow rules do not overlap with the import flow rules, or
		- If the source attribute has a precedence greater than or equal to the precedence of the overlapping import flow rule. You set management agent precedence in Metaverse Designer.

	For more information about setting management agent precedence, see the Forefront Identity Manager Synchronization Service 2010 Help on Microsoft TechNet.

	.LINK
	http://msdn.microsoft.com/en-us/library/microsoft.metadirectoryservices.imasynchronization.mapattributesforexport(v=vs.100).aspx
#>
[CmdletBinding()]
param(
	[Parameter(Mandatory)]
	[ValidateNotNullOrEmpty()]
	[string] $FlowRuleName, 

	[Parameter(Mandatory)]
	[ValidateNotNull()]
	[mventry] $mventry,
	
	[Parameter(Mandatory)]
	[ValidateNotNull()] 
	[csentry] $csentry
)
