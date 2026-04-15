---
id: claude
title: Claude
desc: Alles over Claude AI — gesprekken, ontwerp, projecten
updated: 1
created: 1
---

# Claude

Dit is de root node voor alle Claude-gerelateerde notities in Dendron.

## Hiërarchie

- [[claude.gesprekken]] — Alle opgeslagen gesprekken per datum
- [[claude.ontwerp]] — Architectuurkeuzes en ontwerpbeslissingen
- [[claude.projecten]] — Overzicht van projecten die Claude kent

## Hoe werkt dit?

Elk gesprek met Claude Code wordt automatisch opgeslagen als een Dendron bestand
via het script `sla-gesprek-op`. Gebruik het zo:

```bash
sla-gesprek-op "Onderwerp van het gesprek" "Samenvatting van wat besproken is"
```

Of voor een volledig gesprek:

```bash
sla-gesprek-op --interactief
```

De bestanden worden aangemaakt in:
```
/home/nixos/Dendron-1/
├── claude.md                          ← dit bestand
├── claude.gesprekken.md               ← index van gesprekken
├── claude.gesprekken.2025-01-15.md    ← gesprek op die datum
├── claude.ontwerp.md                  ← ontwerpbeslissingen
└── claude.projecten.md                ← projectoverzicht
```
