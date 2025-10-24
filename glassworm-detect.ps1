#!/usr/bin/env pwsh

# Glassworm Detection Script for Windows/PowerShell
# Detects malicious VSCode/OpenVSX extensions affected by the Glassworm attack
# Date: October 2025
# Requires: PowerShell Core 7.0+ (recommended) or Windows PowerShell 5.1+

<#
.SYNOPSIS
	Detects malicious VSCode extensions affected by the Glassworm attack.

.DESCRIPTION
	This script scans installed VSCode, VSCode Insiders, and VSCodium installations
	for known malicious extensions from the Glassworm attack. It can automatically
	uninstall infected extensions if found.

.NOTES
	If you encounter execution policy errors, run:
	Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser

.LINK
	https://github.com/unic/glassworm-detect
#>

# Known malicious extensions with affected versions
$MaliciousExtensions = @{
	"codejoy.codejoy-vscode-extension" = @("1.8.3", "1.8.4")
	"l-igh-t.vscode-theme-seti-folder" = @("1.2.3")
	"kleinesfilmroellchen.serenity-dsl-syntaxhighlight" = @("0.3.2")
	"JScearcy.rust-doc-viewer" = @("4.2.1")
	"SIRILMP.dark-theme-sm" = @("3.11.4")
	"CodeInKlingon.git-worktree-menu" = @("1.0.9", "1.0.91")
	"ginfuru.better-nunjucks" = @("0.3.2")
	"ellacrity.recoil" = @("0.7.4")
	"grrrck.positron-plus-1-e" = @("0.0.71")
	"jeronimoekerdt.color-picker-universal" = @("2.8.91")
	"srcery-colors.srcery-colors" = @("0.3.9")
	"sissel.shopify-liquid" = @("4.0.1")
	"TretinV3.forts-api-extention" = @("0.3.1")
	"cline-ai-main.cline-ai-agent" = @("3.1.3")
}

# Arrays to store found infected extensions and VSCode installations
$script:InfectedExtensions = @()
$script:VSCodeCommands = @()

# Function to print header
function Write-Header {
	Write-Host "========================================" -ForegroundColor Blue
	Write-Host "   Glassworm Extension Detection Tool" -ForegroundColor Blue
	Write-Host "========================================" -ForegroundColor Blue
	Write-Host ""
}

# Function to check if a command exists
function Test-CommandExists {
	param([string]$Command)

	$null = Get-Command $Command -ErrorAction SilentlyContinue
	return $?
}

# Function to check extensions for a specific VSCode installation
function Test-VSCodeInstallation {
	param(
		[string]$Command,
		[string]$Name
	)

	Write-Host "Checking ${Name}..." -ForegroundColor Blue

	# Check for both .cmd and direct executable
	$cmdExists = Test-CommandExists $Command
	$cmdWithExtExists = Test-CommandExists "$Command.cmd"

	if (-not $cmdExists -and -not $cmdWithExtExists) {
		Write-Host "  ⚠ ${Name} not found" -ForegroundColor Yellow
		return $false
	}

	# Use the command that exists
	$actualCommand = if ($cmdExists) { $Command } else { "$Command.cmd" }

	$script:VSCodeCommands += @{
		Command = $actualCommand
		Name = $Name
	}

	# Get installed extensions with versions
	try {
		$installedExtensions = & $actualCommand --list-extensions --show-versions 2>&1
		if ($LASTEXITCODE -ne 0) {
			throw "Failed to retrieve extensions"
		}
	}
	catch {
		Write-Host "  ⚠ Error retrieving extensions" -ForegroundColor Yellow
		return $false
	}

	if (-not $installedExtensions) {
		Write-Host "  ✓ No extensions installed" -ForegroundColor Green
		return $true
	}

	$foundInfected = $false

	# Check each installed extension against malicious list
	foreach ($extLine in $installedExtensions) {
		# Parse extension ID and version
		$parts = $extLine -split '@'
		$extId = $parts[0]
		$extVersion = $parts[1]

		# Check if this extension is in the malicious list
		if ($MaliciousExtensions.ContainsKey($extId)) {
			# Check if the installed version matches a malicious version
			$maliciousVersions = $MaliciousExtensions[$extId]

			if ($maliciousVersions -contains $extVersion) {
				$script:InfectedExtensions += @{
					VSCodeName = $Name
					Command = $actualCommand
					ExtensionId = $extId
					Version = $extVersion
					FullName = "${extId}@${extVersion}"
				}
				Write-Host "  ✗ INFECTED: ${extId}@${extVersion}" -ForegroundColor Red
				$foundInfected = $true
			}
		}
	}

	if (-not $foundInfected) {
		Write-Host "  ✓ No infected extensions found" -ForegroundColor Green
	}

	Write-Host ""
	return $true
}

