"""Import reviewed L3 artwork and verify the exact-code, offline asset catalog."""

import argparse
import csv
import hashlib
import json
import re
import shutil
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
TAXONOMY = ROOT.parent / "Documents/Category_Taxonomy_CSVs/ValueX_JustQlic_Master_Category_Taxonomy_v1.0.csv"
MANIFEST = ROOT / ".figma/l3-artwork.json"
OUTPUT = ROOT / "lib/core/constants/l3_category_artwork.g.dart"
ASSETS = ROOT / "assets/images/categories/l3"
READY = {"reviewed-ready", "pilot-style-and-compression-approved"}


def require(condition, message):
    if not condition:
        raise ValueError(message)


def read_taxonomy():
    with TAXONOMY.open(encoding="utf-8-sig") as file:
        rows = list(csv.DictReader(file))
    result = {row["Category Code"]: row for row in rows}
    require(len(result) == len(rows) == 907, "Expected 907 unique taxonomy codes")
    return result


def verify_bytes(path, expected_hash, expected_size):
    data = path.read_bytes()
    require(len(data) == expected_size, f"Size mismatch: {path}")
    require(hashlib.sha256(data).hexdigest() == expected_hash, f"Hash mismatch: {path}")
    return data


def verify_webp(data, code):
    require(0 < len(data) <= 30 * 1024, f"{code}: exceeds 30 KiB budget")
    require(data[:4] == b"RIFF" and data[8:12] == b"WEBP", f"{code}: not WebP")
    require(int.from_bytes(data[4:8], "little") + 8 == len(data), f"{code}: invalid RIFF size")


def load_manifest():
    if not MANIFEST.exists():
        return []
    return json.loads(MANIFEST.read_text())["categories"]


def verify_entries(entries, taxonomy):
    require(len({item["code"] for item in entries}) == len(entries), "Duplicate category codes")
    require(len({item["webpSha256"] for item in entries}) == len(entries), "Reused artwork")
    require(len({item["originalSha256"] for item in entries}) == len(entries), "Reused originals")
    for item in entries:
        code = item["code"]
        require(code in taxonomy, f"Unknown category: {code}")
        source = taxonomy[code]
        require(item["path"] == [source[f"L{i} Category"] for i in (1, 2, 3)],
                f"Taxonomy path mismatch: {code}")
        require(item["marketplaceStatus"] == source["Marketplace Status"],
                f"Marketplace restriction drift: {code}")
        require(item["adminEnabled"] == [source[f"Admin Enabled - L{i}"] for i in (1, 2, 3)],
                f"Enablement drift: {code}")
        require(item["asset"] == f"assets/images/categories/l3/{code}.webp",
                f"Unexpected asset path: {code}")
        require(item["pixelSize"] == 256 and item["quality"] == 85 and item["method"] == 6,
                f"Unexpected encoding: {code}")
        require(item["status"] in READY, f"Unreviewed artwork: {code}")
        for field in ("webpSha256", "originalSha256"):
            require(re.fullmatch(r"[a-f0-9]{64}", item[field]), f"Invalid {field}: {code}")
        require(item["figmaFileKey"] and re.fullmatch(r"\d+:\d+", item["figmaNodeId"]),
                f"Missing Figma provenance: {code}")


