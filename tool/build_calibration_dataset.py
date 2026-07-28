#!/usr/bin/env python3
"""Build a deterministic Ultralytics classification calibration dataset."""

from __future__ import annotations

import argparse
import hashlib
import json
import os
import re
import shutil
import sys
import unicodedata
from dataclasses import dataclass
from pathlib import Path

IMAGE_SUFFIXES = {
    ".bmp",
    ".jpeg",
    ".jpg",
    ".png",
    ".tif",
    ".tiff",
    ".webp",
}
DEFAULT_SOURCE = Path(r"D:\insects\1\dataset_416")


@dataclass(frozen=True)
class ClassSpec:
    index: int
    model_label: str
    common_name: str


@dataclass(frozen=True)
class Candidate:
    path: Path
    source_relative: str
    digest: str


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description=(
            "Build a balanced W8A16 calibration dataset from an existing "
            "classification dataset without modifying the source images."
        )
    )
    parser.add_argument(
        "--source",
        type=Path,
        default=DEFAULT_SOURCE,
        help=f"Source dataset root. Defaults to {DEFAULT_SOURCE}.",
    )
    parser.add_argument(
        "--output",
        type=Path,
        default=Path("calibration_data"),
        help="New output directory. It must not already exist.",
    )
    parser.add_argument(
        "--taxonomy",
        type=Path,
        default=Path("assets/data/taxonomy_zh.json"),
        help="Taxonomy whose model_label values define the 28 output classes.",
    )
    parser.add_argument(
        "--per-class",
        type=int,
        default=20,
        help="Number of calibration images placed in val for each class.",
    )
    parser.add_argument(
        "--seed",
        type=int,
        default=20260728,
        help="Seed used for deterministic sampling.",
    )
    parser.add_argument(
        "--source-splits",
        nargs="+",
        default=("train",),
        metavar="SPLIT",
        help=(
            "Source splits to sample, such as 'train' or "
            "'train calibration'. "
            "If none exist, class folders are read directly below --source."
        ),
    )
    parser.add_argument(
        "--allow-shortfall",
        action="store_true",
        help=(
            "Use all available unique images when a class has fewer than "
            "--per-class plus one. The default is to fail."
        ),
    )
    return parser.parse_args()


