# DevaNix — Installatie op NixOS

## Wat wordt geïnstalleerd

- PostgreSQL 15 met pgvector + GIN indexes (sleutels per project)
- direnv (automatisch laden per map)
- `nieuw-project` commando (terminal + VSCodium)
- `get-project-key` helper
- API server op poort 8000 (bereikbaar op telefoon/ander apparaat)

---

## Stap 1 — Repo clonen

```bash
git clone <repo-url> ~/DevaNix
cd ~/DevaNix
```

---

## Stap 2 — NixOS module activeren

Open je NixOS configuratie:

```bash
sudo nano /etc/nixos/configuration.nix
```

Voeg toe bovenaan het bestand:

```nix
imports = [
  ./hardware-configuration.nix
  /home/JOUWGEBRUIKER/DevaNix/nixos/claude-dev.nix   # ← voeg dit toe
];
```

Voeg toe in de `{ config, pkgs, ... }:` sectie:

```nix
services.devanix = {
  enable     = true;
  gebruiker  = "JOUWGEBRUIKER";   # ← jouw gebruikersnaam (uitvoer van: whoami)
};
```

---

## Stap 3 — Scripts beschikbaar maken

```bash
sudo ln -sf ~/DevaNix/scripts/nieuw-project   /usr/local/bin/nieuw-project
sudo ln -sf ~/DevaNix/scripts/get-project-key /usr/local/bin/get-project-key
sudo ln -sf ~/DevaNix/scripts/setup-dendron   /usr/local/bin/setup-dendron
sudo ln -sf ~/DevaNix/scripts/sla-gesprek-op  /usr/local/bin/sla-gesprek-op
sudo ln -sf ~/DevaNix/claude.sh               /usr/local/bin/claude-ask
```

---

## Stap 4 — NixOS opnieuw opbouwen

```bash
sudo nixos-rebuild switch
```

Dit doet automatisch:
- PostgreSQL starten
- Database schema aanmaken
- direnv activeren
- API server starten als systemd service

---

## Stap 5 — Dendron integratie instellen

Zorg dat je Dendron workspace bestaat (standaard aangemaakt door de Dendron extensie in VSCodium).

```bash
# Maak de Claude node structuur aan in Dendron
setup-dendron

# Koppel ook het sla-gesprek-op script
sudo ln -sf ~/DevaNix/scripts/sla-gesprek-op /usr/local/bin/sla-gesprek-op
sudo ln -sf ~/DevaNix/scripts/setup-dendron  /usr/local/bin/setup-dendron
```

Als je Dendron workspace op een ander pad staat:
```bash
setup-dendron /jouw/pad/naar/dendron
```

Na het uitvoeren staan er vier nieuwe bestanden in je Dendron workspace:
- `claude.md` — navigatiepunt voor alles over Claude
- `claude.gesprekken.md` — index van opgeslagen gesprekken
- `claude.ontwerp.md` — architectuurkeuzes
- `claude.projecten.md` — projectoverzicht

---

## Stap 6 — VSCodium instellingen kopiëren

```bash
mkdir -p ~/.config/VSCodium/User
cp ~/DevaNix/vscodium/settings.json ~/.config/VSCodium/User/settings.json
```

Installeer de direnv extensie in VSCodium:

Open VSCodium → Ctrl+Shift+X → zoek: `direnv` → installeer **mkhl.direnv**

---

## Stap 7 — Eerste project aanmaken

```bash
mkdir ~/mijn-eerste-project
cd ~/mijn-eerste-project
git init
nieuw-project
```

Het script:
1. Vraagt of je een nieuwe of bestaande sleutel wilt
2. Opent de browser naar Anthropic console (als nieuw)
3. Slaat de sleutel op in PostgreSQL
4. Maakt `.envrc` aan voor direnv

---

## Gebruik

### In VSCodium terminal

```bash
cd ~/mijn-project      # direnv laadt sleutel automatisch
python3 ~/DevaNix/claude_client.py "Wat is Rust?"
```

### Vanuit eigen Python code

```python
import sys
sys.path.insert(0, '/home/JOUWGEBRUIKER/DevaNix')
from claude_client import vraag_claude

antwoord = vraag_claude("Leg Rust ownership uit")
print(antwoord)
```

### Vanuit terminal (buiten VSCodium)

```bash
claude-ask "Wat is NixOS?"
```

### Vanaf telefoon of ander apparaat in LAN

Zoek je IP-adres:

```bash
ip addr | grep "inet " | grep -v 127
```

Open op je telefoon: `http://JOUW-IP:8000`

Je ziet een overzicht van je projecten en kunt vragen stellen.

---

## Structuur

```
DevaNix/
├── nixos/
│   ├── claude-dev.nix     NixOS module
│   └── schema.sql         PostgreSQL schema
├── scripts/
│   ├── nieuw-project      Project instellen
│   ├── get-project-key    Sleutel ophalen uit DB
│   ├── setup-dendron      Claude node aanmaken in Dendron
│   └── sla-gesprek-op     Gesprek opslaan als Dendron bestand
├── dendron/
│   ├── claude.md                    Template root node
│   ├── claude.gesprekken.md         Template gesprekken index
│   ├── claude.ontwerp.md            Template architectuurkeuzes
│   └── claude.projecten.md          Template projectoverzicht
├── vscodium/
│   └── settings.json      VSCodium instellingen
├── claude_client.py       Python client
├── claude.sh              Shell script
└── server.py              API server voor LAN
```

---

## Controleren of alles werkt

```bash
# PostgreSQL draait?
systemctl status postgresql

# Server draait?
systemctl status devanix-server

# Sleutel zichtbaar voor huidig project?
get-project-key

# Server bereikbaar?
curl http://localhost:8000/projecten
```
