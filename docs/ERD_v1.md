[eHadir_ERD_v1.md](https://github.com/user-attachments/files/28455767/eHadir_ERD_v1.md)

# eHadir Tuition Management System
## ERD v1

centres
├── branches
│   ├── students
│   │   ├── enrollments
│   │   │   ├── attendance_logs
│   │   │   ├── fees
│   │   │   │   └── payments
│   │   │   ├── student_progress
│   │   │   └── transfer_requests
│   │   ├── leaves
│   │   └── enroll_requests
│   │
│   ├── teachers
│   │   ├── teacher_attendances
│   │   │   └── attendance_logs
│   │   ├── salary_rate_rules
│   │   └── leaves
│   │
│   ├── courses
│   │   ├── enrollments
│   │   ├── teacher_attendances
│   │   ├── attendance_logs
│   │   ├── salary_rate_rules
│   │   └── transfer_requests
│   │
│   └── leaves
│
├── books
└── profiles

Key Relationships

students -> enrollments
courses -> enrollments

enrollments -> attendance_logs
teacher_attendances -> attendance_logs

enrollments -> fees
fees -> payments

books -> student_progress
students -> student_progress
enrollments -> student_progress

teachers -> teacher_attendances
salary_rate_rules -> teacher_attendances

students -> transfer_requests
enrollments -> transfer_requests
courses -> transfer_requests
