-- Lignes du panier au moment de la vente (restauration stock à l'annulation)
ALTER TABLE ventes
  ADD COLUMN IF NOT EXISTS lignes_panier JSONB;
