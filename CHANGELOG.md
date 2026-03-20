# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

- Release orchestration script (`hack/release.sh`) with version validation, tag creation, and GPG signing support
- `make release` target to automate the full release workflow
- TrustificationAuth integration subcommand for authentication workflows
- MCP workflow E2E test suite with JSON-RPC client for testing MCP server tools
- MCP instructions file support for providing runtime guidance to AI assistants
- Support for reading chart configuration from both relative and absolute paths

### Changed

- Replaced hardcoded "TSSC" references with dynamic application name resolution
- GitHub integration `token` parameter is now optional
- GoVulnCheck now filters stdlib/toolchain findings (configured via `hack/govulncheck.sh`)
- Go version pinned to 1.25.7 for hermetic builds
- Container image builds now use Podman by default (fallback to Docker)
- Pipeline webhook secret configuration added as deployment option

### Deprecated

_No deprecated features in this release._

### Removed

- Hook scripts feature removed from installer framework
- Production disclaimer messages removed from printer output

### Fixed

- GoVulnCheck filtering for stdlib/toolchain vulnerabilities that cannot be addressed independently
- Integration inspection logic now order-independent, preventing inconsistent resolution
- E2E tests updated to use KinD GitHub Action v1.13.0
- Integration PersistentPostRunE scoping now limited to active integration context
- MCP tool name prefix normalization applied at construction time

### Security

- Dependency vulnerability scanning automated via `make security` target
- Go toolchain pinned to 1.25.7 to ensure reproducible builds and controlled security updates

---

## Release History

_No releases yet. This project is in pre-release development._

<!--
Template for future releases:

## [X.Y.Z] - YYYY-MM-DD

### Added
- New features.

### Changed
- Changes to existing functionality.

### Deprecated
- Features marked for removal in upcoming releases.

### Removed
- Features removed in this release.

### Fixed
- Bug fixes.

### Security
- Security fixes and vulnerability patches.

[X.Y.Z]: https://github.com/redhat-appstudio/helmet/compare/vX.Y.Z-1...vX.Y.Z
-->

[Unreleased]: https://github.com/redhat-appstudio/helmet/commits/main
