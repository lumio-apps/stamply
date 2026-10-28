#!/usr/bin/env python3
"""Builds assets/data/country_facts.json (capital, currency, calling code,
languages) from the MIT-licensed annexare/Countries data.

Source: https://github.com/annexare/Countries (MIT License).

Usage:
  git clone --depth 1 https://github.com/annexare/Countries
  python3 tool/build_facts.py --src Countries/dist
"""

import argparse
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent

# Fund and accounting codes that are not everyday money.
FUNDS = {"USN", "USS", "CHE", "CHW", "BOV", "CLF", "COU", "MXV", "UYI", "UYW", "SVC"}

# Fixes for known mistakes in the source and for contested capitals, which
# the app leaves out instead of taking a side: None removes the field.
FIXES = {
    "XK": {"tel": "383"},
    "PS": {"cap": None},
    "IL": {"cap": None},
    "HK": {"cap": None},
    "MO": {"cap": None},
}
OUT = ROOT / "assets" / "data" / "country_facts.json"
VISA = ROOT / "assets" / "data" / "visa_data.json"


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("--src", required=True, help="the dist folder of annexare/Countries")
    src = Path(ap.parse_args().src)
    countries = json.loads((src / "countries.min.json").read_text(encoding="utf-8"))
    currencies = json.loads((src / "currencies.min.json").read_text(encoding="utf-8"))
    languages = json.loads((src / "languages.min.json").read_text(encoding="utf-8"))
    ours = json.loads(VISA.read_text(encoding="utf-8"))["countries"]

    out_countries, used_cur, used_lang = {}, set(), set()
    for code in sorted(ours):
        c = countries.get(code)
        if not c:
            continue
        row = {}
        if c.get("capital"):
            row["cap"] = c["capital"]
        cur = [x for x in c.get("currency", []) if x in currencies]
        main = [x for x in cur if x not in FUNDS] or cur
        if main:
            row["cur"] = main[:2]
            used_cur.update(main[:2])
        if c.get("phone"):
            row["tel"] = str(c["phone"][0])
        langs = [x for x in c.get("languages", []) if x in languages]
        if langs:
            row["lang"] = langs[:4]
            used_lang.update(langs[:4])
        for key, value in FIXES.get(code, {}).items():
            if value is None:
                row.pop(key, None)
            else:
                row[key] = value
        out_countries[code] = row

    data = {
        "schema": 1,
        "source": "annexare/Countries (MIT License), github.com/annexare/Countries",
        "countries": out_countries,
        "currencies": {
            k: [currencies[k]["name"], currencies[k].get("symbol", k)] for k in sorted(used_cur)
        },
        "languages": {k: languages[k]["name"] for k in sorted(used_lang)},
    }
    OUT.write_text(json.dumps(data, ensure_ascii=False, separators=(",", ":")), encoding="utf-8")
    print(f"{len(out_countries)} countries, {len(used_cur)} currencies, {len(used_lang)} languages")


if __name__ == "__main__":
    main()
