-- Fix user_profiles policy to allow admins to view all profiles
-- This migration adds admin access to user_profiles

-- Drop the existing policies
DROP POLICY IF EXISTS view_own_profile ON public.user_profiles;
DROP POLICY IF EXISTS update_own_profile ON public.user_profiles;

-- Create new policy for viewing profiles (self OR admin)
CREATE POLICY view_profiles ON public.user_profiles
  FOR SELECT
  TO authenticated
  USING (
    -- Users can view their own profile
    auth.uid() = user_id
    OR
    -- Admins can view all profiles (using has_role function)
    public.has_role('admin')
  );

-- Create policy for updating profiles (self only)
CREATE POLICY update_own_profile ON public.user_profiles
  FOR UPDATE
  TO authenticated
  USING (auth.uid() = user_id);

-- Ensure the service role policy exists
DROP POLICY IF EXISTS service_manage_all_profiles ON public.user_profiles;
CREATE POLICY service_manage_all_profiles ON public.user_profiles
  FOR ALL
  TO service_role
  USING (true);

-- Make sure admin exists
DO $$
DECLARE
  admin_count integer;
BEGIN
  SELECT COUNT(*) INTO admin_count FROM public.user_roles WHERE role = 'admin';
  
  IF admin_count = 0 THEN
    UPDATE public.user_roles 
    SET role = 'admin' 
    WHERE user_id = (
      SELECT id FROM auth.users ORDER BY created_at ASC LIMIT 1
    );
    RAISE NOTICE 'Created admin user';
  ELSE
    RAISE NOTICE 'Admin already exists';
  END IF;
END
$$; 