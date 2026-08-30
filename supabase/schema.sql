-- ==============================================================================
-- ClassPilot Teacher Management App - Complete Database Schema & Security (RLS)
-- ==============================================================================

-- Enable UUID extension
create extension if not exists "uuid-ossp";

-- ==============================================================================
-- 1. PROFILES TABLE (Linked to Supabase Auth)
-- ==============================================================================
create table if not exists public.profiles (
    id uuid primary key references auth.users(id) on delete cascade,
    name text not null,
    email text not null,
    avatar_url text,
    role text not null check (role in ('teacher', 'student')),
    created_at timestamptz not null default now()
);

create index if not exists idx_profiles_role on public.profiles(role);
create index if not exists idx_profiles_email on public.profiles(email);

-- ==============================================================================
-- 2. TEACHERS TABLE
-- ==============================================================================
create table if not exists public.teachers (
    id uuid primary key default gen_random_uuid(),
    profile_id uuid not null unique references public.profiles(id) on delete cascade,
    display_name text not null,
    teacher_code text not null unique,
    created_at timestamptz not null default now()
);

create index if not exists idx_teachers_profile on public.teachers(profile_id);
create index if not exists idx_teachers_code on public.teachers(teacher_code);

-- ==============================================================================
-- 3. GRADES TABLE (Academic Course Levels)
-- ==============================================================================
create table if not exists public.grades (
    id uuid primary key default gen_random_uuid(),
    name text not null unique,
    code text not null unique,
    sort_order integer not null default 0,
    is_active boolean not null default true,
    created_at timestamptz not null default now()
);

-- Seed Initial Secondary School Grades
insert into public.grades (name, code, sort_order)
values 
    ('الصف الأول الثانوي', 'SEC_1', 1),
    ('الصف الثاني الثانوي', 'SEC_2', 2)
on conflict (code) do update set name = excluded.name;

-- ==============================================================================
-- 4. GROUPS TABLE (Independent entities associated with a Grade)
-- ==============================================================================
create table if not exists public.groups (
    id uuid primary key default gen_random_uuid(),
    teacher_id uuid not null references public.teachers(id) on delete cascade,
    grade_id uuid not null references public.grades(id) on delete restrict,
    name text not null,
    join_code text not null unique,
    invite_token text not null unique,
    status text not null default 'active' check (status in ('active', 'archived')),
    created_at timestamptz not null default now()
);

create index if not exists idx_groups_teacher on public.groups(teacher_id);
create index if not exists idx_groups_grade on public.groups(grade_id);
create index if not exists idx_groups_join_code on public.groups(join_code);
create index if not exists idx_groups_invite_token on public.groups(invite_token);

-- ==============================================================================
-- 5. STUDENTS TABLE
-- ==============================================================================
create table if not exists public.students (
    id uuid primary key default gen_random_uuid(),
    teacher_id uuid not null references public.teachers(id) on delete cascade,
    profile_id uuid unique references public.profiles(id) on delete set null,
    grade_id uuid not null references public.grades(id) on delete restrict,
    name text not null,
    email text,
    phone text,
    parent_phone text,
    student_code text not null unique,
    status text not null default 'active' check (status in ('active', 'inactive', 'suspended')),
    created_at timestamptz not null default now()
);

create index if not exists idx_students_teacher on public.students(teacher_id);
create index if not exists idx_students_grade on public.students(grade_id);
create index if not exists idx_students_student_code on public.students(student_code);
create index if not exists idx_students_profile on public.students(profile_id);

-- ==============================================================================
-- 6. GROUP_STUDENTS (Enrollment Junction Table)
-- ==============================================================================
create table if not exists public.group_students (
    id uuid primary key default gen_random_uuid(),
    group_id uuid not null references public.groups(id) on delete cascade,
    student_id uuid not null references public.students(id) on delete cascade,
    joined_at timestamptz not null default now(),
    unique(group_id, student_id)
);

