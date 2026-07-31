#!/usr/bin/env python3
"""
Minecraft Web Console — Browser-based server console
Sends commands via named pipe, streams logs in real-time.
"""
import http.server
import json
import os
import subprocess
import threading
import time
from collections import deque
from urllib.parse import parse_qs

# Config
PORT = 8081
MC_PIPE = os.environ.get("MC_PIPE", "/tmp/mc_cmd")
MC_LOG = os.environ.get("MC_LOG", "logs/latest.log")
PASSWORD = os.environ.get("CONSOLE_PASSWORD", "admin123")

# Store last 500 log lines in memory
log_lines = deque(maxlen=500)
log_lock = threading.Lock()


def tail_log():
    """Background thread: tail the Minecraft log file."""
    while not os.path.exists(MC_LOG):
        time.sleep(1)

    with open(MC_LOG, "r") as f:
        # Read existing content
        for line in f:
            with log_lock:
                log_lines.append(line.rstrip())

        # Tail new lines
        while True:
            line = f.readline()
            if line:
                with log_lock:
                    log_lines.append(line.rstrip())
            else:
                time.sleep(0.3)


def send_command(cmd):
    """Send a command to the Minecraft server via named pipe."""
    try:
        with open(MC_PIPE, "w") as pipe:
            pipe.write(cmd + "\n")
            pipe.flush()
        return True
    except Exception as e:
        return str(e)


HTML_PAGE = """<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>Minecraft Console</title>
<style>
  * { margin: 0; padding: 0; box-sizing: border-box; }
  body {
    background: #1a1a2e;
    color: #e0e0e0;
    font-family: 'JetBrains Mono', 'Cascadia Code', 'Fira Code', monospace;
    height: 100vh;
    display: flex;
    flex-direction: column;
  }
  #header {
    background: #16213e;
    padding: 12px 20px;
    border-bottom: 2px solid #0f3460;
    display: flex;
    align-items: center;
    gap: 12px;
  }
  #header h1 {
    font-size: 18px;
    color: #4ecca3;
    font-weight: 600;
  }
  #header .status {
    font-size: 12px;
    color: #888;
  }
  #header .dot {
    width: 8px; height: 8px;
    background: #4ecca3;
    border-radius: 50%;
    display: inline-block;
    animation: pulse 2s infinite;
  }
  @keyframes pulse {
    0%, 100% { opacity: 1; }
    50% { opacity: 0.3; }
  }
  #login {
    display: flex;
    justify-content: center;
    align-items: center;
    height: 100vh;
    flex-direction: column;
    gap: 16px;
  }
  #login input {
    background: #16213e;
    border: 1px solid #0f3460;
    color: #e0e0e0;
    padding: 12px 20px;
    font-size: 16px;
    border-radius: 8px;
    width: 300px;
    font-family: inherit;
  }
  #login button {
    background: #4ecca3;
    color: #1a1a2e;
    border: none;
    padding: 12px 40px;
    font-size: 14px;
    border-radius: 8px;
    cursor: pointer;
    font-weight: 700;
    font-family: inherit;
  }
  #console {
    flex: 1;
    overflow-y: auto;
    padding: 12px 16px;
    font-size: 13px;
    line-height: 1.6;
    scroll-behavior: smooth;
  }
  #console .line { white-space: pre-wrap; word-break: break-all; }
  #console .line.info { color: #4ecca3; }
  #console .line.warn { color: #f5a623; }
  #console .line.error { color: #e74c3c; }
  #console .line.cmd { color: #3498db; font-weight: bold; }
  #input-bar {
    display: flex;
    padding: 12px 16px;
    background: #16213e;
    border-top: 2px solid #0f3460;
    gap: 8px;
  }
  #input-bar span {
    color: #4ecca3;
    font-size: 16px;
    line-height: 40px;
    font-weight: bold;
  }
  #cmd-input {
    flex: 1;
    background: #1a1a2e;
    border: 1px solid #0f3460;
    color: #e0e0e0;
    padding: 8px 14px;
    font-size: 14px;
    font-family: inherit;
    border-radius: 6px;
    outline: none;
  }
  #cmd-input:focus { border-color: #4ecca3; }
  #send-btn {
    background: #4ecca3;
    color: #1a1a2e;
    border: none;
    padding: 8px 20px;
    font-size: 14px;
    border-radius: 6px;
    cursor: pointer;
    font-weight: 700;
    font-family: inherit;
  }
  #send-btn:hover { background: #3dba8f; }
  .quick-cmds {
    padding: 6px 16px;
    background: #16213e;
    display: flex;
    gap: 6px;
    flex-wrap: wrap;
  }
  .quick-cmds button {
    background: #0f3460;
    color: #aaa;
    border: none;
    padding: 4px 12px;
    font-size: 11px;
    border-radius: 4px;
    cursor: pointer;
    font-family: inherit;
  }
  .quick-cmds button:hover { background: #1a4a7a; color: #e0e0e0; }
</style>
</head>
<body>

<div id="login">
  <h1 style="color: #4ecca3; font-size: 24px;">Minecraft Server Console</h1>
  <p style="color: #888;">Enter password to access the console</p>
  <input type="password" id="password" placeholder="Password..." onkeydown="if(event.key==='Enter')login()">
  <button onclick="login()">Connect</button>
</div>

<div id="app" style="display:none; flex-direction:column; height:100vh;">
  <div id="header">
    <span class="dot"></span>
    <h1>Minecraft Console</h1>
    <span class="status">Connected | Auto-refresh: 1s</span>
  </div>
  <div class="quick-cmds">
    <button onclick="sendCmd('list')">list</button>
    <button onclick="sendCmd('tps')">tps</button>
    <button onclick="sendCmd('mem')">memory</button>
    <button onclick="sendCmd('save-all')">save-all</button>
    <button onclick="sendCmd('whitelist list')">whitelist</button>
    <button onclick="sendCmd('op')">op</button>
    <button onclick="sendCmd('gamemode creative')">creative</button>
    <button onclick="sendCmd('gamemode survival')">survival</button>
    <button onclick="sendCmd('time set day')">day</button>
    <button onclick="sendCmd('weather clear')">clear weather</button>
    <button onclick="sendCmd('difficulty peaceful')">peaceful</button>
    <button onclick="sendCmd('stop')">STOP</button>
  </div>
  <div id="console"></div>
  <div id="input-bar">
    <span>&gt;</span>
    <input type="text" id="cmd-input" placeholder="Type a command... (e.g. say Hello)" onkeydown="if(event.key==='Enter')sendCmd()">
    <button id="send-btn" onclick="sendCmd()">Send</button>
  </div>
</div>

<script>
let token = '';
let lastLineCount = 0;

function login() {
  token = document.getElementById('password').value;
  fetch('/api/logs?token=' + encodeURIComponent(token))
    .then(r => { if(r.ok) { document.getElementById('login').style.display='none'; document.getElementById('app').style.display='flex'; startPolling(); } else { alert('Wrong password'); }})
    .catch(() => alert('Connection error'));
}

function startPolling() {
  setInterval(fetchLogs, 1000);
  fetchLogs();
}

function fetchLogs() {
  fetch('/api/logs?token=' + encodeURIComponent(token) + '&since=' + lastLineCount)
    .then(r => r.json())
    .then(data => {
      const con = document.getElementById('console');
      const wasAtBottom = con.scrollTop + con.clientHeight >= con.scrollHeight - 50;
      data.lines.forEach(line => {
        const div = document.createElement('div');
        div.className = 'line';
        if (line.includes('WARN')) div.className += ' warn';
        else if (line.includes('ERROR')) div.className += ' error';
        else if (line.includes('INFO')) div.className += ' info';
        div.textContent = line;
        con.appendChild(div);
      });
      lastLineCount = data.total;
      if (wasAtBottom) con.scrollTop = con.scrollHeight;
    });
}

function sendCmd(cmd) {
  if (!cmd) cmd = document.getElementById('cmd-input').value;
  if (!cmd) return;
  document.getElementById('cmd-input').value = '';

  // Show command in console
  const con = document.getElementById('console');
  const div = document.createElement('div');
  div.className = 'line cmd';
  div.textContent = '> ' + cmd;
  con.appendChild(div);
  con.scrollTop = con.scrollHeight;

  fetch('/api/cmd', {
    method: 'POST',
    headers: {'Content-Type': 'application/json'},
    body: JSON.stringify({cmd: cmd, token: token})
  }).then(r => r.json()).then(data => {
    if (!data.ok) { alert('Error: ' + data.error); }
  });
}
</script>
</body>
</html>
"""


