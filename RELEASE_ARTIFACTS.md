# GitHub Release Artifacts

For version `0.1.0`, publish these files from `.build/release/`:

| File | Purpose |
|---|---|
| `WeReadScreenSaver-0.1.0-arm64.zip` | Direct install archive containing the `.saver` bundle |
| `WeReadScreenSaver-0.1.0-arm64.dmg` | Disk image installer with the bundle and install note |
| `WeReadScreenSaver-0.1.0-arm64.sha256` | SHA-256 checksums for both distributable assets |

Recommended release body:

```md
## WeReadScreenSaver 0.1.0

### Download
- `WeReadScreenSaver-0.1.0-arm64.dmg`
- `WeReadScreenSaver-0.1.0-arm64.zip`

### Verify
- Compare SHA-256 hashes against `WeReadScreenSaver-0.1.0-arm64.sha256`

### Install
1. Open the `.dmg` or unzip the archive.
2. Copy `WeReadScreenSaver.saver` to `~/Library/Screen Savers`
3. Open System Settings and select the screen saver.
```
