#!/usr/bin/env bash
# Claude aanroepen buiten VSCodium — laadt sleutel uit .env
# Gebruik: ./claude.sh "jouw vraag"
# Of maak globaal toegankelijk: sudo ln -s "$(pwd)/claude.sh" /usr/local/bin/claude-ask

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ENV_FILE="$SCRIPT_DIR/.env"

# Laad .env als het bestaat
if [ -f "$ENV_FILE" ]; then
    set -a
    source "$ENV_FILE"
    set +a
fi

if [ -z "$ANTHROPIC_API_KEY" ]; then
    echo "Fout: ANTHROPIC_API_KEY niet ingesteld. Maak een .env bestand aan." >&2
    exit 1
fi

if [ -z "$1" ]; then
    echo "Gebruik: $0 \"jouw vraag\"" >&2
    exit 1
fi

VRAAG="$*"

curl -s https://api.anthropic.com/v1/messages \
    -H "Content-Type: application/json" \
    -H "x-api-key: $ANTHROPIC_API_KEY" \
    -H "anthropic-version: 2023-06-01" \
    -d "{
        \"model\": \"claude-opus-4-6\",
        \"max_tokens\": 4096,
        \"messages\": [{\"role\": \"user\", \"content\": $(echo "$VRAAG" | python3 -c 'import json,sys; print(json.dumps(sys.stdin.read().strip()))')}]
    }" | python3 -c "
import json, sys
data = json.load(sys.stdin)
if 'content' in data:
    for block in data['content']:
        if block.get('type') == 'text':
            print(block['text'])
else:
    print('Fout:', data.get('error', {}).get('message', 'Onbekende fout'), file=sys.stderr)
    sys.exit(1)
"
