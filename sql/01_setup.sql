-- 01_setup.sql; FIRST-TIME SETUP. Run it once.
-- FitTrack - CS157A Team 4, MySQL Community Server 8.0
--
-- What it does:
--   - creates the fittrack database
--   - creates all eleven tables with their keys and constraints
--   - loads sample data (at least 10 rows in every table)
--   - prints a row count per table so you can confirm it worked
--
-- How to run it:
--   MySQL Workbench - File > Open SQL Script, pick this file,
--                     then click the lightning bolt to run the whole script.
--   Command line    - mysql -u root -p < 01_setup.sql
--
-- Safe to re-run: the script drops and rebuilds the fittrack database each
-- time, so you always get a clean, known state. It touches nothing else on
-- the MySQL server.
--
-- 02_fittrack_schema.sql and 03_seed.sql hold the same statements split in
-- two, for when we want to reload sample data without rebuilding the tables.
-- Keep the data here and in 03_seed.sql identical, or the two paths will
-- produce different databases.

DROP DATABASE IF EXISTS fittrack;
CREATE DATABASE fittrack CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE fittrack;

-- ---------------------------------------------------------------------
-- Accounts and people: UserAccount ISA Member | Trainer | Staff
-- (total, disjoint). Shared attributes live on UserAccount. Each subclass
-- inherits UserId as its key: UserId is both its PRIMARY KEY and a FOREIGN
-- KEY to UserAccount (ISA)
-- ---------------------------------------------------------------------

CREATE TABLE UserAccount (
    UserId        INT AUTO_INCREMENT PRIMARY KEY,
    Email         VARCHAR(120) NOT NULL,
    PasswordHash  VARCHAR(255) NOT NULL,
    Role          ENUM('MEMBER','TRAINER','STAFF') NOT NULL,
    Name          VARCHAR(120) NOT NULL,
    Phone         VARCHAR(20),
    DateOfBirth   DATE,
    CreatedAt     DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_useraccount_email UNIQUE (Email)
);

CREATE TABLE Member (
    UserId                INT PRIMARY KEY,
    EmergencyPhoneNumber  VARCHAR(20),
    CONSTRAINT fk_member_user FOREIGN KEY (UserId)
        REFERENCES UserAccount(UserId) ON DELETE CASCADE
);

-- Staff manage memberships and trainers. Created before Trainer and
-- Membership because both reference it.
CREATE TABLE Staff (
    UserId        INT PRIMARY KEY,
    JobTitle      VARCHAR(80) NOT NULL,
    CONSTRAINT fk_staff_user FOREIGN KEY (UserId)
        REFERENCES UserAccount(UserId) ON DELETE CASCADE
);

-- Added by (Staff, exactly one): every trainer was added by one staff member.
-- AddedBy holds that staff member's UserId.
CREATE TABLE Trainer (
    UserId        INT PRIMARY KEY,
    Bio           VARCHAR(500),
    HireDate      DATE,
    AddedBy       INT NOT NULL,
    CONSTRAINT fk_trainer_user FOREIGN KEY (UserId)
        REFERENCES UserAccount(UserId) ON DELETE CASCADE,
    CONSTRAINT fk_trainer_addedby FOREIGN KEY (AddedBy)
        REFERENCES Staff(UserId)
);

-- Memberships and payments
CREATE TABLE MembershipTier (
    TierId        INT AUTO_INCREMENT PRIMARY KEY,
    TierName      VARCHAR(60) NOT NULL,
    TierLevel     INT NOT NULL,
    Fee           DECIMAL(8,2) NOT NULL,
    Description   VARCHAR(255),
    CONSTRAINT uq_tier_name UNIQUE (TierName),
    CONSTRAINT ck_tier_fee CHECK (Fee >= 0)
);

