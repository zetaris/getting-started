"""Silence the JVM's harmless SLF4J warning while JDBC is in use.

The Zetaris driver JAR bundles no logging backend, so the JVM prints "SLF4J:
Failed to load class StaticLoggerBinder" to file descriptor 2 when it starts.
This redirects only file descriptor 2, and only inside the `with` block, so
Python errors outside it still show.
"""

from __future__ import annotations

import contextlib
import os
import sys


@contextlib.contextmanager
def quiet_stderr():
    sys.stderr.flush()
    saved = os.dup(2)
    devnull = os.open(os.devnull, os.O_WRONLY)
    try:
        os.dup2(devnull, 2)
        yield
    finally:
        sys.stderr.flush()
        os.dup2(saved, 2)
        os.close(saved)
        os.close(devnull)
