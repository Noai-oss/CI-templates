#!/usr/bin/env bash
set -euo pipefail

usage() {
  echo "Usage: $0 [vX.Y.Z]" >&2
}

die() {
  echo "error: $*" >&2
  exit 1
}

require_cmd() {
  command -v "$1" >/dev/null 2>&1 || die "$1 is required but was not found"
}

if [ "$#" -gt 1 ]; then
  usage
  exit 2
fi

require_cmd git
require_cmd git-cliff
require_cmd gh
require_cmd typos

if [ -z "${GITHUB_TOKEN:-}" ]; then
  die "GITHUB_TOKEN is not set; run: export GITHUB_TOKEN=\"\$(gh auth token)\""
fi

git fetch --tags origin

version="${1:-}"
if [ -z "$version" ]; then
  version="$(git-cliff --bumped-version | tr -d '\r\n')"
fi

if [[ ! "$version" =~ ^v[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
  usage
  die "version must match vX.Y.Z, got: $version"
fi

if git rev-parse -q --verify "refs/tags/$version" >/dev/null; then
  die "tag already exists: $version"
fi

branch="$(git branch --show-current --no-color)"
if [ "$branch" != "main" ]; then
  die "release preflight must run from main branch, current branch is ${branch:-detached HEAD}"
fi

if [ -n "$(git status --porcelain)" ]; then
  die "working directory has uncommitted changes"
fi

cat <<EOF
Release preflight passed.

Version: ${version}

Next commands are documented in RELEASE.md.
EOF
