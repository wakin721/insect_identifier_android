import json
import tempfile
import unittest
from pathlib import Path

from tool.build_calibration_dataset import build_calibration_dataset


class BuildCalibrationDatasetTest(unittest.TestCase):
    def test_builds_deterministic_balanced_dataset(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            source = root / "source"
            taxonomy = root / "taxonomy.json"
            self._write_taxonomy(taxonomy)

            for class_name, marker in (
                ("00_Class_alpha", b"a"),
                ("乙类", b"b"),
            ):
                for image_index in range(4):
                    self._write_jpeg(
                        source
                        / "train"
                        / class_name
                        / f"image-{image_index}.jpg",
                        marker + bytes([image_index]),
                    )
                self._write_jpeg(
                    source / "calibration" / class_name / "held-out.jpg",
                    marker + b"held-out",
                )

            first = build_calibration_dataset(
                source=source,
                output=root / "first",
                taxonomy=taxonomy,
                per_class=3,
                seed=42,
            )
            second = build_calibration_dataset(
                source=source,
                output=root / "second",
                taxonomy=taxonomy,
                per_class=3,
                seed=42,
            )

            self.assertEqual(first, second)
            self.assertEqual(first["class_count"], 2)
            self.assertEqual(first["train_image_count"], 2)
            self.assertEqual(first["val_image_count"], 6)
            self.assertTrue(
                all(
                    not entry["source"].startswith("calibration/")
                    for item in first["classes"]
                    for split in ("train", "val")
                    for entry in item[split]
                )
            )
            self.assertEqual(
                len(list((root / "first" / "train").rglob("*.jpg"))),
                2,
            )
            self.assertEqual(
                len(list((root / "first" / "val").rglob("*.jpg"))),
                6,
            )
            self.assertTrue((root / "first" / "train" / "Class alpha").is_dir())
            self.assertTrue((root / "first" / "val" / "Class beta").is_dir())

            including_calibration = build_calibration_dataset(
                source=source,
                output=root / "including-calibration",
                taxonomy=taxonomy,
                per_class=3,
                seed=42,
                source_splits=("train", "calibration"),
            )
            self.assertEqual(
                including_calibration["source_splits"],
                ["train", "calibration"],
            )
            self.assertTrue(
                all(
                    item["available_unique_images"] == 5
                    for item in including_calibration["classes"]
                )
            )

            saved_manifest = json.loads(
                (root / "first" / "calibration_manifest.json").read_text(
                    encoding="utf-8"
                )
            )
            self.assertEqual(saved_manifest, first)

    def test_rejects_duplicate_content_in_different_classes(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            source = root / "source"
            taxonomy = root / "taxonomy.json"
            self._write_taxonomy(taxonomy)
            duplicate = b"same-image"
            self._write_jpeg(
                source / "train" / "Class alpha" / "duplicate.jpg",
                duplicate,
            )
            self._write_jpeg(
                source / "train" / "Class beta" / "duplicate.jpg",
                duplicate,
            )

            with self.assertRaisesRegex(
                ValueError,
                "same image content appears in different classes",
            ):
                build_calibration_dataset(
                    source=source,
                    output=root / "output",
                    taxonomy=taxonomy,
                    per_class=1,
                    seed=42,
                    allow_shortfall=True,
                )

    @staticmethod
    def _write_taxonomy(path: Path) -> None:
        path.write_text(
            json.dumps(
                {
                    "classes": [
                        {
                            "class_index": 0,
                            "model_label": "Class alpha",
                            "common_name": "甲类",
                        },
                        {
                            "class_index": 1,
                            "model_label": "Class beta",
                            "common_name": "乙类",
                        },
                    ]
                },
                ensure_ascii=False,
            ),
            encoding="utf-8",
        )

    @staticmethod
    def _write_jpeg(path: Path, payload: bytes) -> None:
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_bytes(b"\xff\xd8\xff\xe0" + payload)


if __name__ == "__main__":
    unittest.main()
