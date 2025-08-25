#!/usr/bin/env python

import os
import sys
import urllib.request
import socket
from urllib.error import HTTPError, URLError

HOST = os.environ.get("HEALTHCHECK_HOST", "localhost")
PORT = os.environ.get("HEALTHCHECK_PORT", "8000")
PATH = os.environ.get("HEALTHCHECK_PATH", "/health")
URL = f"http://{HOST}:{PORT}{PATH}"

try:
    with urllib.request.urlopen(URL, timeout=5) as response:
        if response.status == 200:
            print(f"Health check successful: {URL} returned status {response.status}")
            sys.exit(0)
        else:
            print(f"Health check failed: {URL} returned status {response.status}")
            sys.exit(1)
except HTTPError as e:
    print(f"Health check failed: HTTPError: {e.code} {e.reason}", file=sys.stderr)
    sys.exit(1)
except URLError as e:
    # Handle socket.timeout wrapped in URLError
    if isinstance(e.reason, socket.timeout):
        print(f"Health check failed: Request timed out after 5 seconds", file=sys.stderr)
    else:
        print(f"Health check failed: URLError: {e.reason}", file=sys.stderr)
    sys.exit(1)
except socket.timeout:
    print(f"Health check failed: Request timed out after 5 seconds", file=sys.stderr)
    sys.exit(1)
except Exception as e:
    print(f"An unexpected error occurred: {e}", file=sys.stderr)
    sys.exit(1)
