#!/usr/bin/env python3
"""Builds assets/data/world_map.json, the offline world map used by Stamply.

Source: Natural Earth (public domain), 1:110m admin-0 countries.
Run it once on a computer with internet, then commit the result:

    python tool/build_map.py

Options:
    --scale 50       use the more detailed 1:50m data (bigger file)
    --input FILE     read a local GeoJSON file instead of downloading

Output format (compact on purpose):
    {"w": 2000, "h": 789, "c": {"FR": [[x1, y1, x2, y2, ...], ...], ...}}
Each country is a list of rings; each ring is a flat list of x, y pairs in a
2000-unit wide equirectangular map (latitude 84 N to 58 S, no Antarctica).
"""
import argparse
import json
import os
import sys
import urllib.request

W = 2000
LAT_TOP = 84.0
LAT_BOTTOM = -58.0
K = W / 360.0
H = round((LAT_TOP - LAT_BOTTOM) * K)

URL = ("https://raw.githubusercontent.com/nvkelso/natural-earth-vector/master/"
       "geojson/ne_{scale}m_admin_0_countries.geojson")

# Natural Earth leaves ISO_A2 as -99 for a few countries.
NAME_FIX = {"France": "FR", "Norway": "NO", "Kosovo": "XK", "Northern Cyprus": None,
            "Somaliland": None}


def project(lon, lat):
    lat = max(LAT_BOTTOM, min(LAT_TOP, lat))
    return ((lon + 180.0) * K, (LAT_TOP - lat) * K)


def perp_dist(p, a, b):
    (x, y), (x1, y1), (x2, y2) = p, a, b
    dx, dy = x2 - x1, y2 - y1
    if dx == 0 and dy == 0:
        return ((x - x1) ** 2 + (y - y1) ** 2) ** 0.5
    t = ((x - x1) * dx + (y - y1) * dy) / (dx * dx + dy * dy)
    t = max(0.0, min(1.0, t))
    return ((x - (x1 + t * dx)) ** 2 + (y - (y1 + t * dy)) ** 2) ** 0.5


def simplify(points, tol):
    """Douglas-Peucker, iterative, for an open polyline."""
    if len(points) < 3:
        return points
    keep = [False] * len(points)
    keep[0] = keep[-1] = True
    stack = [(0, len(points) - 1)]
    while stack:
        lo, hi = stack.pop()
        far, idx = 0.0, None
        for i in range(lo + 1, hi):
            d = perp_dist(points[i], points[lo], points[hi])
            if d > far:
                far, idx = d, i
        if idx is not None and far > tol:
            keep[idx] = True
            stack.append((lo, idx))
            stack.append((idx, hi))
    return [p for p, k in zip(points, keep) if k]


def area(ring):
    s = 0.0
    for i in range(len(ring)):
        x1, y1 = ring[i]
        x2, y2 = ring[(i + 1) % len(ring)]
        s += x1 * y2 - x2 * y1
    return abs(s) / 2.0


def country_code(props):
    for key in ("ISO_A2_EH", "ISO_A2"):
        c = props.get(key)
        if isinstance(c, str) and len(c) == 2 and c.isalpha():
            return c.upper()
    return NAME_FIX.get(props.get("NAME") or props.get("ADMIN"))


def exterior_rings(geometry):
    if geometry["type"] == "Polygon":
        yield geometry["coordinates"][0]
    elif geometry["type"] == "MultiPolygon":
        for poly in geometry["coordinates"]:
            yield poly[0]


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--scale", default="110", choices=["110", "50"])
    ap.add_argument("--input")
    ap.add_argument("--out", default=os.path.join(
        os.path.dirname(os.path.abspath(__file__)), "..", "assets", "data", "world_map.json"))
    args = ap.parse_args()

    if args.input:
        data = json.load(open(args.input, encoding="utf-8"))
    else:
        print("Downloading Natural Earth data ...")
        with urllib.request.urlopen(URL.format(scale=args.scale), timeout=60) as r:
            data = json.load(r)

    tol = 0.35 if args.scale == "110" else 0.6
    countries = {}
    for feature in data["features"]:
        code = country_code(feature.get("properties", {}))
        if not code or code == "AQ":
            continue
        rings = []
        for ring in exterior_rings(feature["geometry"]):
            if all(lat < LAT_BOTTOM for _, lat in ring):
                continue  # Antarctica
            pts = [project(lon, lat) for lon, lat in ring]
            if pts and pts[0] == pts[-1]:
                pts = pts[:-1]
            pts = simplify(pts, tol)
            # drop repeated points after rounding
            out = []
            for x, y in pts:
                p = (round(x), round(y))
                if not out or out[-1] != p:
                    out.append(p)
            if len(out) >= 3:
                rings.append(out)
        if not rings:
            continue
        rings.sort(key=area, reverse=True)
        big = [r for r in rings if area(r) >= 2.0] or rings[:1]
        countries.setdefault(code, []).extend(big)

    result = {
        "w": W,
        "h": H,
        "c": {c: [[v for p in r for v in p] for r in rs] for c, rs in sorted(countries.items())},
    }
    with open(args.out, "w", encoding="utf-8") as f:
        json.dump(result, f, separators=(",", ":"))
    print(f"Wrote {len(countries)} countries to {os.path.normpath(args.out)} "
          f"({os.path.getsize(args.out) // 1024} KB)")

    visa = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "assets", "data", "visa_data.json")
    if os.path.exists(visa):
        known = set(json.load(open(visa, encoding="utf-8"))["countries"])
        missing = sorted(known - set(countries))
        print(f"{len(missing)} countries in the visa data have no shape (too small): "
              + ", ".join(missing))


if __name__ == "__main__":
    sys.exit(main())
