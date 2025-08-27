import os
import sys
import json
import subprocess
import urllib.parse
from typing import Tuple, Optional
from http.server import BaseHTTPRequestHandler, HTTPServer

# Add the current directory to Python path for imports
sys.path.append(os.path.dirname(__file__))

# -------------------------
# Shared config and helpers
# -------------------------

PROJECT_ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), '..', '..'))
GODOT_PROJECT = os.path.join(PROJECT_ROOT, 'godot_project')

def _cts_path() -> str:
    # Prefer local build, fallback to cts in PATH
    local = os.path.join(PROJECT_ROOT, 'rust', 'target', 'release', 'cts')
    return local if os.path.exists(local) else 'cts'

def _run_cts(args: list[str], timeout_sec: int = 30) -> Tuple[int, str, str]:
    cmd = [_cts_path()] + args
    try:
        p = subprocess.run(
            cmd,
            cwd=PROJECT_ROOT,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            timeout=timeout_sec,
            check=False,
            text=True
        )
        return p.returncode, p.stdout, p.stderr
    except subprocess.TimeoutExpired:
        return 124, '', 'Timeout executing cts command'
    except FileNotFoundError as e:
        return 127, '', f'Executable not found: {e}'

def _parse_json_line(s: str) -> Optional[dict]:
    # Try last JSON-looking line
    for line in reversed(s.splitlines()):
        t = line.strip()
        if t.startswith('{') and t.endswith('}'):
            try:
                return json.loads(t)
            except Exception:
                continue
    # Fallback: whole string as JSON
    try:
        return json.loads(s)
    except Exception:
        return None

class MCPHandler(BaseHTTPRequestHandler):
    def _send_json(self, obj, code: int = 200):
        data = json.dumps(obj).encode('utf-8')
        self.send_response(code)
        self.send_header('Content-Type', 'application/json')
        self.send_header('Content-Length', str(len(data)))
        self.end_headers()
        self.wfile.write(data)

    def do_GET(self):
        parsed = urllib.parse.urlparse(self.path)
        path = parsed.path
        qs = urllib.parse.parse_qs(parsed.query)
        if path == '/status':
            self._send_json({'status': 'MCP server running', 'project': 'Godot MCP Template', 'mode': 'stdlib'})
            return
        if path == '/db/collections':
            roots = qs.get('roots', ['res://data,res://addons/resource_databases'])[0]
            code, out, err = _run_cts(['db', 'list', '--project-root', PROJECT_ROOT, '--roots', roots])
            data = _parse_json_line(out) or {}
            if code != 0:
                self._send_json({'error': 'cts failed', 'stderr': err, 'stdout': out}, 500)
            else:
                self._send_json(data)
            return
        if path == '/db/search':
            q = qs.get('q', [''])[0]
            if not q:
                self._send_json({'error': 'missing q'}, 400)
                return
            roots = qs.get('roots', ['res://data,res://addons/resource_databases'])[0]
            collection = qs.get('collection', [None])[0]
            limit = qs.get('limit', [None])[0]
            args = ['db', 'search', '--project-root', PROJECT_ROOT, '--query', q, '--roots', roots]
            if collection is not None:
                args += ['--collection', collection]
            if limit is not None:
                args += ['--limit', limit]
            code, out, err = _run_cts(args)
            data = _parse_json_line(out) or {}
            if code != 0:
                self._send_json({'error': 'cts failed', 'stderr': err, 'stdout': out}, 500)
            else:
                self._send_json(data)
            return
        if path == '/db/index/stats':
            roots = qs.get('roots', ['res://data,res://addons/resource_databases'])[0]
            stats_out = os.path.join(PROJECT_ROOT, 'logs', 'db_index_stats.json')
            args = ['db', 'index', '--project-root', PROJECT_ROOT, '--roots', roots, '--stats-out', stats_out]
            code, out, err = _run_cts(args)
            if os.path.exists(stats_out):
                try:
                    with open(stats_out, 'r', encoding='utf-8') as f:
                        self._send_json(json.load(f))
                        return
                except Exception as e:
                    self._send_json({'error': f'failed to read stats: {e}'}, 500)
                    return
            data = _parse_json_line(out) or {}
            if code != 0:
                self._send_json({'error': 'cts failed', 'stderr': err, 'stdout': out}, 500)
            else:
                self._send_json(data)
            return
        # 404 for anything else
        self._send_json({'error': 'not found', 'path': path}, 404)

    def do_POST(self):
        parsed = urllib.parse.urlparse(self.path)
        path = parsed.path
        length = int(self.headers.get('Content-Length', '0') or '0')
        body_raw = self.rfile.read(length) if length > 0 else b''
        try:
            body = json.loads(body_raw.decode('utf-8') or '{}')
        except Exception:
            body = {}
        if path == '/db/export':
            roots = body.get('roots', 'res://data,res://addons/resource_databases')
            out_path = body.get('out')
            args = ['db', 'export', '--project-root', PROJECT_ROOT, '--roots', roots]
            if out_path:
                args += ['--out', out_path]
            code, out, err = _run_cts(args)
            data = _parse_json_line(out) or {}
            if code != 0:
                self._send_json({'error': 'cts failed', 'stderr': err, 'stdout': out}, 500)
            else:
                self._send_json(data)
            return
        if path == '/db/validate':
            roots = body.get('roots', 'res://data,res://addons/resource_databases')
            strict = body.get('strict', False)
            args = ['db', 'validate', '--project-root', PROJECT_ROOT, '--roots', roots]
            if strict:
                args.append('--strict')
            code, out, err = _run_cts(args)
            data = _parse_json_line(out) or {}
            status = 200 if code == 0 else 422
            if code != 0:
                data = {'error': 'validation failed', 'report': data, 'stderr': err}
            self._send_json(data, status)
            return
        self._send_json({'error': 'not found', 'path': path}, 404)

if __name__ == '__main__':
    port = int(os.environ.get('PORT', '5000'))
    server = HTTPServer(('0.0.0.0', port), MCPHandler)
    print(f"[MCP] stdlib server running on http://localhost:{port}")
    try:
        server.serve_forever()
    except KeyboardInterrupt:
        pass
    server.server_close()
