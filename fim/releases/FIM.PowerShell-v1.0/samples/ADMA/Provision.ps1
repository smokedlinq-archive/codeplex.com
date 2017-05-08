param ([mventry] $mventry)

<#
	Determines the provisioning status of a person to the Active Directory MA

	Location: .\MaData\ADMA\PowerShell\Provision.ps1
#>

$ErrorActionPreference = 'Stop'

$ADS_UF_NORMAL_ACCOUNT     = 0x00200
$ADS_UF_DONT_EXPIRE_PASSWD = 0x10000

if ( $mventry.ObjectType -eq 'person' ) {
    $ma  = $mventry.ConnectedMAs['ADMA']
    $rdn = 'CN={0}' -f $mventry['accountName'].Value
    $employeeStatus = $mventry['employeeStatus']
    $shouldExist = @('Active - Full Time','Active - Part Time') -contains $employeeStatus.Value
	$doesExist   = $ma.Connectors.Count -eq 1

    if (-not $doesExist -and $shouldExist) {
        $dn  = $ma.EscapeDNComponent($rdn).Concat('OU=FIM,DC=codeplex,DC=com')
        $employeeID = $mventry['employeeID']

        $csentry = $ma.Connectors.StartNewConnector('user')
        $csentry.DN = $dn
        $csentry['sAMAccountName'].Value = $mventry['accountName'].Value
        $csentry['employeeID'].Value = $employeeID.Value
        $csentry['unicodePwd'].Values.Add('FIM#000000')
        $csentry['userAccountControl'].IntegerValue = $ADS_UF_NORMAL_ACCOUNT -bor $ADS_UF_DONT_EXPIRE_PASSWD
        $csentry.CommitNewConnector()
    } elseif ($doesExist) {
        $csentry = $ma.Connectors.ByIndex[0]
        
        if ($shouldExist) {
            $departmentNumber = $mventry['departmentNumber']

            if ($departmentNumber.IsPresent) {
				$ouMapping = @{
					'IT'    = 'OU=Information Technology,OU=codeplex,OU=com';
					'HR'    = 'OU=Human Resources,OU=codeplex,OU=com';
					'SALES' = 'OU=Sales,OU=codeplex,OU=com';
				};

				$ou = $ouMapping[$departmentNumber.Value]
                $dn = $ma.EscapeDNComponent($rdn).Concat($ou)

                if ($csentry.DN.ToString() -ne $dn.ToString()) {
                    $csentry.DN = $dn
                }
            }
        } else {
            $csentry.Deprovision()
        }
    }
}