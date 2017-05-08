# To install copy FIM.psm1 to:
#   C:\Windows\system32\WindowsPowerShell\v1.0\Modules\FIM

$ErrorActionPreference = 'Stop'

if (-not (Get-PSSnapin |? { $_.Name -eq 'FIMAutomation' })) {
	Add-PSSnapin FIMAutomation
}

function Add-PSTypeAccelerator {
	param(
		[Parameter(Mandatory = $true)]
		[string] $AliasName,
		
		[Parameter(Mandatory = $true)]
		[string] $TypeName,
		
		[switch] $Force = $false
	)
	
	begin {
		$PSTypeAccelerators = [Type]::GetType('System.Management.Automation.TypeAccelerators')
		$Type = Invoke-Expression "[$TypeName]"
		
		if ($PSTypeAccelerators::Get.ContainsKey($AliasName)) {
			if ($Force) {
				$PSTypeAccelerators::Remove($AliasName) | Out-Null
			} else {
				throw 'Type accelerator "{0}" already exists.' -f $AliasName
			}
		}
	}
	
	end {
		$PSTypeAccelerators::Add($AliasName, $Type)
	}
}

function New-FIMImportObject {
	param(
		[Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
		[Guid] $ObjectID,
		
		[Parameter(ValueFromPipelineByPropertyName = $true)]
		[string] $ObjectType = 'Resource',
		
		[FIMImportState] $State = [FIMImportState]::None
	)
	
	process {
		$importObject = New-Object FIMImportObject
		$importObject.ObjectType = $ObjectType
		$importObject.TargetObjectIdentifier = $ObjectID
		$importObject.SourceObjectIdentifier = $ObjectID
		$importObject.State = $State
		$importObject
	}
}

function New-FIMImportChange {
	param(
		[Parameter(Mandatory = $true)]
		[Alias('Name')]
		[string] $AttributeName,
		
		[Parameter(Mandatory = $true)]
		[Alias('Value')]
		[AllowEmptyString()]
		[AllowNull()]
		[string] $AttributeValue,
		
		[FIMImportOperation] $Operation = [FIMImportOperation]::None,
		
		[string] $Locale = 'Invariant',
		
		[switch] $FullyResolved = $true
	)
	
	begin {
		$importChange = New-Object FIMImportChange    
		$importChange.Operation = $Operation
		$importChange.AttributeName = $AttributeName

		if ($AttributeValue) {
			$importChange.AttributeValue = $AttributeValue
		}

		$importChange.Locale = $Locale
		$importChange.FullyResolved = $FullyResolved
	}
	
	end {
		$importChange
	}
}

<#
	.SYNOPSIS
		Returns all help content for the FIM module.
#>
function Get-FIMHelp {
	end {
		$exportedMembers = (Get-Module FIM | Select-Object -Expand ExportedCommands).GetEnumerator() | Select-Object -Expand Name
		Get-Module FIM | Get-Help | Sort Name |? { $exportedMembers -contains $_.Name }
	}
}

<#
	.SYNOPSIS
		Clears the single-valued attribute.

	.EXAMPLE
		Get-FIMResource '/Person[Email != "#Invalid#"]' | Clear-FIMAttribute 'Email' -PassThru | Set-FIMResource

		Removes the attribute value for all resources that have a value in the Email attribute.
#>
function Clear-FIMAttribute {
	param(
		[Parameter(Position = 0, Mandatory = $true, ValueFromPipeline = $true)]
		[ValidateScript({$_ -is [FIMExportObject]})]
		[PSObject] $Resource,
		
		[Parameter(Position = 1, Mandatory = $true)]
		[Alias('Name')]
		[string] $AttributeName,
		
		[string] $Locale = 'Invariant',
		
		[switch] $FullyResolved = $true,
		
		[switch] $PassThru = $false
	)
	
	process {
		$Resource.Changes += @(New-FIMImportChange -AttributeName $AttributeName -AttributeValue $null -Operation Replace -Locale $Locale -FullyResolved:$FullResolved)

		if ($PassThru) {
			$Resource
		}
	}
}

<#
	.SYNOPSIS
		Sets a single-valued attribute.

	.PARAMETER AttributeValue
		The value can be a POCO or a script block which will be passed the current resource to use to calculate a value.

	.EXAMPLE
		Get-FIMResource '/Person[AccountName = "adam.weigert" and Domain = "fim.codeplex.com"]' | Set-FIMAttribute -Name 'Email' -Value 'adam.weigert@fim.codeplex.com'

		Sets the attribute Email to the value "adam.weigert@fim.codeplex.com" for each resource

	.EXAMPLE
		Get-FIMResource '/Person[Domain = "fim.codeplex.com"]' | Set-FIMAttribute -Name 'Email' -Value { $_.AccountName + '@fim.codeplex.com' }

		Sets the attribute Email to the calculated value of each resource

	.NOTES
		The Set-FIMResource cmdlet must be called to commit the change to the resource.

		The FIMAutomation PowerShell snapin does not support DateTime attributes pre-R2.
#>
function Set-FIMAttribute {
	param(
		[Parameter(Position = 0, Mandatory = $true, ValueFromPipeline = $true)]
		[ValidateScript({$_ -is [FIMExportObject]})]
		[PSObject] $Resource,
		
		[Parameter(Position = 1, Mandatory = $true)]
		[Alias('Name')]
		[string] $AttributeName,
		
		[Parameter(Position = 2, Mandatory = $true)]
		[AllowEmptyString()]
		[AllowNull()]
		[Alias('Value')]
		$AttributeValue,
		
		[string] $Locale = 'Invariant',
		
		[switch] $FullyResolved = $true,
		
		[switch] $PassThru = $false
	)
	
	process {
		if ($AttributeValue -is [ScriptBlock]) {
			$AttributeValue = $Resource | &$AttributeValue
		}
		
		$Resource.Changes += @(New-FIMImportChange -AttributeName $AttributeName -AttributeValue $AttributeValue -Operation Replace -Locale $Locale -FullyResolved:$FullResolved)
		
		if ($PassThru) {
			$Resource
		}
	}
}

<#
	.SYNOPSIS
		Adds a value to a multi-valued attribute.

	.PARAMETER AttributeValue
		The value can be a POCO or a script block which will be passed the current resource to use to calculate a value.

	.EXAMPLE
		Get-FIMResource '/Person[AccountName = "adam.weigert" and Domain = "fim.codeplex.com"]' | Add-FIMAttribute -Name 'ProxyAddresses' -Value 'adam.weigert@fim.codeplex.com'

		Adds the value for each resource to the ProxyAddresses attribute

	.EXAMPLE
		Get-FIMResource '/Person[Domain = "fim.codeplex.com"]' | Add-FIMAttribute -Name 'ProxyAddresses' -Value { $_.AccountName + '@fim.codeplex.com' }

		Adds the calculated value to each resource

	.NOTES
		The Set-FIMResource cmdlet must be called to commit the change to the resource.

		The FIMAutomation PowerShell snapin does not support DateTime attributes pre-R2.
#>
function Add-FIMAttribute {
	param(
		[Parameter(Position = 0, Mandatory = $true, ValueFromPipeline = $true)]
		[ValidateScript({$_ -is [FIMExportObject]})]
		[PSObject] $Resource,
		
		[Parameter(Position = 1, Mandatory = $true)]
		[Alias('Name')]
		[string] $AttributeName,
		
		[Parameter(Position = 2, Mandatory = $true)]
		[AllowEmptyString()]
		[AllowNull()]
		[Alias('Value')]
		$AttributeValue,
		
		[string] $Locale = 'Invariant',
		
		[switch] $FullyResolved = $true,
		
		[switch] $PassThru = $false
		
	)
	
	process {
		if ($AttributeValue -is [ScriptBlock]) {
			$AttributeValue = $Resource | &$AttributeValue
		}

		@($AttributeValue) |% {
			$Resource.Changes += @(New-FIMImportChange -AttributeName $AttributeName -AttributeValue $_ -Operation Add -Locale $Locale -FullyResolved:$FullResolved)
		}
		
		if ($PassThru) {
			$Resource
		}
	}
}

<#
	.SYNOPSIS
		Removes a value to a multi-valued attribute.

	.PARAMETER AttributeValue
		The value can be a POCO or a script block which will be passed the current resource to use to calculate a value.

	.EXAMPLE
		Get-FIMResource '/Person[AccountName = "adam.weigert" and Domain = "fim.codeplex.com"]' | Remove-FIMAttribute -Name 'ProxyAddresses' -Value 'adam.weigert@fim.codeplex.com'

		Removes the value for each resource to the ProxyAddresses attribute

	.EXAMPLE
		Get-FIMResource '/Person[Domain = "fim.codeplex.com"]' | Remove-FIMAttribute -Name 'ProxyAddresses' -Value { $_.AccountName + '@fim.codeplex.com' }

		Removes the calculated value to each resource

	.NOTES
		The Set-FIMResource cmdlet must be called to commit the change to the resource.

		The FIMAutomation PowerShell snapin does not support DateTime attributes pre-R2.
#>
function Remove-FIMAttribute {
	param(
		[Parameter(Position = 0, Mandatory = $true, ValueFromPipeline = $true)]
		[ValidateScript({$_ -is [FIMExportObject]})]
		[PSObject] $Resource,
		
		[Parameter(Position = 1, Mandatory = $true)]
		[Alias('Name')]
		[string] $AttributeName,
		
		[Parameter(Position = 2, Mandatory = $true)]
		[AllowEmptyString()]
		[AllowNull()]
		[Alias('Value')]
		$AttributeValue,
		
		[string] $Locale = 'Invariant',
		
		[switch] $FullyResolved = $true,
		
		[switch] $PassThru = $false
		
	)
	
	process {
		if ($AttributeValue -is [ScriptBlock]) {
			$AttributeValue = $Resource | &$AttributeValue
		}
		
		@($AttributeValue) |% {
			$Resource.Changes += @(New-FIMImportChange -AttributeName $AttributeName -AttributeValue $_ -Operation Delete -Locale $Locale -FullyResolved:$FullResolved)
		}
		
		if ($PassThru) {
			$Resource
		}
	}
}

<#
	.SYNOPSIS
		Returns the requested FIM resources.

	.EXAMPLE
		Get-FIMResource -Filter '/Person[AccountName = "adam.weigert" and Domain = "fim.codeplex.com"]'

		Retrieves all FIM resources that match the specified filter.
#>
function Get-FIMResource {
	param(
		[Parameter(Position = 0, Mandatory = $true)]
		[string[]] $Filter,
		
		[PSCredential] $Credential = [PSCredential]::Empty,
		
		[int] $MessageSize = 0,
		
		[string] $ComputerName = 'localhost',
		
		[int] $Port = 5725,
		
		[string] $Uri = 'http://{0}:{1}' -f ($ComputerName,$Port)
	)
	
	begin {
		if ($Credential -eq $null -or $Credential -eq [PSCredential]::Empty) {
			$resources = @(Export-FIMConfig -Uri $Uri -CustomConfig $Filter -OnlyBaseResources -MessageSize $MessageSize)
		} else {
			$resources = @(Export-FIMConfig -Uri $Uri -CustomConfig $Filter -OnlyBaseResources -Credential $Credential -MessageSize $MessageSize)
		}
	}
	
	end {
		if ([int]$resources.Count -gt 0) {
			$resources |% {
				$resource = $_
				
				$resource.ResourceManagementObject.ResourceManagementAttributes |% {
					if ($_.IsMultiValue) {
						$resource | Add-Member -MemberType NoteProperty -Name $_.AttributeName -Value @($_.Values |% {
							if ($_ -like 'urn:uuid:*') {
								$_ -replace '^urn:uuid:',''
							} else {
								$_
							}
						})
					} else {
						if ($_.Value -like 'urn:uuid:*') {
							$resource | Add-Member -MemberType NoteProperty -Name $_.AttributeName -Value ($_.Value -replace '^urn:uuid:','')
						} else {
							$resource | Add-Member -MemberType NoteProperty -Name $_.AttributeName -Value $_.Value
						}
					}

					$resource | Add-Member -MemberType NoteProperty -Name 'Changes' -Value @() -Force
				}

				$resource
			}
		}
	}
}

<#
	.SYNOPSIS
		Deletes the FIM resource(s).

	.EXAMPLE
		Get-FIMResource -Filter '/Person[AccountName = "adam.weigert" and Domain = "fim.codeplex.com"]' | Remove-FIMResource

		Deletes the FIM resource(s).
#>
function Remove-FIMResource {
	[CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
	param(
		[Parameter(Position = 0, Mandatory = $true, ValueFromPipeline = $true)]
		[ValidateScript({$_ -is [FIMExportObject]})]
		[PSObject] $Resource,
		
		[PSCredential] $Credential = [PSCredential]::Empty
	)
	
	begin {
		$importObjects = @()
	}
	
	process {
		if ($PsCmdlet.ShouldProcess($Resource.ObjectID)) {		
			$importObjects += @($Resource | New-FIMImportObject -State Delete)
		}
	}
	
	end {
		if ($importObjects.Count -gt 0) {
			if ($Credential -eq $null -or $Credential -eq [PSCredential]::Empty) {
				$importObjects | Import-FIMConfig -Uri ($Resource.Source)
			} else {
				$importObjects | Import-FIMConfig -Uri ($Resource.Source) -Credential $Credential
			}
		}
	}
}

<#
	.SYNOPSIS
		Creates a new FIM resource.

	.PARAMETER Set
		This parameter only accepts single-valued attributes.

	.PARAMETER Add
		This parameter only accepts multi-valued attributes.

	.EXAMPLE
		New-FIMResource -ObjectType 'Person'

		Creates a new FIM resource with an object type of Person.

	.EXAMPLE
		New-FIMResource -ObjectType 'Person' -Set @{
			Domain      = 'fim.codeplex.com';
			AccountName = 'adam.weigert';
			DisplayName = 'Adam Weigert';
		}

		Creates a new FIM resource with an object type of Person and values for the Domain, AccountName, and DisplayName attributes.

	.NOTES
		The Set-FIMResource cmdlet must be called to commit the change to the resource.

		The FIMAutomation PowerShell snapin does not support DateTime attributes pre-R2.
#>
function New-FIMResource {
	param(
		[Parameter(Position = 0, Mandatory = $true)]
		[ValidateNotNullOrEmpty()]
		[string] $ObjectType,
		
		[Guid] $ObjectID = [Guid]::NewGuid(),
		
		[Alias('Attributes')]
		[Hashtable] $Set,

		[Hashtable] $Add,
		
		[string] $ComputerName = 'localhost',
		
		[int] $Port = 5725,
		
		[string] $Uri = 'http://{0}:{1}' -f ($ComputerName,$Port)
	)
	
	begin {
		$resource = New-Object FIMExportObject
		$resource | Add-Member -MemberType NoteProperty -Name ObjectID -Value $ObjectID
		$resource | Add-Member -MemberType NoteProperty -Name ObjectType -Value $ObjectType
		$resource | Add-Member -MemberType NoteProperty -Name Changes -Value @()
		$resource.Source = $Uri

		if ($Set -ne $null) {
			$Set.Keys |% {
				$resource | Set-FIMAttribute -Name $_ -Value $Set[$_]
			}
		}

		if ($Add -ne $null) {
			$Add.Keys |% {
				$resource | Add-FIMAttribute -Name $_ -Value $Add[$_]
			}
		}
	}
	
	end {
		$resource
	}
}

<#
	.SYNOPSIS
		Commits all changes to the resource.

	.PARAMETER Set
		This parameter only accepts single-valued attributes.

	.PARAMETER Add
		This parameter only accepts multi-valued attributes.

	.PARAMETER Remove
		This parameter only accepts multi-valued attributes.

	.PARAMETER Clear
		This parameter only accepts single-valued attributes.

	.EXAMPLE
		Get-FIMResource '/Person[AccountName = "adam.weigert" and Domain = "fim.codeplex.com"]' | Set-FIMResource -Set {
			DisplayName = 'Adam Weigert';
			Email = 'adam.weigert@fim.codeplex.com';
		}

		Sets the DisplayName and Email attribute for the resource.

	.EXAMPLE
		Get-FIMResource '/Person[Domain = "fim.codeplex.com"]' | Set-FIMResource -Attributes {
			Email = { $_.DisplayName + '@fim.codeplex.com' };
		}

		Sets the Email attribute to the calculated value for each resource.

	.EXAMPLE
		Get-FIMResource '/Person[Domain = "fim.codeplex.com"]' | Add-FIMAttribute -Name 'ProxyAddresses' -Value { $_.DisplayName + '@fim.codeplex.com' } | Set-FIMResource

		Adds the calculated value to the ProxyAddresses attribute for each resource.

	.NOTES
		The default URI used is the one attached to the FIM resource. You can override the URI by passing in one or more of the explicit URI parameters: ComputerName, Port, or Uri.
#>
function Set-FIMResource {
	[CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Low')]
	param(
		[Parameter(Position = 0, Mandatory = $true, ValueFromPipeline = $true)]
		[ValidateScript({$_ -is [FIMExportObject]})]
		[PSObject] $Resource,

		[Alias('Attributes')]
		[Hashtable] $Set,

		[Hashtable] $Add,

		[Hashtable] $Remove,

		[string[]] $Clear,
		
		[Parameter(ParameterSetName = 'ExplicitUri')]
		[string] $ComputerName = 'localhost',
		
		[Parameter(ParameterSetName = 'ExplicitUri')]
		[int] $Port = 5725,
		
		[Parameter(ParameterSetName = 'ExplicitUri')]
		[string] $Uri = 'http://{0}:{1}' -f ($ComputerName,$Port),
		
		[PSCredential] $Credential = [PSCredential]::Empty
	)
	
	begin {
		$importObjects = @()
	}
	
	process {
		if ($PsCmdlet.ShouldProcess($Resource.ObjectID)) {
			if ($Set -ne $null) {
				$Set.Keys |% {
					$Resource | Set-FIMAttribute -Name $_ -Value $Set[$_]
				}
			}

			if ($Add -ne $null) {
				$Add.Keys |% {
					$Resource | Add-FIMAttribute -Name $_ -Value $Add[$_]
				}
			}

			if ($Remove -ne $null) {
				$Remove.Keys |% {
					$Resource | Remove-FIMAttribute -Name $_ -Value $Remove[$_]
				}
			}

			if ($Clear -ne $null) {
				$Clear |% { $Resource | Clear-FIMAttribute -Name $_ }
			}
			
			if ([int]$Resource.Changes.Count -gt 0) {
				if ($Resource.ResourceManagementObject -eq $null) {
					$importObject = $Resource | New-FIMImportObject -State Create
				} else {
					$importObject = $Resource | New-FIMImportObject -State Put
				}
				
				$importObject.Changes = $Resource.Changes
				
				$importObjects += $importObject
			}
		}
	}
	
	end {
		switch ($PsCmdlet.ParameterSetName) {
			'ExplicitUri' {
				#$Uri = $Uri
			}

			default {
				$Uri = $Resource.Source
			}
		}

		if ($importObjects.Count -gt 0) {
			if ($Credential -eq $null -or $Credential -eq [PSCredential]::Empty) {
				$importObjects | Import-FIMConfig -Uri $Uri
			} else {
				$importObjects | Import-FIMConfig -Uri $Uri -Credential $Credential
			}
		}
	}
}

<#
	.SYNOPSIS
		Returns the WMI class for MIIS_Server.
#>
function Get-FIMServer {
	param (
		[ValidateNotNullOrEmpty()]
		[string] $ComputerName = '.'
	)

	end {
		Get-WmiObject -Class 'MIIS_Server' -Namespace 'root\MicrosoftIdentityIntegrationServer' -Computer $ComputerName
	}
}

<#
	.SYNOPSIS
		Clears the run history before the specified date.

	.PARAMETER DateTime
		All run history before the specified value will be deleted.

	.PARAMETER TimeSpan
		All run history before the current date minus the specified time span will be deleted.

	.EXAMPLE
		Get-FIMServer | Clear-FIMRunHistory -Time 30d

		Deletes all run history prior to 30 days ago.
#>
function Clear-FIMRunHistory {
	[CmdletBinding(DefaultParameterSetName = 'DateTime', SupportsShouldProcess = $true, ConfirmImpact = 'Low')]
	param (
		[Parameter(Mandatory = $true, ValueFromPipeline = $true)]
		[ValidateScript({ $_.__CLASS -eq 'MIIS_Server' })]
		[Alias('Server')]
		[WMI] $FIMServer,
		
		[Parameter(Mandatory = $true, ParameterSetName = 'DateTime')]
		[DateTime] $DateTime,
		
		[Parameter(Mandatory = $true, ParameterSetName = 'TimeSpan')]
		[TimeSpan] $TimeSpan
	)
	
	begin {
		switch ($PsCmdlet.ParameterSetName) {
			'TimeSpan' {
				$endingBefore = [DateTime]::Now.Subtract($TimeSpan).ToUniversalTime()
			}
			
			'DateTime' {
				$endingBefore = $DateTime.ToUniversalTime()
			}
		}
	}
	
	process {
		if ($PsCmdlet.ShouldProcess($FIMServer.__SERVER)) {
			$FIMServer | Select-Object -Property @{Name='Name';Expression={$_.__SERVER}},@{Name='Status';Expression={$_.ClearRuns($endingBefore.ToString('yyyy-MM-dd HH:mm:ss.fff'))}}
		}
	}
}

<#
	.SYNOPSIS
		Retrieves all FIM run history.

	.PARAMETER Filter
		This is passed to the Get-WmiObject cmdlet.

	.EXAMPLE
		Get-FIMServer | Get-FIMRunHistory

		Retrieves all run history on the local server.
#>
function Get-FIMRunHistory {
	param (
		[Parameter(Mandatory = $true, ValueFromPipeline = $true)]
		[ValidateScript({ $_.__CLASS -eq 'MIIS_Server' })]
		[Alias('Server')]
		[WMI] $FIMServer,

		[ValidateNotNullOrEmpty()]
		[string] $Filter
	)

	process {
		Get-WmiObject -Class 'MIIS_RunHistory' -Namespace 'root\MicrosoftIdentityIntegrationServer' -Filter $Filter -Computer ($FIMServer.__SERVER)
	}
}

<#
	.SYNOPSIS
		Retrieves all FIM management agents.

	.PARAMETER Filter
		This is passed to the Get-WmiObject cmdlet.

	.EXAMPLE
		Get-FIMServer | Get-FIMManagementAgent

		Retrieves all management agents on the local server.

	.EXAMPLE
		Get-FIMServer | Get-FIMManagementAgent -Name 'FIM'

		Retrieves the management agent with the name FIM on the local server.
#>
function Get-FIMManagementAgent {
	[CmdletBinding(DefaultParameterSetName = 'Filter')]
	param (
		[Parameter(Mandatory = $true, ValueFromPipeline = $true)]
		[ValidateScript({ $_.__CLASS -eq 'MIIS_Server' })]
		[Alias('Server')]
		[WMI] $FIMServer,

		[Parameter(ParameterSetName = 'Filter')]
		[ValidateNotNullOrEmpty()]
		[string] $Filter,
		
		[Parameter(ParameterSetName = 'FilterByName')]
		[ValidateNotNullOrEmpty()]
		[string] $Name
	)

	process {
		if ($PsCmdlet.ParameterSetName -eq 'FilterByName') {
			$Filter = "Name = '$Name'"
		}
		
		Get-WmiObject -Class 'MIIS_ManagementAgent' -Namespace 'root\MicrosoftIdentityIntegrationServer' -Filter $Filter -Computer ($FIMServer.__SERVER)
	}
}

<#
	.SYNOPSIS
		Retrieves the current run status of the specified management agent(s).

	.EXAMPLE
		Get-FIMServer | Get-FIMManagementAgent | Get-FIMManagementAgentStatus

		Retrieves the run status of all management agents on the local server.
#>
function Get-FIMManagementAgentStatus {
	param (
		[Parameter(Mandatory = $true, ValueFromPipeline = $true)]
		[ValidateScript({ $_.__CLASS -eq 'MIIS_ManagementAgent' })]
		[Alias('MA')]
		[WMI] $ManagementAgent
	)
	
	process {
		$ManagementAgent | Select-Object -Property Name,Type,@{Name='Status';Expression={$_.RunStatus().ReturnValue}}
	}
}

<#
	.SYNOPSIS
		Executes the run profile for the specified management agent(s).

	.PARAMETER AsJob
		This will spawn a PowerShell job to run the management agent and return the output from the Start-Job cmdlet.

	.PARAMETER ExpectedStatus
		The default run statuses that are considered successful are 'success' or 'completed-*' when it is not 'completed-*-errors'. 
		
		Use this parameter to override the behavior of when to throw an error.

	.EXAMPLE
		Get-FIMServer | Get-FIMManagementAgent | Start-FIMManagementAgent -Profile 'Full Synchronization'

		Executes the profile 'Full Synchronization' on every management agent on the local server. This is synchronous and will wait for each management agent to run before starting the next one.

	.EXAMPLE
		Get-FIMServer | Get-FIMManagementAgent | Start-FIMManagementAgent -Profile 'Full Import' -AsJob

		Executes the profile 'Full Import' on every management agent on the local server. This is asynchronous and start the run profile for each management agent and return immediately.

	.EXAMPLE
		Start-FIMManagementAgent -Name 'FIM' -Profile 'Export' -AsJob | Wait-Job | Receive-Job

		Executes the profile 'Export' on the 'FIM' management agent on the local server as a PowerShell job but then waits for the job to complete and then retrieves the output.

	.NOTES
		This is a simple example of how you can execute a several run profiles to optimize execution time.
		
		It uses a mixture of both synchronization and asynchronous runs.
	
		Start-FIMManagementAgent -Name 'HR' -Profile 'Full Import' -AsJob
		Start-FIMManagementAgent -Name 'AD' -Profile 'Delta Import' -AsJob
		Start-FIMManagementAgent -Name 'FIM' -Profile 'Delta Import' -AsJob
		Get-Job | Wait-Job | Receive-Job

		Start-FIMManagementAgent -Name 'HR' -Profile 'Delta Synchronization'
		Start-FIMManagementAgent -Name 'AD' -Profile 'Delta Synchronization'
		Start-FIMManagementAgent -Name 'FIM' -Profile 'Delta Synchronization'

		Start-FIMManagementAgent -Name 'AD' -Profile 'Export' -AsJob
		Start-FIMManagementAgent -Name 'FIM' -Profile 'Export' -AsJob
		Get-Job | Wait-Job | Receive-Job

		Start-FIMManagementAgent -Name 'AD' -Profile 'Delta Import' -AsJob
		Start-FIMManagementAgent -Name 'FIM' -Profile 'Delta Import' -AsJob
		Get-Job | Wait-Job | Receive-Job
#>
function Start-FIMManagementAgent {
	[CmdletBinding(DefaultParameterSetName = 'Implicit')]
	param (
		[Parameter(Position = 0, Mandatory = $true, ValueFromPipeline = $true, ParameterSetName = 'Implicit')]
		[ValidateScript({ $_.__CLASS -eq 'MIIS_ManagementAgent' })]
		[Alias('MA')]
		[WMI] $ManagementAgent,
		
		[Parameter(Position = 0, Mandatory = $true, ParameterSetName = 'Explicit')]
		[ValidateNotNullOrEmpty()]
		[Alias('Name')]
		[string] $MaName,
		
		[Parameter(ParameterSetName = 'Explicit')]
		[ValidateNotNullOrEmpty()]
		[string] $ComputerName = '.',
		
		[Parameter(Position = 1, Mandatory = $true)]
		[ValidateNotNullOrEmpty()]
		[Alias('Profile')]
		[string] $RunProfile,

		[ValidateNotNull()]
		[Alias('Status')]
		[ScriptBlock] $ExpectedStatus = { $_ -eq 'success' -or ($_ -like 'completed-*' -and $_ -notlike 'completed-*-errors') },
		
		[Switch] $AsJob = $false
	) 

	begin {
		if ($PsCmdlet.ParameterSetName -eq 'Explicit') {
			$ManagementAgent = Get-FIMServer -ComputerName $ComputerName | Get-FIMManagementAgent -Name $MaName
		}
		
		$__StartFIMManagementAgent = {
			param($ManagementAgent, $RunProfile, $ExpectedStatus)
			
			$ManagementAgent = [WMI]$ManagementAgent
			
			$started = Get-Date
			$result = $ManagementAgent.Execute($RunProfile)
			$finished = Get-Date
			
			$ManagementAgent | Select-Object Name,@{N='Profile';E={$RunProfile}},@{N='Status';E={$result.ReturnValue}},@{N='Started';E={$started}},@{N='Finished';E={Get-Date}},@{N='Duration';E={(Get-Date) - $started}}
			
			$ExpectedStatus = [ScriptBlock]::Create($ExpectedStatus)
			
			if (!($result.ReturnValue |? $ExpectedStatus)) {
				throw "$($ComputerName)\$($MaName) ($($RunProfile)): $($result.ReturnValue)"
			}
		}
	}
	
	process {
		if ($AsJob) {
			Start-Job -Name "Start-FIMManagementAgent: $($ManagementAgent.__SERVER)\$($ManagementAgent.Name) - $RunProfile" -ArgumentList $ManagementAgent.__PATH,$RunProfile,$ExpectedStatus -ScriptBlock $__StartFIMManagementAgent
		} else {
			& $__StartFIMManagementAgent $ManagementAgent.__PATH $RunProfile $ExpectedStatus.ToString()
		}
	}
}

<#
	.SYNOPSIS
		Attmepts to stop the management agent if it is executing a run profile.
#>
function Stop-FIMManagementAgent {
	[CmdletBinding(DefaultParameterSetName = 'Implicit', SupportsShouldProcess = $true, ConfirmImpact = 'Low')]
	param (
		[Parameter(Position = 0, Mandatory = $true, ValueFromPipeline = $true, ParameterSetName = 'Implicit')]
		[ValidateScript({ $_.__CLASS -eq 'MIIS_ManagementAgent' })]
		[Alias('MA')]
		[WMI] $ManagementAgent,
		
		[Parameter(Position = 0, Mandatory = $true, ParameterSetName = 'Explicit')]
		[ValidateNotNullOrEmpty()]
		[Alias('Name')]
		[string] $MaName,
		
		[Parameter(ParameterSetName = 'Explicit')]
		[ValidateNotNullOrEmpty()]
		[string] $ComputerName = '.'
	)

	begin {
		if ($PsCmdlet.ParameterSetName -eq 'Explicit') {
			$ManagementAgent = Get-FIMServer -ComputerName $ComputerName | Get-FIMManagementAgent -Name $MaName
		}
	}
	
	process {
		if ($PsCmdlet.ShouldProcess($ManagementAgent.Name)) {
			$ManagementAgent | Select-Object -Property Name,Type,@{Name='Status';Expression={$_.Stop().ReturnValue}}
		}
	}
}


Add-PSTypeAccelerator -Alias 'FIMExportObject' -Type Microsoft.ResourceManagement.Automation.ObjectModel.ExportObject -Force
Add-PSTypeAccelerator -Alias 'FIMResourceManagementObject' -Type Microsoft.ResourceManagement.Automation.ObjectModel.ResourceManagementObject -Force
Add-PSTypeAccelerator -Alias 'FIMImportState' -Type Microsoft.ResourceManagement.Automation.ObjectModel.ImportState -Force
Add-PSTypeAccelerator -Alias 'FIMImportOperation' -Type Microsoft.ResourceManagement.Automation.ObjectModel.ImportOperation -Force
Add-PSTypeAccelerator -Alias 'FIMImportChange' -Type Microsoft.ResourceManagement.Automation.ObjectModel.ImportChange -Force
Add-PSTypeAccelerator -Alias 'FIMImportObject' -Type Microsoft.ResourceManagement.Automation.ObjectModel.ImportObject -Force
Add-PSTypeAccelerator -Alias 'PSCredential' -Type System.Management.Automation.PSCredential -Force


Export-ModuleMember -Function Get-FIMHelp,Get-FIMResource,Set-FIMAttribute,Add-FIMAttribute,Remove-FIMAttribute,Clear-FIMAttribute,New-FIMResource,Remove-FIMResource,Set-FIMResource,Get-FIMServer,Get-FIMRunHistory,Clear-FIMRunHistory,Get-FIMManagementAgent,Get-FIMManagementAgentStatus,Start-FIMManagementAgent,Stop-FIMManagementAgent