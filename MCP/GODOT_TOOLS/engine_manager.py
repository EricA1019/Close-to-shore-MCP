#!/usr/bin/env python3
"""
Engine Manager: Ensure a local Godot editor binary is available for a given version tag.

Usage:
  python3 MCP/GODOT_TOOLS/engine_manager.py --ensure 4.5-beta5

This downloads from the official mirror and creates symlinks:
  .tools/godot/bin/godot -> .tools/godot/<version>/Godot_<...>
  .tools/godot/bin/godot4.5b5 -> same
"""
import argparse
import os
import sys
import urllib.request
import urllib.error
import shutil
import zipfile
import socket

BASE_DIR = os.path.abspath(os.path.join(os.path.dirname(__file__), '../../..'))
TOOLS_DIR = os.path.join(BASE_DIR, '.tools', 'godot')

def ensure_dirs(path: str):
    os.makedirs(path, exist_ok=True)

def download(url: str, dest: str, timeout: float = 20.0):
    try:
        with urllib.request.urlopen(url, timeout=timeout) as r, open(dest, 'wb') as f:
            shutil.copyfileobj(r, f)
    except (urllib.error.URLError, socket.timeout, OSError) as e:
        print(f"ERROR: Failed to download {url}: {e}", file=sys.stderr)
        raise

def ensure_version(tag: str, timeout: float = 20.0):
    # Expect tags like '4.5-beta5'
    if '-' not in tag:
        print(f"Unexpected tag format: {tag}", file=sys.stderr)
        sys.exit(2)
    version, beta = tag.split('-', 1)
    # Construct tuxfamily URL
    zip_name = f"Godot_v{version}-{beta}_linux.x86_64.zip"
    url = f"https://downloads.tuxfamily.org/godotengine/{version}/{beta}/{zip_name}"

    version_dir = os.path.join(TOOLS_DIR, tag)
    ensure_dirs(version_dir)
    ensure_dirs(os.path.join(TOOLS_DIR, 'bin'))
    zip_path = os.path.join(version_dir, zip_name)
    bin_path = os.path.join(version_dir, f"Godot_v{version}-{beta}_linux.x86_64")

    if not os.path.exists(bin_path):
        print(f"Downloading {url} -> {zip_path}")
        try:
            download(url, zip_path, timeout=timeout)
        except Exception:
            print("HINT: You can provide a local editor binary and link it using --link /path/to/Godot_* --as", file=sys.stderr)
            sys.exit(1)
        print("Extracting zip...")
        with zipfile.ZipFile(zip_path, 'r') as zf:
            zf.extractall(version_dir)
        os.chmod(bin_path, 0o755)
    else:
        print(f"Found existing binary: {bin_path}")

    # Symlinks
    link_default = os.path.join(TOOLS_DIR, 'bin', 'godot')
    link_alias = os.path.join(TOOLS_DIR, 'bin', 'godot4.5b5') if tag == '4.5-beta5' else os.path.join(TOOLS_DIR, 'bin', f'godot-{tag}')
    for link in (link_default, link_alias):
        try:
            if os.path.islink(link) or os.path.exists(link):
                os.remove(link)
        except FileNotFoundError:
            pass
        os.symlink(bin_path, link)
    print(f"Ready: {link_default} -> {bin_path}")


def link_local(path: str, tag: str):
    if not os.path.exists(path):
        print(f"ERROR: Local binary not found: {path}", file=sys.stderr)
        sys.exit(2)
    ensure_dirs(os.path.join(TOOLS_DIR, 'bin'))
    link_default = os.path.join(TOOLS_DIR, 'bin', 'godot')
    link_alias = os.path.join(TOOLS_DIR, 'bin', 'godot4.5b5') if tag == '4.5-beta5' else os.path.join(TOOLS_DIR, 'bin', f'godot-{tag}')
    for link in (link_default, link_alias):
        try:
            if os.path.islink(link) or os.path.exists(link):
                os.remove(link)
        except FileNotFoundError:
            pass
        os.symlink(path, link)
    print(f"Ready: {link_default} -> {path}")


def main():
    p = argparse.ArgumentParser()
    p.add_argument('--ensure', help='Ensure the given Godot version (e.g., 4.5-beta5)')
    p.add_argument('--timeout', type=float, default=float(os.getenv('GODOT_DL_TIMEOUT', '20')), help='Download timeout in seconds (default 20)')
    p.add_argument('--link', help='Path to a local Godot editor binary to link without downloading')
    p.add_argument('--as', dest='as_tag', help='Tag to use for the link (e.g., 4.5-beta6). Used with --link')
    args = p.parse_args()
    if args.link and args.as_tag:
        link_local(args.link, args.as_tag)
        return 0
    if args.ensure:
        ensure_version(args.ensure, timeout=args.timeout)
        return 0
    p.print_help()
    return 1

if __name__ == '__main__':
    sys.exit(main())
