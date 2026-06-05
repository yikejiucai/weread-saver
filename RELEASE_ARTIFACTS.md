# GitHub Release Artifacts

When you upload the files below to a GitHub Release, each file appears as a clickable download asset on the release page. Put the `.dmg` first so it is the primary download option.

For version `0.1.1`, publish these files from `.build/release/`:

| File | Purpose |
|---|---|
| `WeReadScreenSaver-0.1.1-universal.zip` | Direct install archive containing the `.saver` bundle |
| `WeReadScreenSaver-0.1.1-universal.dmg` | Disk image installer with the bundle and install note |
| `WeReadScreenSaver-0.1.1-universal.sha256` | SHA-256 checksums for both distributable assets |

Recommended release body:

```md
## WeReadScreenSaver 0.1.1

### Download
- `WeReadScreenSaver-0.1.1-universal.dmg`
- `WeReadScreenSaver-0.1.1-universal.zip`

### Verify
- Compare SHA-256 hashes against `WeReadScreenSaver-0.1.1-universal.sha256`

### Install
1. Open the `.dmg` or unzip the archive.
2. Copy `WeReadScreenSaver.saver` to `~/Library/Screen Savers`
3. Open System Settings and select the screen saver.
```
