# Device verification — October 8, 2026

Target: Pixel_4a AVD, Android API 37, package `com.het1406.local_storage_lab`.

- Before upgrade, the actual version-1 database was copied to a private backup outside the repository. It had IDs 2 (River, 35), 3 (Acorn, 0), and 4 (Oak, 130).
- `T1_before.png` is the existing Part I project's `evidence/T6_final.png`, recorded October 6. It depicts exactly those three guest rows. This is historical pre-upgrade evidence, not a newly captured October 8 screenshot. Today's original values are independently recorded in `T1_before.json`.
- Today's pre-upgrade screenshot attempts encountered Android system/app-not-responding dialogs. The historical screenshot is included with its provenance instead of presenting a blocked screen as successful verification.
- The exact `Activity09_Jani_Het.apk` was installed with `adb install -r`; the command returned `Success`. No uninstall or data clearing occurred.
- Launching that release upgraded the actual file to version 2. `T1_after.json` records identical guest rows and the new folders/cards tables. T1 device preservation: PASS.
- `release_initial.png` shows the installed release app opening normally with zero folders and its intended empty state.
- After freeing rebuildable Gradle cache space, the emulator restarted successfully. Through the release UI, Study (folder 1) received Ace (card 1) and King (card 2); Archive (folder 2) received Queen (card 3). All have nullable image references and visible suit fallbacks. T2 device create/counts: PASS. Screenshots: `T2_cards.png`, `T2_folders.png`.
- The app was force-stopped with `adb shell am force-stop com.het1406.local_storage_lab` and relaunched with `am start`. All guest, folder and card rows were compared before/after: identical. No new seed records appeared. T4 device persistence: PASS. Screenshot: `T4_after.png`; full comparison: `T4_restart.json`.
- `T1_after.png` shows the preserved guest roster opened from the release app.
- T3 edit/cancel, T5 confirmed/cancelled deletion and T6 invalid/broken-image paths are verified by the automated repository/widget suite, not claimed as separate manual device walkthroughs. The actual release was smoke-tested for upgrade, launch, navigation, folder/card creation, missing-image fallback, and cold restart.
- The initial Android unresponsive dialogs and later host disk exhaustion were environmental limitations encountered during setup. No destructive database recovery was used.

The SHA-256 of the exact submission APK is recorded in `apk_sha256.txt`.
