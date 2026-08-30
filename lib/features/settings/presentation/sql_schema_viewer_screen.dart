import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/theme/text_styles.dart';

class SqlSchemaViewerScreen extends StatelessWidget {
  const SqlSchemaViewerScreen({super.key});

  static const String sqlSchema = '''-- ==============================================================================
-- ClassPilot Teacher - Complete PostgreSQL Database Schema & Real Seed Data
-- ==============================================================================

create extension if not exists "uuid-ossp";

-- 1. PROFILES & GOOGLE OAUTH
create table if not exists public.profiles (
    id uuid primary key references auth.users(id) on delete cascade,
    name text not null default 'الأستاذ',
    email text not null default '',
    avatar_url text,
    role text not null default 'teacher' check (role in ('teacher', 'student')),
    created_at timestamptz not null default now()
);

create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer set search_path = public
as \$\$
begin
  insert into public.profiles (id, name, email, avatar_url, role)
  values (
    new.id,
    coalesce(new.raw_user_meta_data->>'full_name', new.raw_user_meta_data->>'name', split_part(new.email, '@', 1), 'الأستاذ'),
    coalesce(new.email, ''),
    new.raw_user_meta_data->>'avatar_url',
    'teacher'
  )
  on conflict (id) do update set
    name = excluded.name,
    email = excluded.email,
    avatar_url = coalesce(excluded.avatar_url, public.profiles.avatar_url);
  return new;
end;
\$\$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

-- 2. GRADES / GROUPS
create table if not exists public.grades (
    id uuid primary key default gen_random_uuid(),
    name text not null,
    code text not null unique,
    color text default '#4f8ef7',
    schedule text default 'السبت والثلاثاء • 5:00م',
    sort_order integer not null default 0,
    is_active boolean not null default true,
    created_at timestamptz not null default now()
);

-- 3. STUDENTS
create table if not exists public.students (
    id uuid primary key default gen_random_uuid(),
    grade_id uuid references public.grades(id) on delete cascade,
    name text not null,
    email text,
    phone text,
    parent_phone text,
    student_code text not null unique,
    status text not null default 'active' check (status in ('active', 'inactive', 'suspended')),
    created_at timestamptz not null default now()
);

-- 4. CURRICULUM, UNITS & LESSONS
create table if not exists public.curriculum (
    id uuid primary key default gen_random_uuid(),
    grade_id uuid references public.grades(id) on delete cascade,
    title text not null,
    created_at timestamptz not null default now()
);

create table if not exists public.units (
    id uuid primary key default gen_random_uuid(),
    curriculum_id uuid references public.curriculum(id) on delete cascade,
    title text not null,
    description text,
    sort_order integer not null default 0,
    created_at timestamptz not null default now()
);

create table if not exists public.lessons (
    id uuid primary key default gen_random_uuid(),
    unit_id uuid references public.units(id) on delete cascade,
    title text not null,
    description text,
    sort_order integer not null default 0,
    created_at timestamptz not null default now()
);

create table if not exists public.lesson_files (
    id uuid primary key default gen_random_uuid(),
    lesson_id uuid references public.lessons(id) on delete cascade,
    title text not null,
    file_path text not null,
    file_type text not null default 'pdf',
    file_size bigint not null default 0,
    created_at timestamptz not null default now()
);

-- 5. EXAMS & ATTEMPTS
create table if not exists public.exams (
    id uuid primary key default gen_random_uuid(),
    grade_id uuid references public.grades(id) on delete cascade,
    lesson_id uuid references public.lessons(id) on delete set null,
    title text not null,
    duration_minutes integer not null default 30,
    start_at timestamptz default now(),
    end_at timestamptz,
    is_active boolean not null default true,
    status text not null default 'scheduled',
    scheduled_at timestamptz not null default now(),
    created_at timestamptz not null default now()
);

create table if not exists public.exam_questions (
    id uuid primary key default gen_random_uuid(),
    exam_id uuid references public.exams(id) on delete cascade,
    question text not null,
    options jsonb not null default '[]'::jsonb,
    correct_answer text not null,
    sort_order integer not null default 0
);

create table if not exists public.exam_attempts (
    id uuid primary key default gen_random_uuid(),
    exam_id uuid references public.exams(id) on delete cascade,
    student_id uuid references public.students(id) on delete cascade,
    score numeric(6, 2) not null default 0,
    total_score numeric(6, 2) not null default 100,
    started_at timestamptz not null default now(),
    submitted_at timestamptz not null default now(),
    is_official boolean not null default true
);

-- 6. ATTENDANCE & HOMEWORK
create table if not exists public.attendance_sessions (
    id uuid primary key default gen_random_uuid(),
    grade_id uuid references public.grades(id) on delete cascade,
    lesson_title text not null,
    session_date date not null default current_date,
    created_at timestamptz not null default now()
);

create table if not exists public.attendance_records (
    id uuid primary key default gen_random_uuid(),
    session_id uuid references public.attendance_sessions(id) on delete cascade,
    student_id uuid references public.students(id) on delete cascade,
    status text not null check (status in ('present', 'absent', 'late')),
    created_at timestamptz not null default now(),
    unique(session_id, student_id)
);

create table if not exists public.homeworks (
    id uuid primary key default gen_random_uuid(),
    grade_id uuid references public.grades(id) on delete cascade,
    title text not null,
    due_date date,
    created_at timestamptz not null default now()
);

create table if not exists public.homework_records (
    id uuid primary key default gen_random_uuid(),
    homework_id uuid references public.homeworks(id) on delete cascade,
    student_id uuid references public.students(id) on delete cascade,
    status text not null check (status in ('done', 'not_done')),
    created_at timestamptz not null default now(),
    unique(homework_id, student_id)
);

-- 7. STORAGE BUCKET (PDF Lesson Files)
insert into storage.buckets (id, name, public)
values ('lesson-files', 'lesson-files', true)
on conflict (id) do update set public = true;

-- 8. ROW LEVEL SECURITY POLICIES
alter table public.profiles enable row level security;
alter table public.grades enable row level security;
alter table public.students enable row level security;
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

create policy "Profiles full access" on public.profiles for all to authenticated using (true) with check (true);
create policy "Grades full access" on public.grades for all to authenticated using (true) with check (true);
create policy "Students full access" on public.students for all to authenticated using (true) with check (true);
create policy "Curriculum full access" on public.curriculum for all to authenticated using (true) with check (true);
create policy "Units full access" on public.units for all to authenticated using (true) with check (true);
create policy "Lessons full access" on public.lessons for all to authenticated using (true) with check (true);
create policy "Lesson files full access" on public.lesson_files for all to authenticated using (true) with check (true);
create policy "Exams full access" on public.exams for all to authenticated using (true) with check (true);
create policy "Exam questions full access" on public.exam_questions for all to authenticated using (true) with check (true);
create policy "Exam attempts full access" on public.exam_attempts for all to authenticated using (true) with check (true);
create policy "Attendance sessions full access" on public.attendance_sessions for all to authenticated using (true) with check (true);
create policy "Attendance records full access" on public.attendance_records for all to authenticated using (true) with check (true);
create policy "Homeworks full access" on public.homeworks for all to authenticated using (true) with check (true);
create policy "Homework records full access" on public.homework_records for all to authenticated using (true) with check (true);
''';

  void _copySql(BuildContext context) {
    Clipboard.setData(const ClipboardData(text: sqlSchema));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('تم نسخ كود SQL Schema إلى الحافظة بنجاح!'),
        backgroundColor: AppColors.primary,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('مخطط قاعدة البيانات (SQL Schema)'),
        actions: [
          IconButton(
            icon: const Icon(Icons.copy_rounded),
            tooltip: AppStrings.copy,
            onPressed: () => _copySql(context),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primaryDim,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline_rounded, color: AppColors.primary, size: 22),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'انسخ هذا الكود والصقه في نافذة SQL Editor في Supabase لإنشاء وتجهيز جميع الجداول والتخزين بنجاح.',
                      style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textPrimary),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.tableHeaderBg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: SingleChildScrollView(
                  child: SelectableText(
                    sqlSchema,
                    style: AppTextStyles.monoNumber.copyWith(
                      color: AppColors.cyan,
                      fontSize: 12.5,
                      height: 1.5,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              icon: const Icon(Icons.copy_rounded, size: 16),
              label: const Text('نسخ كود SQL Schema بالكامل'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
              ),
              onPressed: () => _copySql(context),
            ),
          ],
        ),
      ),
    );
  }
}