-- Holds (Member, exactly one), Of tier (MembershipTier, exactly one), and
-- Updated by (Staff, at most one). UpdatedBy is NULL when no staff member
-- has changed the membership, e.g. a member bought or renewed it online.
-- MemberId holds the member's UserId; UpdatedBy holds a staff UserId.
CREATE TABLE Membership (
    MembershipId  INT AUTO_INCREMENT PRIMARY KEY,
    MemberId      INT NOT NULL,
    TierId        INT NOT NULL,
    StartDate     DATE NOT NULL,
    EndDate       DATE NOT NULL,
    Status        ENUM('ACTIVE','EXPIRED','CANCELLED') NOT NULL DEFAULT 'ACTIVE',
    UpdatedBy     INT NULL,
    CONSTRAINT fk_membership_member FOREIGN KEY (MemberId)
        REFERENCES Member(UserId) ON DELETE CASCADE,
    CONSTRAINT fk_membership_tier FOREIGN KEY (TierId)
        REFERENCES MembershipTier(TierId),
    CONSTRAINT fk_membership_updatedby FOREIGN KEY (UpdatedBy)
        REFERENCES Staff(UserId) ON DELETE SET NULL,
    CONSTRAINT ck_membership_dates CHECK (EndDate > StartDate)
);

-- Weak entity, identified through Paid by. Key = owner's key + partial key.
-- PaymentNo counts 1, 2, 3, ... within each membership.
CREATE TABLE Payment (
    MembershipId  INT NOT NULL,
    PaymentNo     INT NOT NULL,
    Amount        DECIMAL(8,2) NOT NULL,
    PayDate       DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    Method        ENUM('CARD','CASH','ONLINE') NOT NULL,
    CONSTRAINT pk_payment PRIMARY KEY (MembershipId, PaymentNo),
    CONSTRAINT fk_payment_membership FOREIGN KEY (MembershipId)
        REFERENCES Membership(MembershipId) ON DELETE CASCADE,
    CONSTRAINT ck_payment_no CHECK (PaymentNo > 0),
    CONSTRAINT ck_payment_amount CHECK (Amount > 0)
);

-- Classes, bookings, attendance
-- The kind of class: Barbell Strength, Spin 45, ...
CREATE TABLE ClassType (
    ClassTypeId   INT AUTO_INCREMENT PRIMARY KEY,
    Title         VARCHAR(80) NOT NULL,
    Description   VARCHAR(255),
    CONSTRAINT uq_classtype_title UNIQUE (Title)
);

-- One scheduled occurrence that members book.
-- Of type (ClassType, exactly one) and Leads (Trainer, exactly one)
-- TrainerId holds the trainer's UserId.
CREATE TABLE `Class` (
    ClassId       INT AUTO_INCREMENT PRIMARY KEY,
    ClassTypeId   INT NOT NULL,
    TrainerId     INT NOT NULL,
    RoomNumber    VARCHAR(20) NOT NULL,
    StartTime     DATETIME NOT NULL,
    Capacity      INT NOT NULL,
    CONSTRAINT fk_class_type FOREIGN KEY (ClassTypeId)
        REFERENCES ClassType(ClassTypeId),
    CONSTRAINT fk_class_trainer FOREIGN KEY (TrainerId)
        REFERENCES Trainer(UserId),
    -- a trainer cannot lead two classes at the same time
    CONSTRAINT uq_trainer_slot UNIQUE (TrainerId, StartTime),
    CONSTRAINT ck_class_capacity CHECK (Capacity > 0)
);

-- Makes (Member, exactly one) and Reserves (Class, exactly one)
-- MemberId holds the member's UserId.
-- Capacity rule (BOOKED rows <= Class.Capacity) is checked by the app
-- before INSERT, because a CHECK cannot count rows in another table.
CREATE TABLE Booking (
    BookingId     INT AUTO_INCREMENT PRIMARY KEY,
    MemberId      INT NOT NULL,
    ClassId       INT NOT NULL,
    BookedAt      DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    Status        ENUM('BOOKED','CANCELLED') NOT NULL DEFAULT 'BOOKED',
    CONSTRAINT fk_booking_member FOREIGN KEY (MemberId)
        REFERENCES Member(UserId) ON DELETE CASCADE,
    CONSTRAINT fk_booking_class FOREIGN KEY (ClassId)
        REFERENCES `Class`(ClassId) ON DELETE CASCADE,
    -- a member cannot book the same class twice
    CONSTRAINT uq_member_class UNIQUE (MemberId, ClassId)
);

