[eHadir_PRD_v1.md](https://github.com/user-attachments/files/28455656/eHadir_PRD_v1.md)

# eHadir Tuition Management System
## Product Requirements Document (PRD) v1.0

### Product Type
Multi-Tenant SaaS Tuition Management Platform

## Executive Summary
eHadir Tuition Management System ialah platform SaaS untuk mengurus pelajar, guru, kelas, kehadiran, progress pembelajaran, yuran, pembayaran, gaji guru, cuti dan dashboard operasi.

## Roles
1. Developer
2. Centre Admin
3. Teacher
4. Parent (Phase 2)

## Core Modules
- Student Management
- Teacher Management
- Course Management
- Enrollment Management
- Attendance Management
- Transfer Management
- Learning Progress
- Fee Management
- Payment Management
- Payroll Management
- Leave Management
- Dashboard Analytics

## Multi-Tenant Architecture
Developer
  -> Centres
      -> Branches
          -> Students
          -> Teachers
          -> Courses

All operational tables must contain centre_id.

## Core Tables
- centres
- branches
- profiles
- students
- teachers
- courses
- enrollments
- teacher_attendances
- attendance_logs
- transfer_requests
- books
- student_progress
- fees
- payments
- salary_rate_rules
- leaves
- enroll_requests

## Business Rules

### Attendance
- One attendance per enrollment per day.
- Attendance requires active Teacher Attendance session.
- Attendance linked to enrollment_id.

### Transfer
Temporary Transfer:
- Create new enrollment
- Store previous_enrollment_id
- End Transfer restores original enrollment

Permanent Transfer:
- Old enrollment inactive
- New enrollment active

### Fees
- One enrollment
- One month
- One fee record

### Salary
Teacher Attendance
-> Student Count
-> Salary Rate Rule
-> Auto Salary
-> Salary Adjustment
-> Final Salary

## Parent Portal (Phase 2)
- Attendance History
- Learning Progress
- Fees
- Payments
- Reports

## MVP Scope
Students
Teachers
Courses
Enrollments
Attendance
Transfer
Progress
Fees
Payments
Salary
Leave
Dashboard
