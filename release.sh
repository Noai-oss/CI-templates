#!/usr/bin/env bash
set -euo pipefail

remote="${REMOTE:-origin}"

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

require_cmd git
require_cmd git-cliff
require_cmd gh
require_cmd typos

github_token="${GITHUB_TOKEN:-${GH_TOKEN:-}}"
if [ -z "$github_token" ]; then
  github_token="$(gh auth token 2>/dev/null)" || \
    die "GITHUB_TOKEN/GH_TOKEN is not set and gh auth token failed; run gh auth login"
fi

unset GITHUB_TOKEN GH_TOKEN

git_cliff() {
  GITHUB_TOKEN="$github_token" git-cliff "$@"
}

gh_release() {
  GH_TOKEN="$github_token" gh release "$@"
}

if [ "$#" -gt 1 ]; then
  usage
  exit 2
fi

git fetch --tags --prune-tags "$remote"

if [ "$#" -eq 1 ]; then
  version="$1"
else
  version="$(git_cliff --bumped-version | tr -d '\r\n')"
fi

if [ -z "$version" ]; then
  die "version is empty"
fi

if [[ ! "$version" =~ ^v[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
  usage
  die "version must match vX.Y.Z, got: $version"
fi

if git rev-parse -q --verify "refs/tags/$version" >/dev/null; then
  die "tag already exists: $version"
fi

branch="$(git symbolic-ref --short HEAD 2>/dev/null || true)"
if [ -z "$branch" ]; then
  die "cannot push release commit from a detached HEAD"
fi

echo "Preparing ${version}..."
git_cliff --tag "$version" -o CHANGELOG.md

git add -A
git commit -m "chore(release): prepare for ${version}"

git show --stat HEAD

git tag -a "$version" -m "$version"

git push "$remote" "$branch"
git push "$remote" "$version"

release_notes_file="$(mktemp)"
trap 'rm -f "$release_notes_file"' EXIT

git_cliff --current --strip header >"$release_notes_file"
gh_release create "$version" --title "$version" --notes-file "$release_notes_file"
