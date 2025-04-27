-- Begin transaction
BEGIN;

-- Create a table to track user consents for privacy policy and terms of service
CREATE TABLE IF NOT EXISTS public.user_consents (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    privacy_policy_accepted BOOLEAN NOT NULL DEFAULT FALSE,
    privacy_policy_version VARCHAR(50),
    privacy_policy_accepted_at TIMESTAMPTZ,
    terms_of_service_accepted BOOLEAN NOT NULL DEFAULT FALSE,
    terms_of_service_version VARCHAR(50),
    terms_of_service_accepted_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Add index on user_id for faster lookups
CREATE INDEX IF NOT EXISTS idx_user_consents_user_id ON public.user_consents(user_id);

-- Function to update updated_at automatically
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger to set updated_at on update
DROP TRIGGER IF EXISTS set_updated_at ON public.user_consents;
CREATE TRIGGER set_updated_at
BEFORE UPDATE ON public.user_consents
FOR EACH ROW
EXECUTE PROCEDURE update_updated_at_column();

-- End transaction
COMMIT; 