-- Checks in (Member, exactly one) and For (Class, at most one).
-- ClassId is NULL for a plain gym visit.
CREATE TABLE Attendance (
    AttendanceId  INT AUTO_INCREMENT PRIMARY KEY,
    MemberId      INT NOT NULL,
    ClassId       INT NULL,
    CheckInTime   DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_attendance_member FOREIGN KEY (MemberId)
        REFERENCES Member(UserId) ON DELETE CASCADE,
    CONSTRAINT fk_attendance_class FOREIGN KEY (ClassId)
        REFERENCES `Class`(ClassId) ON DELETE SET NULL
);

CREATE INDEX idx_class_start ON `Class` (StartTime);
CREATE INDEX idx_membership_status ON Membership (Status, EndDate);

-- Accounts: UserId 1-10 are trainers, 11-20 are members, 21-30 are staff.
-- PasswordHash holds the plain demo password until hashing is added,
-- because login.jsp currently compares it directly. Every account: demo123
INSERT INTO UserAccount (UserId, Email, PasswordHash, Role, Name, Phone, DateOfBirth) VALUES
    ( 1, 'john.doe@fittrack.test',         'demo123', 'TRAINER', 'John Doe',         '408-555-0101', '1988-02-14'),
    ( 2, 'jane.doe@fittrack.test',         'demo123', 'TRAINER', 'Jane Doe',         '408-555-0102', '1990-09-03'),
    ( 3, 'robert.pattinson@fittrack.test', 'demo123', 'TRAINER', 'Robert Pattinson', '408-555-0103', '1986-05-13'),
    ( 4, 'aisha.mensah@fittrack.test',     'demo123', 'TRAINER', 'Aisha Mensah',     '408-555-0104', '1992-11-21'),
    ( 5, 'carlos.mendoza@fittrack.test',   'demo123', 'TRAINER', 'Carlos Mendoza',   '408-555-0105', '1984-07-30'),
    ( 6, 'hannah.lee@fittrack.test',       'demo123', 'TRAINER', 'Hannah Lee',       '408-555-0106', '1995-01-08'),
    ( 7, 'victor.okafor@fittrack.test',    'demo123', 'TRAINER', 'Victor Okafor',    '408-555-0107', '1989-03-26'),
    ( 8, 'mei.chen@fittrack.test',         'demo123', 'TRAINER', 'Mei Chen',         '408-555-0108', '1997-12-02'),
    ( 9, 'liam.obrien@fittrack.test',      'demo123', 'TRAINER', 'Liam O''Brien',    '408-555-0109', '1991-06-17'),
    (10, 'grace.park@fittrack.test',       'demo123', 'TRAINER', 'Grace Park',       '408-555-0110', '1994-10-11'),
    (11, 'thai.nguyen@example.com',        'demo123', 'MEMBER',  'Thai Nguyen',      '408-555-0155', '1998-04-12'),
    (12, 'jack.nicholson@example.com',     'demo123', 'MEMBER',  'Jack Nicholson',   '408-555-0177', '1937-04-22'),
    (13, 'cara.silva@example.com',         'demo123', 'MEMBER',  'Cara Silva',       '669-555-0110', '2000-06-27'),
    (14, 'priya.raman@example.com',        'demo123', 'MEMBER',  'Priya Raman',      '408-555-0142', '2004-02-19'),
    (15, 'marcus.bell@example.com',        'demo123', 'MEMBER',  'Marcus Bell',      '650-555-0123', '1985-08-09'),
    (16, 'elena.vasquez@example.com',      'demo123', 'MEMBER',  'Elena Vasquez',    '408-555-0168', '1993-12-30'),
    (17, 'daniel.kim@example.com',         'demo123', 'MEMBER',  'Daniel Kim',       '669-555-0134', '1999-03-05'),
    (18, 'sofia.rossi@example.com',        'demo123', 'MEMBER',  'Sofia Rossi',      '650-555-0189', '1996-07-14'),
    (19, 'omar.haddad@example.com',        'demo123', 'MEMBER',  'Omar Haddad',      '408-555-0191', '1955-11-02'),
    (20, 'linh.tran@example.com',          'demo123', 'MEMBER',  'Linh Tran',        '669-555-0146', '1990-05-25'),
    (21, 'nina.alvarez@fittrack.test',     'demo123', 'STAFF',   'Nina Alvarez',     '408-555-0201', '1979-08-16'),
    (22, 'derek.wong@fittrack.test',       'demo123', 'STAFF',   'Derek Wong',       '408-555-0202', '1983-01-29'),
    (23, 'maria.lopez@fittrack.test',      'demo123', 'STAFF',   'Maria Lopez',      '408-555-0203', '1987-10-04'),
    (24, 'kevin.tran@fittrack.test',       'demo123', 'STAFF',   'Kevin Tran',       '408-555-0204', '2001-03-18'),
    (25, 'ashley.brooks@fittrack.test',    'demo123', 'STAFF',   'Ashley Brooks',    '408-555-0205', '2002-07-09'),
    (26, 'samuel.green@fittrack.test',     'demo123', 'STAFF',   'Samuel Green',     '408-555-0206', '1992-12-21'),
    (27, 'fatima.yusuf@fittrack.test',     'demo123', 'STAFF',   'Fatima Yusuf',     '408-555-0207', '1990-04-02'),
    (28, 'brian.foster@fittrack.test',     'demo123', 'STAFF',   'Brian Foster',     '408-555-0208', '1985-06-27'),
    (29, 'chloe.martin@fittrack.test',     'demo123', 'STAFF',   'Chloe Martin',     '408-555-0209', '1998-09-13'),
    (30, 'ryan.patel@fittrack.test',       'demo123', 'STAFF',   'Ryan Patel',       '408-555-0210', '1994-02-08');

