# Activity 09 — Card Catalogue

Het Jani · Undergraduate · Local Storage, Part II

A Flutter catalogue with folders, cards, and the original Part I guest roster. Tap the people icon to open the guest roster. Folder and card changes use stable integer IDs. Every card belongs to one folder; deleting that folder cascades to its cards after a named confirmation.

## Setup

Test environment: Flutter 3.47.7 stable, Dart 3.13.5, macOS Apple Silicon. Android application ID remains `com.het1406.local_storage_lab` so an in-place update can preserve Part I data.

```sh
flutter pub get
flutter analyze
flutter test --reporter expanded
flutter run
flutter build apk --release
```

The release output is `build/app/outputs/flutter-apk/app-release.apk`. The classroom APK uses the existing development signing configuration; it is not a Play Store release. To upgrade an existing installation, retain its original signing key and install using `adb install -r`; never uninstall or clear storage.

## Database and migration

The documents-directory filename remains `MyDatabase.db`. Version 1 has `my_table(_id INTEGER PRIMARY KEY, name TEXT NOT NULL, age INTEGER NOT NULL)`. Its original helper is retained in `part1_reference/database_helper_v1.dart`.

Version 2 adds `folders`, `cards`, and `idx_cards_folder_id`. `onConfigure` enables foreign keys. `onUpgrade` adds only the catalogue schema when `oldVersion < 2`. `onCreate` creates the guest table plus the same catalogue schema. sqflite wraps these callbacks in a transaction; no nested transaction is needed. There is no automatic seeding, so opening the app cannot duplicate records.

Card titles and folder names must be nonblank. Suits are restricted to Spades, Hearts, Diamonds and Clubs. Names are unique for folders. SQL constraints supplement form/repository validation. A foreign key rejects nonexistent folder IDs. Updates/deletions that affect no record report failure. UI reads refresh independently after successful writes, so a failed refresh does not repeat the insert.

## Image references

`image_ref` is nullable text. The app supports HTTPS image URLs. Empty, malformed, unsupported or unavailable references show the suit symbol; that symbol also stays visible during loading. No image bytes are stored in SQLite. Network access is optional and all tests run without depending on a live image service. Local files/assets are deliberately not accepted as image sources by this implementation.

## Tests and evidence

See `evidence/test_output.txt`, `evidence/analysis_output.txt` and the device evidence for actual results. Automated tests use isolated temporary databases; they never erase the emulator's Part I database.

| Test | Expected | Automated observation | Status |
| --- | --- | --- | --- |
| T1 | Upgrade keeps every guest row; fresh and upgraded schemas match | Fictional guest IDs 7 and 12 retain all values; version 2, FK enabled, schema comparison passes | PASS (automated); device results recorded separately |
| T2 | Two cards under one folder, one under another, distinct IDs and correct counts | Folder IDs 1/2; card IDs 1/2/3; counts 2/1; queries remain scoped | PASS |
| T3 | Update one ID; cancel writes nothing | Card 1 title/notes updated; card 2 unchanged; widget test cancels edit of ID 11 with zero writes | PASS |
| T4 | Reopening preserves records, without duplicate seeds | Close/reopen same file yields identical ordered card rows | PASS for DB reopen; device force-stop result recorded separately |
| T5 | Cancel changes nothing; confirmation cascades only selected folder | Widget test cancels folder 8 with zero writes, then confirms one targeted deletion. SQLite test removes folder 1/cards 1 and 2; folder 2/card 3 survive | PASS |
| T6 | Invalid input writes nothing; missing/broken images fall back | Blank title, invalid suit, duplicate folder and nonexistent parent rejected; null/malformed/unavailable images render the suit | PASS |

The original emulator database was backed up before migration outside this repository. It contains three fictional rows: `(2, River, 35)`, `(3, Acorn, 0)`, `(4, Oak, 130)`. `evidence/T1_before.json` records these original values. Screenshot/device verification must be read with the device report; database reopen is not claimed as an Android force-stop test.

## Rubric map

| Criterion | Files/evidence |
| --- | --- |
| Schema and preservation | `lib/database_helper.dart`, `part1_reference/`, T1 |
| Models, repository and CRUD | `lib/catalogue_repository.dart`, `lib/catalogue_screen.dart`, T2–T5 |
| Images and usability | `CardImage`, shared `CardForm`, widget tests, T6 |
| Tests and evidence | `test/`, `evidence/` |
| Written work | Separate `Jani_Het_CriticalThinking.docx` submission |
| Reproducibility | This README, `pubspec.yaml`, `pubspec.lock`, platform folders |

## Sources and delivery limitations

Extended the existing Part I project, `het1406/local-storage-lab-08`. The pasted Activity 09 lecture companion supplied the schema and requirements. Official U1–U4 question text was not included in that lecture and is still needed to finish the required reflection lab. The DOCX is kept outside the public repository because it includes a student ID. Assistance details are recorded in its required disclosure.

References: [Flutter installation](https://docs.flutter.dev/install/manual), [sqflite package documentation](https://pub.dev/packages/sqflite). Flutter's Material icons are provided through the SDK. No external image assets are bundled.

The instructor's official assignment takes precedence over the lecture companion. iCollege upload and receipt verification must be completed separately; local files or GitHub publication do not constitute an iCollege submission.
