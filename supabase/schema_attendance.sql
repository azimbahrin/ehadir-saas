
-- =====================================================
-- eHadir SaaS Attendance + Transfer + Progress Schema v1
-- Requires: schema_foundation.sql already executed
-- Tables added:
-- 1. teacher_attendances
-- 2. attendance_logs
-- 3. transfer_requests
-- 4. books
-- 5. student_progress
-- =====================================================

-- =====================================================
-- TEACHER ATTENDANCES
-- AppSheet: Teacher Attendance
-- Purpose: Start Class / End Class / Salary base
-- =====================================================

create table if not exists teacher_attendances (
    id uuid primary key default gen_random_uuid(),

    centre_id uuid not null references centres(id) on delete cascade,
    branch_id uuid not null references branches(id) on delete restrict,

    teacher_attendance_code text not null unique,

    teacher_id uuid not null references teachers(id) on delete restrict,
    course_id uuid not null references courses(id) on delete restrict,

    class_date date not null default current_date,

    start_time timestamptz,
    end_time timestamptz,

    official_start_time timestamptz,
    official_end_time timestamptz,

    total_hours numeric(8,2) default 0,

    payment_status text not null default 'pending',
    payment_date date,

    salary_note text,
    salary_adjustment numeric(10,2) default 0,

    total_students_attend integer default 0,
    salary_rate numeric(10,2) default 0,
    auto_salary numeric(10,2) default 0,
    final_salary numeric(10,2) default 0,
    total_salary numeric(10,2) default 0,
    salary_month text,

    status text not null default 'active',

    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now(),

    constraint chk_teacher_attendance_payment_status
    check (payment_status in ('pending', 'paid'))
);

create index if not exists idx_teacher_attendances_centre
on teacher_attendances(centre_id);

create index if not exists idx_teacher_attendances_branch
on teacher_attendances(branch_id);

create index if not exists idx_teacher_attendances_teacher
on teacher_attendances(teacher_id);

create index if not exists idx_teacher_attendances_course_date
on teacher_attendances(course_id, class_date);

-- Only one open class session per course per day
create unique index if not exists uq_open_teacher_attendance_per_course
on teacher_attendances(course_id, class_date)
where end_time is null;


-- =====================================================
-- ATTENDANCE LOGS
-- AppSheet: Attendance Log
-- Purpose: Student attendance per enrollment per day
-- =====================================================

create table if not exists attendance_logs (
    id uuid primary key default gen_random_uuid(),

    centre_id uuid not null references centres(id) on delete cascade,
    branch_id uuid not null references branches(id) on delete restrict,

    attendance_code text unique,

    student_id uuid not null references students(id) on delete cascade,
    course_id uuid not null references courses(id) on delete restrict,
    enrollment_id uuid not null references enrollments(id) on delete cascade,

    teacher_attendance_id uuid references teacher_attendances(id) on delete set null,

    attendance_date date not null default current_date,
    attendance_time time default current_time,

    start_time timestamptz,
    end_time timestamptz,
    duration interval,

    teacher_id uuid references teachers(id) on delete set null,

    fee_adjustment numeric(10,2) default 0,
    fee_note text,
    auto_fee numeric(10,2) default 0,
    final_fee numeric(10,2) default 0,

    live_transfer_course_id uuid references courses(id) on delete set null,
    live_transfer_teacher_attendance_id uuid references teacher_attendances(id) on delete set null,
    live_transfer_teacher_id uuid references teachers(id) on delete set null,
    live_transfer_enrollment_id uuid references enrollments(id) on delete set null,

    log_check text,

    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now(),

    -- This is the AppSheet duplicate protection rule:
    -- 1 enrollment can only attend once per date.
    unique (enrollment_id, attendance_date)
);

create index if not exists idx_attendance_logs_centre
on attendance_logs(centre_id);

create index if not exists idx_attendance_logs_branch
on attendance_logs(branch_id);

create index if not exists idx_attendance_logs_student_date
on attendance_logs(student_id, attendance_date);

create index if not exists idx_attendance_logs_course_date
on attendance_logs(course_id, attendance_date);