-- Staff: UserId 21-30. Inserted before Trainer because Trainer.AddedBy
-- references Staff.
INSERT INTO Staff (UserId, JobTitle) VALUES
    (21, 'General Manager'),
    (22, 'Fitness Director'),
    (23, 'Membership Manager'),
    (24, 'Front Desk Associate'),
    (25, 'Front Desk Associate'),
    (26, 'Corporate Accounts Coordinator'),
    (27, 'Billing Specialist'),
    (28, 'Facilities Manager'),
    (29, 'Member Services Lead'),
    (30, 'Operations Coordinator');

-- Trainers: UserId 1-10. AddedBy is the UserId of the staff member who
-- added the trainer: the General Manager (21) or Fitness Director (22).
INSERT INTO Trainer (UserId, Bio, HireDate, AddedBy) VALUES
    ( 1, 'Strength and conditioning, 8 years.',              '2021-03-01', 21),
    ( 2, 'Cycling and endurance coaching.',                  '2022-07-15', 22),
    ( 3, 'Functional training and sports performance.',      '2023-01-09', 22),
    ( 4, 'Vinyasa yoga and mobility, RYT-500 certified.',    '2020-09-14', 21),
    ( 5, 'Boxing technique and conditioning, former amateur.','2019-05-20', 21),
    ( 6, 'Pilates and core rehabilitation.',                 '2022-02-01', 22),
    ( 7, 'Kettlebell and strongman training.',               '2021-11-08', 21),
    ( 8, 'Dance fitness and Zumba instructor.',              '2023-06-12', 22),
    ( 9, 'Rowing and aerobic endurance.',                    '2024-01-15', 22),
    (10, 'HIIT and outdoor bootcamp coach.',                 '2024-08-05', 22);

-- Members: UserId 11-20.
INSERT INTO Member (UserId, EmergencyPhoneNumber) VALUES
    (11, '408-555-0156'),
    (12, '408-555-0178'),
    (13, '669-555-0111'),
    (14, '408-555-0143'),
    (15, '650-555-0124'),
    (16, '408-555-0169'),
    (17, '669-555-0135'),
    (18, '650-555-0190'),
    (19, '408-555-0192'),
    (20, '669-555-0147');

-- ---------------------------------------------------------------------
-- Membership tiers. Fee is the monthly fee.
-- ---------------------------------------------------------------------

