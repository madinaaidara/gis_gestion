-- Lier un dossier crédit à la vente d'origine (suivi des remboursements)
ALTER TABLE credits
  ADD COLUMN IF NOT EXISTS vente_id UUID REFERENCES ventes(id) ON DELETE SET NULL;
