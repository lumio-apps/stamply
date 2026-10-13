#!/usr/bin/env python3
"""Builds assets/data/visa_data.json from the open Passport Index Data.

Source: https://github.com/imorte/passport-index-data (MIT License).

Usage:
  python3 tool/build_data.py                 # download the latest data from GitHub
  python3 tool/build_data.py --src <folder>  # use a local copy of the repository

The app ships this file inside the APK (works offline) and downloads the same
file from the main branch when the user taps "Update data" in Settings.
"""

import argparse
import csv
import io
import json
import re
import sys
import urllib.request
from pathlib import Path

UPSTREAM = "https://raw.githubusercontent.com/imorte/passport-index-data/main"
OUT = Path(__file__).resolve().parent.parent / "assets" / "data" / "visa_data.json"

# Short codes keep the file small. Numbers mean "visa free for N days".
STATUS = {
    "visa free": "vf",
    "visa on arrival": "voa",
    "eta": "eta",
    "e-visa": "ev",
    "visa required": "vr",
    "no admission": "na",
}

# Friendlier or current names for a few countries.
NAME_FIXES = {
    "Swaziland": "Eswatini",
    "Czech Republic": "Czechia",
    "Macao": "Macau",
    "Vatican": "Vatican City",
}


def read(src, name):
    if src:
        return (Path(src) / name).read_text(encoding="utf-8")
    with urllib.request.urlopen(f"{UPSTREAM}/{name}", timeout=60) as r:
        return r.read().decode("utf-8")


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--src", help="local folder with the upstream files")
    args = ap.parse_args()

    readme = read(args.src, "README.md")
    m = re.search(r"Last updated:\s*\*\*(\d{1,2}) (\w+) (\d{4})\*\*", readme)
    if not m:
        sys.exit("Could not find the 'Last updated' date in the upstream README.")
    months = ["January", "February", "March", "April", "May", "June", "July",
              "August", "September", "October", "November", "December"]
    version = f"{m.group(3)}-{months.index(m.group(2)) + 1:02d}-{int(m.group(1)):02d}"

    names = next(csv.reader(io.StringIO(read(args.src, "passport-index-matrix.csv"))))
    codes = next(csv.reader(io.StringIO(read(args.src, "passport-index-matrix-iso2.csv"))))
    countries = {}
    for name, code in zip(names[1:], codes[1:]):
        countries[code] = NAME_FIXES.get(name, name)

    rules = {}
    unknown = set()
    for row in csv.DictReader(io.StringIO(read(args.src, "passport-index-tidy-iso2.csv"))):
        p, d, req = row["Passport"], row["Destination"], row["Requirement"].strip()
        if req == "-1" or p == d:
            continue
        if req.isdigit():
            value = int(req)
        elif req in STATUS:
            value = STATUS[req]
        else:
            unknown.add(req)
            continue
        rules.setdefault(p, {})[d] = value

    if unknown:
        print("Skipped unknown values:", ", ".join(sorted(unknown)), file=sys.stderr)
    if len(countries) < 150 or len(rules) < 150:
        sys.exit("Upstream data looks incomplete; not writing the file.")

    data = {
        "schema": 1,
        "version": version,
        "source": "Passport Index Data, github.com/imorte/passport-index-data (MIT License)",
        "countries": dict(sorted(countries.items(), key=lambda kv: kv[1])),
        "rules": {k: dict(sorted(v.items())) for k, v in sorted(rules.items())},
    }
    OUT.parent.mkdir(parents=True, exist_ok=True)
    OUT.write_text(json.dumps(data, ensure_ascii=False, separators=(",", ":")), encoding="utf-8")
    print(f"Wrote {OUT} (version {version}, {len(countries)} countries, "
          f"{sum(len(v) for v in rules.values())} rules, {OUT.stat().st_size // 1024} KB)")


if __name__ == "__main__":
    main()
