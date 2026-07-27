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
EXPECTED_SHA256 = "c8721348aba1c541d124c0cd2b1fc7f89fe4ac5ddb4fbc18bf4132328c6f8e63"
EXPECTED_LABELS = [
    "Acrida cinerea",
    "Acrididae",
    "Apidae",
    "Carabidae",
    "Coenagrionidae",
    "Colias erate",
    "Colias heos",
    "Colias poliographus",
    "Curculionidae",
    "Eumolpidae",
    "Libellulidae",
    "Lycaenidae",
    "Myrmeleontidae",
    "Pieris rapae",
    "Pontia daplidice",
    "Scarabaeoidea",
    "Syrphidae",
    "Tenebrionidae",
    "Vespidae",
]
REQUIRED_FILES = [
    ".github/workflows/android.yml",
    "README.md",
    "analysis_options.yaml",
    "assets/data/taxonomy_zh.json",
    "assets/models/.gitkeep",
    "android/app/build.gradle.kts",
    "android/app/src/main/AndroidManifest.xml",
    "android/app/src/main/kotlin/top/myneri/insectidentifier/MainActivity.kt",
    "android/build.gradle.kts",
    "android/gradle.properties",
    "android/gradle/wrapper/gradle-wrapper.properties",
    "android/settings.gradle.kts",
    "lib/main.dart",
    "models/best.pt",
    "pubspec.yaml",
    "requirements-export.txt",
    "test/classification_output_parser_test.dart",
    "tool/export_model.py",
]
DISALLOWED_PLATFORM_DIRECTORIES = ["ios", "linux", "macos", "web", "windows"]
RELATIVE_DART_IMPORT = re.compile(r"^import\s+['\"](?P<path>\.{1,2}/[^'\"]+)['\"];", re.MULTILINE)


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

    present_platforms = [name for name in DISALLOWED_PLATFORM_DIRECTORIES if (ROOT / name).exists()]
    if present_platforms:
        fail(f"Android-only project unexpectedly contains platform directories: {present_platforms}")


def validate_taxonomy() -> int:
    taxonomy_path = ROOT / "assets/data/taxonomy_zh.json"
    payload = json.loads(taxonomy_path.read_text(encoding="utf-8"))
    classes = payload.get("classes")
    if not isinstance(classes, list):
        fail("taxonomy_zh.json must contain a classes array.")
    if len(classes) != len(EXPECTED_LABELS):
        fail(f"Expected {len(EXPECTED_LABELS)} taxonomy classes, found {len(classes)}.")

    indices = [entry.get("class_index") for entry in classes]
    labels = [entry.get("model_label") for entry in classes]
    if indices != list(range(len(EXPECTED_LABELS))):
        fail(f"Unexpected taxonomy indices: {indices}")
    if labels != EXPECTED_LABELS:
        fail(f"Unexpected taxonomy labels: {labels}")
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
    allowed_ranks = {"species", "family", "superfamily"}
    for entry in classes:
        if not isinstance(entry, dict):
            fail("Every taxonomy class must be a JSON object.")
        missing = sorted(required_fields.difference(entry))
        if missing:
            fail(f"Taxonomy class {entry.get('class_index')} is missing {missing}")
        if entry["rank"] not in allowed_ranks:
            fail(f"Unsupported taxonomy rank for class {entry['class_index']}: {entry['rank']}")
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
    if "YoloInsectClassifier" not in main_text or "FileHistoryRepository" not in main_text:
        fail("lib/main.dart is not wired to the classifier and history repository.")

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

    manifest = (ROOT / "android/app/src/main/AndroidManifest.xml").read_text(encoding="utf-8")
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
    if len(header) != 24 or header[:8] != b"\x89PNG\r\n\x1a\n" or header[12:16] != b"IHDR":
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
    return len(expected)


def validate_build_configuration() -> None:
    pubspec = (ROOT / "pubspec.yaml").read_text(encoding="utf-8")
    workflow = (ROOT / ".github/workflows/android.yml").read_text(encoding="utf-8")
    app_gradle = (ROOT / "android/app/build.gradle.kts").read_text(encoding="utf-8")
    settings_gradle = (ROOT / "android/settings.gradle.kts").read_text(encoding="utf-8")

    for asset in ("assets/data/taxonomy_zh.json", "assets/models/"):
        if asset not in pubspec:
            fail(f"pubspec.yaml does not declare asset {asset!r}.")
    for package in ("crop_your_image", "image_picker", "path_provider", "ultralytics_yolo"):
        if f"{package}:" not in pubspec:
            fail(f"pubspec.yaml is missing dependency {package!r}.")

    workflow_requirements = [
        "python tool/validate_project.py",
        "python tool/export_model.py",
        "flutter analyze",
        "flutter test",
        "flutter build apk --release --split-per-abi",
        "flutter build appbundle --release",
        "actions/upload-artifact@v4",
    ]
    for value in workflow_requirements:
        if value not in workflow:
            fail(f"Android workflow is missing step text {value!r}.")

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
