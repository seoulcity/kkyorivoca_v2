-- Begin transaction
BEGIN;

-- Update existing policy version to not current
UPDATE public.policy_versions
SET is_current = FALSE
WHERE policy_type = '${POLICY_TYPE}' AND is_current = TRUE;

-- Insert new policy version
INSERT INTO public.policy_versions 
  (policy_type, version, published_at, is_current)
VALUES 
  ('${POLICY_TYPE}', '${NEW_VERSION}', NOW(), TRUE);

-- End transaction
COMMIT; 