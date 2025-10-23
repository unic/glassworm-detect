# Glassworm Extension Detection Tool

A bash script to detect and remove malicious VSCode extensions affected by the **Glassworm** supply chain attack (October 2025).

## What is Glassworm?

Glassworm is a supply chain attack that compromised multiple VSCode extensions on both the OpenVSX and Microsoft VSCode marketplaces. The malicious versions of these extensions contained code that could:

- Execute arbitrary commands on the host system
- Steal sensitive data including credentials
- Establish persistent backdoors
- Exfiltrate source code and project files

## Affected Extensions

This tool checks for the following malicious extensions and their compromised versions, according to [https://www.koi.ai/blog/glassworm-first-self-propagating-worm-using-invisible-code-hits-openvsx-marketplace](https://www.koi.ai/blog/glassworm-first-self-propagating-worm-using-invisible-code-hits-openvsx-marketplace)

### OpenVSX Extensions

- `codejoy.codejoy-vscode-extension` @ 1.8.3, 1.8.4
- `l-igh-t.vscode-theme-seti-folder` @ 1.2.3
- `kleinesfilmroellchen.serenity-dsl-syntaxhighlight` @ 0.3.2
- `JScearcy.rust-doc-viewer` @ 4.2.1
- `SIRILMP.dark-theme-sm` @ 3.11.4
- `CodeInKlingon.git-worktree-menu` @ 1.0.9, 1.0.91
- `ginfuru.better-nunjucks` @ 0.3.2
- `ellacrity.recoil` @ 0.7.4
- `grrrck.positron-plus-1-e` @ 0.0.71
- `jeronimoekerdt.color-picker-universal` @ 2.8.91
- `srcery-colors.srcery-colors` @ 0.3.9
- `sissel.shopify-liquid` @ 4.0.1
- `TretinV3.forts-api-extention` @ 0.3.1

### Microsoft VSCode Extensions

- `cline-ai-main.cline-ai-agent` @ 3.1.3

## Requirements

- **Bash 4.0+** (the script uses associative arrays)
- **macOS/Linux** operating system
- VSCode, VSCode Insiders, or VSCodium installed (optional - script will check all)

### Checking Your Bash Version

```bash
bash --version
```

On macOS, the default `/bin/bash` is version 3.2. If you need to upgrade:

```bash
# Install via Homebrew
brew install bash

# Verify installation
/usr/local/bin/bash --version
```

The script uses `#!/usr/bin/env bash` to automatically use the newer version if available.

## Usage

### Basic Usage

1. **Clone the repository**:

   ```bash
   git clone https://github.com/unic/glassworm-detect
   ```

2. **Make the script executable** (if not already):

   ```bash
   chmod +x glassworm-detect.sh
   ```

3. **Run the script**:

   ```bash
   ./glassworm-detect.sh
   ```

4. **Follow the prompts** - if infected extensions are found, you'll be asked whether to uninstall them.

### What the Script Does

The script will:

1. ✅ **Scan all VSCode installations** on your system:

   - Visual Studio Code (`code`)
   - Visual Studio Code Insiders (`code-insiders`)
   - VSCodium (`codium`)

2. 🔍 **Check all installed extensions** against the known malicious list

3. 📊 **Report findings** with color-coded output:

   - 🟢 Green = Clean/Safe
   - 🟡 Yellow = Warnings
   - 🔴 Red = Infected extensions found

4. 🗑️ **Offer to uninstall** any infected extensions (with confirmation)

5. 📝 **Generate a log file** with scan results (timestamped)

### Exit Codes

The script returns meaningful exit codes for automation:

- `0` - Clean system, no infections found
- `1` - Infected extensions detected

This allows you to use it in scripts:

```bash
if ./glassworm-detect.sh; then
    echo "System is clean"
else
    echo "Infections found - please review"
fi
```

## How It Works

### Detection Process

1. **Discovery Phase**

   - Checks for available VSCode installations using `command -v`
   - Stores found installations for reporting

2. **Scanning Phase**

   - For each VSCode installation, runs: `code --list-extensions --show-versions`
   - Parses the output to extract extension IDs and version numbers
   - Compares each installed extension against the malicious extensions database

3. **Matching Phase**

   - Checks both the extension ID (publisher.name) and specific version number
   - Only flags extensions that match BOTH the ID and a known malicious version
   - Safe versions of the same extension are not flagged

4. **Reporting Phase**

   - Displays all findings with clear visual indicators
   - Warns if multiple VSCode installations are present
   - Creates a timestamped log file for auditing

5. **Remediation Phase** (optional)
   - Prompts user for each infected extension
   - Executes `code --uninstall-extension <id>` for confirmed removals
   - Reports success/failure of each uninstall operation

### Log Files

Each scan creates a log file named: `glassworm-scan-YYYYMMDD-HHMMSS.log`

The log contains:

- Scan timestamp
- User who ran the scan
- VSCode installations found
- List of infected extensions (if any)

## Example Output

### Clean System

```text
========================================
   Glassworm Extension Detection Tool
========================================

Checking Visual Studio Code...
  ✓ No infected extensions found

Checking Visual Studio Code Insiders...
  ⚠ Visual Studio Code Insiders not found

Checking VSCodium...
  ⚠ VSCodium not found

========================================
              Summary
========================================

VSCode installations found: 1
✓ CLEAN: No infected extensions found!
  Your system appears to be safe from Glassworm.

Scan log saved to: glassworm-scan-20251023-143052.log
```

### Infected System

```text
========================================
   Glassworm Extension Detection Tool
========================================

Checking Visual Studio Code...
  ✗ INFECTED: cline-ai-main.cline-ai-agent@3.1.3

========================================
              Summary
========================================

VSCode installations found: 1
✗ INFECTED: Found 1 malicious extension(s)!

Infected extensions:
  • cline-ai-main.cline-ai-agent@3.1.3 (in Visual Studio Code)

========================================
        Uninstall Infected Extensions
========================================

Found: cline-ai-main.cline-ai-agent@3.1.3 in Visual Studio Code
Do you want to uninstall this extension? (y/n): y
Uninstalling cline-ai-main.cline-ai-agent@3.1.3 from Visual Studio Code...
✓ Successfully uninstalled cline-ai-main.cline-ai-agent

========================================
      Recommended Next Steps
========================================

1. Review your system for suspicious activity
2. Change passwords for sensitive accounts
3. Run a full system security scan
4. Monitor for unusual network activity
5. Check browser extensions and other applications

Scan log saved to: glassworm-scan-20251023-143127.log
```

## Security Recommendations

If the script detects infected extensions, you should:

### Immediate Actions

1. ✅ **Uninstall all infected extensions** (script offers to do this)
2. 🔐 **Change passwords** for:
   - GitHub/GitLab accounts
   - Cloud service providers (AWS, Azure, GCP)
   - Email accounts
   - Any credentials stored in your projects
3. 🔄 **Rotate API keys and tokens**
4. 🔍 **Review recent activity** in your repositories and cloud accounts

### Follow-Up Actions

1. 🛡️ **Run security scans**:
   - Full system antivirus scan
   - Rootkit detection tools
   - Network traffic monitoring
2. 📊 **Check logs** for:
   - Unauthorized access attempts
   - Unusual file modifications
   - Suspicious network connections
3. 🔔 **Enable 2FA** on all critical accounts if not already enabled
4. 💾 **Review backups** - ensure they're not compromised
5. 👥 **Inform your team** if working in a shared environment

## Limitations

- **Version-specific detection**: Only flags the exact malicious versions listed
- **User scope only**: Checks extensions for the current user only
- **Installed versions only**: Cannot detect extensions that were installed and removed
- **System extensions**: May not detect system-wide installed extensions
- **Manual installation**: Cannot detect manually installed extensions (not via marketplace)

## Contributing

If you discover additional compromised extensions or versions, please update the `MALICIOUS_EXTENSIONS` associative array in the script:

```bash
MALICIOUS_EXTENSIONS["publisher.extension-name"]="version1 version2"
```

## License

This script is provided as-is for security purposes. Feel free to use, modify, and distribute.

## References

- [Glassworm Attack Information](<[#](https://www.koi.ai/blog/glassworm-first-self-propagating-worm-using-invisible-code-hits-openvsx-marketplace)>)
- [VSCode Security Best Practices](https://code.visualstudio.com/docs/editor/extension-marketplace#_extension-security)
- [OpenVSX Registry](https://open-vsx.org/)

## Disclaimer

This tool is provided for detection and remediation purposes only. While it checks for known malicious extensions, it cannot guarantee complete protection or detect all potential threats. Always follow security best practices and consult with security professionals if you suspect your system has been compromised.

---

**Last Updated**: October 23, 2025
**Script Version**: 1.0.0
