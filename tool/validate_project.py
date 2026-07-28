#!/usr/bin/env python3
"""Fast repository checks that do not require Flutter or Ultralytics."""

from __future__ import annotations

import hashlib
import json
import re
import struct
import sys
import xml.etree.ElementTree as ET
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
EXPECTED_SHA256 = "3a9da0f028ca92357594fee769369f4ff4e2ac0f0652598b2fe2a20f3a40e608"
EXPECTED_CLASS_COUNT = 28
REQUIRED_FILES = [
    ".github/workflows/android.yml",
    "LICENSE",
    "README.md",
    "analysis_options.yaml",
    "assets/data/taxonomy_zh.json",
    "assets/images/app_icon.png",
    "assets/models/.gitkeep",
    "android/app/build.gradle.kts",
    "android/app/src/main/AndroidManifest.xml",
    "android/app/src/main/kotlin/top/myneri/insectidentifier/MainActivity.kt",
    "android/build.gradle.kts",
    "android/gradle.properties",
    "android/gradle/wrapper/gradle-wrapper.properties",
    "android/settings.gradle.kts",
    "lib/controllers/developer_settings_controller.dart",
    "lib/main.dart",
    "lib/models/model_variant.dart",
    "lib/repositories/developer_settings_repository.dart",
    "lib/screens/developer_options_screen.dart",
    "models/best.pt",
    "pubspec.yaml",
    "requirements-export.txt",
    "test/app_controller_test.dart",
    "test/about_screen_test.dart",
    "test/classification_output_parser_test.dart",
    "test/developer_settings_test.dart",
    "test/history_repository_test.dart",
    "test/model_status_banner_test.dart",
    "tool/export_model.py",
    "tool/generate_launcher_icons.py",
]
DISALLOWED_PLATFORM_DIRECTORIES = ["ios", "linux", "macos", "web", "windows"]
RELATIVE_DART_IMPORT = re.compile(
    r"^import\s+['\"](?P<path>\.{1,2}/[^'\"]+)['\"];",
    re.MULTILINE,
)


def fail(message: str) -> None:
    raise RuntimeError(message)


def sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        for chunk in iter(lambda: handle.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def validate_required_files() -> None:
    missing = [relative for relative in REQUIRED_FILES if not (ROOT / relative).is_file()]
    if missing:
        fail(f"Missing required files: {missing}")

    present_platforms = [
        name for name in DISALLOWED_PLATFORM_DIRECTORIES if (ROOT / name).exists()
    ]
    if present_platforms:
        fail(
            "Android-only project unexpectedly contains platform directories: "
            f"{present_platforms}"
        )


def validate_taxonomy() -> int:
    taxonomy_path = ROOT / "assets/data/taxonomy_zh.json"
    payload = json.loads(taxonomy_path.read_text(encoding="utf-8"))
    classes = payload.get("classes")
    if not isinstance(classes, list):
        fail("taxonomy_zh.json must contain a classes array.")
    if len(classes) != EXPECTED_CLASS_COUNT:
        fail(
            f"Expected {EXPECTED_CLASS_COUNT} taxonomy classes, "
            f"found {len(classes)}."
        )

    indices = [entry.get("class_index") for entry in classes]
    labels = [entry.get("model_label") for entry in classes]
    if indices != list(range(EXPECTED_CLASS_COUNT)):
        fail(f"Unexpected taxonomy indices: {indices}")
    if any(not isinstance(label, str) or not label.strip() for label in labels):
        fail("Taxonomy model labels must be non-empty strings.")
    if len(set(labels)) != len(labels):
        fail("Taxonomy model labels must be unique.")

    required_fields = {
        "class_index",
        "model_label",
        "common_name",
        "scientific_name",
        "rank",
        "rank_cn",
        "order_cn",
        "order_latin",
        "family_cn",
        "family_latin",
        "genus_cn",
        "genus_latin",
    }
    allowed_ranks = {"species", "genus", "family", "superfamily"}
    for entry in classes:
        if not isinstance(entry, dict):
            fail("Every taxonomy class must be a JSON object.")
        missing = sorted(required_fields.difference(entry))
        if missing:
            fail(f"Taxonomy class {entry.get('class_index')} is missing {missing}")
        if entry["rank"] not in allowed_ranks:
            fail(
                f"Unsupported taxonomy rank for class {entry['class_index']}: "
                f"{entry['rank']}"
            )
        for field in required_fields.difference({"class_index"}):
            value = entry[field]
            if not isinstance(value, str) or not value.strip():
                fail(f"Taxonomy class {entry['class_index']} has invalid {field!r}.")

    return len(classes)


def validate_model() -> str:
    checkpoint_path = ROOT / "models/best.pt"
    digest = sha256(checkpoint_path)
    if digest != EXPECTED_SHA256:
        fail(f"Unexpected models/best.pt SHA-256: {digest}")
    if checkpoint_path.stat().st_size < 1024 * 1024:
        fail("models/best.pt is unexpectedly small.")
    return digest


def validate_dart_sources() -> int:
    dart_files = sorted((ROOT / "lib").rglob("*.dart"))
    if not dart_files:
        fail("No Dart source files found.")

    for path in dart_files:
        text = path.read_text(encoding="utf-8")
        if "TODO" in text or "FIXME" in text:
            fail(f"Unresolved marker in {path.relative_to(ROOT)}")
        for match in RELATIVE_DART_IMPORT.finditer(text):
            target = (path.parent / match.group("path")).resolve()
            if not target.is_file():
                fail(
                    f"Broken relative Dart import in {path.relative_to(ROOT)}: "
                    f"{match.group('path')}"
                )

    main_text = (ROOT / "lib/main.dart").read_text(encoding="utf-8")
    if (
        "YoloInsectClassifier" not in main_text
        or "FileHistoryRepository" not in main_text
        or "FileDeveloperSettingsRepository" not in main_text
    ):
        fail(
            "lib/main.dart is not wired to the classifier, history, "
            "and developer settings repositories."
        )

    return len(dart_files)


def validate_android_xml() -> int:
    xml_files = sorted((ROOT / "android/app/src").rglob("*.xml"))
    if not xml_files:
        fail("No Android XML resource files found.")
    for path in xml_files:
        try:
            ET.parse(path)
        except ET.ParseError as error:
            fail(f"Invalid Android XML in {path.relative_to(ROOT)}: {error}")

    manifest = (ROOT / "android/app/src/main/AndroidManifest.xml").read_text(
        encoding="utf-8"
    )
    required_manifest_values = [
        "android.permission.CAMERA",
        'android:name=".MainActivity"',
        'android:exported="true"',
        'android:allowBackup="false"',
    ]
    for value in required_manifest_values:
        if value not in manifest:
            fail(f"Android manifest is missing {value!r}.")
    return len(xml_files)


def read_png_dimensions(path: Path) -> tuple[int, int]:
    with path.open("rb") as handle:
        header = handle.read(24)
    if (
        len(header) != 24
        or header[:8] != b"\x89PNG\r\n\x1a\n"
        or header[12:16] != b"IHDR"
    ):
        fail(f"Invalid PNG header: {path.relative_to(ROOT)}")
    return struct.unpack(">II", header[16:24])


def validate_icons() -> int:
    expected = {
        "mipmap-mdpi/ic_launcher.png": 48,
        "mipmap-hdpi/ic_launcher.png": 72,
        "mipmap-xhdpi/ic_launcher.png": 96,
        "mipmap-xxhdpi/ic_launcher.png": 144,
        "mipmap-xxxhdpi/ic_launcher.png": 192,
    }
    res = ROOT / "android/app/src/main/res"
    for relative, size in expected.items():
        path = res / relative
        if not path.is_file():
            fail(f"Missing Android launcher icon: {path.relative_to(ROOT)}")
        if read_png_dimensions(path) != (size, size):
            fail(f"Unexpected launcher icon dimensions: {path.relative_to(ROOT)}")

    app_icon = ROOT / "assets/images/app_icon.png"
    if read_png_dimensions(app_icon) != (512, 512):
        fail("Unexpected About screen app icon dimensions.")
    return len(expected) + 1


def validate_workflow_action_versions(workflow: str) -> None:
    minimum_major_versions = {
        "actions/checkout": 6,
        "actions/setup-python": 6,
        "actions/cache": 5,
        "actions/setup-java": 5,
        "actions/upload-artifact": 6,
    }

    for action, minimum_major in minimum_major_versions.items():
        match = re.search(
            rf"uses:\s*{re.escape(action)}@v(?P<major>\d+)\b",
            workflow,
        )
        if match is None:
            fail(f"Android workflow is missing action {action!r}.")
        major = int(match.group("major"))
        if major < minimum_major:
            fail(
                f"Android workflow uses outdated {action}@v{major}; "
                f"expected v{minimum_major} or newer."
            )


def validate_build_configuration() -> None:
    pubspec = (ROOT / "pubspec.yaml").read_text(encoding="utf-8")
    app_info = (ROOT / "lib/core/app_info.dart").read_text(encoding="utf-8")
    workflow = (ROOT / ".github/workflows/android.yml").read_text(encoding="utf-8")
    export_requirements = (ROOT / "requirements-export.txt").read_text(
        encoding="utf-8"
    )
    app_gradle = (ROOT / "android/app/build.gradle.kts").read_text(encoding="utf-8")
    settings_gradle = (ROOT / "android/settings.gradle.kts").read_text(
        encoding="utf-8"
    )

    for asset in (
        "assets/data/taxonomy_zh.json",
        "assets/images/app_icon.png",
        "assets/models/",
    ):
        if asset not in pubspec:
            fail(f"pubspec.yaml does not declare asset {asset!r}.")

    license_path = ROOT / "LICENSE"
    if sha256(license_path) != (
        "0d96a4ff68ad6d4b6f1f30f713b18d5184912ba8dd389f86aa7710db079abcb0"
    ):
        fail("LICENSE must match the unmodified GNU AGPL-3.0 text.")
    for package in ("crop_your_image", "image_picker", "path_provider", "ultralytics_yolo"):
        if f"{package}:" not in pubspec:
            fail(f"pubspec.yaml is missing dependency {package!r}.")
    if "ai-edge-quantizer==0.8.0" not in export_requirements:
        fail("requirements-export.txt must pin the W8A32 quantizer.")

    pubspec_version = re.search(
        r"^version:\s*(?P<version>\d+\.\d+\.\d+)\+(?P<build>\d+)\s*$",
        pubspec,
        re.MULTILINE,
    )
    app_version = re.search(
        r"static const version = '(?P<version>\d+\.\d+\.\d+)';",
        app_info,
    )
    app_build = re.search(
        r"static const buildNumber = (?P<build>\d+);",
        app_info,
    )
    if pubspec_version is None or app_version is None or app_build is None:
        fail("Unable to read the application version configuration.")
    if (
        pubspec_version.group("version") != app_version.group("version")
        or pubspec_version.group("build") != app_build.group("build")
    ):
        fail("pubspec.yaml and AppInfo contain different application versions.")

    workflow_requirements = [
        "python tool/validate_project.py",
        "python tool/export_model.py",
        "--quantize fp32",
        "--quantize w8a32",
        "assets/models/insect_classifier_fp32.tflite",
        "assets/models/insect_classifier_w8a32.tflite",
        "flutter analyze",
        "flutter test",
        "flutter build apk --release --split-per-abi",
        "flutter build appbundle --release",
    ]
    for value in workflow_requirements:
        if value not in workflow:
            fail(f"Android workflow is missing step text {value!r}.")

    validate_workflow_action_versions(workflow)

    if 'applicationId = "top.myneri.insectidentifier"' not in app_gradle:
        fail("Unexpected Android applicationId.")
    supported_agp_versions = [
        'id("com.android.application") version "8.11.1"',
        'id("com.android.application") version "9.0.1"',
    ]
    if not any(version in settings_gradle for version in supported_agp_versions):
        fail("Unsupported Android Gradle Plugin version.")


def main() -> int:
    validate_required_files()
    class_count = validate_taxonomy()
    digest = validate_model()
    dart_count = validate_dart_sources()
    xml_count = validate_android_xml()
    icon_count = validate_icons()
    validate_build_configuration()

    print(
        "Validated "
        f"{class_count} taxonomy classes, {dart_count} Dart files, "
        f"{xml_count} Android XML files, and {icon_count} launcher icons."
    )
    print(f"Checkpoint SHA-256: {digest}")
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except Exception as error:  # noqa: BLE001 - CLI validation entrypoint.
        print(f"ERROR: {error}", file=sys.stderr)
        raise SystemExit(1) from error
