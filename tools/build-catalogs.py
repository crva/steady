#!/usr/bin/env python3
"""Regenerates the String Catalogs from a build's extracted strings + tools/translations.py.

Usage: python3 tools/build-catalogs.py [DerivedData path]   (default: build/DerivedData)
Build first (xcodebuild ... -derivedDataPath build/DerivedData build).
Exits non-zero and lists keys that have no translation.
"""
import glob, json, os, sys

sys.path.insert(0, os.path.dirname(__file__))
from translations import T, PLURALS

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
derived = sys.argv[1] if len(sys.argv) > 1 else os.path.join(ROOT, "build/DerivedData")
base = os.path.join(derived, "Build/Intermediates.noindex/Steady.build/Debug-iphonesimulator")
LANGS = ("fr", "es", "de")
TARGETS = {
    "Steady": "Steady/Resources/Localizable.xcstrings",
    "SteadyWidgets": "SteadyWidgets/Localizable.xcstrings",
}

def unit(value):
    return {"stringUnit": {"state": "translated", "value": value}}

missing = []
for target, catalog_path in TARGETS.items():
    keys = {}
    for path in glob.glob(f"{base}/{target}.build/Objects-normal/*/*.stringsdata"):
        for items in json.load(open(path)).get("tables", {}).values():
            for item in items:
                keys.setdefault(item["key"], item)
    if not keys:
        sys.exit(f"No extracted strings for {target}; build first.")

    strings = {}
    for key in sorted(keys):
        item = keys[key]
        entry = {}
        if item.get("comment"):
            entry["comment"] = item["comment"]
        localizations = {}
        if key in PLURALS:
            for lang, (one, other) in PLURALS[key].items():
                localizations[lang] = {"variations": {"plural": {"one": unit(one), "other": unit(other)}}}
        elif key in T:
            if item.get("value"):
                localizations["en"] = unit(item["value"])
            for lang, value in zip(LANGS, T[key]):
                localizations[lang] = unit(value)
        else:
            missing.append(f"{target}: {key!r}")
        if localizations:
            entry["localizations"] = localizations
        strings[key] = entry

    catalog = {"sourceLanguage": "en", "strings": strings, "version": "1.0"}
    with open(os.path.join(ROOT, catalog_path), "w") as f:
        json.dump(catalog, f, ensure_ascii=False, indent=2, separators=(",", " : "))
        f.write("\n")
    print(f"{catalog_path}: {len(strings)} strings")

if missing:
    print("Missing translations:\n  " + "\n  ".join(missing))
    sys.exit(1)
