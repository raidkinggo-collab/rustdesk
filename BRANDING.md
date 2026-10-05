# RionsDesk — rebrand of RustDesk client

Fork of `rustdesk/rustdesk`. Baked-in server, key, name. Consent-based remote
support client (visible UI, password/pairing) — same behavior as upstream,
just branded and pre-pointed at `rd.rions.nl`.

## Done (committed edits)

`libs/hbb_common/src/config.rs`:
- `APP_NAME` default → `RionsDesk` (drives window title, tray tooltip, config dir, log dir)
- `RENDEZVOUS_SERVERS` → `["rd.rions.nl"]`
- `RS_PUB_KEY` → `s3TBUoXzMAwdgoqSrSElykO1p5Pwv6Y50hHdegOYaG8=`

API server auto-derives: rendezvous port `21116` minus 2 = `http://rd.rions.nl:21114`.
No separate api-server edit needed. Users need zero manual config.

## Done — icons (generated from RIONS square logo via PIL)

| File | Set |
|---|---|
| `res/icon.ico` `res/icon.png` | ✅ app icon + 512 png |
| `res/tray-icon.ico` | ✅ tray |
| `res/32x32..128x128@2x.png` | ✅ Linux sizes |
| `res/mac-icon.png` | ✅ 1024 mac |
| `flutter/windows/runner/resources/app_icon.ico` | ✅ Windows exe icon |
| `flutter/android/.../mipmap-*/ic_launcher*.png` | ✅ Android densities |

Source 810x796 → ~2% stretch to square. Negligible. Re-pad to square first if
you want pixel-perfect. Regenerate anytime: `res/gen_icon.sh` or the PIL snippet.

## Installer / binary naming

- Install output file → `RionsDesk-<version>-install.exe` (`build.py`). ✅
- Internal binary stays `rustdesk.exe` (BINARY_NAME in
  `flutter/windows/CMakeLists.txt`). Deliberate: service install, portable
  packer, registry keys all hardcode `rustdesk.exe`. Renaming cascades into
  runtime failures for zero user-visible gain — APP_NAME already brands all UI.
  <!-- ponytail: internal exe name left as rustdesk; rename only if you also fix service+packer+registry refs -->
- MSI product string (sciter path only, unused by flutter build): pass
  `--app-name RionsDesk` to `res/msi/preprocess.py` if you ever build MSI.

## Build — lazy path (no local toolchain)

1. Push this fork to your GitHub (`rions/rionsdesk` or similar).
2. Enable Actions on the fork.
3. Push a tag:
   ```bash
   git tag 1.0.0 && git push origin 1.0.0
   ```
4. `.github/workflows/flutter-tag.yml` builds Windows/Linux/mac installers on GitHub runners.
5. Download installers from the Actions run artifacts / release.

Signed `custom.txt` client config is Pro-only (needs RustDesk's private key) —
irrelevant here, you bake defaults at compile time instead.

## Build — local (heavy, only if you must)

Needs: Rust, Flutter, vcpkg, LLVM, Python 3, VS Build Tools (Windows).
`python build.py --flutter`. First setup = hours. Prefer the Actions path.

## Deploy to users

Ship the built installer. Client auto-connects to `rd.rions.nl`, auth against
accounts you make in the web portal (`http://rd.rions.nl:21114/_admin/`).