INSERT INTO MembershipTier (TierId, TierName, TierLevel, Fee, Description) VALUES
    ( 1, 'Off-Peak',      1,  24.00, 'Gym floor weekdays 10am-4pm, up to 4 classes a month.'),
    ( 2, 'Student',       1,  25.00, 'Gym floor plus 4 classes a month with a valid student ID.'),
    ( 3, 'Senior',        1,  25.00, 'Gym floor plus 4 classes a month for members 65 and over.'),
    ( 4, 'Basic',         2,  29.00, 'Gym floor access during staffed hours.'),
    ( 5, 'Silver',        3,  49.00, 'Gym floor plus up to 8 booked classes a month.'),
    ( 6, 'Corporate',     3,  45.00, 'Silver benefits, billed through a partner employer.'),
    ( 7, 'Gold',          4,  79.00, 'Unlimited classes and 2 guest passes a month.'),
    ( 8, 'Family',        4, 129.00, 'Gold benefits for up to 4 people in one household.'),
    ( 9, 'Platinum',      5, 109.00, 'Unlimited classes plus 2 personal training sessions a month.'),
    (10, 'Elite Athlete', 6, 149.00, 'Platinum plus recovery room and nutrition coaching.');

-- Memberships. Dates are relative to today so statuses stay correct.
-- MemberId and UpdatedBy are UserIds (members 11-20, staff 21-30).
-- Cara (13) renewed after her Basic expired; Sofia (18) cancelled Gold and
-- moved to Basic; Elena (16) has only an expired membership, so she has
-- no upcoming bookings.
-- UpdatedBy: the staff member who last changed the membership. NULL means
-- the member bought or renewed it online with no staff involvement.
--   Membership Manager (23) processed Sofia's cancellation and tier change;
--   front desk (24, 25) verified Priya's student ID and Omar's senior rate;
--   Corporate Accounts (26) set up Linh's employer-billed plan;
--   Member Services (29) updated Cara's renewal.
INSERT INTO Membership (MembershipId, MemberId, TierId, StartDate, EndDate, Status, UpdatedBy) VALUES
    ( 1, 11,  5, DATE_SUB(CURDATE(), INTERVAL  40 DAY), DATE_ADD(CURDATE(), INTERVAL 325 DAY), 'ACTIVE', NULL),
    ( 2, 12,  7, DATE_SUB(CURDATE(), INTERVAL  10 DAY), DATE_ADD(CURDATE(), INTERVAL 355 DAY), 'ACTIVE', NULL),
    ( 3, 13,  4, DATE_SUB(CURDATE(), INTERVAL 400 DAY), DATE_SUB(CURDATE(), INTERVAL  35 DAY), 'EXPIRED', NULL),
    ( 4, 14,  2, DATE_SUB(CURDATE(), INTERVAL  60 DAY), DATE_ADD(CURDATE(), INTERVAL 120 DAY), 'ACTIVE', 24),
    ( 5, 15,  9, DATE_SUB(CURDATE(), INTERVAL  20 DAY), DATE_ADD(CURDATE(), INTERVAL 345 DAY), 'ACTIVE', NULL),
    ( 6, 16,  5, DATE_SUB(CURDATE(), INTERVAL 300 DAY), DATE_SUB(CURDATE(), INTERVAL   5 DAY), 'EXPIRED', NULL),
    ( 7, 17,  1, DATE_SUB(CURDATE(), INTERVAL  90 DAY), DATE_ADD(CURDATE(), INTERVAL  90 DAY), 'ACTIVE', NULL),
    ( 8, 18,  7, DATE_SUB(CURDATE(), INTERVAL 200 DAY), DATE_ADD(CURDATE(), INTERVAL 165 DAY), 'CANCELLED', 23),
    ( 9, 19,  3, DATE_SUB(CURDATE(), INTERVAL  15 DAY), DATE_ADD(CURDATE(), INTERVAL 350 DAY), 'ACTIVE', 25),
    (10, 20,  6, DATE_SUB(CURDATE(), INTERVAL  45 DAY), DATE_ADD(CURDATE(), INTERVAL 320 DAY), 'ACTIVE', 26),
    (11, 13,  5, DATE_SUB(CURDATE(), INTERVAL  30 DAY), DATE_ADD(CURDATE(), INTERVAL 335 DAY), 'ACTIVE', 29),
    (12, 18,  4, DATE_SUB(CURDATE(), INTERVAL  30 DAY), DATE_ADD(CURDATE(), INTERVAL  60 DAY), 'ACTIVE', 23);

