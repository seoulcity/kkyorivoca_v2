-- Create a new user_profiles table to mirror auth.Users
-- This migration will create the table and populate it with existing data

-- Create the table
CREATE TABLE IF NOT EXISTS public.user_profiles (
  id UUID PRIMARY KEY,
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE UNIQUE,
  email TEXT,
  phone TEXT,
  display_name TEXT,
  providers TEXT[],
  provider_type TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Add comment to the table
COMMENT ON TABLE public.user_profiles IS 'Stores user profile information mirrored from auth.users';

-- Create indexes for faster lookups
CREATE INDEX IF NOT EXISTS idx_user_profiles_user_id ON public.user_profiles(user_id);
CREATE INDEX IF NOT EXISTS idx_user_profiles_email ON public.user_profiles(email);

-- Create trigger function to update the updated_at column
CREATE OR REPLACE FUNCTION public.update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
   NEW.updated_at = NOW();
   RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger for updated_at
DROP TRIGGER IF EXISTS update_user_profiles_updated_at ON public.user_profiles;
CREATE TRIGGER update_user_profiles_updated_at
BEFORE UPDATE ON public.user_profiles
FOR EACH ROW
EXECUTE FUNCTION public.update_updated_at_column();

-- Create or replace function to sync new users
CREATE OR REPLACE FUNCTION public.sync_user_to_profiles()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.user_profiles (id, user_id, email, phone, display_name, providers, provider_type)
  VALUES (
    gen_random_uuid(),
    NEW.id,
    NEW.email,
    NEW.phone,
    NEW.raw_user_meta_data->>'full_name',
    ARRAY[NEW.raw_app_meta_data->>'provider']::TEXT[],
    NEW.raw_app_meta_data->>'provider'
  )
  ON CONFLICT (user_id) 
  DO UPDATE SET
    email = EXCLUDED.email,
    phone = EXCLUDED.phone,
    display_name = EXCLUDED.display_name,
    providers = EXCLUDED.providers,
    provider_type = EXCLUDED.provider_type,
    updated_at = NOW();
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create trigger for new user insertions
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
AFTER INSERT ON auth.users
FOR EACH ROW
EXECUTE FUNCTION public.sync_user_to_profiles();

-- Create trigger for user updates
DROP TRIGGER IF EXISTS on_auth_user_updated ON auth.users;
CREATE TRIGGER on_auth_user_updated
AFTER UPDATE ON auth.users
FOR EACH ROW
EXECUTE FUNCTION public.sync_user_to_profiles();

-- Insert existing users from auth.users into user_profiles
INSERT INTO public.user_profiles (id, user_id, email, phone, display_name, providers, provider_type)
SELECT 
  gen_random_uuid(),
  id,
  email,
  phone,
  raw_user_meta_data->>'full_name',
  ARRAY[raw_app_meta_data->>'provider']::TEXT[],
  raw_app_meta_data->>'provider'
FROM 
  auth.users
ON CONFLICT (user_id) DO NOTHING;

-- Grant permissions
ALTER TABLE public.user_profiles ENABLE ROW LEVEL SECURITY;

-- Create policy for authenticated users to view their own profile
CREATE POLICY view_own_profile ON public.user_profiles
  FOR SELECT
  TO authenticated
  USING (auth.uid() = user_id);

-- Create policy for authenticated users to update their own profile
CREATE POLICY update_own_profile ON public.user_profiles
  FOR UPDATE
  TO authenticated
  USING (auth.uid() = user_id);

-- Create policy for service role to manage all profiles
CREATE POLICY service_manage_all_profiles ON public.user_profiles
  FOR ALL
  TO service_role
  USING (true); 