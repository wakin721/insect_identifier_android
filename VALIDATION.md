# Validation status

Validation date: 2026-07-28

## Completed in the delivery environment

- Confirmed `models/best.pt` SHA-256: `3a9da0f028ca92357594fee769369f4ff4e2ac0f0652598b2fe2a20f3a40e608`.
- Confirmed the bundled taxonomy contains 28 contiguous classes in the checkpoint label order.
- Parsed all JSON and Android XML files successfully.
- Checked `pubspec.yaml`, application version metadata, and required GitHub Actions build steps.
- Checked all relative Dart imports, required Flutter assets, Android package paths, launcher-icon PNG headers and dimensions.
- Compiled the Python validation and model-export scripts with Python 3.13.
- Ran the deterministic calibration dataset builder unit tests.
- Checked the workflow action versions and both FP32/W8A16 export commands.
- Confirmed the project contains only the Android platform target.

Run the same repository checks with:

```bash
python tool/validate_project.py
```

## Deferred to GitHub Actions or a Flutter workstation

The delivery environment does not contain the Flutter SDK, Android SDK, Gradle distribution, Ultralytics LiteRT export dependencies, or Android emulator/device. Therefore the following commands were not executed locally:

```bash
python tool/export_model.py --quantize fp32
python tool/export_model.py --quantize w8a16 --data calibration
flutter pub get
flutter analyze
flutter test
flutter build apk --release --split-per-abi
flutter build appbundle --release
```

`.github/workflows/android.yml` performs those steps with pinned toolchain versions. A successful Actions run is the definitive build verification and produces the installable split APKs and AAB as workflow artifacts.
