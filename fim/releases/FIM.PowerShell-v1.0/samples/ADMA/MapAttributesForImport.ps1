param ([string] $FlowRuleName, [csentry] $csentry, [mventry] $mventry)

<#
	Maps the annoying AD groupType to scope and type attributes

	Location: .\MaData\ADMA\PowerShell\MapAttributesForImport.ps1
#>

$ErrorActionPreference = 'Stop'

switch ($csentry.ObjectType) {
	'group' {
		switch ($FlowRuleName) {
			'type' {
				$groupType = $csentry['groupType'].IntegerValue

				if ( ($groupType -bor 14) -eq 14 ) {
					$mventry['type'].Value = 'Distribution'
				} else {
					$mventry['type'].Value = 'Security'
				}
			}

			'scope' { 
				$groupType = $csentry['groupType'].IntegerValue

				if ( ($groupType -band 2) -eq 2 ) {
					$mventry['scope'].Value = 'Global'
				} elseif ( ($groupType -band 4) -eq 4 ) {
					$mventry['scope'].Value = 'DomainLocal'
				} else {
					$mventry['scope'].Value = 'Universal'
				}
			}
		}
	}
}