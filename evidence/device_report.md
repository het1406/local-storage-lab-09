# Device verification — October 8, 2026

Target: Pixel_4a AVD, Android API 37, package `com.het1406.local_storage_lab`.

- Before upgrade, the actual version-1 database was copied to a private backup outside the repository. It had IDs 2 (River, 35), 3 (Acorn, 0), and 4 (Oak, 130).
- `T1_before.png` is the existing Part I project's `evidence/T6_final.png`, recorded October 6. It depicts exactly those three guest rows. This is historical pre-upgrade evidence, not a newly captured October 8 screenshot. Today's original values are independently recorded in `T1_before.json`.
- Today's pre-upgrade screenshot attempts encountered Android system/app-not-responding dialogs. The historical screenshot is included with its provenance instead of presenting a blocked screen as successful verification.
- The exact `Activity09_Jani_Het.apk` was installed with `adb install -r`; the command returned `Success`. No uninstall or data clearing occurred.
- Launching that release upgraded the actual file to version 2. `T1_after.json` records identical guest rows and the new folders/cards tables. T1 device preservation: PASS.
- `release_initial.png` shows the installed release app opening normally with zero folders and its intended empty state.
- Full folder/card UI walkthrough and force-stop persistence screenshots are pending. The initial walkthrough was interrupted and the emulator later refused to start because the host disk was full. Automated database reopen is separately tested and is not being presented as a completed device force-stop test.

The SHA-256 of the exact submission APK is recorded in `apk_sha256.txt`.
