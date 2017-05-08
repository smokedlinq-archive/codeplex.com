param ([string] $FlowRuleName, [csentry] $csentry, [mventry] $mventry)

<#
	Maps the userPrincipalName attribute to the email address or default value

	Location: .\MaData\ADMA\PowerShell\MapAttributesForExport.ps1
#>

$ErrorActionPreference = 'Stop'

switch ($FlowRuleName) {
    'user.userPrincipalName' { 
        $email = $mventry['email']

        if ($email.IsPresent) {
            $csentry['userPrincipalName'].Value = $email.Value
        } else {
            $csentry['userPrincipalName'].Value = '{0}@codeplex.com' -f $mventry['accountName'].Value
        }
    }
}