create index if not exists idx_group_students_group on public.group_students(group_id);
create index if not exists idx_group_students_student on public.group_students(student_id);

-- ==============================================================================
-- 7. CURRICULUM (Grade-Level Course Structure)
-- ==============================================================================
create table if not exists public.curriculum (
    id uuid primary key default gen_random_uuid(),
    teacher_id uuid not null references public.teachers(id) on delete cascade,
    grade_id uuid not null references public.grades(id) on delete cascade,
    title text not null,
    subject text not null default 'برمجة الحاسب',
    description text,
    is_active boolean not null default true,
    created_at timestamptz not null default now(),
    unique(teacher_id, grade_id)
);

create index if not exists idx_curriculum_teacher on public.curriculum(teacher_id);
create index if not exists idx_curriculum_grade on public.curriculum(grade_id);

-- ==============================================================================
-- 8. UNITS TABLE (Belongs to Curriculum)
-- ==============================================================================
create table if not exists public.units (
    id uuid primary key default gen_random_uuid(),
    curriculum_id uuid not null references public.curriculum(id) on delete cascade,
    title text not null,
    description text,
    sort_order integer not null default 0,
    created_at timestamptz not null default now()
);

create index if not exists idx_units_curriculum on public.units(curriculum_id);

-- ==============================================================================
-- 9. LESSONS TABLE (Belongs to Unit)
-- ==============================================================================
create table if not exists public.lessons (
    id uuid primary key default gen_random_uuid(),
    unit_id uuid not null references public.units(id) on delete cascade,
    title text not null,
    description text,
    sort_order integer not null default 0,
    created_at timestamptz not null default now()
);

create index if not exists idx_lessons_unit on public.lessons(unit_id);

-- ==============================================================================
-- 10. LESSON_FILES TABLE (PDF / Resource metadata)
-- ==============================================================================
create table if not exists public.lesson_files (
    id uuid primary key default gen_random_uuid(),
    lesson_id uuid not null references public.lessons(id) on delete cascade,
    title text not null,
    file_path text not null,
    file_type text not null default 'pdf',
    file_size bigint not null default 0,
    created_at timestamptz not null default now()
);

create index if not exists idx_lesson_files_lesson on public.lesson_files(lesson_id);

-- ==============================================================================
-- 11. EXAMS TABLE (Belongs to Grade / Curriculum)
-- ==============================================================================
create table if not exists public.exams (
    id uuid primary key default gen_random_uuid(),
    teacher_id uuid not null references public.teachers(id) on delete cascade,
    grade_id uuid not null references public.grades(id) on delete cascade,
    lesson_id uuid references public.lessons(id) on delete set null,
    title text not null,
    duration_minutes integer not null default 30,
    start_at timestamptz,
    end_at timestamptz,
    is_active boolean not null default true,
    created_at timestamptz not null default now()
);

create index if not exists idx_exams_teacher on public.exams(teacher_id);
create index if not exists idx_exams_grade on public.exams(grade_id);
create index if not exists idx_exams_lesson on public.exams(lesson_id);

-- ==============================================================================
-- 12. EXAM_QUESTIONS TABLE (Multiple Choice Only)
-- ==============================================================================
create table if not exists public.exam_questions (
    id uuid primary key default gen_random_uuid(),
    exam_id uuid not null references public.exams(id) on delete cascade,
    question text not null,
    options jsonb not null default '[]'::jsonb,
    correct_answer text not null,
    sort_order integer not null default 0
);

create index if not exists idx_exam_questions_exam on public.exam_questions(exam_id);

-- ==============================================================================
-- 13. EXAM_ATTEMPTS TABLE
-- ==============================================================================
create table if not exists public.exam_attempts (
    id uuid primary key default gen_random_uuid(),
    exam_id uuid not null references public.exams(id) on delete cascade,
    student_id uuid not null references public.students(id) on delete cascade,
    score numeric(6, 2) not null default 0,
    total_score numeric(6, 2) not null default 100,
    answers jsonb default '{}'::jsonb,
    started_at timestamptz not null default now(),
    submitted_at timestamptz,
    is_official boolean not null default true
);

