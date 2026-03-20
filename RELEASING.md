# Release Process

This document describes the release process for the Helmet framework library. Releases are coordinated using git tags and automated via GitHub Actions.

## Version Guidelines

Helmet follows [Semantic Versioning 2.0.0](https://semver.org/) with specific policies for each development phase.

### Version Format

All versions **must** follow the pattern:

```
v<major>.<minor>.<patch>[-<prerelease>]
```

**Valid examples:**
- `v0.1.0`
- `v1.2.3`
- `v0.1.0-beta.1`
- `v1.0.0-rc.2`

**Invalid examples:**
- `0.1.0` (missing `v` prefix)
- `v1.2` (missing patch version)
- `v1.0.0beta1` (missing `-` separator)

### Phase 1: Beta Releases (v0.x.y)

During this phase, breaking changes are permitted between minor versions. This is a project policy — Go modules do not enforce stability guarantees for v0.x versions, but consumers should expect instability:

| Version | Stability | Breaking Changes |
|---------|-----------|------------------|
| `v0.1.0-beta.1` | Unstable | Allowed |
| `v0.1.0` | Unstable | Allowed |
| `v0.2.0` | Unstable | Allowed |

**Semantic Versioning during v0.x:**
- **Major**: Always `0` (pre-stable)
- **Minor**: Incremented for any changes (features, breaking changes)
- **Patch**: Bug fixes only

### Phase 2: Release Candidates (v1.0.0-rc.x)

Pre-release versions for final validation before stable:

| Version | Purpose |
|---------|---------|
| `v1.0.0-rc.1` | Feature freeze, testing |
| `v1.0.0-rc.2` | Bug fixes from rc.1 feedback |

### Phase 3: Stable Releases (v1.x.y+)

After `v1.0.0`, semantic versioning is strictly followed:

| Change Type | Version Bump |
|-------------|--------------|
| Bug fixes | Patch (`1.0.x`) |
| New features (backward compatible) | Minor (`1.x.0`) |
| Breaking changes | Major (`x.0.0`) |

## Pre-Release Checklist

Before cutting a release, complete the following tasks:

### 1. Code Quality

- [ ] All CI checks passing on `main` branch
- [ ] `make lint` passes locally with no warnings
- [ ] `make test-unit` passes with >80% coverage for `framework/`, `api/`, `internal/resolver`
- [ ] `make security` passes (no unresolved vulnerabilities)
- [ ] `make verify-mod` confirms `go.mod`/`go.sum` are clean

### 2. E2E Validation

- [ ] `make test-e2e-cli` passes against KinD cluster
- [ ] `make test-e2e-mcp` passes against KinD cluster with pushed image
- [ ] Example application (`helmet-ex`) deploys successfully

### 3. Documentation

- [ ] `README.md` reflects current API surface
- [ ] All `docs/*.md` pages updated for new features or behavior changes
- [ ] `CLAUDE.md` updated if build targets, API types, or framework patterns changed
- [ ] `AGENTS.md` updated if agent-relevant context changed (see PR checklist in `CONTRIBUTING.md`)

### 4. Dependencies

- [ ] `go mod tidy -v` executed
- [ ] `go mod vendor` re-run if dependencies changed
- [ ] No pending security advisories for dependencies

### 5. Release Notes Preparation

While GitHub can auto-generate release notes, consider preparing a summary that highlights:

- **Breaking changes** (especially for v0.x.x releases)
- **New features** with links to documentation
- **Bug fixes** with issue references
- **Deprecation notices** for upcoming removals
- **Migration guide** if API changes require consumer updates

## Release Process

### Automated Release (Recommended)

Use the `make release` target to orchestrate the entire process:

```bash
# Example: Release v0.1.0-beta.1
make release GITHUB_REF_NAME=v0.1.0-beta.1
```

This target:
1. Builds the example application
2. Runs unit tests
3. Runs linting
4. Verifies module integrity
5. Executes `hack/release.sh` to create and push the git tag
6. Creates GitHub release with auto-generated notes

**Prerequisites:**
- `GITHUB_TOKEN` environment variable set with appropriate permissions
- Clean working tree on `main` branch, synced with `origin/main`

### Manual Release

For granular control or troubleshooting, use the underlying scripts directly.

#### Step 1: Create and Push Tag

```bash
# Standard annotated tag
./hack/release.sh v0.1.0-beta.1

# GPG-signed tag (recommended for production releases)
./hack/release.sh -s v0.1.0-beta.1
```

The script performs these validations:
- Version format matches `v<major>.<minor>.<patch>[-<prerelease>]`
- Current branch is `main`
- Local `main` is in sync with `origin/main`
- Working tree has no uncommitted changes
- Tag doesn't already exist (local or remote)

On success, the tag is created locally and pushed to `origin`.

#### Step 2: Create GitHub Release

```bash
# Requires 'gh' CLI and GITHUB_TOKEN
make github-release-create GITHUB_REF_NAME=v0.1.0-beta.1
```

This creates a GitHub release with auto-generated release notes based on merged PRs since the previous tag.

#### Step 3: Verify Release Artifacts (CI)

After pushing the tag, GitHub Actions automatically:
- Runs full test suite (unit + E2E)
- Builds release binaries via `goreleaser` (if configured)
- Publishes release artifacts to the GitHub release

Monitor the workflow at: `https://github.com/redhat-appstudio/helmet/actions`

### Post-Release Tasks

- [ ] Verify release appears at `https://github.com/redhat-appstudio/helmet/releases`
- [ ] Confirm release notes are accurate and complete
- [ ] Test library import as a consumer: `go get github.com/redhat-appstudio/helmet@v0.1.0-beta.1`
- [ ] Update downstream consumers' documentation with new version
- [ ] Announce release (if applicable) to relevant channels

## Troubleshooting

### Tag Already Exists

**Symptom:**
```
Tag 'v0.1.0-beta.1' already exists locally
```

**Resolution:**

If the tag was created incorrectly and **not yet pushed**:

```bash
# Delete local tag
git tag -d v0.1.0-beta.1

# Re-run release script
./hack/release.sh v0.1.0-beta.1
```

If the tag was already pushed to remote:

```bash
# Verify the tag on remote
git ls-remote --tags origin | grep v0.1.0-beta.1

# If incorrect, delete from remote (DANGEROUS - coordinate with team)
git push origin :refs/tags/v0.1.0-beta.1

# Delete local tag
git tag -d v0.1.0-beta.1

# Re-run release script
./hack/release.sh v0.1.0-beta.1
```

**Caution:** Deleting published tags can break existing consumers using `go get`. Only delete tags that were pushed in error within minutes of creation.

### Failed Tag Push

**Symptom:**
```
Failed to push tag to remote
Tag created locally. You can push manually:
   git push origin v0.1.0-beta.1
Or cleanup:
   git tag -d v0.1.0-beta.1
```

**Common Causes:**
1. Network connectivity issues
2. Insufficient GitHub permissions
3. Protected tag rules in repository settings

**Resolution:**

Retry the push manually:

```bash
git push origin v0.1.0-beta.1
```

If push continues to fail, check repository permissions and tag protection rules.

### Local/Remote Branch Out of Sync

**Symptom:**
```
Local main branch is not in sync with origin/main
Local:  abc123
Remote: def456
Run 'git pull' or 'git push' to synchronize
```

**Resolution:**

If remote is ahead (you need to pull):

```bash
git pull origin main --ff-only
./hack/release.sh v0.1.0-beta.1
```

If local is ahead (you need to push):

```bash
git push origin main
./hack/release.sh v0.1.0-beta.1
```

If branches have diverged (rare):

```bash
# Review the divergence
git log main..origin/main
git log origin/main..main

# Rebase or merge as appropriate
git pull --rebase origin main

# Re-run release
./hack/release.sh v0.1.0-beta.1
```

### Uncommitted Changes

**Symptom:**
```
Working tree has uncommitted changes. Commit or stash them first.
```

**Resolution:**

Review the changes:

```bash
git status
git diff
```

Either commit the changes:

```bash
git add .
git commit -m "chore: prepare for v0.1.0-beta.1 release"
git push origin main
./hack/release.sh v0.1.0-beta.1
```

Or stash them (if unrelated to the release):

```bash
git stash
./hack/release.sh v0.1.0-beta.1
git stash pop
```

### GitHub Release Creation Fails

**Symptom:**
```
Error: GitHub token not found or insufficient permissions
```

**Resolution:**

1. Verify `GITHUB_TOKEN` is set:
   ```bash
   echo $GITHUB_TOKEN
   ```

2. Ensure token has `repo` scope (required for creating releases)

3. Authenticate `gh` CLI:
   ```bash
   gh auth status
   gh auth login
   ```

4. Retry release creation:
   ```bash
   make github-release-create GITHUB_REF_NAME=v0.1.0-beta.1
   ```

### GoReleaser Errors (CI)

**Symptom:** GitHub Actions workflow fails during `goreleaser release` step

**Common Causes:**
1. `.goreleaser.yaml` configuration errors
2. Missing build dependencies
3. Insufficient disk space in CI

**Resolution:**

1. Test GoReleaser locally in snapshot mode:
   ```bash
   make goreleaser-snapshot
   ```

2. Review `.goreleaser.yaml` for syntax errors

3. Check GitHub Actions logs for specific error messages

4. If GoReleaser is not configured or needed, consider removing the step from CI workflows

## Advanced: Signing Releases

### GPG-Signed Tags

For production releases (`v1.x.x`), use GPG-signed tags to verify authenticity:

```bash
# Ensure GPG key is configured
git config --global user.signingkey <your-key-id>

# Create signed tag
./hack/release.sh -s v1.0.0
```

Consumers can verify the signature:

```bash
git tag -v v1.0.0
```

### Signed Commits

While not enforced by the release script, consider signing release-related commits:

```bash
git commit -S -m "chore: prepare v1.0.0 release"
```

## Reference

- [Semantic Versioning Specification](https://semver.org/)
- [GitHub CLI Documentation](https://cli.github.com/manual/)
- [GoReleaser Documentation](https://goreleaser.com/)
- [Contributing Guide](../CONTRIBUTING.md)
- [Makefile Targets](../Makefile)