class ConsoleHandler(http.server.BaseHTTPRequestHandler):
    def log_message(self, format, *args):
        pass  # Suppress default logging

    def do_GET(self):
        if self.path == "/" or self.path.startswith("/?"):
            self.send_response(200)
            self.send_header("Content-Type", "text/html")
            self.end_headers()
            self.wfile.write(HTML_PAGE.encode())

        elif self.path.startswith("/api/logs"):
            params = parse_qs(self.path.split("?", 1)[1] if "?" in self.path else "")
            token = params.get("token", [""])[0]
            if token != PASSWORD:
                self.send_response(401)
                self.end_headers()
                return

            since = int(params.get("since", ["0"])[0])
            with log_lock:
                all_lines = list(log_lines)

            new_lines = all_lines[since:] if since < len(all_lines) else []

            self.send_response(200)
            self.send_header("Content-Type", "application/json")
            self.end_headers()
            self.wfile.write(json.dumps({
                "lines": new_lines,
                "total": len(all_lines)
            }).encode())
        else:
            self.send_response(404)
            self.end_headers()

    def do_POST(self):
        if self.path == "/api/cmd":
            length = int(self.headers.get("Content-Length", 0))
            body = json.loads(self.rfile.read(length))

            if body.get("token") != PASSWORD:
                self.send_response(401)
                self.end_headers()
                return

            cmd = body.get("cmd", "").strip()
            if cmd:
                result = send_command(cmd)
                with log_lock:
                    log_lines.append(f"[WebConsole] > {cmd}")

            self.send_response(200)
            self.send_header("Content-Type", "application/json")
            self.end_headers()
            self.wfile.write(json.dumps({"ok": True}).encode())
        else:
            self.send_response(404)
            self.end_headers()


if __name__ == "__main__":
    # Start log tailer
    t = threading.Thread(target=tail_log, daemon=True)
    t.start()

    print(f"Minecraft Web Console running on http://localhost:{PORT}")
    print(f"Log file: {MC_LOG}")
    print(f"Command pipe: {MC_PIPE}")

    server = http.server.HTTPServer(("0.0.0.0", PORT), ConsoleHandler)
    server.serve_forever()
