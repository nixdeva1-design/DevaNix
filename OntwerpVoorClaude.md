# DevaNix — Ontwerp voor Claude

Dit bestand wordt automatisch gelezen door Claude Code bij elke nieuwe sessie.
Lees dit volledig voordat je iets bouwt of antwoordt.

---

## Wie ik ben

Ik ben de eigenaar van dit project en werk op **NixOS** met **Neovim** en **VSCodium**.
Ik ben nieuw in het programmeren maar denk architecturaal — van groot naar klein.
Ik wil bouwen zonder webinterfaces, alles via terminal en code.
Gebruikersnaam op het systeem: `nixos`

---

## De kernvisie

### Ontwerp als code — top-down bouwen

Het idee: schrijf eerst de filosofie en het ontwerp in gewone taal (Markdown),
verfijn dat naar een gestructureerd datamodel (Datalog), en laat dat de
directe bron zijn van uitvoerbare code. Geïnspireerd door hoe NixOS werkt:
`.nix` bestanden zijn tegelijk ontwerp én uitvoering van het systeem.

```
Filosofie (.md, Dendron, Logseq)
    ↓
Gestructureerd datamodel (Datalog)
    ↓  ← Claude helpt hier met vertaling
NixOS modules + Rust types
    ↓
Rust applicatie + HTML/CSS/JS
```

### Het principe

De frictie tussen ontwerp en code lost op wanneer het ontwerp al de structuur
heeft van code — maar nog leesbaar is als taal. NixOS bewijst dat dit werkt
voor infrastructuur. DevaNix past dit toe op het hele ontwikkelproces.

---

## Technische keuzes

| Laag | Tool | Waarom |
|---|---|---|
| Besturingssysteem | NixOS | Declaratief, reproduceerbaar |
| Editor | Neovim + VSCodium | Terminal-first |
| Kennis & ontwerp | Dendron + Logseq | Hiërarchisch, Markdown-gebaseerd |
| Datamodel | Datalog | Declaratief, relaties als logica |
| Sleutelbeheer | PostgreSQL + pgvector | Per project, lokaal, doorzoekbaar |
| Omgevingsvariabelen | direnv | Automatisch laden per map |
| Backend | Rust | Veilig, snel, systeemniveau |
| Frontend | HTML + CSS + JS | Eenvoudig, bereikbaar op elk apparaat |
| AI | Claude (deze) | Via CLI, Python, shell en API server |

---

## Wat er al gebouwd is

### `nixos/claude-dev.nix`
NixOS module die het hele systeem configureert:
- PostgreSQL 15 met pgvector extensie
- direnv met nix-direnv
- Systemd service voor de API server
- Automatisch schema initialiseren bij eerste start

Activeren in `/etc/nixos/configuration.nix`:
```nix
imports = [ /home/nixos/DevaNix/nixos/claude-dev.nix ];
services.devanix = { enable = true; gebruiker = "nixos"; };
```

### `nixos/schema.sql`
PostgreSQL tabel `projecten` met:
- GIN index op naam (snel zoeken op gedeeltelijke naam)
- GIN index op talen en tags (filteren)
- pgvector kolom voor semantisch zoeken (toekomstig gebruik)
- Automatische `bijgewerkt` timestamp trigger

### `scripts/nieuw-project`
Interactief commando voor elk nieuw project:
- Detecteert projectnaam via git root of mapnaam
- Zoekt op in PostgreSQL: nieuw of bestaand?
- Vraagt handmatige goedkeuring bij nieuwe sleutel
- Opent browser naar Anthropic console
- Slaat sleutel op in PostgreSQL (nooit in een bestand)
- Schrijft `.envrc` die direnv gebruikt

### `scripts/get-project-key`
Helper die de sleutel ophaalt uit PostgreSQL op basis van
de huidige git-map. Wordt aangeroepen door `.envrc`.

### `claude_client.py`
Python client die:
- Sleutel ophaalt uit `$ANTHROPIC_API_KEY` (via direnv) of direct uit PostgreSQL
- Claude Opus 4.6 aanroept met adaptive thinking
- Werkt als module (`from claude_client import vraag_claude`)
- Werkt als CLI (`python3 claude_client.py "vraag"`)

### `server.py`
FastAPI server op poort 8000:
- Bereikbaar op het lokale netwerk (telefoon, tablet)
- HTML interface op `/` — geen app nodig op het andere apparaat
- `/projecten` — lijst alle projecten zonder sleutels
- `/vraag` — stel een vraag aan Claude voor een project
- `/project/{naam}` — info over één project

### `claude.sh`
Shell script voor Claude aanroepen zonder Python:
```bash
claude-ask "jouw vraag"
```

### `vscodium/settings.json`
VSCodium instellingen met direnv integratie.

### `dendron/` — Dendron templates
Templates voor de Claude node hiërarchie in Dendron:
- `claude.md` — root node
- `claude.gesprekken.md` — gesprekken index
- `claude.ontwerp.md` — architectuurkeuzes
- `claude.projecten.md` — projectoverzicht

