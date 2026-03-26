#!/usr/bin/env bash
# Release orchestration script for helmet framework
# Usage: ./hack/release.sh [-s] <version>
# Example: ./hack/release.sh v0.1.0-beta.1
# Example: ./hack/release.sh -s v0.1.0-beta.1  (GPG-signed)

set -o errexit
set -o nounset
set -o pipefail


# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

usage() {
    echo "
Usage:
    ${0##*/} [-s] <version>

Optional arguments:
    -s
        Create GPG signed tag.
    -h, --help
        Display this message.

Example:
    ${0##*/} v0.1.0-beta.1
    ${0##*/} -s v0.1.0-beta.1
" >&2
}

# Parse arguments
parse_args() {
    SIGN_TAG=false
  
    while [[ $# -gt 0 ]]; do
        case $1 in
        -s)
            SIGN_TAG=true
            shift
            ;;
        -h | --help)
            usage
            exit 0
            ;;
        -*)
            echo "[ERROR] Unknown argument: $1"
            usage
            exit 1
            ;;
        *)
            VERSION="$1"
            shift
            ;;
        esac
    done
}

# Validate version is provided
validate_version() {
    if [ -z "${VERSION:-}" ]; then
        echo "Version must be provided."
        exit 1
    fi
    
}

# Validate version format (must start with 'v')
validate_version_format() {
    if [[ ! "${VERSION}" =~ ^v[0-9]+\.[0-9]+\.[0-9]+(-.*)?$ ]]; then
        echo "Invalid version format: '${VERSION}'"
        echo "Version must match pattern: v<major>.<minor>.<patch>[-<prerelease>]"
        echo "Examples: v0.1.0, v1.2.3, v0.1.0-beta.1, v1.0.0-rc.2"
        exit 1
    fi

    echo "Release version: ${VERSION}"
}

# Change to project root
init() {
    cd "$PROJECT_ROOT"
}

branch_status() {
    # Check if we're in a git repository
    if [ ! -d .git ]; then
        echo "Not in a git repository"
        exit 2
    fi

    # Ensure we're on main branch
    CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD)
    if [ "${CURRENT_BRANCH}" != "main" ]; then
        echo "Releases must be created from 'main' branch (current: '${CURRENT_BRANCH}')"
        exit 2
    fi

    # Verify local main is in sync with origin/main
    if ! git fetch origin main; then
        echo "Failed to fetch from origin"
        exit 2
    fi

    LOCAL_HASH=$(git rev-parse HEAD)
    REMOTE_HASH=$(git rev-parse origin/main)

    if [ "${LOCAL_HASH}" != "${REMOTE_HASH}" ]; then
        echo "Local main branch is not in sync with origin/main"
        echo "Local:  ${LOCAL_HASH}"
        echo "Remote: ${REMOTE_HASH}"
        echo "Run 'git pull' or 'git push' to synchronize"
        exit 2
    fi

    # Check for uncommitted changes
    if ! git diff-index --quiet HEAD --; then
        echo "Working tree has uncommitted changes. Commit or stash them first."
        exit 2
    fi
}

verify_tag() {
    # Verify tag doesn't already exist (local and remote)
    if git rev-parse "${VERSION}" >/dev/null 2>&1; then
        echo "Tag '${VERSION}' already exists locally"
        exit 2
    fi
    if git ls-remote --tags origin | grep -q "refs/tags/${VERSION}$"; then
        echo "Tag '${VERSION}' already exists on remote"
        exit 2
    fi
}

# Create annotated tag
create_release_tag() {
    if [ "${SIGN_TAG}" = true ]; then
        git tag -s "${VERSION}" -m "Release ${VERSION}"
        echo "GPG-signed tag '${VERSION}' created"
    else
        git tag -a "${VERSION}" -m "Release ${VERSION}"
        echo "Tag '${VERSION}' created"
    fi
}

# Push tag
push_tag() {
    if ! git push origin "${VERSION}"; then
        echo "Failed to push tag to remote"
        echo "Tag created locally. You can Push manually:"
        echo "   git push origin ${VERSION}"
        echo "Or cleanup:"
        echo "   git tag -d ${VERSION}"
        exit 1
    fi
    echo "Tag '${VERSION}' pushed to remote"
}

# Success message
success() {
    echo
    echo "Release ${VERSION} created successfully!"
    echo
    echo "Next steps:"
    echo "  1. Monitor CI pipeline for release build"
    echo "  2. Review automatically generated release notes"
    echo "  3. If using goreleaser, it should run automatically on tag push"
    echo "  4. Verify release artifacts are published correctly"
    echo
    echo "To create GitHub release manually:"
    echo "  make github-release-create GITHUB_REF_NAME=${VERSION}"
    exit 0
}
validation() {
    validate_version
    validate_version_format
}

pre_release_checks() {
    branch_status
    verify_tag
}

release() {
    create_release_tag
    push_tag
}

main() {
    parse_args "$@"
    validation
    init
    pre_release_checks
    release
    success
}

if [ "${BASH_SOURCE[0]}" == "$0" ]; then
    main "$@"
fi
