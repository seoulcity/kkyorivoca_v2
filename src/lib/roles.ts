// src/lib/roles.ts
import { readable, derived } from 'svelte/store';
import { user } from './auth';
import { supabase } from './supabase';

// Role types
export type UserRole = 'admin' | 'manager' | 'member';

// Store for current user's role
export const userRole = derived<typeof user, UserRole | null>(
  user,
  ($user, set) => {
    // Default to null when not logged in
    if (!$user) {
      set(null);
      return;
    }
    
    // Fetch user's role from database
    const fetchRole = async () => {
      try {
        const { data, error } = await supabase
          .from('user_roles')
          .select('role')
          .eq('user_id', $user.id)
          .single();
        
        if (error) {
          console.error('Error fetching user role:', error);
          set('member'); // Default to member role on error
          return;
        }
        
        if (data && data.role) {
          set(data.role as UserRole);
        } else {
          set('member'); // Default to member if no role found
        }
      } catch (err) {
        console.error('Exception fetching user role:', err);
        set('member'); // Default to member role on exception
      }
    };
    
    fetchRole();
    
    // Set up role change subscription
    const subscription = supabase
      .channel('user-role-changes')
      .on(
        'postgres_changes',
        {
          event: '*',
          schema: 'public',
          table: 'user_roles',
          filter: `user_id=eq.${$user.id}`
        },
        (payload) => {
          if (payload.new && 'role' in payload.new) {
            set(payload.new.role as UserRole);
          }
        }
      )
      .subscribe();
    
    // Cleanup subscription when the store is no longer used
    return () => {
      subscription.unsubscribe();
    };
  },
  null // Initial value
);

// Role check utilities
export const isAdmin = derived(userRole, $role => $role === 'admin');
export const isManager = derived(userRole, $role => $role === 'admin' || $role === 'manager');
export const isMember = derived(userRole, $role => $role !== null);

// Function to check if user has a specific role
export function hasRole(role: UserRole, userRoleValue: UserRole | null): boolean {
  if (userRoleValue === null) return false;
  
  switch (role) {
    case 'admin':
      return userRoleValue === 'admin';
    case 'manager':
      return userRoleValue === 'admin' || userRoleValue === 'manager';
    case 'member':
      return true; // All authenticated users have at least member role
    default:
      return false;
  }
}

// Function to format role for display
export function formatRole(role: UserRole | null | undefined): string {
  if (!role) return '권한 없음';
  
  switch (role) {
    case 'admin': return '관리자';
    case 'manager': return '매니저';
    case 'member': return '일반회원';
    default: return '알 수 없음';
  }
} 