create index if not exists idx_attendance_logs_enrollment_date
on attendance_logs(enrollment_id, attendance_date);

create index if not exists idx_attendance_logs_teacher_attendance
on attendance_logs(teacher_attendance_id);


-- =====================================================
-- TRANSFER REQUESTS
-- AppSheet: Transfer Request
-- Purpose: Temporary / Permanent transfer
-- =====================================================

create table if not exists transfer_requests (
    id uuid primary key default gen_random_uuid(),

    centre_id uuid not null references centres(id) on delete cascade,
    branch_id uuid not null references branches(id) on delete restrict,

    transfer_code text not null unique,

    student_id uuid not null references students(id) on delete cascade,

    old_enrollment_id uuid not null references enrollments(id) on delete restrict,
    old_course_id uuid not null references courses(id) on delete restrict,
    new_course_id uuid not null references courses(id) on delete restrict,

    transfer_date date not null default current_date,

    status text not null default 'pending',
    transfer_mode text not null,

    end_transfer_at timestamptz,

    transfer_info text,

    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now(),

    constraint chk_transfer_mode
    check (transfer_mode in ('temporary', 'permanent')),

    constraint chk_transfer_status
    check (status in ('pending', 'active', 'completed', 'cancelled'))
);

create index if not exists idx_transfer_requests_centre
on transfer_requests(centre_id);

create index if not exists idx_transfer_requests_student
on transfer_requests(student_id);

create index if not exists idx_transfer_requests_old_enrollment
on transfer_requests(old_enrollment_id);

create index if not exists idx_transfer_requests_old_course
on transfer_requests(old_course_id);

create index if not exists idx_transfer_requests_new_course
on transfer_requests(new_course_id);

-- Only one active temporary transfer per student at a time
create unique index if not exists uq_active_temporary_transfer_per_student
on transfer_requests(student_id)
where transfer_mode = 'temporary'
and status = 'active'
and end_transfer_at is null;


-- =====================================================
-- BOOKS
-- AppSheet: Book Master
-- Purpose: Book reference for progress tracking
-- =====================================================

create table if not exists books (
    id uuid primary key default gen_random_uuid(),

    centre_id uuid not null references centres(id) on delete cascade,

    book_code text not null unique,
    book_name text not null,

    total_pages integer default 0,
    expected_attendance_to_finish integer,
    minimum_page_by_3_attend integer,
    book_level integer,

    status text not null default 'active',

    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now()
);

create index if not exists idx_books_centre
on books(centre_id);


-- =====================================================
-- STUDENT PROGRESS
-- AppSheet: Student Book Progress
-- Purpose: Book/page/star progress per student/enrollment
-- =====================================================

create table if not exists student_progress (
    id uuid primary key default gen_random_uuid(),

    centre_id uuid not null references centres(id) on delete cascade,

    progress_code text not null unique,

    student_id uuid not null references students(id) on delete cascade,
    course_id uuid not null references courses(id) on delete restrict,
    enrollment_id uuid not null references enrollments(id) on delete cascade,
    book_id uuid references books(id) on delete set null,

    current_page integer default 0,
    star_rating integer,

    progress_date date not null default current_date,

    pages_remaining integer,
    attendance_count integer,
    expected_page_now integer,
    progress_gap integer,

    status text,
    urgency_level text,

    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now(),

    constraint chk_star_rating
    check (star_rating is null or star_rating between 1 and 5)
);

create index if not exists idx_student_progress_centre
on student_progress(centre_id);

create index if not exists idx_student_progress_student
on student_progress(student_id);

create index if not exists idx_student_progress_course
on student_progress(course_id);

create index if not exists idx_student_progress_enrollment
on student_progress(enrollment_id);

create index if not exists idx_student_progress_book
on student_progress(book_id);

-- Optional duplicate guard:
-- One progress update per enrollment per date per book.
create unique index if not exists uq_progress_enrollment_book_date
on student_progress(enrollment_id, book_id, progress_date)
where book_id is not null;


-- =====================================================
-- END OF schema_attendance.sql
-- =====================================================
