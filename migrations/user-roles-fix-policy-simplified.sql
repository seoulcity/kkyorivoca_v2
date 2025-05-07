-- Emergency fix for infinite recursion in user_roles policies
-- This script simplifies policies to eliminate recursion

-- First, drop all existing policies
DROP POLICY IF EXISTS manage_roles ON public.user_roles;
DROP POLICY IF EXISTS view_roles ON public.user_roles;
DROP POLICY IF EXISTS service_manage_all_roles ON public.user_roles;

-- Create simple policies without complex conditions

-- Allow all authenticated users to view all roles (simple read-only)
CREATE POLICY read_all_roles ON public.user_roles
  FOR SELECT
  TO authenticated
  USING (true);

-- Allow only service_role to modify roles (not user-dependent)
CREATE POLICY service_manage_roles ON public.user_roles
  FOR ALL
  TO service_role
  USING (true);

-- Update has_role function to avoid policy checks
CREATE OR REPLACE FUNCTION public.has_role(required_role public.user_role)
RETURNS BOOLEAN AS $$
DECLARE
  user_role public.user_role;
BEGIN
  -- Bypass RLS with security definer
  SELECT role INTO user_role 
  FROM public.user_roles 
  WHERE user_id = auth.uid() 
  LIMIT 1;
  
  -- Basic role hierarchy check
  IF user_role = 'admin' THEN
    RETURN true; -- Admin can do everything
  ELSIF user_role = 'manager' AND required_role != 'admin' THEN
    RETURN true; -- Manager can do manager and member things
  ELSIF user_role = 'member' AND required_role = 'member' THEN
    RETURN true; -- Member can only do member things
  ELSE
    RETURN false;
  END IF;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Make first user an admin for testing if no admin exists
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
  END IF;
END
$$; 