-- Payments (weak entity). One row per monthly charge; PaymentNo restarts
-- at 1 for each membership. Amount matches the tier's Fee.
INSERT INTO Payment (MembershipId, PaymentNo, Amount, PayDate, Method) VALUES
    ( 1, 1,  49.00, DATE_SUB(NOW(), INTERVAL  40 DAY), 'CARD'),
    ( 1, 2,  49.00, DATE_SUB(NOW(), INTERVAL  10 DAY), 'CARD'),
    ( 2, 1,  79.00, DATE_SUB(NOW(), INTERVAL  10 DAY), 'ONLINE'),
    ( 3, 1,  29.00, DATE_SUB(NOW(), INTERVAL 400 DAY), 'CASH'),
    ( 3, 2,  29.00, DATE_SUB(NOW(), INTERVAL 370 DAY), 'CASH'),
    ( 4, 1,  25.00, DATE_SUB(NOW(), INTERVAL  60 DAY), 'ONLINE'),
    ( 4, 2,  25.00, DATE_SUB(NOW(), INTERVAL  30 DAY), 'ONLINE'),
    ( 5, 1, 109.00, DATE_SUB(NOW(), INTERVAL  20 DAY), 'CARD'),
    ( 6, 1,  49.00, DATE_SUB(NOW(), INTERVAL 300 DAY), 'CARD'),
    ( 7, 1,  24.00, DATE_SUB(NOW(), INTERVAL  90 DAY), 'CASH'),
    ( 7, 2,  24.00, DATE_SUB(NOW(), INTERVAL  60 DAY), 'CASH'),
    ( 7, 3,  24.00, DATE_SUB(NOW(), INTERVAL  30 DAY), 'CARD'),
    ( 8, 1,  79.00, DATE_SUB(NOW(), INTERVAL 200 DAY), 'ONLINE'),
    ( 9, 1,  25.00, DATE_SUB(NOW(), INTERVAL  15 DAY), 'CASH'),
    (10, 1,  45.00, DATE_SUB(NOW(), INTERVAL  45 DAY), 'ONLINE'),
    (10, 2,  45.00, DATE_SUB(NOW(), INTERVAL  15 DAY), 'ONLINE'),
    (11, 1,  49.00, DATE_SUB(NOW(), INTERVAL  30 DAY), 'CARD'),
    (12, 1,  29.00, DATE_SUB(NOW(), INTERVAL  30 DAY), 'CARD');

-- Class types and scheduled classes
INSERT INTO ClassType (ClassTypeId, Title, Description) VALUES
    ( 1, 'Barbell Strength',        'Squat, press, and deadlift technique.'),
    ( 2, 'Spin 45',                 'Indoor cycling intervals.'),
    ( 3, 'Mobility Flow',           'Guided stretching and joint work.'),
    ( 4, 'HIIT Circuit',            'Timed stations, full body.'),
    ( 5, 'Vinyasa Yoga',            'Breath-linked flowing yoga sequences.'),
    ( 6, 'Pilates Core',            'Mat Pilates focused on core stability.'),
    ( 7, 'Boxing Fundamentals',     'Stance, footwork, and bag combinations.'),
    ( 8, 'Kettlebell Conditioning', 'Swings, cleans, and carries.'),
    ( 9, 'Zumba',                   'Latin-inspired dance cardio.'),
    (10, 'Rowing Intervals',        'Erg intervals for aerobic power.');

