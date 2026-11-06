-- ==============================================================================
-- Supabase SQL Patch: Enable User Profile & Teacher Auto-Registration
-- ==============================================================================

-- 1. Ensure profiles allows INSERT for authenticated users
drop policy if exists "Users can insert own profile" on public.profiles;
create policy "Users can insert own profile"
    on public.profiles for insert
    with check (auth.uid() = id);

drop policy if exists "Users can update own profile" on public.profiles;
create policy "Users can update own profile"
    on public.profiles for update
    using (auth.uid() = id);

-- 2. Ensure teachers table allows INSERT/UPDATE for profile owner
drop policy if exists "Teachers can insert their own record" on public.teachers;
create policy "Teachers can insert their own record"
    on public.teachers for insert
    with check (profile_id = auth.uid());

drop policy if exists "Teachers can update their own record" on public.teachers;
create policy "Teachers can update their own record"
    on public.teachers for update
    using (profile_id = auth.uid());
