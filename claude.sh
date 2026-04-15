#!/usr/bin/env bash
# DevaNix — Claude aanroepen vanuit terminal (buiten VSCodium)
# Sleutel komt uit PostgreSQL of uit omgevingsvariabele
# Gebruik: ./claude.sh "jouw vraag"
#          claude-ask "jouw vraag"   (na sudo ln -s)

set -euo pipefail

if [ -z "${1:-}" ]; then
  echo "Gebruik: $0 \"jouw vraag\""
  exit 1
fi

# Sleutel ophalen: eerst omgevingsvariabele, dan PostgreSQL
if [ -z "${ANTHROPIC_API_KEY:-}" ]; then
  ANTHROPIC_API_KEY=$(get-project-key 2>/dev/null || echo "")
fi

if [ -z "$ANTHROPIC_API_KEY" ]; then
  echo "Fout: geen API-sleutel gevonden." >&2
  echo "Voer 'nieuw-project' uit in de projectmap." >&2
  exit 1
fi

VRAAG="$*"

curl -s https://api.anthropic.com/v1/messages \
  -H "Content-Type: application/json" \
  -H "x-api-key: $ANTHROPIC_API_KEY" \
  -H "anthropic-version: 2023-06-01" \
  -d "$(python3 -c "
import json, sys
print(json.dumps({
  'model': 'claude-opus-4-6',
  'max_tokens': 4096,
  'messages': [{'role': 'user', 'content': sys.argv[1]}]
}))" "$VRAAG")" \
  | python3 -c "
import json, sys
data = json.load(sys.stdin)
if 'content' in data:
    for b in data['content']:
        if b.get('type') == 'text':
            print(b['text'])
else:
    print('Fout:', data.get('error', {}).get('message', 'onbekend'), file=sys.stderr)
    sys.exit(1)
"
