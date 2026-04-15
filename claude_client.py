"""
DevaNix Claude client
Laadt de API-sleutel uit PostgreSQL op basis van de projectnaam.

Gebruik:
  python3 claude_client.py "jouw vraag"
  python3 claude_client.py --project mijn-project "jouw vraag"

Vanuit andere code:
  from claude_client import vraag_claude
  antwoord = vraag_claude("Jouw vraag")
"""

import sys
import os
import subprocess
from pathlib import Path

import psycopg2
import anthropic


def _project_naam() -> str:
    """Bepaal projectnaam: eerst $DEVANIX_PROJECT, dan git root, dan mapnaam."""
    if os.environ.get("DEVANIX_PROJECT"):
        return os.environ["DEVANIX_PROJECT"]
    try:
        result = subprocess.run(
            ["git", "rev-parse", "--show-toplevel"],
            capture_output=True, text=True, check=True
        )
        return Path(result.stdout.strip()).name
    except subprocess.CalledProcessError:
        return Path.cwd().name


def _haal_sleutel(project: str) -> str:
    """Haal API-sleutel op uit PostgreSQL."""

    # Eerste keus: omgevingsvariabele (al gezet door direnv)
    if os.environ.get("ANTHROPIC_API_KEY"):
        return os.environ["ANTHROPIC_API_KEY"]

    db = os.environ.get("DEVANIX_DB", "projectkeys")
    try:
        conn = psycopg2.connect(dbname=db)
        cur  = conn.cursor()
        cur.execute(
            "SELECT api_sleutel FROM projecten WHERE naam = %s",
            (project,)
        )
        rij = cur.fetchone()
        conn.close()
    except psycopg2.OperationalError as e:
        raise RuntimeError(
            f"PostgreSQL niet bereikbaar. "
            f"Is de devanix-service actief? (systemctl status postgresql)\n{e}"
        ) from e

    if not rij:
        raise ValueError(
            f"Geen API-sleutel gevonden voor project '{project}'. "
            f"Voer 'nieuw-project' uit in de projectmap."
        )
    return rij[0]


def vraag_claude(
    vraag: str,
    project: str | None = None,
    model: str = "claude-opus-4-6",
    max_tokens: int = 4096,
) -> str:
    """Stel een vraag aan Claude. Retourneert de tekst van het antwoord."""
    project = project or _project_naam()
    sleutel = _haal_sleutel(project)

    client = anthropic.Anthropic(api_key=sleutel)
    response = client.messages.create(
        model=model,
        max_tokens=max_tokens,
        thinking={"type": "adaptive"},
        messages=[{"role": "user", "content": vraag}],
    )
    return "\n".join(b.text for b in response.content if b.type == "text")


if __name__ == "__main__":
    import argparse

    parser = argparse.ArgumentParser(description="Stel een vraag aan Claude")
    parser.add_argument("vraag", nargs="+", help="De vraag")
    parser.add_argument("--project", "-p", help="Projectnaam (optioneel)")
    args = parser.parse_args()

    print(vraag_claude(" ".join(args.vraag), project=args.project))
