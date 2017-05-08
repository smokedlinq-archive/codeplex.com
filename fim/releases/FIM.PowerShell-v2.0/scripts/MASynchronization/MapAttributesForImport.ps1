#Requires -Version 3.0

<#
	.SYNOPSIS
	Called to map attributes from a connector space entry to a metaverse entry.

	.PARAMETER FlowRuleName
	Contains the name of the flow rule. You must use only alphanumeric characters for the FlowRuleName parameter; otherwise, you can encounter problems in a rules extension.

	.PARAMETER csentry
	Contains a CSEntry object that represents the source connector space entry.

	.PARAMETER mventry
	Contains a CSEntry object that represents the destination metaverse entry.

	.NOTES
	Flow rules are not executed in the order that is shown in Synchronization Service Manager. Forefront Identity Manager Synchronization Service (FIM Synchronization Service) uses these rules according to the state of the connector space object. Configure your rules based on the state of the object instead of the rules being called in a predetermined order.

	For multiple import flow rules, the management agent that has precedence provides the attribute value. You set management agent precedence in the Metaverse Designer. For more information about setting management agent precedence, see the Forefront Identity Manager Synchronization Service 2010 Help on Microsoft TechNet.

	Attribute flow mapping is called only if a source attribute exists. When the last source attribute of an import attribute flow mapping is deleted, the attribute flow rules are not called, and the target attribute is automatically deleted.

	.LINK
	http://msdn.microsoft.com/en-us/library/microsoft.metadirectoryservices.imasynchronization.mapattributesforimport(v=vs.100).aspx
#>
[CmdletBinding()]
param(
	[Parameter(Mandatory)]
	[ValidateNotNullOrEmpty()]
	[string] $FlowRuleName, 
	
	[Parameter(Mandatory)]
	[ValidateNotNull()]
	[csentry] $csentry, 
	
	[Parameter(Mandatory)]
	[ValidateNotNull()]
	[mventry] $mventry
)