### `scripts/setup-dendron`
Eenmalig script dat de Claude node structuur aanmaakt in de Dendron workspace:
```bash
setup-dendron                          # gebruikt /home/nixos/Dendron-1
setup-dendron /ander/pad/naar/dendron  # aangepast pad
```
Kopieert de templates naar de Dendron workspace zonder bestaande bestanden te overschrijven.

### `scripts/sla-gesprek-op`
Slaat een gesprek op als Dendron bestand:
```bash
sla-gesprek-op "Onderwerp" "Samenvatting"
sla-gesprek-op --interactief
```
Maakt `claude.gesprekken.YYYY-MM-DD.md` aan in de Dendron workspace
en voegt een regel toe aan `claude.gesprekken.md` (de index).

---

## Dendron workspace

Locatie: `/home/nixos/Dendron-1/`
Config: `/home/nixos/Dendron-1/dendron.yml`

### Claude node structuur
```
Dendron-1/
├── claude.md                          ← root, navigatiepunt
├── claude.gesprekken.md               ← index van alle gesprekken
├── claude.gesprekken.2025-01-15.md    ← gesprek op die datum (auto-aangemaakt)
├── claude.ontwerp.md                  ← architectuurkeuzes
└── claude.projecten.md                ← projectoverzicht
```

### Gesprek opslaan na een sessie
```bash
sla-gesprek-op "Wat we besproken hebben" "Korte samenvatting"
# of interactief:
sla-gesprek-op --interactief
```

---

## Hoe direnv werkt in dit systeem

```
cd project-x/
    ↓
direnv leest .envrc
    ↓
.envrc roept get-project-key aan
    ↓
get-project-key vraagt PostgreSQL: "sleutel voor project-x?"
    ↓
ANTHROPIC_API_KEY wordt automatisch geladen in de shell
    ↓
VSCodium terminal + Neovim + Python scripts hebben de sleutel
```

Geen sleutel staat ooit in een bestand — alleen in PostgreSQL.

---

## Wat nog gebouwd moet worden

### Prioriteit 1 — Systeem werkend krijgen
- [ ] Installatie op de echte NixOS machine doorlopen
- [ ] Eerste project aanmaken met `nieuw-project`
- [ ] Testen: `curl http://localhost:8000/projecten`
- [ ] Telefoon verbinden met de API server

### Prioriteit 2 — Dendron integratie
- [x] Claude node structuur aanmaken als templates in `dendron/`
- [x] `setup-dendron` script bouwen voor eenmalige installatie
- [x] `sla-gesprek-op` script bouwen voor gesprekken opslaan
- [ ] `setup-dendron` uitvoeren op de echte NixOS machine (`/home/nixos/Dendron-1`)
- [ ] `sudo ln -sf ~/DevaNix/scripts/sla-gesprek-op /usr/local/bin/sla-gesprek-op`
- [ ] Dendron workspace koppelen aan DevaNix projectstructuur
- [ ] Ontwerp-notities traceerbaar naar code

### Prioriteit 3 — Datalog laag
- [ ] Datalog schema per project definiëren in Markdown
- [ ] Claude vertaalt Datalog assertions naar Rust types
- [ ] Bidirectionele traceerbaarheid ontwerp ↔ code

### Prioriteit 4 — Rust applicaties
- [ ] Eerste Rust project bouwen vanuit een Dendron ontwerp
- [ ] NixOS flake per project voor reproduceerbare builds
- [ ] Rust types gegenereerd vanuit Datalog schema

### Prioriteit 5 — Multi-device
- [ ] Versleutelde sync van PostgreSQL naar ander apparaat
- [ ] Telefoon als volwaardige interface via de API server

---

## Hoe Claude hier moet werken

- Bouw altijd **van boven naar beneden**: filosofie → structuur → code
- Sla ideeën op in dit bestand als ze veranderen
- Elk nieuw project krijgt een eigen sectie in Dendron
- Geen `.env` bestanden — altijd PostgreSQL via direnv
- Commits in het Nederlands met duidelijke beschrijving
- Vraag om goedkeuring bij grote architectuurkeuzes

---

## Installatie samengevat (voor nieuwe sessie)

```bash
git clone https://github.com/nixdeva1-design/devanix ~/DevaNix
cd ~/DevaNix
sudo ln -sf ~/DevaNix/scripts/nieuw-project   /usr/local/bin/nieuw-project
sudo ln -sf ~/DevaNix/scripts/get-project-key /usr/local/bin/get-project-key
sudo ln -sf ~/DevaNix/scripts/setup-dendron   /usr/local/bin/setup-dendron
sudo ln -sf ~/DevaNix/scripts/sla-gesprek-op  /usr/local/bin/sla-gesprek-op
sudo ln -sf ~/DevaNix/claude.sh               /usr/local/bin/claude-ask
setup-dendron   # maakt claude node aan in /home/nixos/Dendron-1
# Voeg NixOS module toe aan /etc/nixos/configuration.nix
sudo nixos-rebuild switch
```
