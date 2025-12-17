# Changelog

All notable changes to the Tech Support Toolkit will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.1.0] - 2024-12-16

### Added
- **Master launcher** (`Start-TechSupport.ps1`) - Interactive menu to run any script
- **Shared module** (`modules/TechSupport.psm1`) - Common functions for all scripts
- **Configuration file** (`config/settings.json`) - Centralized settings
- **WinUtil integration** - Option 0 in fix-common.ps1 launches Chris Titus WinUtil
- **Service recovery** - SSH and Tailscale auto-restart on failure
- **Logging system** - All operations logged to Desktop
- **CLAUDE.md** - AI agent instructions for proper toolkit usage

### Changed
- Improved error handling across all scripts
- Better progress indicators and status messages
- More consistent output formatting
- Enhanced documentation with examples

### Fixed
- Chrome profile detection for newer Chrome versions
- Firewall rule creation idempotency
- Password generation character set

## [1.0.0] - 2024-12-16

### Added
- **Core Scripts**
  - `bootstrap.ps1` - Initial RustDesk setup for remote access
  - `setup.ps1` - Full Tailscale + SSH configuration
  - `verify.ps1` - Verify all components working

- **Diagnostic Scripts**
  - `diagnose.ps1` - Comprehensive system diagnostic
  - `google-audit.ps1` - Google account and Drive sync audit
  - `backup.ps1` - Backup user data before changes

- **Fix Scripts**
  - `browser-cleanup.ps1` - Clear cache, manage profiles
  - `fix-common.ps1` - Temp files, DNS, startup, Windows fixes
  - `install-tools.ps1` - Install utilities via winget

- **Remote Scripts**
  - `claude-code.ps1` - Install/login/logout Claude Code CLI

- **Documentation**
  - `README.md` - Main documentation
  - `docs/QUICKSTART.md` - Copy-paste instructions for family
  - `docs/GOOGLE-ACCOUNT-GUIDE.md` - Google account confusion guide
  - `docs/CHEATSHEET.md` - Quick command reference
  - `config/tools.json` - Configurable tool list

- **CI/CD**
  - GitHub Actions workflow for PSScriptAnalyzer linting
  - JSON validation

### Security
- SSH restricted to Tailscale IPs only (100.64.0.0/10)
- Dedicated admin user with randomized password
- Optional SSH key authentication
- All traffic encrypted via Tailscale

---

## Roadmap

### Planned for v1.2.0
- [ ] macOS support
- [ ] Linux support
- [ ] Scheduled health checks
- [ ] Email/SMS notifications
- [ ] Remote command queue
- [ ] Web dashboard

### Planned for v1.3.0
- [ ] Multi-machine management
- [ ] Automatic updates
- [ ] Backup to cloud (Google Drive, OneDrive)
- [ ] Integration with ticketing systems

---

## Contributing

1. Fork the repository
2. Create a feature branch
3. Run PSScriptAnalyzer on your changes
4. Submit a pull request

## License

MIT License - See [LICENSE](LICENSE) file
