[eHadir_DATABASE_SCHEMA_v1.md](https://github.com/user-attachments/files/28456118/eHadir_DATABASE_SCHEMA_v1.md)

# eHadir Tuition Management System
## Database Schema v1.0

Product: eHadir Tuition Management System  
Database: Supabase PostgreSQL  
Architecture: Multi-Tenant SaaS  
Auth Model: Supabase Auth + profiles table  

---

# 1. Design Principles

## 1.1 Multi-Tenant Rule

Every operational table must include:

```sql
centre_id uuid not null references centres(id)
```

This ensures each tuition centre only accesses its own data.

## 1.2 Internal ID vs Display Code

Use UUID as internal primary key.

Example:

```text
id = uuid
student_code = S2026-0001
```

The code is shown to users. UUID is used by database relations.

## 1.3 AppSheet Mapping

| AppSheet | Supabase |
|---|---|
| Students | students |
| Teachers | teachers |
| Course | courses |
| Enrollment | enrollments |
| Attendance Log | attendance_logs |
| Teacher Attendance | teacher_attendances |
| Transfer Request | transfer_requests |
| Book Master | books |
| Student Book Progress | student_progress |
| Yuran | fees |
| Payments | payments |
| SalaryRateRule | salary_rate_rules |
| Leave | leaves |
| Enroll Request | enroll_requests |

---

# 2. Core Tables

## 2.1 centres

Purpose: Stores each tuition centre / tenant.

```sql
create table centres (
  id uuid primary key default gen_random_uuid(),
  centre_name text not null,
  status text not null default 'active',
  subscription_status text default 'trial',
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);
```

---

## 2.2 branches

Purpose: Stores centre branches.

```sql
create table branches (
  id uuid primary key default gen_random_uuid(),
  centre_id uuid not null references centres(id) on delete cascade,
  branch_code text,
  branch_name text not null,
  status text not null default 'active',
  created_at timestamptz default now(),
  updated_at timestamptz default now(),

  unique (centre_id, branch_code)
);
```

---

## 2.3 profiles

Purpose: Stores application user profile linked to Supabase Auth.

Roles:
- developer
- admin
- teacher
- parent

```sql
create table profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  centre_id uuid references centres(id) on delete set null,
  branch_id uuid references branches(id) on delete set null,
  role text not null,
  full_name text,
  email text,
  phone text,
  status text not null default 'active',
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);
```

---

# 3. Student & Teacher Module

## 3.1 students

```sql
create table students (
  id uuid primary key default gen_random_uuid(),
  centre_id uuid not null references centres(id) on delete cascade,
  branch_id uuid references branches(id) on delete set null,

  student_code text not null,
  first_name text not null,
  last_name text,
  age integer,
  gender text,
  headshot_url text,
  phone text,
  email text,
  transport text,
  status text not null default 'active',
  joined_at date default current_date,

  created_at timestamptz default now(),
  updated_at timestamptz default now(),

  unique (centre_id, student_code)
);
```

---

## 3.2 teachers

```sql
create table teachers (
  id uuid primary key default gen_random_uuid(),
  centre_id uuid not null references centres(id) on delete cascade,
  branch_id uuid references branches(id) on delete set null,

  teacher_code text not null,
  teacher_name text not null,
  profile_id uuid references profiles(id) on delete set null,
  status text not null default 'active',

  created_at timestamptz default now(),
  updated_at timestamptz default now(),

  unique (centre_id, teacher_code)
);
```

---

# 4. Course & Enrollment Module

## 4.1 courses

```sql
create table courses (
  id uuid primary key default gen_random_uuid(),
  centre_id uuid not null references centres(id) on delete cascade,
  branch_id uuid references branches(id) on delete set null,

  course_code text not null,
  course_name text not null,
  description text,
  day text,
  day_sort integer,
  start_time time,
  end_time time,
  image_url text,
  main_teacher_id uuid references teachers(id) on delete set null,
  monthly_fee numeric(10,2) default 0,
  class_type text,
  status text not null default 'active',

  created_at timestamptz default now(),
  updated_at timestamptz default now(),

  unique (centre_id, course_code)
);
```

---

## 4.2 enrollments

Enrollment is the core hub of the system.

```sql
create table enrollments (
  id uuid primary key default gen_random_uuid(),
  centre_id uuid not null references centres(id) on delete cascade,
  branch_id uuid references branches(id) on delete set null,

  enrollment_code text not null,
  student_id uuid not null references students(id) on delete cascade,
  course_id uuid not null references courses(id) on delete restrict,

  date_enrolled date default current_date,
  status text not null default 'active',

  transfer_note text,
  new_course_id uuid references courses(id) on delete set null,
  previous_enrollment_id uuid references enrollments(id) on delete set null,
  student_photo_url text,

  created_at timestamptz default now(),
  updated_at timestamptz default now(),

  unique (centre_id, enrollment_code)
);
```

Recommended unique rule for active same course protection can be handled with partial unique index later.

---

## 4.3 enroll_requests

```sql
create table enroll_requests (
  id uuid primary key default gen_random_uuid(),
  centre_id uuid not null references centres(id) on delete cascade,
  branch_id uuid references branches(id) on delete set null,

  request_code text not null,
  student_id uuid not null references students(id) on delete cascade,
  course_id uuid not null references courses(id) on delete restrict,
  enroll_date date default current_date,
  status text not null default 'pending',

  created_at timestamptz default now(),
  updated_at timestamptz default now(),

  unique (centre_id, request_code)
);
```

---

# 5. Attendance Module

## 5.1 teacher_attendances

```sql
create table teacher_attendances (
  id uuid primary key default gen_random_uuid(),
  centre_id uuid not null references centres(id) on delete cascade,
  branch_id uuid references branches(id) on delete set null,

  teacher_attendance_code text not null,
  teacher_id uuid not null references teachers(id) on delete restrict,
  course_id uuid not null references courses(id) on delete restrict,

  class_date date not null default current_date,

  start_time timestamptz,
  end_time timestamptz,

  official_start_time timestamptz,
  official_end_time timestamptz,

  total_hours numeric(8,2),
  total_students_attend integer default 0,

  salary_rate numeric(10,2) default 0,
  auto_salary numeric(10,2) default 0,
  salary_adjustment numeric(10,2) default 0,
  final_salary numeric(10,2) default 0,

  payment_status text default 'pending',
  payment_date date,
  salary_note text,
  salary_month text,

  created_at timestamptz default now(),
  updated_at timestamptz default now(),

  unique (centre_id, teacher_attendance_code)
);
```

---

## 5.2 attendance_logs

```sql
create table attendance_logs (
  id uuid primary key default gen_random_uuid(),
  centre_id uuid not null references centres(id) on delete cascade,
  branch_id uuid references branches(id) on delete set null,

  attendance_code text,
  student_id uuid not null references students(id) on delete cascade,
  course_id uuid not null references courses(id) on delete restrict,
  enrollment_id uuid not null references enrollments(id) on delete cascade,
  teacher_attendance_id uuid references teacher_attendances(id) on delete set null,

  attendance_date date not null default current_date,
  attendance_time time,

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

  created_at timestamptz default now(),
  updated_at timestamptz default now(),

  unique (enrollment_id, attendance_date)
);
```

Important rule: one attendance per enrollment per day.

---

# 6. Transfer Module

## 6.1 transfer_requests

```sql
create table transfer_requests (
  id uuid primary key default gen_random_uuid(),
  centre_id uuid not null references centres(id) on delete cascade,
  branch_id uuid references branches(id) on delete set null,

  transfer_code text not null,

  student_id uuid not null references students(id) on delete cascade,
  old_enrollment_id uuid not null references enrollments(id) on delete restrict,

  old_course_id uuid not null references courses(id) on delete restrict,
  new_course_id uuid not null references courses(id) on delete restrict,

  transfer_date date default current_date,
  status text not null default 'pending',
  transfer_mode text not null,

  end_transfer_at timestamptz,
  transfer_info text,

  created_at timestamptz default now(),
  updated_at timestamptz default now(),

  unique (centre_id, transfer_code)
);
```

Allowed transfer_mode:
- temporary
- permanent

---

# 7. Learning Progress Module

## 7.1 books

```sql
create table books (
  id uuid primary key default gen_random_uuid(),
  centre_id uuid not null references centres(id) on delete cascade,

  book_code text not null,
  book_name text not null,
  total_pages integer default 0,
  expected_attendance_to_finish integer,
  minimum_page_by_3_attend integer,
  book_level integer,

  status text default 'active',

  created_at timestamptz default now(),
  updated_at timestamptz default now(),

  unique (centre_id, book_code)
);
```

---

## 7.2 student_progress

```sql
create table student_progress (
  id uuid primary key default gen_random_uuid(),
  centre_id uuid not null references centres(id) on delete cascade,

  progress_code text not null,

  student_id uuid not null references students(id) on delete cascade,
  course_id uuid not null references courses(id) on delete restrict,
  enrollment_id uuid not null references enrollments(id) on delete cascade,
  book_id uuid references books(id) on delete set null,

  current_page integer default 0,
  star_rating integer,
  progress_date date default current_date,

  pages_remaining integer,
  attendance_count integer,
  expected_page_now integer,
  progress_gap integer,

  status text,
  urgency_level text,

  created_at timestamptz default now(),
  updated_at timestamptz default now(),

  unique (centre_id, progress_code)
);
```

---

# 8. Fee & Payment Module

## 8.1 fees

```sql
create table fees (
  id uuid primary key default gen_random_uuid(),
  centre_id uuid not null references centres(id) on delete cascade,

  fee_code text not null,

  student_id uuid not null references students(id) on delete cascade,
  enrollment_id uuid not null references enrollments(id) on delete cascade,

  fee_month date not null,
  amount numeric(10,2) not null default 0,
  amount_paid numeric(10,2) not null default 0,
  balance numeric(10,2) not null default 0,

  payment_status text not null default 'unpaid',
  payment_date date,
  label_month text,
  enrollment_month_key text,

  created_at timestamptz default now(),
  updated_at timestamptz default now(),

  unique (centre_id, fee_code),
  unique (enrollment_id, fee_month)
);
```

---

## 8.2 payments

```sql
create table payments (
  id uuid primary key default gen_random_uuid(),
  centre_id uuid not null references centres(id) on delete cascade,
  branch_id uuid references branches(id) on delete set null,

  payment_code text not null,

  student_id uuid not null references students(id) on delete cascade,
  course_id uuid references courses(id) on delete set null,
  fee_id uuid references fees(id) on delete set null,

  amount numeric(10,2) not null default 0,
  payment_date date default current_date,
  status text not null default 'completed',

  created_at timestamptz default now(),
  updated_at timestamptz default now(),

  unique (centre_id, payment_code)
);
```

---

# 9. Payroll Module

## 9.1 salary_rate_rules

```sql
create table salary_rate_rules (
  id uuid primary key default gen_random_uuid(),
  centre_id uuid not null references centres(id) on delete cascade,

  rate_rule_code text not null,

  class_type text,
  teacher_id uuid references teachers(id) on delete cascade,
  course_id uuid references courses(id) on delete cascade,

  min_student integer default 0,
  max_student integer default 0,
  session_rate numeric(10,2) not null default 0,
  note text,

  created_at timestamptz default now(),
  updated_at timestamptz default now(),

  unique (centre_id, rate_rule_code)
);
```

---

# 10. Leave Module

## 10.1 leaves

```sql
create table leaves (
  id uuid primary key default gen_random_uuid(),
  centre_id uuid not null references centres(id) on delete cascade,
  branch_id uuid references branches(id) on delete set null,

  leave_code text not null,

  leave_owner_type text not null,
  leave_scope text,

  teacher_id uuid references teachers(id) on delete cascade,
  student_id uuid references students(id) on delete cascade,

  start_date date not null,
  end_date date not null,
  reason text,
  status text not null default 'active',

  created_at timestamptz default now(),
  updated_at timestamptz default now(),

  unique (centre_id, leave_code)
);
```

Allowed leave_owner_type:
- teacher
- student

---

# 11. Optional Config Table

## 11.1 dashboard_cards

```sql
create table dashboard_cards (
  id uuid primary key default gen_random_uuid(),
  centre_id uuid references centres(id) on delete cascade,

  section text,
  title text not null,
  icon_url text,
  sort_order integer default 0,
  section_sort_order integer default 0,
  metric_key text,
  is_active boolean default true,

  created_at timestamptz default now(),
  updated_at timestamptz default now()
);
```

---

# 12. Recommended Indexes

```sql
create index idx_students_centre on students(centre_id);
create index idx_students_branch on students(branch_id);

create index idx_courses_centre on courses(centre_id);
create index idx_courses_branch on courses(branch_id);

create index idx_enrollments_student on enrollments(student_id);
create index idx_enrollments_course on enrollments(course_id);
create index idx_enrollments_status on enrollments(status);

create index idx_teacher_attendances_teacher on teacher_attendances(teacher_id);
create index idx_teacher_attendances_course_date on teacher_attendances(course_id, class_date);

create index idx_attendance_logs_enrollment_date on attendance_logs(enrollment_id, attendance_date);
create index idx_attendance_logs_student_date on attendance_logs(student_id, attendance_date);
create index idx_attendance_logs_course_date on attendance_logs(course_id, attendance_date);

create index idx_fees_enrollment_month on fees(enrollment_id, fee_month);
create index idx_payments_fee on payments(fee_id);

create index idx_transfer_student on transfer_requests(student_id);
create index idx_transfer_old_enrollment on transfer_requests(old_enrollment_id);

create index idx_progress_student on student_progress(student_id);
create index idx_progress_enrollment on student_progress(enrollment_id);

create index idx_leaves_student on leaves(student_id);
create index idx_leaves_teacher on leaves(teacher_id);
```

---

# 13. Tables Not Migrated From AppSheet

These AppSheet tables should not become physical Supabase tables in MVP:

- Dashboard
- DashboardStats
- Branch Dashboard
- Salary Summary
- Teacher Salary Summary
- Counter
- Settings

Replacement:
- Dashboard queries
- PostgreSQL views
- Frontend state
- PostgreSQL sequence / code generation function

---

# 14. Important Constraints

## Attendance Duplicate Protection

```sql
unique (enrollment_id, attendance_date)
```

## Fee Duplicate Protection

```sql
unique (enrollment_id, fee_month)
```

## Display Code Protection

Each table using user-facing code should use:

```sql
unique (centre_id, code_column)
```

Example:

```sql
unique (centre_id, student_code)
```

---

# 15. Next Step

After this schema is approved:

1. Generate `schema.sql`
2. Paste into Supabase SQL Editor
3. Create tables
4. Add Row Level Security policies
5. Connect Next.js app through Cursor
