[CmdletBinding()]
param
(
    [Parameter(Mandatory=$true)]
    [string] $Path,

    [Parameter(Mandatory=$true)]
    [string] $Identity,

    [Parameter(Mandatory=$true)]
    [System.Security.AccessControl.RegistryRights] $Rights,

    [System.Security.AccessControl.InheritanceFlags] $Inheritance = [System.Security.AccessControl.InheritanceFlags]::None,
    [System.Security.AccessControl.PropagationFlags] $Propagation = [System.Security.AccessControl.PropagationFlags]::None
)

$rule = New-Object System.Security.AccessControl.RegistryAccessRule $Identity,$Rights,$Inheritance,$Propagation,Allow

$acl = Get-Acl $Path
$acl.AddAccessRule($rule)

Set-Acl -Path $Path -Acl $acl