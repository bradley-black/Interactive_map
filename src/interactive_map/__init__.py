"""Serve the website version of Been There Atlas (the standalone/ folder) on this computer."""

import functools
import http.server
import sys
import webbrowser
from pathlib import Path

SITE = Path(__file__).resolve().parents[2] / "standalone"


def main() -> None:
    port = int(sys.argv[1]) if len(sys.argv) > 1 else 8000
    if not (SITE / "index.html").exists():
        sys.exit(f"Couldn't find the website files in {SITE}")
    handler = functools.partial(http.server.SimpleHTTPRequestHandler, directory=SITE)
    with http.server.ThreadingHTTPServer(("127.0.0.1", port), handler) as server:
        url = f"http://localhost:{port}"
        print(f"Been There Atlas is running at {url}  (press Ctrl+C to stop)")
        webbrowser.open(url)
        try:
            server.serve_forever()
        except KeyboardInterrupt:
            print("\nStopped.")
