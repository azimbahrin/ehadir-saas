-- ==========================================
-- eHadir SaaS Seed Data v1
-- ==========================================

-- CENTRE
insert into centres (
    centre_name,
    status
)
values (
    'SMART Tuition Centre',
    'active'
);

-- BRANCHES
insert into branches (
    centre_id,
    branch_name,
    status
)
select
    id,
    'HQ',
    'active'
from centres
where centre_name = 'SMART Tuition Centre';

insert into branches (
    centre_id,
    branch_name,
    status
)
select
    id,
    'Senai',
    'active'
from centres
where centre_name = 'SMART Tuition Centre';

-- TEACHER
insert into teachers (
    centre_id,
    branch_id,
    teacher_code,
    teacher_name,
    status
)
select
    c.id,
    b.id,
    'TEN2026-0001',
    'Cikgu Azim',
    'active'
from centres c
join branches b on b.centre_id = c.id
where c.centre_name = 'SMART Tuition Centre'
and b.branch_name = 'HQ';

-- COURSE
insert into courses (
    centre_id,
    branch_id,
    course_code,
    course_name,
    day_of_week,
    monthly_fee,
    class_type,
    teacher_id,
    status
)
select
    c.id,
    b.id,
    'K2026-0001',
    'Matematik 6 Tahun',
    'Saturday',
    120.00,
    'Weekend',
    t.id,
    'active'
from centres c
join branches b on b.centre_id = c.id
join teachers t on t.centre_id = c.id
where c.centre_name = 'SMART Tuition Centre'
and b.branch_name = 'HQ'
and t.teacher_code = 'TEN2026-0001';

-- STUDENT
insert into students (
    centre_id,
    branch_id,
    student_code,
    first_name,
    gender,
    age,
    status
)
select
    c.id,
    b.id,
    'S2026-0001',
    'Ali',
    'Male',
    6,
    'active'
from centres c
join branches b on b.centre_id = c.id
where c.centre_name = 'SMART Tuition Centre'
and b.branch_name = 'HQ';

-- ENROLLMENT
insert into enrollments (
    centre_id,
    branch_id,
    enrollment_code,
    student_id,
    course_id,
    date_enrolled,
    status
)
select
    c.id,
    b.id,
    'ENR0001',
    s.id,
    cr.id,
    current_date,
    'active'
from centres c
join branches b on b.centre_id = c.id
join students s on s.centre_id = c.id
join courses cr on cr.centre_id = c.id
where c.centre_name = 'SMART Tuition Centre'
and b.branch_name = 'HQ'
and s.student_code = 'S2026-0001'
and cr.course_code = 'K2026-0001';
