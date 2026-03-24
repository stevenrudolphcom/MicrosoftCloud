#Script to clean up PowerShell modules that were installed.
#Only modules that are not in the exclusion list will be uninstalled if you chose ForceRemoval. 
#If you choose TestMode, it will only list the modules that would be removed without actually uninstalling them.

param(
	[switch]$ForceRemoval,
	[switch]$TestMode,
	[string[]]$ExcludeModules = @(
		"Microsoft.PowerShell.Archive",
		"Microsoft.PowerShell.Diagnostics",
		"Microsoft.PowerShell.Host",
		"Microsoft.PowerShell.Management",
		"Microsoft.PowerShell.Security",
		"Microsoft.PowerShell.Utility",
		"PackageManagement",
		"PowerShellGet",
		"PSReadLine"
	)
)

if ($ForceRemoval -and $TestMode) {
	Write-Error "Bitte nur einen Modus waehlen: -ForceRemoval oder -TestMode."
	return
}

if (-not $ForceRemoval -and -not $TestMode) {
	$selection = Read-Host "Modus waehlen: [F]orceRemoval, [T]estmodus (WhatIf), [A]bbrechen"
	switch ($selection.ToUpperInvariant()) {
		"F" { $ForceRemoval = $true }
		"T" { $TestMode = $true }
		default {
			Write-Output "Abgebrochen."
			return
		}
	}
}

$cleanupModules = {
	param(
		[switch]$ForceRemoval,
		[switch]$TestMode,
		[string[]]$ExcludeModules
	)

	# Get only modules that are manageable by PowerShellGet from installed repositories.
	$installed = Get-InstalledModule -ErrorAction SilentlyContinue |
		Where-Object { $ExcludeModules -notcontains $_.Name }

	if (-not $installed) {
		Write-Output "Keine deinstallierbaren Module gefunden (oder alle sind ausgeschlossen)."
		return
	}

	Write-Output ("Gefundene deinstallierbare Module: " + $installed.Count)
	$installed | Select-Object Name, Version, Repository | Format-Table -AutoSize

	foreach ($module in $installed) {
		if ($ForceRemoval) {
			Uninstall-Module -Name $module.Name -RequiredVersion $module.Version -Force -ErrorAction Continue
		}
	}

	if ($ForceRemoval) {
		Write-Output "Deinstallation ausgefuehrt."
	}
	else {
		Write-Output ("Testmodus abgeschlossen. Es wurden keine Module entfernt. Geplante Deinstallationen: " + $installed.Count)
	}
}

& $cleanupModules -ForceRemoval:$ForceRemoval -TestMode:$TestMode -ExcludeModules $ExcludeModules
