#!/usr/bin/env python3
import datetime as dt
import hashlib
import json
import sqlite3
import subprocess
import sys
import urllib.request
from pathlib import Path
from typing import Optional

from Crypto.Cipher import AES


def chrome_key() -> bytes:
    password = subprocess.check_output(
        [
            "security",
            "find-generic-password",
            "-w",
            "-s",
            "Chrome Safe Storage",
            "-a",
            "Chrome",
        ]
    ).rstrip(b"\n")
    return hashlib.pbkdf2_hmac("sha1", password, b"saltysalt", 1003, 16)


def decrypt_cookie(key: bytes, host: str, encrypted_value: bytes) -> str:
    payload = encrypted_value[3:] if encrypted_value.startswith(b"v10") else encrypted_value
    value = AES.new(key, AES.MODE_CBC, b" " * 16).decrypt(payload)
    padding = value[-1]
    if 1 <= padding <= 16:
        value = value[:-padding]

    digest = hashlib.sha256(host.encode("utf-8")).digest()
    if value.startswith(digest):
        value = value[len(digest) :]

    return value.decode("utf-8")


def chrome_profiles() -> list[Path]:
    chrome_root = Path.home() / "Library/Application Support/Google/Chrome"
    profiles = []
    for cookies_path in chrome_root.glob("*/Cookies"):
        if cookies_path.parent.name == "System Profile":
            continue
        profiles.append(cookies_path)
    return sorted(profiles, key=lambda path: ("0" if path.parent.name == "Default" else "1", path.parent.name))


def load_weread_cookies(cookies_path: Path, key: bytes) -> dict[str, str]:
    cookies: dict[str, str] = {}
    connection = sqlite3.connect(f"file:{cookies_path}?mode=ro", uri=True)
    try:
        rows = connection.execute(
            """
            SELECT host_key, name, value, encrypted_value
            FROM cookies
            WHERE host_key LIKE '%weread.qq.com%'
            ORDER BY host_key, name
            """
        )
        for host, name, value, encrypted_value in rows:
            if value:
                cookies[name] = value
            elif encrypted_value:
                cookies[name] = decrypt_cookie(key, host, encrypted_value)
    finally:
        connection.close()
    return cookies


def fetch_shelf(cookies: dict[str, str]) -> dict:
    cookie_header = "; ".join(f"{name}={value}" for name, value in sorted(cookies.items()))
    request = urllib.request.Request(
        "https://weread.qq.com/web/shelf/sync",
        headers={
            "Cookie": cookie_header,
            "Referer": "https://weread.qq.com/web/shelf",
            "Accept": "application/json, text/plain, */*",
            "User-Agent": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 Chrome/137 Safari/537.36",
        },
    )
    with urllib.request.urlopen(request, timeout=20) as response:
        return json.load(response)


def iso_from_timestamp(value) -> Optional[str]:
    if not value:
        return None
    return dt.datetime.fromtimestamp(float(value), tz=dt.timezone.utc).isoformat().replace("+00:00", "Z")


def shelf_item(book: dict, kind: str, sort_index: int) -> Optional[dict]:
    book_id = book.get("bookId", "")
    title = book.get("title", "")
    if not book_id or not title:
        return None
    if book.get("type") == 11 or book_id.startswith("CB_"):
        return None

    return {
        "id": book_id,
        "title": title,
        "author": book.get("author") or "",
        "coverURL": book.get("cover"),
        "openURL": f"https://weread.qq.com/web/bookDetail/{book_id}",
        "kind": kind,
        "sortIndex": sort_index,
        "updatedAt": iso_from_timestamp(book.get("readUpdateTime") or book.get("updateTime")),
    }


def payload_from_response(response: dict) -> dict:
    items = []
    for book in response.get("books") or []:
        item = shelf_item(book, "book", len(items))
        if item:
            items.append(item)
    for album in response.get("lectureBooks") or []:
        item = shelf_item(album, "album", len(items))
        if item:
            items.append(item)

    return {
        "source": "Chrome 登录态",
        "fetchedAt": dt.datetime.now(dt.timezone.utc).isoformat().replace("+00:00", "Z"),
        "items": items,
    }


def main() -> int:
    if len(sys.argv) != 2:
        print("usage: sync-shelf-cache.py <output-json>", file=sys.stderr)
        return 2

    output_path = Path(sys.argv[1])
    key = chrome_key()

    for cookies_path in chrome_profiles():
        cookies = load_weread_cookies(cookies_path, key)
        if not cookies.get("wr_vid") or not cookies.get("wr_skey"):
            continue
        payload = payload_from_response(fetch_shelf(cookies))
        if not payload["items"]:
            continue
        output_path.parent.mkdir(parents=True, exist_ok=True)
        output_path.write_text(json.dumps(payload, ensure_ascii=False, indent=2, sort_keys=True), encoding="utf-8")
        print(f"Wrote {len(payload['items'])} shelf items to {output_path}")
        return 0

    print("No logged-in WeRead Chrome profile found", file=sys.stderr)
    return 1


if __name__ == "__main__":
    raise SystemExit(main())
