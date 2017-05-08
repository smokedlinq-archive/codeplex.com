param ([csentry] $csentry)

<#
	Filters accounts with improper data in the employeeID attribute

	Location: .\MaData\ADMA\PowerShell\FilterForDisconnection.ps1
#>

$ErrorActionPreference = 'Stop'

switch ($csentry.ObjectType) {
    'user'  { 
        $employeeID = $csentry['employeeID']

        if ($employeeID.IsPresent) {
            $employeeID.Value -notmatch '^\d{9,9}$'
        } else {
            $true
        }
    }
}

$false