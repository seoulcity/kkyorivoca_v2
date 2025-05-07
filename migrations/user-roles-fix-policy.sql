-- Fix infinite recursion in user_roles policies
-- This script updates the policies to prevent infinite recursion

-- Drop existing policies causing the recursion
DROP POLICY IF EXISTS manage_roles ON public.user_roles;
DROP POLICY IF EXISTS view_roles ON public.user_roles;
DROP POLICY IF EXISTS service_manage_all_roles ON public.user_roles;

-- Create a more direct policy for admins (avoids the recursion)
CREATE POLICY manage_roles ON public.user_roles
  FOR ALL
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM auth.users 
      WHERE auth.users.id = auth.uid() 
      AND EXISTS (
        SELECT 1 FROM public.user_roles 
        WHERE user_roles.user_id = auth.users.id 
        AND user_roles.role = 'admin'
      )
    )
  );

-- Create policy for authenticated users to view roles
CREATE POLICY view_roles ON public.user_roles
  FOR SELECT
  TO authenticated
  USING (true);

-- Create policy for service role to manage all roles
CREATE POLICY service_manage_all_roles ON public.user_roles
  FOR ALL
  TO service_role
  USING (true);

-- Update the has_role function to avoid recursion
CREATE OR REPLACE FUNCTION public.has_role(required_role public.user_role)
RETURNS BOOLEAN AS $$
BEGIN
  -- Direct query to check user role
  RETURN (
    SELECT EXISTS (
      SELECT 1 
      FROM public.user_roles 
      WHERE user_id = auth.uid() 
      AND role = required_role
    )
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create an admin user for testing if none exists
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