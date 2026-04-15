---
id: claude.ontwerp
title: Claude Ontwerp
desc: Architectuurkeuzes en ontwerpbeslissingen voor DevaNix
updated: 1
created: 1
---

# Ontwerp & Architectuur

Hier staan de grote keuzes die gemaakt zijn tijdens het bouwen van DevaNix.

## Kernprincipes

1. **Sleutels nooit in bestanden** — altijd PostgreSQL via direnv
2. **Top-down denken** — filosofie → structuur → code
3. **Declaratief** — NixOS-stijl: ontwerp is ook uitvoering
4. **Terminal-first** — geen webinterfaces nodig voor beheer

## Dataflow

```
Filosofie (.md, Dendron, Logseq)
    ↓
Gestructureerd datamodel (Datalog)
    ↓  ← Claude helpt hier
NixOS modules + Rust types
    ↓
Rust applicatie + HTML/CSS/JS
```

## Genomen beslissingen

<!-- Voeg hier beslissingen toe -->

### 2025 — PostgreSQL voor sleutelbeheer
**Beslissing**: API sleutels opslaan in PostgreSQL, niet in `.env` bestanden.
**Reden**: Veiliger, centraal beheerd, doorzoekbaar, werkt per project via direnv.
**Gevolg**: `get-project-key` haalt sleutel op, direnv laadt hem automatisch.

### 2025 — Dendron als kennislaag
**Beslissing**: Gesprekken met Claude opslaan als Dendron hiërarchie.
**Reden**: Doorzoekbaar, traceeerbaar, onderdeel van het kennissysteem.
**Gevolg**: `sla-gesprek-op` script schrijft naar `/home/nixos/Dendron-1/`.