def import_entries(source_path, entries, taxonomy):
    incoming = json.loads(source_path.read_text())
    by_code = {item["code"]: item for item in entries}
    copies = {}
    seen = set()
    for item in incoming:
        code = item["code"]
        require(code not in seen, f"Duplicate import code: {code}")
        seen.add(code)
        require(code in taxonomy, f"Unknown import code: {code}")
        require(item["status"] in READY, f"Unreviewed import: {code}")
        original = item["original"]
        derivative = item["recommendedPilotDerivative"]
        require(original["dimensions"] == [1024, 1024], f"Unexpected original size: {code}")
        require(derivative["dimensions"] == [256, 256], f"Unexpected derivative size: {code}")
        verify_bytes(source_path.parent / original["path"], original["sha256"], original["bytes"])
        asset_source = source_path.parent / derivative["path"]
        data = verify_bytes(asset_source, derivative["sha256"], derivative["bytes"])
        verify_webp(data, code)
        taxon = taxonomy[code]
        entry = {
            "code": code,
            "path": item["path"],
            "subject": item["subject"],
            "cue": item["cue"],
            "background": item["background"],
            "marketplaceStatus": taxon["Marketplace Status"],
            "adminEnabled": [taxon[f"Admin Enabled - L{i}"] for i in (1, 2, 3)],
            "asset": f"assets/images/categories/l3/{code}.webp",
            "pixelSize": 256,
            "quality": derivative["quality"],
            "method": derivative["method"],
            "bytes": len(data),
            "webpSha256": derivative["sha256"],
            "originalSha256": original["sha256"],
            "originalBytes": original["bytes"],
            "originalUrl": original["url"],
            "figmaFileKey": item["figmaFileKey"],
            "figmaNodeId": item["figmaNodeId"],
            "figmaSessionId": item["figmaSessionId"],
            "model": item["model"],
            "status": item["status"],
            "reviewNotes": item.get("reviewNotes", ""),
        }
        require(code not in by_code or by_code[code] == entry,
                f"Conflicting existing artwork: {code}; review before replacing")
        by_code[code] = entry
        copies[code] = asset_source
    result = sorted(by_code.values(), key=lambda item: item["code"])
    verify_entries(result, taxonomy)
    ASSETS.mkdir(parents=True, exist_ok=True)
    for code, path in copies.items():
        target = ASSETS / f"{code}.webp"
        temporary = target.with_suffix(".webp.tmp")
        shutil.copyfile(path, temporary)
        temporary.replace(target)
    return result


def render_catalog(entries, total):
    lines = [
        "// Generated by tool/generate_category_artwork.py. Do not edit.",
        "",
        f"const l3ArtworkTaxonomyCount = {total};",
        "const Map<String, String> l3CategoryArtworkByCode = {",
    ]
    lines.extend(f"  '{item['code']}': '{item['asset']}'," for item in entries)
    return "\n".join([*lines, "};", ""])


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--import-manifest", type=Path)
    parser.add_argument("--check", action="store_true")
    parser.add_argument("--require-complete", action="store_true")
    args = parser.parse_args()
    require(not (args.check and args.import_manifest), "Import and check are separate operations")
    taxonomy = read_taxonomy()
    entries = load_manifest()
    verify_entries(entries, taxonomy)
    for item in entries:
        verify_webp(verify_bytes(ROOT / item["asset"], item["webpSha256"], item["bytes"]),
                    item["code"])
    if args.import_manifest:
        entries = import_entries(args.import_manifest.resolve(), entries, taxonomy)
    require(bool(entries), "No reviewed artwork imported")
    pending = sorted(set(taxonomy) - {item["code"] for item in entries})
    manifest = json.dumps({
        "version": 1,
        "taxonomyCount": len(taxonomy),
        "readyCount": len(entries),
        "pendingCodes": pending,
        "categories": entries,
    }, indent=2) + "\n"
    catalog = render_catalog(entries, len(taxonomy))
    require({path.name for path in ASSETS.iterdir()} == {f"{item['code']}.webp" for item in entries},
            "Asset directory contains missing or untracked files")
    if args.check:
        require(MANIFEST.read_text() == manifest, "Artwork manifest/coverage is stale")
        require(OUTPUT.read_text() == catalog, "Generated artwork catalog is stale")
    else:
        for path, content in ((MANIFEST, manifest), (OUTPUT, catalog)):
            temporary = path.with_suffix(path.suffix + ".tmp")
            temporary.write_text(content)
            temporary.replace(path)
    print(f"L3 artwork: {len(entries)}/{len(taxonomy)} ready, {len(pending)} pending, "
          f"{sum(item['bytes'] for item in entries):,} bundled bytes")
    require(not args.require_complete or not pending,
            f"Rollout incomplete: {len(pending)} categories still need artwork")


if __name__ == "__main__":
    main()
