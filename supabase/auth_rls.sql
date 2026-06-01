-- =====================================================
-- eHadir SaaS Auth + RLS Security v1
-- Requires:
-- 1. schema_foundation.sql
-- 2. schema_attendance.sql
--
-- Purpose:
-- Enable Row Level Security for multi-tenant SaaS.
-- Roles:
-- - developer
-- - admin
-- - teacher
-- - parent
-- =====================================================

-- =====================================================
-- Helper Functions
-- =====================================================

create or replace function public.current_user_role()
returns text
language sql
security definer
stable
as $$
  select role
  from public.profiles
  where id = auth.uid()
  limit 1;
$$;

create or replace function public.current_user_centre_id()
returns uuid
language sql
security definer
stable
as $$
  select centre_id
  from public.profiles
  where id = auth.uid()
  limit 1;
$$;

create or replace function public.is_developer()
returns boolean
language sql
security definer
stable
as $$
  select exists (
    select 1
    from public.profiles
    where id = auth.uid()
    and role = 'developer'
    and status = 'active'
  );
$$;

create or replace function public.is_admin()
returns boolean
language sql
security definer
stable
as $$
  select exists (
    select 1
    from public.profiles
    where id = auth.uid()
    and role = 'admin'
    and status = 'active'
  );
$$;

create or replace function public.is_teacher()
returns boolean
language sql
security definer
stable
as $$
  select exists (
    select 1
    from public.profiles
    where id = auth.uid()
    and role = 'teacher'
    and status = 'active'
  );
$$;

create or replace function public.is_parent()
returns boolean
language sql
security definer
stable
as $$
  select exists (
    select 1
    from public.profiles
    where id = auth.uid()
    and role = 'parent'
    and status = 'active'
  );
$$;


-- =====================================================
-- Enable RLS
-- =====================================================

alter table centres enable row level security;
alter table branches enable row level security;
alter table profiles enable row level security;
alter table students enable row level security;
alter table teachers enable row level security;
alter table courses enable row level security;
alter table enrollments enable row level security;

alter table teacher_attendances enable row level security;
alter table attendance_logs enable row level security;
alter table transfer_requests enable row level security;
alter table books enable row level security;
alter table student_progress enable row level security;


-- =====================================================
-- PROFILES Policies
-- =====================================================

drop policy if exists "profiles_select_own_or_developer" on profiles;
create policy "profiles_select_own_or_developer"
on profiles
for select
to authenticated
using (
  id = auth.uid()
  or public.is_developer()
  or (
    centre_id = public.current_user_centre_id()
    and public.current_user_role() in ('admin')
  )
);

drop policy if exists "profiles_update_own" on profiles;
create policy "profiles_update_own"
on profiles
for update
to authenticated
using (id = auth.uid())
with check (id = auth.uid());

drop policy if exists "profiles_admin_manage_centre" on profiles;
create policy "profiles_admin_manage_centre"
on profiles
for all
to authenticated
using (
  public.is_developer()
  or (
    public.current_user_role() = 'admin'
    and centre_id = public.current_user_centre_id()
  )
)
with check (
  public.is_developer()
  or (
    public.current_user_role() = 'admin'
    and centre_id = public.current_user_centre_id()
  )
);


-- =====================================================
-- CENTRES Policies
-- =====================================================

drop policy if exists "centres_select" on centres;
create policy "centres_select"
on centres
for select
to authenticated
using (
  public.is_developer()
  or id = public.current_user_centre_id()
);

drop policy if exists "centres_developer_all" on centres;
create policy "centres_developer_all"
on centres
for all
to authenticated
using (public.is_developer())
with check (public.is_developer());


-- =====================================================
-- Generic Centre Policies
-- Applies to multi-tenant operational tables
-- =====================================================

-- BRANCHES
drop policy if exists "branches_select_centre" on branches;
create policy "branches_select_centre"
on branches
for select
to authenticated
using (
  public.is_developer()
  or centre_id = public.current_user_centre_id()
);

drop policy if exists "branches_admin_write" on branches;
create policy "branches_admin_write"
on branches
for all
to authenticated
using (
  public.is_developer()
  or (
    public.current_user_role() = 'admin'
    and centre_id = public.current_user_centre_id()
  )
)
with check (
  public.is_developer()
  or (
    public.current_user_role() = 'admin'
    and centre_id = public.current_user_centre_id()
  )
);


-- STUDENTS
drop policy if exists "students_select_centre" on students;
create policy "students_select_centre"
on students
for select
to authenticated
using (
  public.is_developer()
  or centre_id = public.current_user_centre_id()
);

drop policy if exists "students_admin_write" on students;
create policy "students_admin_write"
on students
for all
to authenticated
using (
  public.is_developer()
  or (
    public.current_user_role() = 'admin'
    and centre_id = public.current_user_centre_id()
  )
)
with check (
  public.is_developer()
  or (
    public.current_user_role() = 'admin'
    and centre_id = public.current_user_centre_id()
  )
);


-- TEACHERS
drop policy if exists "teachers_select_centre" on teachers;
create policy "teachers_select_centre"
on teachers
for select
to authenticated
using (
  public.is_developer()
  or centre_id = public.current_user_centre_id()
);