-- Hours are counted from midnight today: -42 = two days ago 6am,
-- -6 = yesterday 6pm, 30 = tomorrow 6am, 42 = tomorrow 6pm, and so on.
-- Classes 1-4 are in the past so attendance can point at them.
-- Class 9 has capacity 3 and three bookings, so it shows as FULL.
INSERT INTO `Class` (ClassId, ClassTypeId, TrainerId, RoomNumber, StartTime, Capacity) VALUES
    ( 1,  1,  1, 'Studio A', DATE_ADD(DATE(NOW()), INTERVAL -42 HOUR), 12),
    ( 2,  2,  2, 'Cycle',    DATE_ADD(DATE(NOW()), INTERVAL -30 HOUR), 20),
    ( 3,  5,  4, 'Studio B', DATE_ADD(DATE(NOW()), INTERVAL -18 HOUR), 15),
    ( 4,  4, 10, 'Studio A', DATE_ADD(DATE(NOW()), INTERVAL  -6 HOUR), 10),
    ( 5,  1,  1, 'Studio A', DATE_ADD(DATE(NOW()), INTERVAL  30 HOUR), 12),
    ( 6,  2,  2, 'Cycle',    DATE_ADD(DATE(NOW()), INTERVAL  42 HOUR), 20),
    ( 7,  7,  5, 'Studio C', DATE_ADD(DATE(NOW()), INTERVAL  43 HOUR), 10),
    ( 8,  3,  3, 'Studio B', DATE_ADD(DATE(NOW()), INTERVAL  55 HOUR), 15),
    ( 9,  4, 10, 'Studio A', DATE_ADD(DATE(NOW()), INTERVAL  66 HOUR),  3),
    (10,  6,  6, 'Studio B', DATE_ADD(DATE(NOW()), INTERVAL  78 HOUR), 12),
    (11,  8,  7, 'Studio A', DATE_ADD(DATE(NOW()), INTERVAL  90 HOUR),  8),
    (12, 10,  9, 'Studio C', DATE_ADD(DATE(NOW()), INTERVAL 102 HOUR), 10),
    (13,  9,  8, 'Studio B', DATE_ADD(DATE(NOW()), INTERVAL 114 HOUR), 25),
    (14,  5,  4, 'Studio B', DATE_ADD(DATE(NOW()), INTERVAL 126 HOUR), 15),
    (15,  2,  2, 'Cycle',    DATE_ADD(DATE(NOW()), INTERVAL 138 HOUR), 20),
    (16,  1,  1, 'Studio A', DATE_ADD(DATE(NOW()), INTERVAL 150 HOUR), 12);

-- ---------------------------------------------------------------------
-- Bookings. Only members with an active membership book upcoming classes.
-- Class 5 has one CANCELLED row, which proves spots left ignores it.
-- ---------------------------------------------------------------------

-- Bookings for the past classes, made four days ago
INSERT INTO Booking (MemberId, ClassId, BookedAt, Status) VALUES
    (11, 1, DATE_SUB(NOW(), INTERVAL 4 DAY), 'BOOKED'),
    (12, 1, DATE_SUB(NOW(), INTERVAL 4 DAY), 'BOOKED'),
    (15, 1, DATE_SUB(NOW(), INTERVAL 4 DAY), 'BOOKED'),
    (13, 2, DATE_SUB(NOW(), INTERVAL 4 DAY), 'BOOKED'),
    (17, 2, DATE_SUB(NOW(), INTERVAL 4 DAY), 'BOOKED'),
    (14, 3, DATE_SUB(NOW(), INTERVAL 4 DAY), 'BOOKED'),
    (19, 3, DATE_SUB(NOW(), INTERVAL 4 DAY), 'BOOKED'),
    (20, 4, DATE_SUB(NOW(), INTERVAL 4 DAY), 'BOOKED'),
    (11, 4, DATE_SUB(NOW(), INTERVAL 4 DAY), 'BOOKED'),
    (18, 4, DATE_SUB(NOW(), INTERVAL 4 DAY), 'CANCELLED');

