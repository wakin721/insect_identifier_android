# Validation status

Validation date: 2026-07-27

## Completed in the delivery environment

- Confirmed `models/best.pt` SHA-256: `c8721348aba1c541d124c0cd2b1fc7f89fe4ac5ddb4fbc18bf4132328c6f8e63`.
- Confirmed the bundled taxonomy contains 19 contiguous classes in the checkpoint label order.
- Parsed all JSON and Android XML files successfully.
- Parsed `pubspec.yaml`, `analysis_options.yaml`, `.metadata`, and the GitHub Actions workflow as YAML.
- Checked all relative Dart imports, required Flutter assets, Android package paths, launcher-icon PNG headers and dimensions.
- Compiled the Python validation and model-export scripts with Python 3.13.
- Checked every GitHub Actions `run` block with `bash -n`.
- Confirmed the project contains only the Android platform target.

Run the same repository checks with:

```bash
python tool/validate_project.py
```

## Deferred to GitHub Actions or a Flutter workstation

The delivery environment does not contain the Flutter SDK, Android SDK, Gradle distribution, Ultralytics LiteRT export dependencies, or Android emulator/device. Therefore the following commands were not executed locally:

```bash
python tool/export_model.py
flutter pub get
flutter analyze
flutter test
flutter build apk --release --split-per-abi
flutter build appbundle --release
```

`.github/workflows/android.yml` performs those steps with pinned toolchain versions. A successful Actions run is the definitive build verification and produces the installable split APKs and AAB as workflow artifacts.