def sha256_file(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        for chunk in iter(lambda: handle.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def load_taxonomy(path: Path) -> list[ClassSpec]:
    payload = json.loads(path.read_text(encoding="utf-8"))
    raw_classes = payload.get("classes")
    if not isinstance(raw_classes, list) or not raw_classes:
        raise ValueError(f"Taxonomy has no classes array: {path}")

    classes: list[ClassSpec] = []
    for raw in raw_classes:
        if not isinstance(raw, dict):
            raise ValueError("Every taxonomy class must be an object.")
        index = raw.get("class_index")
        model_label = raw.get("model_label")
        common_name = raw.get("common_name")
        if (
            not isinstance(index, int)
            or not isinstance(model_label, str)
            or not model_label.strip()
            or not isinstance(common_name, str)
            or not common_name.strip()
        ):
            raise ValueError(
                "Taxonomy classes require class_index, model_label, and common_name."
            )
        classes.append(
            ClassSpec(
                index=index,
                model_label=model_label.strip(),
                common_name=common_name.strip(),
            )
        )

    classes.sort(key=lambda item: item.index)
    if [item.index for item in classes] != list(range(len(classes))):
        raise ValueError("Taxonomy class indices must be contiguous and begin at zero.")
    if len({item.model_label for item in classes}) != len(classes):
        raise ValueError("Taxonomy model labels must be unique.")
    return classes


def normalize_alias(value: str) -> str:
    normalized = unicodedata.normalize("NFKC", value).strip().casefold()
    if normalized.isdigit():
        return f"index:{int(normalized)}"
    normalized = re.sub(r"^\d+[\s._-]+", "", normalized)
    return "".join(character for character in normalized if character.isalnum())


def build_alias_map(classes: list[ClassSpec]) -> dict[str, ClassSpec]:
    aliases: dict[str, ClassSpec] = {}
    for item in classes:
        raw_aliases = {
            item.model_label,
            item.common_name,
            str(item.index),
            f"{item.index:02d}",
        }
        for raw_alias in raw_aliases:
            alias = normalize_alias(raw_alias)
            existing = aliases.get(alias)
            if existing is not None and existing != item:
                raise ValueError(
                    f"Ambiguous taxonomy alias {raw_alias!r}: "
                    f"{existing.model_label!r} and {item.model_label!r}"
                )
            aliases[alias] = item
    return aliases


def resolve_scan_roots(source: Path, splits: tuple[str, ...]) -> list[Path]:
    requested = [source / split for split in splits]
    existing = [path for path in requested if path.is_dir()]
    if existing:
        missing = [path.name for path in requested if not path.is_dir()]
        if missing:
            raise FileNotFoundError(
                f"Requested source splits do not exist under {source}: {missing}"
            )
        return existing
    return [source]


def has_supported_image_header(path: Path) -> bool:
    with path.open("rb") as handle:
        header = handle.read(16)
    suffix = path.suffix.lower()
    if suffix in {".jpg", ".jpeg"}:
        return header.startswith(b"\xff\xd8\xff")
    if suffix == ".png":
        return header.startswith(b"\x89PNG\r\n\x1a\n")
    if suffix == ".webp":
        return (
            len(header) >= 12
            and header.startswith(b"RIFF")
            and header[8:12] == b"WEBP"
        )
    if suffix == ".bmp":
        return header.startswith(b"BM")
    if suffix in {".tif", ".tiff"}:
        return header.startswith((b"II*\x00", b"MM\x00*"))
    return False


def discover_candidates(
    source: Path,
    scan_roots: list[Path],
    classes: list[ClassSpec],
    output: Path,
) -> dict[int, list[Candidate]]:
    aliases = build_alias_map(classes)
    candidates: dict[int, dict[str, Candidate]] = {
        item.index: {} for item in classes
    }
    digest_owners: dict[str, tuple[ClassSpec, str]] = {}
    unknown_directories: set[str] = set()
    invalid_images: list[str] = []

    for scan_root in scan_roots:
        for path in sorted(scan_root.rglob("*")):
            if not path.is_file() or path.suffix.lower() not in IMAGE_SUFFIXES:
                continue
            resolved_path = path.resolve()
            if resolved_path.is_relative_to(output):
                continue

            relative_to_split = path.relative_to(scan_root)
            if len(relative_to_split.parts) < 2:
                unknown_directories.add("<source root>")
                continue
            source_class_name = relative_to_split.parts[0]
            class_spec = aliases.get(normalize_alias(source_class_name))
            if class_spec is None:
                unknown_directories.add(source_class_name)
                continue
            if path.stat().st_size == 0 or not has_supported_image_header(path):
                invalid_images.append(path.relative_to(source).as_posix())
                continue

            digest = sha256_file(path)
            source_relative = path.relative_to(source).as_posix()
            owner = digest_owners.get(digest)
            if owner is not None and owner[0].index != class_spec.index:
                raise ValueError(
                    "The same image content appears in different classes: "
                    f"{owner[1]} ({owner[0].model_label}) and "
                    f"{source_relative} ({class_spec.model_label})"
                )
            digest_owners[digest] = (class_spec, source_relative)
            candidates[class_spec.index].setdefault(
                digest,
                Candidate(
                    path=path,
                    source_relative=source_relative,
                    digest=digest,
                ),
            )

    if unknown_directories:
        preview = ", ".join(sorted(unknown_directories)[:10])
        raise ValueError(
            "Image-containing directories do not match taxonomy labels, "
            f"common names, or class indices: {preview}"
        )
    if invalid_images:
        preview = ", ".join(invalid_images[:10])
        raise ValueError(f"Unsupported or invalid image headers: {preview}")
    return {
        class_index: sorted(items.values(), key=lambda item: item.source_relative)
        for class_index, items in candidates.items()
    }


def sampling_key(candidate: Candidate, class_index: int, seed: int) -> bytes:
    material = (
        f"{seed}\0{class_index}\0{candidate.source_relative}\0{candidate.digest}"
    )
    return hashlib.sha256(material.encode("utf-8")).digest()


def select_candidates(
    candidates: dict[int, list[Candidate]],
    classes: list[ClassSpec],
    per_class: int,
    seed: int,
    allow_shortfall: bool,
) -> dict[int, tuple[Candidate, list[Candidate]]]:
    selected: dict[int, tuple[Candidate, list[Candidate]]] = {}
    required = per_class + 1
    for item in classes:
        available = candidates[item.index]
        ranked = sorted(
            available,
            key=lambda candidate: sampling_key(candidate, item.index, seed),
        )
        if len(ranked) < required and not allow_shortfall:
            raise ValueError(
                f"Class {item.index} ({item.model_label}) has "
                f"{len(ranked)} unique images; {required} are required "
                f"for 1 train metadata image and {per_class} val images."
            )
        if len(ranked) < 2:
            raise ValueError(
                f"Class {item.index} ({item.model_label}) needs at least "
                "2 unique images."
            )
        train_image = ranked[0]
        val_images = ranked[1 : 1 + min(per_class, len(ranked) - 1)]
        selected[item.index] = (train_image, val_images)
    return selected


def copy_candidate(
    candidate: Candidate,
    destination: Path,
    ordinal: int,
) -> dict[str, str]:
    destination.mkdir(parents=True, exist_ok=True)
    filename = (
        f"{ordinal:04d}_{candidate.digest[:16]}{candidate.path.suffix.lower()}"
    )
    output_path = destination / filename
    shutil.copy2(candidate.path, output_path)
    return {
        "output": output_path.as_posix(),
        "source": candidate.source_relative,
        "sha256": candidate.digest,
    }


def build_calibration_dataset(
    *,
    source: Path,
    output: Path,
    taxonomy: Path,
    per_class: int,
    seed: int,
    source_splits: tuple[str, ...] = ("train",),
    allow_shortfall: bool = False,
) -> dict[str, object]:
    if per_class <= 0:
        raise ValueError("--per-class must be a positive integer.")

    source = source.resolve()
    output = output.resolve()
    taxonomy = taxonomy.resolve()
    if not source.is_dir():
        raise FileNotFoundError(f"Source dataset directory not found: {source}")
    if not taxonomy.is_file():
        raise FileNotFoundError(f"Taxonomy file not found: {taxonomy}")
    if output.exists():
        raise FileExistsError(
            f"Output already exists: {output}. Choose a new directory."
        )
    if source == output or source.is_relative_to(output):
        raise ValueError("Output cannot be the source directory or its parent.")

    classes = load_taxonomy(taxonomy)
    scan_roots = resolve_scan_roots(source, source_splits)
    candidates = discover_candidates(source, scan_roots, classes, output)
    selected = select_candidates(
        candidates,
        classes,
        per_class,
        seed,
        allow_shortfall,
    )

    output.parent.mkdir(parents=True, exist_ok=True)
    staging = output.with_name(f".{output.name}.building-{os.getpid()}")
    if staging.exists():
        raise FileExistsError(f"Temporary output already exists: {staging}")

    manifest_classes: list[dict[str, object]] = []
    dataset_digest = hashlib.sha256()
    try:
        for item in classes:
            train_image, val_images = selected[item.index]
            train_entry = copy_candidate(
                train_image,
                staging / "train" / item.model_label,
                1,
            )
            val_entries = [
                copy_candidate(
                    candidate,
                    staging / "val" / item.model_label,
                    ordinal,
                )
                for ordinal, candidate in enumerate(val_images, start=1)
            ]
            for split, entry in (
                ("train", train_entry),
                *(("val", entry) for entry in val_entries),
            ):
                relative_output = Path(entry["output"]).relative_to(staging)
                entry["output"] = relative_output.as_posix()
                dataset_digest.update(split.encode("utf-8"))
                dataset_digest.update(b"\0")
                dataset_digest.update(entry["output"].encode("utf-8"))
                dataset_digest.update(b"\0")
                dataset_digest.update(entry["sha256"].encode("ascii"))
                dataset_digest.update(b"\n")
            manifest_classes.append(
                {
                    "class_index": item.index,
                    "model_label": item.model_label,
                    "common_name": item.common_name,
                    "available_unique_images": len(candidates[item.index]),
                    "train": [train_entry],
                    "val": val_entries,
                }
            )

        val_total = sum(len(item["val"]) for item in manifest_classes)
        manifest: dict[str, object] = {
            "schema_version": 1,
            "seed": seed,
            "requested_val_images_per_class": per_class,
            "source_splits": list(source_splits),
            "taxonomy_sha256": sha256_file(taxonomy),
            "dataset_sha256": dataset_digest.hexdigest(),
            "class_count": len(classes),
            "train_image_count": len(classes),
            "val_image_count": val_total,
            "classes": manifest_classes,
        }
        (staging / "calibration_manifest.json").write_text(
            json.dumps(manifest, ensure_ascii=False, indent=2) + "\n",
            encoding="utf-8",
        )
        staging.rename(output)
    except Exception:
        if staging.exists():
            shutil.rmtree(staging)
        raise

    return manifest


def main() -> int:
    args = parse_args()
    manifest = build_calibration_dataset(
        source=args.source,
        output=args.output,
        taxonomy=args.taxonomy,
        per_class=args.per_class,
        seed=args.seed,
        source_splits=tuple(args.source_splits),
        allow_shortfall=args.allow_shortfall,
    )
    print(f"Calibration dataset: {args.output.resolve()}")
    print(f"Classes:            {manifest['class_count']}")
    print(f"Train images:       {manifest['train_image_count']}")
    print(f"Val images:         {manifest['val_image_count']}")
    print(f"Dataset SHA-256:    {manifest['dataset_sha256']}")
    if int(manifest["val_image_count"]) < 300:
        print(
            "WARNING: Ultralytics recommends more than 300 calibration images.",
            file=sys.stderr,
        )
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except Exception as error:  # noqa: BLE001 - CLI should report concise errors.
        print(f"ERROR: {error}", file=sys.stderr)
        raise SystemExit(1) from error
