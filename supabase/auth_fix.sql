-- ==============================================================================
-- Supabase SQL Patch: Permissions, RLS & Admin Management
-- ==============================================================================

-- 1. Profiles Table Policies
drop policy if exists "Users can insert own profile" on public.profiles;
create policy "Users can insert own profile"
    on public.profiles for insert
    with check (auth.uid() = id);

drop policy if exists "Users can update own profile" on public.profiles;
create policy "Users can update own profile"
    on public.profiles for update
    using (auth.uid() = id);

-- 2. Teachers Table Policies
drop policy if exists "Teachers can insert their own record" on public.teachers;
create policy "Teachers can insert their own record"
    on public.teachers for insert
    with check (profile_id = auth.uid());

drop policy if exists "Teachers can update their own record" on public.teachers;
create policy "Teachers can update their own record"
    on public.teachers for update
    using (profile_id = auth.uid());

-- 3. Students Table Policies (Allows teachers to delete / manage students in their groups)
drop policy if exists "Teachers manage their assigned students" on public.students;
drop policy if exists "Teachers can manage students" on public.students;

create policy "Teachers can manage students"
    on public.students for all
    using (
        auth.uid() = teacher_id
        or exists (
            select 1 from public.grades
            where grades.id = students.grade_id
            and grades.teacher_id = auth.uid()
        )
        or exists (
            select 1 from public.profiles
            where profiles.id = auth.uid()
            and profiles.role = 'teacher'
        )
    )
    with check (
        auth.uid() = teacher_id
        or exists (
            select 1 from public.grades
            where grades.id = students.grade_id
            and grades.teacher_id = auth.uid()
        )
        or exists (
            select 1 from public.profiles
            where profiles.id = auth.uid()
            and profiles.role = 'teacher'
        )
    );

drop policy if exists "Students can view own record" on public.students;
create policy "Students can view own record"
    on public.students for select
    using (
        auth.uid() = user_id
        or (exists (select 1 from public.profiles where profiles.id = auth.uid() and profiles.phone is not null and profiles.phone = students.phone))
    );

-- 4. Delete policies on child records (Attendance, Homework, Exams)
drop policy if exists "Teachers can delete student attendance" on public.attendance_records;
create policy "Teachers can delete student attendance"
    on public.attendance_records for delete
    using (true);

drop policy if exists "Teachers can delete student homework" on public.homework_records;
create policy "Teachers can delete student homework"
    on public.homework_records for delete
    using (true);

drop policy if exists "Teachers can delete student exam attempts" on public.exam_attempts;
create policy "Teachers can delete student exam attempts"
    on public.exam_attempts for delete
    using (true);

-- ==============================================================================
-- 5. ADMIN UTILITY: Completely Wipe a User and All Associated Data
-- ==============================================================================
-- To delete a user completely from the Supabase Dashboard:
-- 1. Go to "Authentication" -> "Users"
-- 2. Find the user, click "..." -> "Delete user"
--
-- If you want to delete a user and ALL their data cleanly via SQL Editor:
-- Run this function:
create or replace function public.admin_delete_user(target_user_id uuid)
returns text as $$
declare
    user_role text;
begin
    -- 1. Get role from profiles
    select role into user_role from public.profiles where id = target_user_id;

    -- 2. Delete child activity records
    delete from public.attendance_records where student_id in (select id from public.students where user_id = target_user_id);
    delete from public.homework_records where student_id in (select id from public.students where user_id = target_user_id);
    delete from public.exam_attempts where student_id in (select id from public.students where user_id = target_user_id);
    
    -- 3. Delete student records
    delete from public.students where user_id = target_user_id or teacher_id = target_user_id;

    -- 4. If teacher, clean up groups/curriculum
    delete from public.grades where teacher_id = target_user_id;
    delete from public.curriculum where teacher_id = target_user_id;
    delete from public.teachers where profile_id = target_user_id;

    -- 5. Delete profile
    delete from public.profiles where id = target_user_id;

    -- 6. Delete auth user (from auth.users)
    delete from auth.users where id = target_user_id;

    return 'User ' || target_user_id || ' completely wiped.';
end;
$$ language plpgsql security definer;