-- Bookings for upcoming classes, made today
INSERT INTO Booking (MemberId, ClassId, Status) VALUES
    (11,  5, 'BOOKED'), (12,  5, 'BOOKED'), (13,  5, 'CANCELLED'),
    (11,  6, 'BOOKED'), (13,  6, 'BOOKED'), (17,  6, 'BOOKED'),
    (15,  7, 'BOOKED'), (20,  7, 'BOOKED'),
    (12,  8, 'BOOKED'), (19,  8, 'BOOKED'),
    (11,  9, 'BOOKED'), (12,  9, 'BOOKED'), (14,  9, 'BOOKED'),
    (18, 10, 'BOOKED'), (14, 10, 'BOOKED'),
    (15, 11, 'BOOKED'), (17, 11, 'BOOKED'),
    (20, 12, 'BOOKED'),
    (13, 13, 'BOOKED'), (18, 13, 'BOOKED'), (14, 13, 'BOOKED'),
    (19, 14, 'BOOKED'),
    (12, 16, 'BOOKED'), (15, 16, 'BOOKED');

-- ---------------------------------------------------------------------
-- Attendance
-- ---------------------------------------------------------------------

-- Class check-ins: members who booked a past class and showed up, checked
-- in 10 minutes before it started. Marcus (15) booked class 1 but no-showed.
INSERT INTO Attendance (MemberId, ClassId, CheckInTime)
SELECT b.MemberId, b.ClassId, DATE_SUB(c.StartTime, INTERVAL 10 MINUTE)
    FROM Booking b
    JOIN `Class` c ON c.ClassId = b.ClassId
    WHERE b.Status = 'BOOKED'
    AND (b.MemberId, b.ClassId) IN ((11,1), (12,1), (13,2), (17,2),
                                    (14,3), (19,3), (20,4), (11,4))
    ORDER BY c.StartTime;

-- Plain gym visits, not tied to a class (ClassId is NULL)
INSERT INTO Attendance (MemberId, ClassId, CheckInTime) VALUES
    (16, NULL, DATE_SUB(NOW(), INTERVAL 10 DAY)),
    (11, NULL, DATE_SUB(NOW(), INTERVAL  3 DAY)),
    (15, NULL, DATE_SUB(NOW(), INTERVAL  3 DAY)),
    (12, NULL, DATE_SUB(NOW(), INTERVAL  1 DAY)),
    (18, NULL, DATE_SUB(NOW(), INTERVAL  1 DAY)),
    (17, NULL, DATE_SUB(NOW(), INTERVAL 20 HOUR)),
    (20, NULL, DATE_SUB(NOW(), INTERVAL  8 HOUR)),
    (13, NULL, DATE_SUB(NOW(), INTERVAL  4 HOUR)),
    (19, NULL, DATE_SUB(NOW(), INTERVAL  2 HOUR));

-- ---------------------------------------------------------------------
-- Check: all eleven tables, each should show 10 or more rows.
-- ---------------------------------------------------------------------

SELECT 'UserAccount' AS TableName, COUNT(*) AS RowsLoaded FROM UserAccount
UNION ALL SELECT 'Member',          COUNT(*) FROM Member
UNION ALL SELECT 'Trainer',         COUNT(*) FROM Trainer
UNION ALL SELECT 'Staff',           COUNT(*) FROM Staff
UNION ALL SELECT 'MembershipTier',  COUNT(*) FROM MembershipTier
UNION ALL SELECT 'Membership',      COUNT(*) FROM Membership
UNION ALL SELECT 'Payment',         COUNT(*) FROM Payment
UNION ALL SELECT 'ClassType',       COUNT(*) FROM ClassType
UNION ALL SELECT 'Class',           COUNT(*) FROM `Class`
UNION ALL SELECT 'Booking',         COUNT(*) FROM Booking
UNION ALL SELECT 'Attendance',      COUNT(*) FROM Attendance;

-- Upcoming classes with remaining spots, the same rows the home page shows.
SELECT c.StartTime,
        ct.Title,
        u.Name AS Trainer,
        c.RoomNumber,
        c.Capacity,
        c.Capacity - (SELECT COUNT(*)
                        FROM Booking b
                        WHERE b.ClassId = c.ClassId
                            AND b.Status = 'BOOKED') AS RemainingSpots
    FROM `Class` c
    JOIN ClassType ct ON ct.ClassTypeId = c.ClassTypeId
    JOIN Trainer t    ON t.UserId = c.TrainerId
    JOIN UserAccount u ON u.UserId = t.UserId
    WHERE c.StartTime >= NOW()
    ORDER BY c.StartTime;