drop policy if exists "teachers_admin_write" on teachers;
create policy "teachers_admin_write"
on teachers
for all
to authenticated
using (
  public.is_developer()
  or (
    public.current_user_role() = 'admin'
    and centre_id = public.current_user_centre_id()
  )
)
with check (
  public.is_developer()
  or (
    public.current_user_role() = 'admin'
    and centre_id = public.current_user_centre_id()
  )
);


-- COURSES
drop policy if exists "courses_select_centre" on courses;
create policy "courses_select_centre"
on courses
for select
to authenticated
using (
  public.is_developer()
  or centre_id = public.current_user_centre_id()
);

drop policy if exists "courses_admin_write" on courses;
create policy "courses_admin_write"
on courses
for all
to authenticated
using (
  public.is_developer()
  or (
    public.current_user_role() = 'admin'
    and centre_id = public.current_user_centre_id()
  )
)
with check (
  public.is_developer()
  or (
    public.current_user_role() = 'admin'
    and centre_id = public.current_user_centre_id()
  )
);


-- ENROLLMENTS
drop policy if exists "enrollments_select_centre" on enrollments;
create policy "enrollments_select_centre"
on enrollments
for select
to authenticated
using (
  public.is_developer()
  or centre_id = public.current_user_centre_id()
);

drop policy if exists "enrollments_admin_write" on enrollments;
create policy "enrollments_admin_write"
on enrollments
for all
to authenticated
using (
  public.is_developer()
  or (
    public.current_user_role() = 'admin'
    and centre_id = public.current_user_centre_id()
  )
)
with check (
  public.is_developer()
  or (
    public.current_user_role() = 'admin'
    and centre_id = public.current_user_centre_id()
  )
);


-- =====================================================
-- Attendance / Transfer / Progress Policies
-- Admin can manage all within centre.
-- Teacher can read centre data for MVP.
-- Later we can restrict teacher to assigned classes only.
-- =====================================================

-- TEACHER ATTENDANCES
drop policy if exists "teacher_attendances_select_centre" on teacher_attendances;
create policy "teacher_attendances_select_centre"
on teacher_attendances
for select
to authenticated
using (
  public.is_developer()
  or centre_id = public.current_user_centre_id()
);

drop policy if exists "teacher_attendances_admin_teacher_write" on teacher_attendances;
create policy "teacher_attendances_admin_teacher_write"
on teacher_attendances
for all
to authenticated
using (
  public.is_developer()
  or (
    public.current_user_role() in ('admin', 'teacher')
    and centre_id = public.current_user_centre_id()
  )
)
with check (
  public.is_developer()
  or (
    public.current_user_role() in ('admin', 'teacher')
    and centre_id = public.current_user_centre_id()
  )
);


-- ATTENDANCE LOGS
drop policy if exists "attendance_logs_select_centre" on attendance_logs;
create policy "attendance_logs_select_centre"
on attendance_logs
for select
to authenticated
using (
  public.is_developer()
  or centre_id = public.current_user_centre_id()
);

drop policy if exists "attendance_logs_admin_teacher_write" on attendance_logs;
create policy "attendance_logs_admin_teacher_write"
on attendance_logs
for all
to authenticated
using (
  public.is_developer()
  or (
    public.current_user_role() in ('admin', 'teacher')
    and centre_id = public.current_user_centre_id()
  )
)
with check (
  public.is_developer()
  or (
    public.current_user_role() in ('admin', 'teacher')
    and centre_id = public.current_user_centre_id()
  )
);


-- TRANSFER REQUESTS
drop policy if exists "transfer_requests_select_centre" on transfer_requests;
create policy "transfer_requests_select_centre"
on transfer_requests
for select
to authenticated
using (
  public.is_developer()
  or centre_id = public.current_user_centre_id()
);

drop policy if exists "transfer_requests_admin_write" on transfer_requests;
create policy "transfer_requests_admin_write"
on transfer_requests
for all
to authenticated
using (
  public.is_developer()
  or (
    public.current_user_role() = 'admin'
    and centre_id = public.current_user_centre_id()
  )
)
with check (
  public.is_developer()
  or (
    public.current_user_role() = 'admin'
    and centre_id = public.current_user_centre_id()
  )
);


-- BOOKS
drop policy if exists "books_select_centre" on books;
create policy "books_select_centre"
on books
for select
to authenticated
using (
  public.is_developer()
  or centre_id = public.current_user_centre_id()
);

drop policy if exists "books_admin_write" on books;
create policy "books_admin_write"
on books
for all
to authenticated
using (
  public.is_developer()
  or (
    public.current_user_role() = 'admin'
    and centre_id = public.current_user_centre_id()
  )
)
with check (
  public.is_developer()
  or (
    public.current_user_role() = 'admin'
    and centre_id = public.current_user_centre_id()
  )
);


-- STUDENT PROGRESS
drop policy if exists "student_progress_select_centre" on student_progress;
create policy "student_progress_select_centre"
on student_progress
for select
to authenticated
using (
  public.is_developer()
  or centre_id = public.current_user_centre_id()
);

drop policy if exists "student_progress_admin_teacher_write" on student_progress;
create policy "student_progress_admin_teacher_write"
on student_progress
for all
to authenticated
using (
  public.is_developer()
  or (
    public.current_user_role() in ('admin', 'teacher')
    and centre_id = public.current_user_centre_id()
  )
)
with check (
  public.is_developer()
  or (
    public.current_user_role() in ('admin', 'teacher')
    and centre_id = public.current_user_centre_id()
  )
);


-- =====================================================
-- END OF auth_rls.sql
-- =====================================================