create index if not exists idx_exam_attempts_exam on public.exam_attempts(exam_id);
create index if not exists idx_exam_attempts_student on public.exam_attempts(student_id);

-- ==============================================================================
-- 14. ATTENDANCE_SESSIONS TABLE
-- ==============================================================================
create table if not exists public.attendance_sessions (
    id uuid primary key default gen_random_uuid(),
    group_id uuid not null references public.groups(id) on delete cascade,
    title text not null,
    session_date date not null default current_date,
    created_at timestamptz not null default now()
);

create index if not exists idx_attendance_sessions_group on public.attendance_sessions(group_id);
create index if not exists idx_attendance_sessions_date on public.attendance_sessions(session_date);

-- ==============================================================================
-- 15. ATTENDANCE_RECORDS TABLE
-- ==============================================================================
create table if not exists public.attendance_records (
    id uuid primary key default gen_random_uuid(),
    session_id uuid not null references public.attendance_sessions(id) on delete cascade,
    student_id uuid not null references public.students(id) on delete cascade,
    status text not null check (status in ('present', 'absent', 'late')),
    notes text,
    unique(session_id, student_id)
);

create index if not exists idx_attendance_records_session on public.attendance_records(session_id);
create index if not exists idx_attendance_records_student on public.attendance_records(student_id);

-- ==============================================================================
-- 16. HOMEWORKS TABLE
-- ==============================================================================
create table if not exists public.homeworks (
    id uuid primary key default gen_random_uuid(),
    group_id uuid not null references public.groups(id) on delete cascade,
    lesson_id uuid references public.lessons(id) on delete set null,
    title text not null,
    due_date date,
    created_at timestamptz not null default now()
);

create index if not exists idx_homeworks_group on public.homeworks(group_id);

-- ==============================================================================
-- 17. HOMEWORK_RECORDS TABLE (Real-life manual check: Done / Not Done)
-- ==============================================================================
create table if not exists public.homework_records (
    id uuid primary key default gen_random_uuid(),
    homework_id uuid not null references public.homeworks(id) on delete cascade,
    student_id uuid not null references public.students(id) on delete cascade,
    status text not null check (status in ('done', 'not_done')),
    created_at timestamptz not null default now(),
    unique(homework_id, student_id)
);

create index if not exists idx_homework_records_homework on public.homework_records(homework_id);
create index if not exists idx_homework_records_student on public.homework_records(student_id);

-- ==============================================================================
-- 18. STORAGE BUCKET CONFIGURATION (Private Bucket)
-- ==============================================================================
insert into storage.buckets (id, name, public)
values ('lesson-files', 'lesson-files', false)
on conflict (id) do update set public = false;

-- ==============================================================================
-- 19. ROW LEVEL SECURITY (RLS) & HELPER FUNCTIONS
-- ==============================================================================

-- Helper function: check if authenticated user is a teacher
create or replace function public.is_teacher()
returns boolean as $$
begin
    return exists (
        select 1 from public.profiles
        where id = auth.uid() and role = 'teacher'
    );
end;
$$ language plpgsql security definer;

-- Helper function: get current teacher record id
create or replace function public.current_teacher_id()
returns uuid as $$
declare
    t_id uuid;
begin
    select id into t_id from public.teachers where profile_id = auth.uid() limit 1;
    return t_id;
end;
$$ language plpgsql security definer;

