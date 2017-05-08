param([csentry] $csentry)

<#
	Determines the deprovisioning status of a user

	Location: .\MaData\ADMA\PowerShell\MapAttributesForImport.ps1
#>

$ADS_UF_ACCOUNTDISABLE = 0x002
$ADS_UF_NORMAL_ACCOUNT = 0x200

switch ($csentry.ObjectType) {
    'user' {
		if ($csentry.DN.ToString() -match ',OU=FIM,DC=codeplex,DC=com$') {
            'Delete'
        } else {
			# Disable and disconnect the user object
            $uac = $csentry['userAccountControl']

            if ($uac.IsPresent) {
                $uac.IntegerValue = $uac.IntegerValue -bor $ADS_UF_ACCOUNTDISABLE 
            } else {
                $uac.IntegerValue = $ADS_UF_NORMAL_ACCOUNT -bor $ADS_UF_ACCOUNTDISABLE 
            }

            'Disconnect'
        }
    }
}