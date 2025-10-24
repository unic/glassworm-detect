#!/usr/bin/env bash

# Glassworm Detection Script
# Detects malicious VSCode/OpenVSX extensions affected by the Glassworm attack
# Date: October 2025

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Known malicious extensions with affected versions
# Format: "extension_id|version1 version2 ..."
MALICIOUS_EXTENSIONS=(
	"codejoy.codejoy-vscode-extension|1.8.3 1.8.4"
	"l-igh-t.vscode-theme-seti-folder|1.2.3"
	"kleinesfilmroellchen.serenity-dsl-syntaxhighlight|0.3.2"
	"JScearcy.rust-doc-viewer|4.2.1"
	"SIRILMP.dark-theme-sm|3.11.4"
	"CodeInKlingon.git-worktree-menu|1.0.9 1.0.91"
	"ginfuru.better-nunjucks|0.3.2"
	"ellacrity.recoil|0.7.4"
	"grrrck.positron-plus-1-e|0.0.71"
	"jeronimoekerdt.color-picker-universal|2.8.91"
	"srcery-colors.srcery-colors|0.3.9"
	"sissel.shopify-liquid|4.0.1"
	"TretinV3.forts-api-extention|0.3.1"
	"cline-ai-main.cline-ai-agent|3.1.3"
)

# Array to store found infected extensions
INFECTED_EXTENSIONS=()
VSCODE_COMMANDS=()

# Function to get malicious versions for an extension ID
get_malicious_versions() {
	local ext_id="$1"
	for entry in "${MALICIOUS_EXTENSIONS[@]}"; do
		local entry_id="${entry%%|*}"
		local entry_versions="${entry#*|}"
		if [[ "$entry_id" == "$ext_id" ]]; then
			echo "$entry_versions"
			return 0
		fi
	done
	return 1
}

# Function to print header
print_header() {
	echo -e "${BLUE}========================================${NC}"
	echo -e "${BLUE}   Glassworm Extension Detection Tool${NC}"
	echo -e "${BLUE}========================================${NC}"
	echo ""
}

# Function to check if a command exists
command_exists() {
	command -v "$1" >/dev/null 2>&1
}

# Function to check extensions for a specific VSCode installation
check_vscode_installation() {
	local cmd="$1"
	local name="$2"

	echo -e "${BLUE}Checking ${name}...${NC}"

	if ! command_exists "$cmd"; then
		echo -e "${YELLOW}  ⚠ ${name} not found${NC}"
		return 1
	fi

	VSCODE_COMMANDS+=("$cmd:$name")

	# Get installed extensions with versions
	local installed_extensions
	installed_extensions=$("$cmd" --list-extensions --show-versions 2>/dev/null)

	if [ -z "$installed_extensions" ]; then
		echo -e "${GREEN}  ✓ No extensions installed${NC}"
		return 0
	fi

	local found_infected=false

	# Check each installed extension against malicious list
	while IFS= read -r ext_line; do
		# Parse extension ID and version
		local ext_id="${ext_line%@*}"
		local ext_version="${ext_line##*@}"

		# Check if this extension is in the malicious list
		local malicious_versions
		malicious_versions=$(get_malicious_versions "$ext_id")
		if [ -n "$malicious_versions" ]; then
			# Check if the installed version matches a malicious version
			for bad_version in $malicious_versions; do
				if [[ "$ext_version" == "$bad_version" ]]; then
					INFECTED_EXTENSIONS+=("$name:$ext_id@$ext_version")
					echo -e "${RED}  ✗ INFECTED: $ext_id@$ext_version${NC}"
					found_infected=true
				fi
			done
		fi
	done <<< "$installed_extensions"

	if [ "$found_infected" = false ]; then
		echo -e "${GREEN}  ✓ No infected extensions found${NC}"
	fi

	echo ""
	return 0
}

# Function to uninstall an extension
uninstall_extension() {
	local vscode_name="$1"
	local ext_full="$2"

	# Extract command from vscode_name
	local cmd=""
	case "$vscode_name" in
		*"Insiders"*) cmd="code-insiders" ;;
		*"VSCodium"*) cmd="codium" ;;
		*) cmd="code" ;;
	esac

	# Extract extension ID (without version)
	local ext_id="${ext_full%@*}"

	echo -e "${YELLOW}Uninstalling $ext_full from $vscode_name...${NC}"

	if $cmd --uninstall-extension "$ext_id" >/dev/null 2>&1; then
		echo -e "${GREEN}✓ Successfully uninstalled $ext_id${NC}"
		return 0
	else
		echo -e "${RED}✗ Failed to uninstall $ext_id${NC}"
		return 1
	fi
}

