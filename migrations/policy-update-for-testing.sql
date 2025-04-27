-- Begin transaction
BEGIN;

-- Update existing privacy policy version to not current
UPDATE public.policy_versions
SET is_current = FALSE
WHERE policy_type = 'privacy_policy' AND is_current = TRUE;

-- Insert new privacy policy version
INSERT INTO public.policy_versions 
  (policy_type, version, published_at, is_current)
VALUES 
  ('privacy_policy', '1.1', NOW(), TRUE);

-- Update existing terms of service version to not current
UPDATE public.policy_versions
SET is_current = FALSE
WHERE policy_type = 'terms_of_service' AND is_current = TRUE;

-- Insert new terms of service version
INSERT INTO public.policy_versions 
  (policy_type, version, published_at, is_current)
VALUES 
  ('terms_of_service', '1.1', NOW(), TRUE);

-- End transaction
COMMIT; 