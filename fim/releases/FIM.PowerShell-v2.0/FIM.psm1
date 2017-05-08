#Requires -Version 3.0
#Requires -PSSnapin FIMAutomation -Version 2.0

function Add-PSTypeAccelerator {
	[CmdletBinding()]
	param(
		[Parameter(Mandatory, ValueFromPipeline)]
		[ValidateNotNull()]
		[Type] $Type,

		[Parameter(Mandatory, ValueFromPipelineByPropertyName)]
		[ValidateNotNullOrEmpty()]
		[Alias('Alias')]
		[string] $Name = $Type.Name
	)

	begin {
		$PSTypeAccelerators = [Type]::GetType("System.Management.Automation.TypeAccelerators, $([PSObject].Assembly.FullName)")
	}

	process {
		$PSTypeAccelerators::AddReplace($Name, $Type)
	}
}

function New-FIMImportObject {
	[CmdletBinding()]
	param(
		[Parameter(Position=0, Mandatory, ValueFromPipelineByPropertyName)]
		[Guid] $ObjectID,
		
		[Parameter(Mandatory, ValueFromPipelineByPropertyName)]
		[string] $ObjectType = 'Resource',
		
		[FIMImportState] $State = [FIMImportState]::None
	)
	
	begin {
		$ImportObject = New-Object FIMImportObject
		$ImportObject.ObjectType = $ObjectType
		$ImportObject.TargetObjectIdentifier = $ObjectID
		$ImportObject.SourceObjectIdentifier = $ObjectID
		$ImportObject.State = $State
	}

	end {
		$ImportObject
	}
}

function New-FIMImportChange {
	[CmdletBinding()]
	param(
		[Parameter(Position=0, Mandatory)]
		[Alias('Name')]
		[string] $AttributeName,
		
		[Parameter(Position=1, Mandatory)]
		[Alias('Value')]
		[AllowEmptyString()]
		[AllowNull()]
		[string] $AttributeValue,
		
		[FIMImportOperation] $Operation = [FIMImportOperation]::None,
		
		[string] $Locale = 'Invariant',
		
		[switch] $FullyResolved = $true
	)
	
	begin {
		$ImportChange = New-Object FIMImportChange    
		$ImportChange.Operation = $Operation
		$ImportChange.AttributeName = $AttributeName

		if ($AttributeValue) {
			$ImportChange.AttributeValue = $AttributeValue
		}

		$ImportChange.Locale = $Locale
		$ImportChange.FullyResolved = $FullyResolved
	}
	
	end {
		$ImportChange
	}
}

<#
	.SYNOPSIS
		Creates a BASE64 encoded (AES 256-bit) string that can be used with the FIM PowerShell workflow activity to encrypt data.

	.OUTPUTS
		Base64 String
#>
function New-FIMPowerShellActivityEncryptionKey {
	[CmdletBinding()]
	param()

	begin {
		$AES = [System.Security.Cryptography.AesCryptoServiceProvider]::Create()
		AES.GenerateKey()
	}

	end {
		[Convert]::ToBase64String($AES.Key)
	}
}

<#
	.SYNOPSIS
		Returns all help content for the FIM module.