# Function to offer uninstallation
offer_uninstall() {
	echo ""
	echo -e "${YELLOW}========================================${NC}"
	echo -e "${YELLOW}        Uninstall Infected Extensions${NC}"
	echo -e "${YELLOW}========================================${NC}"
	echo ""

	for infected in "${INFECTED_EXTENSIONS[@]}"; do
		local vscode_name="${infected%%:*}"
		local ext_info="${infected#*:}"

		echo -e "${RED}Found: $ext_info in $vscode_name${NC}"
		read -p "Do you want to uninstall this extension? (y/n): " -n 1 -r
		echo ""

		if [[ $REPLY =~ ^[Yy]$ ]]; then
			uninstall_extension "$vscode_name" "$ext_info"
		else
			echo -e "${YELLOW}Skipped uninstallation${NC}"
		fi
		echo ""
	done
}

# Function to print summary
print_summary() {
	echo ""
	echo -e "${BLUE}========================================${NC}"
	echo -e "${BLUE}              Summary${NC}"
	echo -e "${BLUE}========================================${NC}"
	echo ""

	local num_installations=${#VSCODE_COMMANDS[@]}
	echo -e "VSCode installations found: ${BLUE}$num_installations${NC}"

	if [ $num_installations -gt 1 ]; then
		echo -e "${YELLOW}⚠ Multiple VSCode installations detected:${NC}"
		for vscode in "${VSCODE_COMMANDS[@]}"; do
			echo -e "  • ${vscode#*:}"
		done
		echo ""
	fi

	local num_infected=${#INFECTED_EXTENSIONS[@]}

	if [ $num_infected -eq 0 ]; then
		echo -e "${GREEN}✓ CLEAN: No infected extensions found!${NC}"
		echo -e "${GREEN}  Your system appears to be safe from Glassworm.${NC}"
		return 0
	else
		echo -e "${RED}✗ INFECTED: Found $num_infected malicious extension(s)!${NC}"
		echo ""
		echo -e "${RED}Infected extensions:${NC}"
		for infected in "${INFECTED_EXTENSIONS[@]}"; do
			local vscode_name="${infected%%:*}"
			local ext_info="${infected#*:}"
			echo -e "  • $ext_info ${YELLOW}(in $vscode_name)${NC}"
		done
		echo ""

		if [ $num_installations -gt 1 ]; then
			echo -e "${YELLOW}⚠ WARNING: You have multiple VSCode installations.${NC}"
			echo -e "${YELLOW}  Please ensure you check and clean ALL installations.${NC}"
			echo ""
		fi

		return 1
	fi
}

# Main execution
main() {
	print_header

	# Check for different VSCode installations
	check_vscode_installation "code" "Visual Studio Code"
	check_vscode_installation "code-insiders" "Visual Studio Code Insiders"
	check_vscode_installation "codium" "VSCodium"

	# Print summary and get status
	print_summary
	local status=$?

	# Offer to uninstall if infections found
	if [ ${#INFECTED_EXTENSIONS[@]} -gt 0 ]; then
		offer_uninstall

		echo ""
		echo -e "${YELLOW}========================================${NC}"
		echo -e "${YELLOW}      Recommended Next Steps${NC}"
		echo -e "${YELLOW}========================================${NC}"
		echo ""
		echo "1. Review your system for suspicious activity"
		echo "2. Change passwords for sensitive accounts"
		echo "3. Run a full system security scan"
		echo "4. Monitor for unusual network activity"
		echo "5. Check browser extensions and other applications"
		echo ""
	fi

	# Create log file
	local log_file="glassworm-scan-$(date +%Y%m%d-%H%M%S).log"
	{
		echo "Glassworm Scan Report"
		echo "Date: $(date)"
		echo "User: $(whoami)"
		echo ""
		echo "VSCode Installations Found: ${#VSCODE_COMMANDS[@]}"
		for vscode in "${VSCODE_COMMANDS[@]}"; do
			echo "  - ${vscode#*:}"
		done
		echo ""
		echo "Infected Extensions: ${#INFECTED_EXTENSIONS[@]}"
		for infected in "${INFECTED_EXTENSIONS[@]}"; do
			echo "  - $infected"
		done
	} > "$log_file"

	echo -e "${BLUE}Scan log saved to: $log_file${NC}"
	echo ""

	# Exit with appropriate code
	exit $status
}

# Run main function
main
