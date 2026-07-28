#!/usr/bin/env python3
"""Export the bundled Ultralytics YOLO classifier to Android LiteRT/TFLite."""

from __future__ import annotations

import argparse
import json
import shutil
import sys
import zipfile
from pathlib import Path
from typing import Any

EXPECTED_MODEL_SHA256 = "3a9da0f028ca92357594fee769369f4ff4e2ac0f0652598b2fe2a20f3a40e608"


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description=(
            "Export an Ultralytics classification checkpoint to the FP32 LiteRT "
            "model consumed by the Android Flutter app."
        )
    )
    parser.add_argument(
        "--input",
        type=Path,
        default=Path("models/best.pt"),
        help="Input Ultralytics .pt checkpoint.",
    )
    parser.add_argument(
        "--output",
        type=Path,
        default=Path("assets/models/insect_classifier.tflite"),
        help="Destination LiteRT/TFLite file.",
    )
    parser.add_argument(
        "--taxonomy",
        type=Path,
        default=Path("assets/data/taxonomy_zh.json"),
        help="Taxonomy mapping used to validate label order.",
    )
    parser.add_argument(
        "--imgsz",
        type=int,
        default=416,
        help="Square export input size. The checkpoint was trained with 416.",
    )
    parser.add_argument(
        "--skip-checksum",
        action="store_true",
        help="Allow a replacement checkpoint without the bundled SHA-256.",
    )
    return parser.parse_args()


def sha256(path: Path) -> str:
    import hashlib

    digest = hashlib.sha256()
    with path.open("rb") as handle:
        for chunk in iter(lambda: handle.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def load_expected_labels(path: Path) -> list[str]:
    payload = json.loads(path.read_text(encoding="utf-8"))
    raw_classes = payload.get("classes")
    if not isinstance(raw_classes, list) or not raw_classes:
        raise ValueError(f"Taxonomy file has no classes: {path}")

    by_index: dict[int, str] = {}
    for entry in raw_classes:
        if not isinstance(entry, dict):
            raise ValueError("Every taxonomy class must be an object.")
        class_index = entry.get("class_index")
        model_label = entry.get("model_label")
        if not isinstance(class_index, int) or not isinstance(model_label, str):
            raise ValueError("Taxonomy entries require integer class_index and string model_label.")
        if class_index in by_index:
            raise ValueError(f"Duplicate taxonomy class index: {class_index}")
        by_index[class_index] = model_label

    expected_indices = list(range(len(by_index)))
    if sorted(by_index) != expected_indices:
        raise ValueError(
            "Taxonomy class indices must be contiguous and begin at zero: "
            f"found {sorted(by_index)}"
        )
    return [by_index[index] for index in expected_indices]


def normalize_names(raw_names: Any) -> list[str]:
    if isinstance(raw_names, dict):
        normalized: dict[int, str] = {}
        for key, value in raw_names.items():
            normalized[int(key)] = str(value)
        indices = sorted(normalized)
        if indices != list(range(len(indices))):
            raise ValueError(f"Model label indices are not contiguous: {indices}")
        return [normalized[index] for index in indices]
    if isinstance(raw_names, (list, tuple)):
        return [str(value) for value in raw_names]
    raise TypeError(f"Unsupported model names type: {type(raw_names).__name__}")


def validate_tflite(path: Path, expected_labels: list[str]) -> None:
    if not path.is_file() or path.stat().st_size < 1024:
        raise RuntimeError(f"Export did not create a usable model: {path}")

    with path.open("rb") as handle:
        header = handle.read(8)
    if header[4:8] != b"TFL3":
        raise RuntimeError(f"Unexpected LiteRT/TFLite header in {path}")

    if not zipfile.is_zipfile(path):
        raise RuntimeError("Exported model is missing appended Ultralytics metadata.")

    with zipfile.ZipFile(path) as archive:
        try:
            metadata = json.loads(archive.read("metadata.json"))
        except KeyError as error:
            raise RuntimeError("Exported model has no metadata.json entry.") from error

    task = metadata.get("task")
    if task != "classify":
        raise RuntimeError(f"Exported metadata task is {task!r}, expected 'classify'.")
    embedded_labels = normalize_names(metadata.get("names"))
    if embedded_labels != expected_labels:
        raise RuntimeError(
            "Exported label order differs from taxonomy mapping.\n"
            f"Embedded: {embedded_labels}\nExpected: {expected_labels}"
        )


def main() -> int:
    args = parse_args()
    input_path = args.input.resolve()
    taxonomy_path = args.taxonomy.resolve()
    output_path = args.output.resolve()

    if args.imgsz <= 0:
        raise ValueError("--imgsz must be a positive integer.")
    if not input_path.is_file():
        raise FileNotFoundError(f"Checkpoint not found: {input_path}")
    if not taxonomy_path.is_file():
        raise FileNotFoundError(f"Taxonomy mapping not found: {taxonomy_path}")

    actual_hash = sha256(input_path)
    if not args.skip_checksum and actual_hash != EXPECTED_MODEL_SHA256:
        raise RuntimeError(
            "Checkpoint SHA-256 does not match the bundled model. "
            "Use --skip-checksum only after updating and validating taxonomy labels.\n"
            f"Expected: {EXPECTED_MODEL_SHA256}\nActual:   {actual_hash}"
        )

    expected_labels = load_expected_labels(taxonomy_path)

    try:
        from ultralytics import YOLO
        import ultralytics
    except ImportError as error:
        raise RuntimeError(
            "Ultralytics export dependencies are missing. Install "
            "'ultralytics[export-litert]==8.4.104'."
        ) from error

    print(f"Ultralytics: {ultralytics.__version__}")
    print(f"Checkpoint:  {input_path}")
    print(f"SHA-256:     {actual_hash}")
    print(f"Image size:  {args.imgsz} x {args.imgsz}")

    model = YOLO(str(input_path))
    if model.task != "classify":
        raise RuntimeError(f"Checkpoint task is {model.task!r}, expected 'classify'.")
    model_labels = normalize_names(model.names)
    if model_labels != expected_labels:
        raise RuntimeError(
            "Checkpoint label order differs from taxonomy mapping.\n"
            f"Model:    {model_labels}\nTaxonomy: {expected_labels}"
        )

    exported = model.export(
        format="litert",
        imgsz=args.imgsz,
        device="cpu",
        batch=1,
    )
    exported_path = Path(str(exported)).resolve()
    if not exported_path.is_file():
        candidates = sorted(exported_path.rglob("*.tflite")) if exported_path.exists() else []
        if len(candidates) != 1:
            raise RuntimeError(
                f"Could not identify exported .tflite file from {exported_path}: {candidates}"
            )
        exported_path = candidates[0]

    output_path.parent.mkdir(parents=True, exist_ok=True)
    if exported_path != output_path:
        shutil.copy2(exported_path, output_path)
    validate_tflite(output_path, expected_labels)

    print(f"Android model: {output_path}")
    print(f"Size:          {output_path.stat().st_size / (1024 * 1024):.2f} MiB")
    print(f"Classes:       {len(expected_labels)}")
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except Exception as error:  # noqa: BLE001 - CLI should report a concise terminal error.
        print(f"ERROR: {error}", file=sys.stderr)
        raise SystemExit(1) from error
