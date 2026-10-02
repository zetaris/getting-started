from __future__ import annotations

import json
import os
import re
import uuid
from typing import Any
from urllib.error import HTTPError, URLError
from urllib.request import Request, urlopen

import zetaris_sql

zetaris_sql.load_env()  # .env.local, repo root or top-level checkout

BASE_URL = os.environ.get("ZETARIS_BASE_URL", "http://localhost:3000").removesuffix(
    "/"
)
ORG_ID = os.environ.get("ZETARIS_ORG_ID")

if not ORG_ID or not re.fullmatch(r"[0-9]+", ORG_ID):
    raise RuntimeError("Set ZETARIS_ORG_ID to the numeric organization ID in .env.local.")
if not re.fullmatch(r"https?://[^/]+", BASE_URL):
    raise RuntimeError("ZETARIS_BASE_URL must be an HTTP(S) origin without a path.")


def _read_json(response: Any) -> Any:
    return json.loads(response.read().decode("utf-8"))


def _unreachable_message(error: BaseException) -> str:
    reason = error.reason if isinstance(error, URLError) else error
    return f"Cannot reach {BASE_URL}: {reason}"


def _request(path: str, token: str, method: str = "GET", body: Any = None) -> Any:
    headers = {
        "Authorization": f"Bearer {token}",
        "X-Org-ID": ORG_ID,
        "X-Request-ID": str(uuid.uuid4()),
    }
    data = None
    if body is not None:
        headers["Content-Type"] = "application/json"
        data = json.dumps(body, ensure_ascii=False).encode("utf-8")

    request = Request(f"{BASE_URL}{path}", data=data, headers=headers, method=method)
    try:
        with urlopen(request, timeout=30) as response:
            if response.status == 204:
                return None
            return _read_json(response)
    except HTTPError as error:
        content_type = error.headers.get("content-type", "")
        if "text/html" in content_type:
            detail = "The server returned an HTML page; check the API route."
        else:
            detail = error.read(500).decode("utf-8", errors="replace")
        raise RuntimeError(
            f"{method} {path} failed: HTTP {error.code} {detail}"
        ) from error
    except (OSError, TimeoutError, URLError) as error:
        raise RuntimeError(_unreachable_message(error)) from error


def zetaris_request(path: str, method: str = "GET", body: Any = None) -> Any:
    """Make an authenticated request to the Zetaris UI proxy API."""

    token = os.environ.get("ZETARIS_API_KEY")
    if not token:
        username = os.environ.get("ZETARIS_USERNAME")
        password = os.environ.get("ZETARIS_PASSWORD")
        if not username or not password:
            raise RuntimeError(
                "Set ZETARIS_API_KEY or both ZETARIS_USERNAME and "
                "ZETARIS_PASSWORD."
            )

        login_request = Request(
            f"{BASE_URL}/api/auth/login",
            data=json.dumps(
                {"username": username, "password": password}, ensure_ascii=False
            ).encode("utf-8"),
            headers={
                "Content-Type": "application/json",
                "X-Request-ID": str(uuid.uuid4()),
            },
            method="POST",
        )
        try:
            with urlopen(login_request, timeout=30) as response:
                login = _read_json(response)
        except HTTPError as error:
            raise RuntimeError(f"Zetaris login failed: HTTP {error.code}") from error
        except (OSError, TimeoutError, URLError) as error:
            raise RuntimeError(_unreachable_message(error)) from error

        token = None
        if isinstance(login, dict):
            token = login.get("idToken") or login.get("token") or login.get(
                "accessToken"
            )
        if not token:
            match = re.search(
                r"[A-Za-z0-9_-]{8,}\.[A-Za-z0-9_-]{8,}\.[A-Za-z0-9_-]{8,}",
                json.dumps(login),
            )
            token = match.group(0) if match else None
        if not isinstance(token, str) or not token:
            raise RuntimeError("Zetaris login did not return an access token.")

    return _request(path, token, method, body)