#>
function Get-FIMHelp {
	[CmdletBinding()]
	param()

	end {
		Get-Help -Module FIM
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
	[CmdletBinding()]
	param(
		[Parameter(Position=0, Mandatory, ValueFromPipeline)]
		[ValidateScript({$_ -is [FIMExportObject]})]
		[Alias('InputObject')]
		[PSObject] $Resource,
		
		[Parameter(Position=1, Mandatory)]
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
	[CmdletBinding()]
	param(
		[Parameter(Position = 0, Mandatory, ValueFromPipeline)]
		[ValidateScript({$_ -is [FIMExportObject]})]
		[PSObject] $Resource,
		
		[Parameter(Position = 1, Mandatory)]
		[Alias('Name')]
		[string] $AttributeName,
		
		[Parameter(Position = 2, Mandatory)]
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
	[CmdletBinding()]
	param(
		[Parameter(Position = 0, Mandatory, ValueFromPipeline)]
		[ValidateScript({$_ -is [FIMExportObject]})]
		[PSObject] $Resource,
		
		[Parameter(Position = 1, Mandatory)]
		[Alias('Name')]
		[string] $AttributeName,
		
		[Parameter(Position = 2, Mandatory)]
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

		@($AttributeValue) | ForEach-Object {
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
	[CmdletBinding()]
	param(
		[Parameter(Position = 0, Mandatory, ValueFromPipeline)]
		[ValidateScript({$_ -is [FIMExportObject]})]
		[PSObject] $Resource,
		
		[Parameter(Position = 1, Mandatory)]
		[Alias('Name')]
		[string] $AttributeName,
		
		[Parameter(Position = 2, Mandatory)]
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
		
		@($AttributeValue) | ForEach-Object {
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
	[CmdletBinding()]
	param(
		[Parameter(Position = 0, Mandatory)]
		[string[]] $Filter,
		
		[Credential]
		$Credential,
		
		[int] $MessageSize = 0,
		
		[Parameter(ParameterSetName = 'ComputerAndPort')]
		[string] $ComputerName = 'localhost',

		[Parameter(ParameterSetName = 'ComputerAndPort')]
		[int] $Port = 5725,
		
		[Parameter(ParameterSetName = 'Uri')]
		[string] $Uri = "http://${ComputerName}:${Port}"
	)
	
	begin {
		$ExportParameters = @{}

        if ($PSBoundParameters.ContainsKey('Credential')) {
			 $ExportParameters.Credential = $Credential
		}

		$Resources = @(Export-FIMConfig -Uri $Uri -CustomConfig $Filter -OnlyBaseResources -MessageSize $MessageSize @ExportParameters)
	}
	
	end {
		if ([int]$Resources.Count -gt 0) {
			$Resources | ForEach-Object {
				$Resource = $_
				
				$Resource.ResourceManagementObject.ResourceManagementAttributes | ForEach-Object {
					if ($_.IsMultiValue) {
						Add-Member -InputObject $Resource -MemberType NoteProperty -Name $_.AttributeName -Value @($_.Values | ForEach-Object {
							if ($_ -like 'urn:uuid:*') {
								$_ -replace '^urn:uuid:',''
							} else {
								$_
							}
						})
					} else {
						if ($_.Value -like 'urn:uuid:*') {
							Add-Member -InputObject $Resource -MemberType NoteProperty -Name $_.AttributeName -Value ($_.Value -replace '^urn:uuid:','')
						} else {
							Add-Member -InputObject $Resource -MemberType NoteProperty -Name $_.AttributeName -Value $_.Value
						}
					}

					Add-Member -InputObject $Resource -MemberType NoteProperty -Name 'Changes' -Value @() -Force
				}

				$Resource
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
	[CmdletBinding(SupportsShouldProcess, ConfirmImpact='High')]
	param(
		[Parameter(Position=0, Mandatory, ValueFromPipeline)]
		[ValidateScript({$_ -is [FIMExportObject]})]
		[PSObject] $Resource,
		
		[Credential] $Credential
	)
	
	begin {
		$ImportObjects = @()
	}
	
	process {
		if ($PsCmdlet.ShouldProcess($Resource.ObjectID)) {		
			$ImportObjects += @(New-FIMImportObject -ObjectID $Resource.ObjectID -State Delete)
		}
	}
	
	end {
		if ($ImportObjects.Count -gt 0) {
			$ImportParameters = @{}

			if ($PSBoundParameters.ContainsKey('Credential')) {
				$ImportParameters.Credential = $Credential
			}

			$ImportObjects | Group-Object -Property Source | ForEach-Object {
                $ImportParameters.Uri = $_.Name
				$_.Group | Import-FIMConfig @ImportParameters
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
	[CmdletBinding()]
	param(
		[Parameter(Position=0, Mandatory)]
		[ValidateNotNullOrEmpty()]
		[string] $ObjectType,
		
		[Guid] $ObjectID = [Guid]::NewGuid(),
		
		[Alias('Attributes')]
		[Hashtable] $Set,

		[Hashtable] $Add
	)
	
	begin {
		$Resource = New-Object FIMExportObject
		$Resource | Add-Member -MemberType NoteProperty -Name ObjectID -Value $ObjectID
		$Resource | Add-Member -MemberType NoteProperty -Name ObjectType -Value $ObjectType
		$Resource | Add-Member -MemberType NoteProperty -Name Changes -Value @()
		$Resource.Source = $null

		if ($Set) {
			$Set.Keys | ForEach-Object {
				Set-FIMAttribute -Resource $Resource -Name $_ -Value $Set[$_]
			}
		}

		if ($Add) {
			$Add.Keys | ForEach-Object {
				Add-FIMAttribute -Resource $Resource -Name $_ -Value $Add[$_]
			}
		}
	}
	
	end {
		$Resource
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
		
		[Parameter(ParameterSetName = 'ComputerAndPort')]
		[string] $ComputerName = 'localhost',
		
		[Parameter(ParameterSetName = 'ComputerAndPort')]
		[int] $Port = 5725,
		
		[Parameter(ParameterSetName = 'ExplicitUri')]
		[string] $Uri = 'http://{0}:{1}' -f ($ComputerName,$Port),
		
		[Credential] $Credential
	)
	
	begin {
		$ImportObjects = @()
	}
	
	process {
		if ($PsCmdlet.ShouldProcess($Resource.ObjectID)) {
			if ($Set) {
				$Set.Keys | ForEach-Object {
					Set-FIMAttribute -Resource $Resource -Name $_ -Value $Set[$_]
				}
			}

			if ($Add) {
				$Add.Keys | ForEach-Object {
					Add-FIMAttribute -Resource $Resource -Name $_ -Value $Add[$_]
				}
			}

			if ($Remove) {
				$Remove.Keys | ForEach-Object {
					Remove-FIMAttribute -Resource $Resource -Name $_ -Value $Remove[$_]
				}
			}

			if ($Clear) {
				$Clear | ForEach-Objet { 
                    Clear-FIMAttribute -Resource $Resource -Name $_ 
                }
			}
			
			if ([int]$Resource.Changes.Count -gt 0) {
				if ($Resource.ResourceManagementObject -eq $null) {
					$ImportObject = New-FIMImportObject -ObjectID $Resource.ObjectID -State Create
				} else {
					$ImportObject = New-FIMImportObject -ObjectID $Resource.ObjectID -State Put
				}
				
				$ImportObject.Changes = $Resource.Changes
				
				$ImportObjects += $ImportObject
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
	[CmdletBinding()]
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
	[CmdletBinding()]
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
	[CmdletBinding()]
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


Add-PSTypeAccelerator -Name 'FIMExportObject' -Type Microsoft.ResourceManagement.Automation.ObjectModel.ExportObject
Add-PSTypeAccelerator -Name 'FIMResourceManagementObject' -Type Microsoft.ResourceManagement.Automation.ObjectModel.ResourceManagementObject
Add-PSTypeAccelerator -Name 'FIMImportState' -Type Microsoft.ResourceManagement.Automation.ObjectModel.ImportState
Add-PSTypeAccelerator -Name 'FIMImportOperation' -Type Microsoft.ResourceManagement.Automation.ObjectModel.ImportOperation
Add-PSTypeAccelerator -Name 'FIMImportChange' -Type Microsoft.ResourceManagement.Automation.ObjectModel.ImportChange
Add-PSTypeAccelerator -Name 'FIMImportObject' -Type Microsoft.ResourceManagement.Automation.ObjectModel.ImportObject


Export-ModuleMember -Function Get-FIMHelp,Get-FIMResource,Set-FIMAttribute,Add-FIMAttribute,Remove-FIMAttribute,Clear-FIMAttribute,New-FIMResource,Remove-FIMResource,Set-FIMResource,Get-FIMServer,Get-FIMRunHistory,Clear-FIMRunHistory,Get-FIMManagementAgent,Get-FIMManagementAgentStatus,Start-FIMManagementAgent,Stop-FIMManagementAgent