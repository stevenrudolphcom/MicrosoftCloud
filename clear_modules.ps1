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
	Write-Error "Please choose only one mode: -ForceRemoval or -TestMode."
	return
}

if (-not $ForceRemoval -and -not $TestMode) {
	$selection = Read-Host "Choose mode: [F]orceRemoval, [T]est mode (WhatIf), [A]bort"
	switch ($selection.ToUpperInvariant()) {
		"F" { $ForceRemoval = $true }
		"T" { $TestMode = $true }
		default {
			Write-Output "Aborted."
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
		Write-Output "No uninstallable modules found (or all are excluded)."
		return
	}

	Write-Output ("Found uninstallable modules: " + $installed.Count)
	$installed | Select-Object Name, Version, Repository | Format-Table -AutoSize

	$uninstalledCount = 0
	foreach ($module in $installed) {
		if ($ForceRemoval) {
			try {
				Uninstall-Module -Name $module.Name -RequiredVersion $module.Version -Force -ErrorAction Stop
				$uninstalledCount++
				Write-Output "Uninstalled $uninstalledCount of $($installed.Count): $($module.Name) (Version: $($module.Version))"
			} catch {
				Write-Output "Failed to uninstall $($module.Name): $_"
			}
		}
	}

	if ($ForceRemoval) {
		Write-Output "Uninstallation executed."
	}
	else {
		Write-Output ("Test mode completed. No modules were removed. Planned uninstallations: " + $installed.Count)
	}
}

& $cleanupModules -ForceRemoval:$ForceRemoval -TestMode:$TestMode -ExcludeModules $ExcludeModules
