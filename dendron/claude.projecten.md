---
id: claude.projecten
title: Claude Projecten
desc: Overzicht van projecten die Claude kent
updated: 1
created: 1
---

# Projecten

Overzicht van alle projecten die via DevaNix beheerd worden.
De volledige lijst staat in PostgreSQL — dit bestand is een leesbare samenvatting.

Haal de live lijst op:
```bash
psql projectkeys -c "SELECT naam, omschrijving, talen, bijgewerkt FROM projecten_overzicht ORDER BY bijgewerkt DESC;"
```

## Actieve projecten

<!-- Projecten worden hier handmatig of via sla-gesprek-op toegevoegd -->

### DevaNix
**Status**: In ontwikkeling
**Beschrijving**: Het systeem dat dit allemaal mogelijk maakt.
**Talen**: Nix, Python, Bash, (toekomstig) Rust
**Repo**: https://github.com/nixdeva1-design/devanix