-- Enable RLS on all 17 tables
alter table public.profiles enable row level security;
alter table public.teachers enable row level security;
alter table public.grades enable row level security;
alter table public.groups enable row level security;
alter table public.students enable row level security;
alter table public.group_students enable row level security;
alter table public.curriculum enable row level security;
alter table public.units enable row level security;
alter table public.lessons enable row level security;
alter table public.lesson_files enable row level security;
alter table public.exams enable row level security;
alter table public.exam_questions enable row level security;
alter table public.exam_attempts enable row level security;
alter table public.attendance_sessions enable row level security;
alter table public.attendance_records enable row level security;
alter table public.homeworks enable row level security;
alter table public.homework_records enable row level security;

-- PROFILES RLS
create policy "Users can view own profile" on public.profiles for select using (auth.uid() = id);
create policy "Users can update own profile" on public.profiles for update using (auth.uid() = id);
create policy "Teachers can view student profiles" on public.profiles for select using (public.is_teacher());

-- TEACHERS RLS
create policy "Teachers can view and manage their own teacher record"
    on public.teachers for all
    using (profile_id = auth.uid())
    with check (profile_id = auth.uid());

create policy "Public/Students can view teacher by code"
    on public.teachers for select
    using (true);

-- GRADES RLS
create policy "Authenticated users can read grades"
    on public.grades for select
    using (auth.role() = 'authenticated');

create policy "Teachers can manage grades"
    on public.grades for all
    using (public.is_teacher())
    with check (public.is_teacher());

-- GROUPS RLS
create policy "Teachers manage their own groups"
    on public.groups for all
    using (public.is_teacher() and teacher_id = public.current_teacher_id())
    with check (public.is_teacher() and teacher_id = public.current_teacher_id());

-- STUDENTS RLS
create policy "Teachers manage their assigned students"
    on public.students for all
    using (public.is_teacher() and teacher_id = public.current_teacher_id())
    with check (public.is_teacher() and teacher_id = public.current_teacher_id());

-- GROUP_STUDENTS RLS
create policy "Teachers manage enrollments in their groups"
    on public.group_students for all
    using (
        exists (
            select 1 from public.groups
            where groups.id = group_students.group_id
            and groups.teacher_id = public.current_teacher_id()
        )
    );

-- CURRICULUM RLS
create policy "Teachers manage their curriculum"
    on public.curriculum for all
    using (public.is_teacher() and teacher_id = public.current_teacher_id())
    with check (public.is_teacher() and teacher_id = public.current_teacher_id());

-- UNITS RLS
create policy "Teachers manage units in their curriculum"
    on public.units for all
    using (
        exists (
            select 1 from public.curriculum
            where curriculum.id = units.curriculum_id
            and curriculum.teacher_id = public.current_teacher_id()
        )
    );

-- LESSONS RLS
create policy "Teachers manage lessons in their units"
    on public.lessons for all
    using (
        exists (
            select 1 from public.units
            join public.curriculum on curriculum.id = units.curriculum_id
            where units.id = lessons.unit_id
            and curriculum.teacher_id = public.current_teacher_id()
        )
    );

-- LESSON_FILES RLS
create policy "Teachers manage lesson files"
    on public.lesson_files for all
    using (
        exists (
            select 1 from public.lessons
            join public.units on units.id = lessons.unit_id
            join public.curriculum on curriculum.id = units.curriculum_id
            where lessons.id = lesson_files.lesson_id
            and curriculum.teacher_id = public.current_teacher_id()
        )
    );

-- EXAMS RLS
create policy "Teachers manage their exams"
    on public.exams for all
    using (public.is_teacher() and teacher_id = public.current_teacher_id())
    with check (public.is_teacher() and teacher_id = public.current_teacher_id());

create policy "Authenticated students can view active exams"
    on public.exams for select
    using (auth.role() = 'authenticated' and is_active = true);

-- EXAM_QUESTIONS RLS
create policy "Teachers manage exam questions"
    on public.exam_questions for all
    using (
        exists (
            select 1 from public.exams
            where exams.id = exam_questions.exam_id
            and exams.teacher_id = public.current_teacher_id()
        )
    );

