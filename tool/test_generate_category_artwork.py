import copy
import hashlib
import tempfile
import unittest
from pathlib import Path

import generate_category_artwork as artwork


class ArtworkValidationTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.taxonomy = artwork.read_taxonomy()
        cls.entries = artwork.load_manifest()

    def test_imported_entries_match_authoritative_taxonomy(self):
        self.assertTrue(self.entries)
        artwork.verify_entries(self.entries, self.taxonomy)
        for item in self.entries:
            data = artwork.verify_bytes(
                artwork.ROOT / item["asset"], item["webpSha256"], item["bytes"])
            artwork.verify_webp(data, item["code"])

    def test_duplicate_codes_and_images_are_rejected(self):
        with self.assertRaisesRegex(ValueError, "Duplicate category codes"):
            artwork.verify_entries([self.entries[0], self.entries[0]], self.taxonomy)
        for field in ("webpSha256", "originalSha256"):
            with self.subTest(field=field):
                entries = copy.deepcopy(self.entries[:2])
                entries[1][field] = entries[0][field]
                with self.assertRaisesRegex(ValueError, "Reused"):
                    artwork.verify_entries(entries, self.taxonomy)

    def test_wrong_category_path_policy_and_encoding_are_rejected(self):
        changes = {
            "code": "CAT-9999",
            "path": ["Wrong", "Parent", "Smartphones"],
            "marketplaceStatus": "Unsupported",
            "adminEnabled": ["No", "Yes", "Yes"],
            "asset": "assets/images/categories/l1/mobiles.webp",
            "pixelSize": 1024,
            "quality": 80,
            "method": 4,
            "status": "awaiting-review",
            "webpSha256": "bad",
            "originalSha256": "bad",
            "figmaNodeId": "",
        }
        for field, value in changes.items():
            with self.subTest(field=field):
                entry = copy.deepcopy(self.entries[0])
                entry[field] = value
                with self.assertRaises(ValueError):
                    artwork.verify_entries([entry], self.taxonomy)

    def test_asset_budget_and_container_validation(self):
        for data in (b"", b"x" * (30 * 1024 + 1), b"not-webp", b"RIFF1234WEBP"):
            with self.subTest(length=len(data)):
                with self.assertRaises(ValueError):
                    artwork.verify_webp(data, "CAT-0001")

    def test_hash_and_byte_count_are_both_checked(self):
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / "asset"
            path.write_bytes(b"test bytes")
            digest = hashlib.sha256(path.read_bytes()).hexdigest()
            self.assertEqual(artwork.verify_bytes(path, digest, 10), b"test bytes")
            with self.assertRaisesRegex(ValueError, "Hash mismatch"):
                artwork.verify_bytes(path, "0" * 64, 10)
            with self.assertRaisesRegex(ValueError, "Size mismatch"):
                artwork.verify_bytes(path, digest, 11)

    def test_generated_catalog_matches_committed_snapshot(self):
        self.assertEqual(
            artwork.OUTPUT.read_text(),
            artwork.render_catalog(self.entries, len(self.taxonomy)),
        )


if __name__ == "__main__":
    unittest.main()
