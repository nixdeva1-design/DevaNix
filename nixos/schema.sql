-- DevaNix PostgreSQL schema
-- Wordt automatisch uitgevoerd door systemd bij eerste start

-- pgvector: vector embeddings voor semantisch zoeken (toekomstig gebruik)
CREATE EXTENSION IF NOT EXISTS vector;

-- pg_trgm: GIN index voor snelle tekst zoeken op projectnaam
CREATE EXTENSION IF NOT EXISTS pg_trgm;

-- ── Hoofdtabel: projecten ────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS projecten (
  id           SERIAL       PRIMARY KEY,
  naam         TEXT         UNIQUE NOT NULL,
  api_sleutel  TEXT         NOT NULL,
  omschrijving TEXT,
  talen        TEXT[],                        -- bijv. ["rust","python","html"]
  tags         TEXT[],                        -- vrije tags
  embedding    vector(1536),                  -- voor semantisch zoeken later
  aangemaakt   TIMESTAMPTZ  DEFAULT NOW(),
  bijgewerkt   TIMESTAMPTZ  DEFAULT NOW()
);

-- ── GIN indexes ──────────────────────────────────────────────────────────────

-- Snel zoeken op projectnaam (gedeeltelijke naam werkt ook)
CREATE INDEX IF NOT EXISTS idx_projecten_naam_gin
  ON projecten USING GIN (naam gin_trgm_ops);

-- Snel filteren op programmeertalen
CREATE INDEX IF NOT EXISTS idx_projecten_talen_gin
  ON projecten USING GIN (talen);

-- Snel filteren op tags
CREATE INDEX IF NOT EXISTS idx_projecten_tags_gin
  ON projecten USING GIN (tags);

-- ── Trigger: bijgewerkt automatisch bijwerken ────────────────────────────────
CREATE OR REPLACE FUNCTION update_bijgewerkt()
RETURNS TRIGGER AS $$
BEGIN
  NEW.bijgewerkt = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_projecten_bijgewerkt ON projecten;
CREATE TRIGGER trg_projecten_bijgewerkt
  BEFORE UPDATE ON projecten
  FOR EACH ROW EXECUTE FUNCTION update_bijgewerkt();

-- ── Handige views ────────────────────────────────────────────────────────────

-- Overzicht zonder API-sleutels (veilig om te tonen)
CREATE OR REPLACE VIEW projecten_overzicht AS
  SELECT
    id,
    naam,
    omschrijving,
    talen,
    tags,
    aangemaakt,
    bijgewerkt
  FROM projecten
  ORDER BY bijgewerkt DESC;
