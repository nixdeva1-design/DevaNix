"""
DevaNix API server
Draait als systemd service op NixOS.
Bereikbaar voor HTML op andere apparaten in het LAN.

Start handmatig: uvicorn server:app --host 0.0.0.0 --port 8000 --reload
"""

import os
import psycopg2
import anthropic

from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import HTMLResponse
from pydantic import BaseModel

DB   = os.environ.get("DEVANIX_DB",   "projectkeys")
PORT = int(os.environ.get("DEVANIX_PORT", "8000"))

app = FastAPI(
    title       = "DevaNix",
    description = "Claude API via PostgreSQL sleutelbeheer",
    version     = "0.1.0",
)

app.add_middleware(
    CORSMiddleware,
    allow_origins  = ["*"],   # LAN-toegang — pas aan voor productie
    allow_methods  = ["*"],
    allow_headers  = ["*"],
)


# ── Helpers ──────────────────────────────────────────────────────────────────

def _db():
    return psycopg2.connect(dbname=DB)


def _sleutel(project: str) -> str:
    conn = _db()
    cur  = conn.cursor()
    cur.execute("SELECT api_sleutel FROM projecten WHERE naam = %s", (project,))
    rij = cur.fetchone()
    conn.close()
    if not rij:
        raise HTTPException(404, f"Project '{project}' niet gevonden. "
                                  "Voer 'nieuw-project' uit.")
    return rij[0]


# ── API endpoints ─────────────────────────────────────────────────────────────

class VraagRequest(BaseModel):
    vraag:   str
    project: str


@app.get("/", response_class=HTMLResponse)
async def index():
    """Eenvoudige HTML interface — bereikbaar op elk apparaat in het LAN."""
    return """
<!DOCTYPE html>
<html lang="nl">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>DevaNix</title>
  <style>
    * { box-sizing: border-box; margin: 0; padding: 0; }
    body { font-family: monospace; background: #0f0f0f; color: #e0e0e0;
           max-width: 800px; margin: 0 auto; padding: 2rem; }
    h1 { color: #7dd3fc; margin-bottom: 1.5rem; }
    select, textarea, button {
      width: 100%; padding: .75rem; margin-bottom: 1rem;
      background: #1e1e1e; color: #e0e0e0; border: 1px solid #333;
      border-radius: 4px; font-family: monospace; font-size: 1rem;
    }
    button { background: #1d4ed8; border: none; cursor: pointer; }
    button:hover { background: #2563eb; }
    #antwoord {
      white-space: pre-wrap; background: #1e1e1e; padding: 1rem;
      border-radius: 4px; min-height: 4rem; border: 1px solid #333;
    }
    #laden { color: #7dd3fc; display: none; }
  </style>
</head>
<body>
  <h1>DevaNix</h1>

  <select id="project">
    <option value="">Projecten laden...</option>
  </select>

  <textarea id="vraag" rows="4" placeholder="Stel een vraag..."></textarea>

  <button onclick="stuurVraag()">Verstuur</button>

  <p id="laden">Bezig...</p>
  <div id="antwoord"></div>

  <script>
    async function laadProjecten() {
      const r = await fetch('/projecten');
      const data = await r.json();
      const sel = document.getElementById('project');
      sel.innerHTML = data.map(p =>
        `<option value="${p.naam}">${p.naam}${p.omschrijving ? ' — ' + p.omschrijving : ''}</option>`
      ).join('');
    }

    async function stuurVraag() {
      const project = document.getElementById('project').value;
      const vraag   = document.getElementById('vraag').value.trim();
      if (!project || !vraag) return;

      document.getElementById('laden').style.display = 'block';
      document.getElementById('antwoord').textContent = '';

      const r = await fetch('/vraag', {
        method: 'POST',
        headers: {'Content-Type': 'application/json'},
        body: JSON.stringify({project, vraag})
      });
      const data = await r.json();
      document.getElementById('laden').style.display = 'none';
      document.getElementById('antwoord').textContent =
        r.ok ? data.antwoord : 'Fout: ' + data.detail;
    }

    laadProjecten();
  </script>
</body>
</html>
"""


@app.get("/projecten")
async def lijst_projecten():
    """Alle projecten zonder API-sleutels."""
    conn = _db()
    cur  = conn.cursor()
    cur.execute(
        "SELECT naam, omschrijving, talen, aangemaakt FROM projecten "
        "ORDER BY bijgewerkt DESC"
    )
    rijen = cur.fetchall()
    conn.close()
    return [
        {"naam": r[0], "omschrijving": r[1], "talen": r[2],
         "aangemaakt": str(r[3])}
        for r in rijen
    ]


@app.post("/vraag")
async def vraag_claude(req: VraagRequest):
    """Stel een vraag aan Claude voor een specifiek project."""
    sleutel  = _sleutel(req.project)
    client   = anthropic.Anthropic(api_key=sleutel)
    response = client.messages.create(
        model      = "claude-opus-4-6",
        max_tokens = 4096,
        thinking   = {"type": "adaptive"},
        messages   = [{"role": "user", "content": req.vraag}],
    )
    tekst = "\n".join(b.text for b in response.content if b.type == "text")
    return {"antwoord": tekst, "project": req.project}


@app.get("/project/{naam}")
async def project_info(naam: str):
    """Info over één project (zonder sleutel)."""
    conn = _db()
    cur  = conn.cursor()
    cur.execute(
        "SELECT naam, omschrijving, talen, tags, aangemaakt, bijgewerkt "
        "FROM projecten WHERE naam = %s",
        (naam,)
    )
    rij = cur.fetchone()
    conn.close()
    if not rij:
        raise HTTPException(404, f"Project '{naam}' niet gevonden.")
    return {
        "naam": rij[0], "omschrijving": rij[1], "talen": rij[2],
        "tags": rij[3], "aangemaakt": str(rij[4]), "bijgewerkt": str(rij[5])
    }
