# Release

Run the local preflight first:

```bash
export GITHUB_TOKEN="$(gh auth token)"
bash release-preflight.sh [vX.Y.Z]
```

Use the version printed by preflight:

```bash
VERSION=vX.Y.Z
```

Prepare the changelog and commit:

```bash
git-cliff --tag "$VERSION" -o CHANGELOG.md
git diff -- CHANGELOG.md
git add CHANGELOG.md
git commit -m "chore(release): prepare for $VERSION"
git show
```

Publish after reviewing the commit and notes:

```bash
git tag -a "$VERSION" -m "$VERSION"
git-cliff --current --strip header > release-notes.md
cat release-notes.md
git push origin main "$VERSION"
gh release create "$VERSION" --title "$VERSION" --notes-file release-notes.md
rm release-notes.md
```
