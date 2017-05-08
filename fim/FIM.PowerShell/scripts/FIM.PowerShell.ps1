#Requires -Version 3.0

function Add-PSTypeAccelerator {
	[CmdletBinding()]
	param(
		[Parameter(Mandatory = $true, ValueFromPipeline = $true)]
		[ValidateNotNull()]
		[Type] $Type,

		[Parameter(ValueFromPipelineByPropertyName = $true)]
		[ValidateNotNullOrEmpty()]
		[Alias('Alias')]
		[string] $Name = $Type.Name
	)

	begin {
		$PSTypeAccelerators = [Type]::GetType("System.Management.Automation.TypeAccelerators, $([PSObject].Assembly.FullName)")
	}

	process {
		if ($PSTypeAccelerators::Add) {
			if ($PSTypeAccelerators::Get.ContainsKey($Name)) {
				$PSTypeAccelerators::Remove($Name) | Out-Null
			}

			$PSTypeAccelerators::Add($Name, $Type)
		} elseif ($PSTypeAccelerators::AddReplace) {
			$PSTypeAccelerators::AddReplace($Name, $Type)
		}
	}
}

Add-Type -Path "${ENV:PROGRAMFILES}\Microsoft Forefront Identity Manager\2010\Synchronization Service\Bin\Assemblies\Microsoft.MetadirectoryServicesEx.dll"

# Import all public types from Microsoft.MetadirectoryServices (exclude interfaces)
[Microsoft.MetadirectoryServices.MVEntry].Assembly.GetTypes() |? { $_.Namespace -eq 'Microsoft.MetadirectoryServices' -and $_.Name -notlike 'I*' } | Add-PSTypeAccelerator

# Helper types
Add-PSTypeAccelerator -Name SecureString -Type ([System.Security.SecureString])
