"""
Claude API client - laadt sleutel automatisch uit .env
Gebruik: python3 claude_client.py "jouw vraag hier"
"""

import sys
import os
from pathlib import Path
from dotenv import load_dotenv
import anthropic

# Laad .env vanuit de projectmap (werkt ook als je het script buiten de map aanroept)
load_dotenv(Path(__file__).parent / ".env")

def vraag_claude(vraag: str) -> str:
    client = anthropic.Anthropic()  # leest ANTHROPIC_API_KEY uit omgevingsvariabelen

    response = client.messages.create(
        model="claude-opus-4-6",
        max_tokens=4096,
        thinking={"type": "adaptive"},
        messages=[{"role": "user", "content": vraag}],
    )

    tekst_blokken = [b.text for b in response.content if b.type == "text"]
    return "\n".join(tekst_blokken)


if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Gebruik: python3 claude_client.py \"jouw vraag\"")
        sys.exit(1)

    vraag = " ".join(sys.argv[1:])
    print(vraag_claude(vraag))