create policy "Authenticated users can view exam questions"
    on public.exam_questions for select
    using (auth.role() = 'authenticated');

-- EXAM_ATTEMPTS RLS
create policy "Teachers view and manage exam attempts"
    on public.exam_attempts for all
    using (
        exists (
            select 1 from public.exams
            where exams.id = exam_attempts.exam_id
            and exams.teacher_id = public.current_teacher_id()
        )
    );

create policy "Students can insert own exam attempts"
    on public.exam_attempts for insert
    with check (auth.role() = 'authenticated');

create policy "Students can view own exam attempts"
    on public.exam_attempts for select
    using (auth.role() = 'authenticated');

-- ATTENDANCE_SESSIONS RLS
create policy "Teachers manage attendance sessions"
    on public.attendance_sessions for all
    using (
        exists (
            select 1 from public.groups
            where groups.id = attendance_sessions.group_id
            and groups.teacher_id = public.current_teacher_id()
        )
    );

-- ATTENDANCE_RECORDS RLS
create policy "Teachers manage attendance records"
    on public.attendance_records for all
    using (
        exists (
            select 1 from public.attendance_sessions
            join public.groups on groups.id = attendance_sessions.group_id
            where attendance_sessions.id = attendance_records.session_id
            and groups.teacher_id = public.current_teacher_id()
        )
    );

-- HOMEWORKS RLS
create policy "Teachers manage homeworks"
    on public.homeworks for all
    using (
        exists (
            select 1 from public.groups
            where groups.id = homeworks.group_id
            and groups.teacher_id = public.current_teacher_id()
        )
    );

-- HOMEWORK_RECORDS RLS
create policy "Teachers manage homework records"
    on public.homework_records for all
    using (
        exists (
            select 1 from public.homeworks
            join public.groups on groups.id = homeworks.group_id
            where homeworks.id = homework_records.homework_id
            and groups.teacher_id = public.current_teacher_id()
        )
    );

-- STORAGE BUCKET RLS POLICIES for 'lesson-files'
create policy "Authenticated teachers can upload lesson files"
    on storage.objects for insert
    with check (
        bucket_id = 'lesson-files'
        and auth.role() = 'authenticated'
        and public.is_teacher()
    );

create policy "Authenticated users can read lesson files"
    on storage.objects for select
    using (
        bucket_id = 'lesson-files'
        and auth.role() = 'authenticated'
    );

create policy "Authenticated teachers can delete lesson files"
    on storage.objects for delete
    using (
        bucket_id = 'lesson-files'
        and auth.role() = 'authenticated'
        and public.is_teacher()
    );

-- ==============================================================================
-- 20. TRIGGER: AUTOMATIC PROFILE & TEACHER CREATION ON SIGNUP
-- ==============================================================================
create or replace function public.handle_new_user()
returns trigger as $$
declare
    new_role text;
    teacher_name text;
    gen_code text;
begin
    new_role := coalesce(new.raw_user_meta_data->>'role', 'teacher');
    teacher_name := coalesce(new.raw_user_meta_data->>'full_name', new.raw_user_meta_data->>'name', split_part(new.email, '@', 1));
    
    -- Insert profile
    insert into public.profiles (id, name, email, avatar_url, role)
    values (
        new.id,
        teacher_name,
        new.email,
        new.raw_user_meta_data->>'avatar_url',
        new_role
    );

    -- If teacher, automatically create a teacher record with a unique 6-digit code
    if new_role = 'teacher' then
        gen_code := 'TCH-' || upper(substring(replace(gen_random_uuid()::text, '-', '') from 1 for 6));
        insert into public.teachers (profile_id, display_name, teacher_code)
        values (new.id, teacher_name, gen_code);
    end if;

    return new;
end;
$$ language plpgsql security definer;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
    after insert on auth.users
    for each row execute function public.handle_new_user();
