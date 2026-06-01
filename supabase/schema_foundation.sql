
-- =====================================================
-- eHadir SaaS Foundation Schema v1
-- =====================================================

create extension if not exists "pgcrypto";

-- =====================================================
-- CENTRES
-- =====================================================

create table centres (
    id uuid primary key default gen_random_uuid(),

    centre_name text not null,
    status text not null default 'active',

    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now()
);

-- =====================================================
-- BRANCHES
-- =====================================================

create table branches (
    id uuid primary key default gen_random_uuid(),

    centre_id uuid not null references centres(id) on delete cascade,

    branch_name text not null,
    status text not null default 'active',

    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now()
);

create index idx_branches_centre
on branches(centre_id);

-- =====================================================
-- PROFILES
-- =====================================================

create table profiles (
    id uuid primary key references auth.users(id) on delete cascade,

    centre_id uuid references centres(id) on delete cascade,

    full_name text not null,
    role text not null,

    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now(),

    constraint chk_role
    check (
        role in (
            'developer',
            'admin',
            'teacher',
            'parent'
        )
    )
);

create index idx_profiles_centre
on profiles(centre_id);

-- =====================================================
-- STUDENTS
-- =====================================================

create table students (
    id uuid primary key default gen_random_uuid(),

    centre_id uuid not null references centres(id) on delete cascade,
    branch_id uuid not null references branches(id) on delete restrict,

    student_code text not null unique,

    first_name text not null,
    last_name text,

    gender text,
    age integer,

    phone text,
    email text,

    status text not null default 'active',

    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now()
);

create index idx_students_centre
on students(centre_id);

create index idx_students_branch
on students(branch_id);

-- =====================================================
-- TEACHERS
-- =====================================================

create table teachers (
    id uuid primary key default gen_random_uuid(),

    centre_id uuid not null references centres(id) on delete cascade,
    branch_id uuid references branches(id),

    teacher_code text not null unique,

    teacher_name text not null,

    phone text,
    email text,

    status text not null default 'active',

    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now()
);

create index idx_teachers_centre
on teachers(centre_id);

-- =====================================================
-- COURSES
-- =====================================================

create table courses (
    id uuid primary key default gen_random_uuid(),

    centre_id uuid not null references centres(id) on delete cascade,
    branch_id uuid not null references branches(id),

    course_code text not null unique,

    course_name text not null,
    description text,

    day_of_week text,

    start_time time,
    end_time time,

    monthly_fee numeric(10,2) default 0,

    class_type text,

    teacher_id uuid references teachers(id),

    status text not null default 'active',

    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now()
);

create index idx_courses_centre
on courses(centre_id);

create index idx_courses_branch
on courses(branch_id);

-- =====================================================
-- ENROLLMENTS
-- =====================================================

create table enrollments (
    id uuid primary key default gen_random_uuid(),

    centre_id uuid not null references centres(id) on delete cascade,
    branch_id uuid not null references branches(id),

    enrollment_code text not null unique,

    student_id uuid not null references students(id),
    course_id uuid not null references courses(id),

    previous_enrollment_id uuid references enrollments(id),

    date_enrolled date not null default current_date,

    status text not null default 'active',

    transfer_note text,

    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now()
);

create index idx_enrollments_student
on enrollments(student_id);

create index idx_enrollments_course
on enrollments(course_id);

create index idx_enrollments_centre
on enrollments(centre_id);

-- =====================================================
-- UNIQUE ACTIVE ENROLLMENT
-- Prevent duplicate active enrollment
-- =====================================================

create unique index uq_active_student_course
on enrollments(student_id, course_id)
where status = 'active';
