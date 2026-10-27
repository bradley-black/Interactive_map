"""Check how much of the free Supabase plan the website version is using.

Reads the project address and public key from standalone/config.js and asks the
database's usage_summary() function (see standalone/supabase-setup.sql).

Exit codes: 0 = below the threshold, 1 = at or above it, 2 = not set up yet, 3 = check failed.
"""

import argparse
import json
import re
import sys
import urllib.error
import urllib.request
from pathlib import Path

CONFIG = Path(__file__).resolve().parents[2] / "standalone" / "config.js"


def read_config() -> tuple[str, str] | None:
    if not CONFIG.exists():
        return None
    text = CONFIG.read_text(encoding="utf-8")
    url = re.search(r'supabaseUrl\s*:\s*"([^"]*)"', text)
    key = re.search(r'supabaseAnonKey\s*:\s*"([^"]*)"', text)
    if not url or not key or not url.group(1) or not key.group(1):
        return None
    return url.group(1).rstrip("/"), key.group(1)


def fetch_usage(url: str, key: str) -> dict:
    req = urllib.request.Request(
        f"{url}/rest/v1/rpc/usage_summary",
        data=b"{}",
        method="POST",
        headers={"apikey": key, "Authorization": f"Bearer {key}", "Content-Type": "application/json"},
    )
    with urllib.request.urlopen(req, timeout=20) as resp:
        return json.load(resp)


def fmt(n: float) -> str:
    return f"{n / 1e9:.2f} GB" if n >= 1e9 else f"{round(n / 1e6)} MB"


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    parser.add_argument("--threshold", type=float, default=95, help="percent that counts as nearly full (default 95)")
    args = parser.parse_args()

    config = read_config()
    if not config:
        print("NOT SET UP: standalone/config.js has no Supabase address or key yet.")
        sys.exit(2)
    try:
        u = fetch_usage(*config)
    except urllib.error.HTTPError as e:
        hint = " Run the latest standalone/supabase-setup.sql in Supabase." if e.code == 404 else ""
        if e.code == 503:
            hint = " The project may be paused: restore it from the Supabase dashboard."
        print(f"CHECK FAILED: Supabase answered {e.code}.{hint}")
        sys.exit(3)
    except (OSError, json.JSONDecodeError) as e:   # OSError covers no network, timeouts and dropped connections
        print(f"CHECK FAILED: couldn't reach Supabase ({e}).")
        sys.exit(3)

    parts = {
        "Photo storage": (u["photo_bytes"], u["photo_limit"]),
        "Database": (u["db_bytes"], u["db_limit"]),
    }
    over = []
    for name, (used, limit) in parts.items():
        pct = used / limit * 100
        print(f"{name}: {fmt(used)} of {fmt(limit)} ({pct:.0f}%)")
        if pct >= args.threshold:
            over.append(f"{name.lower()} {pct:.0f}% full")
    if over:
        print(f"WARNING: {' and '.join(over)} on the free Supabase plan.")
        sys.exit(1)
    print(f"OK: everything is below {args.threshold:.0f}%.")
