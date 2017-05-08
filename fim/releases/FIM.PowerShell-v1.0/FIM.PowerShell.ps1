[System.Reflection.Assembly]::LoadFile('C:\Program Files\Microsoft Forefront Identity Manager\2010\Synchronization Service\Bin\Assemblies\Microsoft.MetadirectoryServicesEx.dll') | Out-Null

# Add FIM type accelerators [csentry] [mventry] [attrib] [DeprovisionAction]
$PSTypeAccelerators = [Type]::GetType("System.Management.Automation.TypeAccelerators")

if ($PSTypeAccelerators::Get.MVEntry -eq $null) {
    $PSTypeAccelerators::Add('MVEntry', [Microsoft.MetadirectoryServices.MVEntry])
    $PSTypeAccelerators::Add('CSEntry', [Microsoft.MetadirectoryServices.CSEntry])
    $PSTypeAccelerators::Add('Attrib', [Microsoft.MetadirectoryServices.Attrib])
    $PSTypeAccelerators::Add('DeprovisionAction', [Microsoft.MetadirectoryServices.DeprovisionAction])
    $PSTypeAccelerators::Add('ValueCollection', [Microsoft.MetadirectoryServices.ValueCollection])
}

# ResolveJoinSearch Expected Object Output
function New-ResolveJoinSearch {
    param(
        [int]    $imventry     = -1,
        [string] $MVObjectType = $null,
        [switch] $Success      = $false
    )
    
    end {
        New-Object PSObject | Select-Object @{Name='imventry';Expression={$imventry}},@{Name='MVObjectType';Expression={$MVObjectType}},@{Name='Result';Expression={$Success}}
    }
}

# ShouldProjectToMV Expected Object Output
function New-ShouldProjectToMV {
    param(
        [string] $MVObjectType = $null,
        [switch] $Success      = $false
    )
    
    end {
        New-Object PSObject | Select-Object @{Name='MVObjectType';Expression={$MVObjectType}},@{Name='Result';Expression={$Success}}
    }
}