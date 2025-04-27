-- Begin transaction
BEGIN;

-- Check if tables exist, create if they don't
CREATE TABLE IF NOT EXISTS public.policy_versions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    policy_type VARCHAR(50) NOT NULL, 
    version VARCHAR(50) NOT NULL,
    published_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    is_current BOOLEAN NOT NULL DEFAULT TRUE
);

-- Ensure only one current version per policy type
CREATE UNIQUE INDEX IF NOT EXISTS idx_policy_versions_current 
ON public.policy_versions(policy_type) 
WHERE is_current = TRUE;

-- Add initial versions if they don't exist
INSERT INTO public.policy_versions (policy_type, version, published_at, is_current)
SELECT 'privacy_policy', '1.0', NOW(), TRUE
WHERE NOT EXISTS (SELECT 1 FROM public.policy_versions WHERE policy_type = 'privacy_policy');

INSERT INTO public.policy_versions (policy_type, version, published_at, is_current)
SELECT 'terms_of_service', '1.0', NOW(), TRUE
WHERE NOT EXISTS (SELECT 1 FROM public.policy_versions WHERE policy_type = 'terms_of_service');

-- End transaction
COMMIT; 