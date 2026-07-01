-- Codes d'activation à usage unique (commercialisation Gis Gestion)
-- Exécuter dans Supabase → SQL Editor

CREATE TABLE IF NOT EXISTS codes_activation (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  code TEXT UNIQUE NOT NULL,
  type_abonnement TEXT NOT NULL DEFAULT 'pro',
  duree_jours INTEGER NOT NULL DEFAULT 365,
  est_utilise BOOLEAN NOT NULL DEFAULT FALSE,
  shop_id UUID REFERENCES shops(id) ON DELETE SET NULL,
  date_utilisation TIMESTAMPTZ,
  date_expiration_code TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_codes_activation_code ON codes_activation (UPPER(code));
CREATE INDEX IF NOT EXISTS idx_codes_activation_utilise ON codes_activation (est_utilise) WHERE est_utilise = FALSE;

-- Une seule licence par boutique
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint WHERE conname = 'licences_shop_id_key'
  ) THEN
    ALTER TABLE licences ADD CONSTRAINT licences_shop_id_key UNIQUE (shop_id);
  END IF;
END $$;

ALTER TABLE codes_activation ENABLE ROW LEVEL SECURITY;

-- Les clients n'accèdent pas directement aux codes : activation via fonction RPC uniquement
DROP POLICY IF EXISTS "No direct access codes" ON codes_activation;

-- Fonction sécurisée : 1 code = 1 boutique, puis code marqué utilisé
CREATE OR REPLACE FUNCTION activer_code_licence(p_shop_id UUID, p_code TEXT)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_code codes_activation%ROWTYPE;
  v_exp TIMESTAMPTZ;
  v_base TIMESTAMPTZ;
  v_current_exp TIMESTAMPTZ;
  v_normalized TEXT;
BEGIN
  v_normalized := UPPER(TRIM(p_code));

  IF v_normalized = '' THEN
    RETURN jsonb_build_object('success', false, 'error', 'Code vide');
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM shops WHERE id = p_shop_id AND owner_id = auth.uid()
  ) THEN
    RETURN jsonb_build_object('success', false, 'error', 'Boutique non autorisée');
  END IF;

  SELECT * INTO v_code
  FROM codes_activation
  WHERE UPPER(code) = v_normalized AND est_utilise = FALSE
  FOR UPDATE;

  IF NOT FOUND THEN
    RETURN jsonb_build_object('success', false, 'error', 'Code invalide ou déjà utilisé');
  END IF;

  IF v_code.date_expiration_code IS NOT NULL AND v_code.date_expiration_code < NOW() THEN
    RETURN jsonb_build_object('success', false, 'error', 'Ce code a expiré');
  END IF;

  SELECT date_expiration INTO v_current_exp FROM licences WHERE shop_id = p_shop_id;

  v_base := GREATEST(COALESCE(v_current_exp, NOW()), NOW());
  v_exp := v_base + (v_code.duree_jours || ' days')::INTERVAL;

  INSERT INTO licences (
    shop_id, date_installation, date_expiration, est_active, code_activation, type_abonnement
  ) VALUES (
    p_shop_id, NOW(), v_exp, TRUE, v_normalized, v_code.type_abonnement
  )
  ON CONFLICT (shop_id) DO UPDATE SET
    date_expiration = EXCLUDED.date_expiration,
    est_active = TRUE,
    code_activation = EXCLUDED.code_activation,
    type_abonnement = EXCLUDED.type_abonnement;

  UPDATE codes_activation SET
    est_utilise = TRUE,
    shop_id = p_shop_id,
    date_utilisation = NOW()
  WHERE id = v_code.id;

  RETURN jsonb_build_object(
    'success', true,
    'type_abonnement', v_code.type_abonnement,
    'date_expiration', v_exp
  );
END;
$$;

GRANT EXECUTE ON FUNCTION activer_code_licence(UUID, TEXT) TO authenticated;

-- Exemples de codes TEST (usage unique — générez-en d'autres après chaque vente)
INSERT INTO codes_activation (code, type_abonnement, duree_jours) VALUES
  ('GIS-TEST-PRO-001', 'pro', 365),
  ('GIS-TEST-PRO-002', 'pro', 365),
  ('GIS-TEST-ANNUEL-001', 'annuel', 365),
  ('GIS-TEST-MOIS-001', 'pro', 30)
ON CONFLICT (code) DO NOTHING;

-- Comment générer un code pour un client payant :
-- INSERT INTO codes_activation (code, type_abonnement, duree_jours)
-- VALUES ('GIS-' || upper(substr(md5(random()::text), 1, 8)), 'pro', 365);
