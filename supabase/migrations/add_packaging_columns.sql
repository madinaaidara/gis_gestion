-- Colonnes optionnelles pour conditionnement à 3 niveaux (ex: paquet > sachet > pièce)
-- À exécuter dans l'éditeur SQL Supabase si les colonnes n'existent pas encore.

ALTER TABLE produits
  ADD COLUMN IF NOT EXISTS unite_intermediaire TEXT,
  ADD COLUMN IF NOT EXISTS quantite_base_par_intermediaire DOUBLE PRECISION,
  ADD COLUMN IF NOT EXISTS quantite_intermediaire_par_lot DOUBLE PRECISION;
