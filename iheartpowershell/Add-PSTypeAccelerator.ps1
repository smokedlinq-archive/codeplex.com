[CmdletBinding()]
param
(
    [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
    [ValidateNotNull()]
    [Type] $Type,

    [Parameter(ValueFromPipelineByPropertyName = $true)]
    [ValidateNotNullOrEmpty()]
    [string] $Name = $Type.Name
)

begin {
    $PSTypeAccelerators = [Type]::GetType("System.Management.Automation.TypeAccelerators, $([PSObject].Assembly.FullName)")
}

process {
    if ($PSTypeAccelerators::Add) {
        $PSTypeAccelerators::Add($Name, $Type)
    } elseif ($PSTypeAccelerators::AddReplace) {
        $PSTypeAccelerators::AddReplace($Name, $Type)
    }
}