# Function to uninstall an extension
function Uninstall-Extension {
	param(
		[hashtable]$InfectedInfo
	)

	$vscodeName = $InfectedInfo.VSCodeName
	$command = $InfectedInfo.Command
	$extId = $InfectedInfo.ExtensionId
	$fullName = $InfectedInfo.FullName

	Write-Host "Uninstalling $fullName from $vscodeName..." -ForegroundColor Yellow

	try {
		& $command --uninstall-extension $extId 2>&1 | Out-Null
		if ($LASTEXITCODE -eq 0) {
			Write-Host "✓ Successfully uninstalled $extId" -ForegroundColor Green
			return $true
		}
		else {
			Write-Host "✗ Failed to uninstall $extId" -ForegroundColor Red
			return $false
		}
	}
	catch {
		Write-Host "✗ Failed to uninstall $extId - $_" -ForegroundColor Red
		return $false
	}
}

# Function to offer uninstallation
function Invoke-UninstallOffer {
	Write-Host ""
	Write-Host "========================================" -ForegroundColor Yellow
	Write-Host "        Uninstall Infected Extensions" -ForegroundColor Yellow
	Write-Host "========================================" -ForegroundColor Yellow
	Write-Host ""

	foreach ($infected in $script:InfectedExtensions) {
		$vscodeName = $infected.VSCodeName
		$fullName = $infected.FullName

		Write-Host "Found: $fullName in $vscodeName" -ForegroundColor Red

		$response = Read-Host "Do you want to uninstall this extension? (y/n)"

		if ($response -match '^[Yy]') {
			Uninstall-Extension -InfectedInfo $infected
		}
		else {
			Write-Host "Skipped uninstallation" -ForegroundColor Yellow
		}
		Write-Host ""
	}
}

# Function to print summary
function Write-Summary {
	Write-Host ""
	Write-Host "========================================" -ForegroundColor Blue
	Write-Host "              Summary" -ForegroundColor Blue
	Write-Host "========================================" -ForegroundColor Blue
	Write-Host ""

	$numInstallations = $script:VSCodeCommands.Count
	Write-Host "VSCode installations found: " -NoNewline
	Write-Host $numInstallations -ForegroundColor Blue

	if ($numInstallations -gt 1) {
		Write-Host "⚠ Multiple VSCode installations detected:" -ForegroundColor Yellow
		foreach ($vscode in $script:VSCodeCommands) {
			Write-Host "  • $($vscode.Name)"
		}
		Write-Host ""
	}

	$numInfected = $script:InfectedExtensions.Count

	if ($numInfected -eq 0) {
		Write-Host "✓ CLEAN: No infected extensions found!" -ForegroundColor Green
		Write-Host "  Your system appears to be safe from Glassworm." -ForegroundColor Green
		return 0
	}
	else {
		Write-Host "✗ INFECTED: Found $numInfected malicious extension(s)!" -ForegroundColor Red
		Write-Host ""
		Write-Host "Infected extensions:" -ForegroundColor Red
		foreach ($infected in $script:InfectedExtensions) {
			$vscodeName = $infected.VSCodeName
			$fullName = $infected.FullName
			Write-Host "  • $fullName " -NoNewline -ForegroundColor Red
			Write-Host "(in $vscodeName)" -ForegroundColor Yellow
		}
		Write-Host ""

		if ($numInstallations -gt 1) {
			Write-Host "⚠ WARNING: You have multiple VSCode installations." -ForegroundColor Yellow
			Write-Host "  Please ensure you check and clean ALL installations." -ForegroundColor Yellow
			Write-Host ""
		}

		return 1
	}
}

# Main execution
function Main {
	Write-Header

	# Check for different VSCode installations
	Test-VSCodeInstallation -Command "code" -Name "Visual Studio Code"
	Test-VSCodeInstallation -Command "code-insiders" -Name "Visual Studio Code Insiders"
	Test-VSCodeInstallation -Command "codium" -Name "VSCodium"

	# Print summary and get status
	$status = Write-Summary

	# Offer to uninstall if infections found
	if ($script:InfectedExtensions.Count -gt 0) {
		Invoke-UninstallOffer

		Write-Host ""
		Write-Host "========================================" -ForegroundColor Yellow
		Write-Host "      Recommended Next Steps" -ForegroundColor Yellow
		Write-Host "========================================" -ForegroundColor Yellow
		Write-Host ""
		Write-Host "1. Review your system for suspicious activity"
		Write-Host "2. Change passwords for sensitive accounts"
		Write-Host "3. Run a full system security scan"
		Write-Host "4. Monitor for unusual network activity"
		Write-Host "5. Check browser extensions and other applications"
		Write-Host ""
	}

	# Create log file
	$timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
	$logFile = "glassworm-scan-$timestamp.log"

	$logContent = @"
Glassworm Scan Report
Date: $(Get-Date)
User: $env:USERNAME
Computer: $env:COMPUTERNAME

VSCode Installations Found: $($script:VSCodeCommands.Count)
$(foreach ($vscode in $script:VSCodeCommands) { "  - $($vscode.Name)`n" })

Infected Extensions: $($script:InfectedExtensions.Count)
$(foreach ($infected in $script:InfectedExtensions) { "  - $($infected.VSCodeName): $($infected.FullName)`n" })
"@

	$logContent | Out-File -FilePath $logFile -Encoding UTF8

	Write-Host "Scan log saved to: $logFile" -ForegroundColor Blue
	Write-Host ""

	# Exit with appropriate code
	exit $status
}

# Run main function
Main
