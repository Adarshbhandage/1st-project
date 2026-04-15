import { createClient } from 'https://cdn.jsdelivr.net/npm/@supabase/supabase-js/+esm'

// Initialize Supabase Client
const supabaseUrl = 'https://yjfjoodeuzrkqetqovtd.supabase.co'
const supabaseKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InlqZmpvb2RldXpya3FldHFvdnRkIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzYwNzQ4ODYsImV4cCI6MjA5MTY1MDg4Nn0.M357d5iMYsVQLCN0GPKjB_maWgROrD3Q0kbgjrJunfY'
export const supabase = createClient(supabaseUrl, supabaseKey)

// Helper: Get Current User Profile Data
export async function getCurrentProfile() {
  const { data: { user } } = await supabase.auth.getUser();
  if (!user) return null;
  
  const { data: profile, error } = await supabase
    .from('profiles')
    .select('*')
    .eq('id', user.id)
    .single();
    
  if (error) {
    console.error("Error fetching profile:", error);
    return null;
  }
  return { user, profile };
}

// Helper: Must Be Logged In Guard
// Add this to dashboards to kick out unauthenticated users
export async function requireAuth(expectedRole = null) {
  const data = await getCurrentProfile();
  if (!data) {
    window.location.href = 'login.html';
    return null;
  }
  
  if (expectedRole && data.profile.role !== expectedRole) {
    alert(`Access denied. You are logged in as a ${data.profile.role}.`);
    // Redirect to the correct dashboard based on role
    if (data.profile.role === 'student') window.location.href = 'dashboard-student.html';
    if (data.profile.role === 'owner') window.location.href = 'dashboard-owner.html';
    return null;
  }
  return data;
}

// Helper: Logout
export async function logout() {
  await supabase.auth.signOut();
  window.location.href = 'index.html';
}
