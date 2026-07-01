-- Politiques RLS pour la table licences (déjà existante dans Supabase)
-- Colonnes : id, shop_id, date_installation, date_expiration, est_active, code_activation, type_abonnement

ALTER TABLE licences ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Owners read own licence" ON licences;
DROP POLICY IF EXISTS "Owners insert own licence" ON licences;
DROP POLICY IF EXISTS "Owners update own licence" ON licences;

CREATE POLICY "Owners read own licence"
  ON licences FOR SELECT
  USING (
    shop_id IN (SELECT id FROM shops WHERE owner_id = auth.uid())
  );

CREATE POLICY "Owners insert own licence"
  ON licences FOR INSERT
  WITH CHECK (
    shop_id IN (SELECT id FROM shops WHERE owner_id = auth.uid())
  );

CREATE POLICY "Owners update own licence"
  ON licences FOR UPDATE
  USING (
    shop_id IN (SELECT id FROM shops WHERE owner_id = auth.uid())
  );
