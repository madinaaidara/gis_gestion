-- Prix de revente en gros (par lot = unite_achat) et traçabilité grossiste
-- À exécuter dans l'éditeur SQL Supabase si les colonnes n'existent pas encore.

ALTER TABLE produits
  ADD COLUMN IF NOT EXISTS prix_vente_gros DOUBLE PRECISION;
