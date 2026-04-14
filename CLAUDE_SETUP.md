# Claude Code instellen in VSCodium

## 1. API-sleutel instellen

```bash
cp .env.example .env
# Bewerk .env en vul je sleutel in:
# ANTHROPIC_API_KEY=sk-ant-...
```

Haal je sleutel op via: https://console.anthropic.com/settings/keys

---

## 2. Python-afhankelijkheden installeren

```bash
pip install -r requirements.txt
```

---

## 3. Claude aanroepen vanuit code (Python)

```python
from claude_client import vraag_claude

antwoord = vraag_claude("Leg Pythons list comprehensions uit")
print(antwoord)
```

Of direct via terminal:

```bash
python3 claude_client.py "Leg Pythons list comprehensions uit"
```

---

## 4. Claude aanroepen buiten VSCodium (shell)

```bash
chmod +x claude.sh
./claude.sh "Wat is de hoofdstad van Nederland?"
```

Globaal beschikbaar maken (optioneel):

```bash
sudo ln -s "$(pwd)/claude.sh" /usr/local/bin/claude-ask
# Daarna overal aanroepen:
claude-ask "Hoe werkt recursie?"
```

---

## 5. Claude Code CLI in VSCodium

Claude Code is al geïnstalleerd (`/opt/node22/bin/claude`).

### Eenmalig instellen

Stel de API-sleutel in voor de huidige shell-sessie:

```bash
export ANTHROPIC_API_KEY="sk-ant-..."
```

Of voeg toe aan `~/.bashrc` / `~/.zshrc` voor permanent:

```bash
echo 'export ANTHROPIC_API_KEY="sk-ant-..."' >> ~/.bashrc
source ~/.bashrc
```

### Starten in VSCodium

Open de geïntegreerde terminal in VSCodium (`Ctrl+`` `) en typ:

```bash
claude
```

### VSCodium extensie (Open VSX)

VSCodium gebruikt de Open VSX marketplace. Zoek naar:
- **Claude Dev** (saoudrizwan.claude-dev) via `ext install saoudrizwan.claude-dev`
- Of installeer handmatig via `.vsix` bestand van de Open VSX marketplace

---

## Bestandsoverzicht

| Bestand | Doel |
|---|---|
| `.env` | API-sleutel (nooit in git zetten!) |
| `.env.example` | Template voor `.env` |
| `claude_client.py` | Python-client met `.env` ondersteuning |
| `claude.sh` | Shell-script voor gebruik buiten VSCodium |
| `requirements.txt` | Python-afhankelijkheden |
