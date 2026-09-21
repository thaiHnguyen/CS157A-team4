-- 01_setup.sql; FIRST-TIME SETUP. run it once.
-- What it does:
--   1. creates the fittrack database
--   2. creates all ten tables with their keys and constraints
--   3. loads sample accounts, trainers, members, tiers, and a schedule
--   4. prints a short summary so you can confirm it worked
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

-- Accounts and people 
CREATE TABLE UserAccount (
    UserId        INT AUTO_INCREMENT PRIMARY KEY,
    Email         VARCHAR(120) NOT NULL,
    PasswordHash  VARCHAR(255) NOT NULL,
    Role          ENUM('MEMBER','TRAINER','STAFF') NOT NULL,
    CreatedAt     DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_useraccount_email UNIQUE (Email)
);

CREATE TABLE Member (
    MemberId      INT AUTO_INCREMENT PRIMARY KEY,
    UserId        INT NOT NULL,
    FullName      VARCHAR(120) NOT NULL,
    Phone         VARCHAR(20),
    DateOfBirth   DATE,
    CONSTRAINT uq_member_user UNIQUE (UserId),
    CONSTRAINT fk_member_user FOREIGN KEY (UserId)
        REFERENCES UserAccount(UserId) ON DELETE CASCADE
);

CREATE TABLE Trainer (
    TrainerId     INT AUTO_INCREMENT PRIMARY KEY,
    UserId        INT NOT NULL,
    FullName      VARCHAR(120) NOT NULL,
    Bio           VARCHAR(500),
    HireDate      DATE,
    CONSTRAINT uq_trainer_user UNIQUE (UserId),
    CONSTRAINT fk_trainer_user FOREIGN KEY (UserId)
        REFERENCES UserAccount(UserId) ON DELETE CASCADE
);

-- Memberships and payments 

CREATE TABLE MembershipTier (
    TierId        INT AUTO_INCREMENT PRIMARY KEY,
    TierName      VARCHAR(60) NOT NULL,
    TierLevel     INT NOT NULL,
    MonthlyFee    DECIMAL(8,2) NOT NULL,
    Description   VARCHAR(255),
    CONSTRAINT uq_tier_name UNIQUE (TierName)
);

CREATE TABLE Membership (
    MembershipId  INT AUTO_INCREMENT PRIMARY KEY,
    MemberId      INT NOT NULL,
    TierId        INT NOT NULL,
    StartDate     DATE NOT NULL,
    EndDate       DATE NOT NULL,
    Status        ENUM('ACTIVE','EXPIRED','CANCELLED') NOT NULL DEFAULT 'ACTIVE',
    CONSTRAINT fk_membership_member FOREIGN KEY (MemberId)
        REFERENCES Member(MemberId) ON DELETE CASCADE,
    CONSTRAINT fk_membership_tier FOREIGN KEY (TierId)
        REFERENCES MembershipTier(TierId),
    CONSTRAINT ck_membership_dates CHECK (EndDate > StartDate)
);

CREATE TABLE Payment (
    PaymentId     INT AUTO_INCREMENT PRIMARY KEY,
    MembershipId  INT NOT NULL,
    Amount        DECIMAL(8,2) NOT NULL,
    PaidOn        DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    Method        ENUM('CARD','CASH','ONLINE') NOT NULL,
    CONSTRAINT fk_payment_membership FOREIGN KEY (MembershipId)
        REFERENCES Membership(MembershipId) ON DELETE CASCADE
);

-- Sessions, schedule, bookings, attendance 

CREATE TABLE `Session` (
    SessionId       INT AUTO_INCREMENT PRIMARY KEY,
    Title           VARCHAR(80) NOT NULL,
    Description     VARCHAR(255),
    DurationMinutes INT NOT NULL DEFAULT 60
);

CREATE TABLE Schedule (
    ScheduleId    INT AUTO_INCREMENT PRIMARY KEY,
    SessionId     INT NOT NULL,
    TrainerId     INT NOT NULL,
    RoomNumber    VARCHAR(20) NOT NULL,
    StartTime     DATETIME NOT NULL,
    Capacity      INT NOT NULL,
    CONSTRAINT fk_schedule_session FOREIGN KEY (SessionId)
        REFERENCES `Session`(SessionId) ON DELETE CASCADE,
    CONSTRAINT fk_schedule_trainer FOREIGN KEY (TrainerId)
        REFERENCES Trainer(TrainerId),
    CONSTRAINT uq_trainer_slot UNIQUE (TrainerId, StartTime),
    CONSTRAINT ck_schedule_capacity CHECK (Capacity > 0)
);

CREATE TABLE SessionBooking (
    BookingId     INT AUTO_INCREMENT PRIMARY KEY,
    MemberId      INT NOT NULL,
    ScheduleId    INT NOT NULL,
    BookedAt      DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    Status        ENUM('BOOKED','CANCELLED') NOT NULL DEFAULT 'BOOKED',
    CONSTRAINT fk_booking_member FOREIGN KEY (MemberId)
        REFERENCES Member(MemberId) ON DELETE CASCADE,
    CONSTRAINT fk_booking_schedule FOREIGN KEY (ScheduleId)
        REFERENCES Schedule(ScheduleId) ON DELETE CASCADE,
    -- a member cannot book the same session twice
    CONSTRAINT uq_member_schedule UNIQUE (MemberId, ScheduleId)
);

CREATE TABLE Attendance (
    AttendanceId  INT AUTO_INCREMENT PRIMARY KEY,
    MemberId      INT NOT NULL,
    ScheduleId    INT NULL,
    CheckInTime   DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_attendance_member FOREIGN KEY (MemberId)
        REFERENCES Member(MemberId) ON DELETE CASCADE,
    CONSTRAINT fk_attendance_schedule FOREIGN KEY (ScheduleId)
        REFERENCES Schedule(ScheduleId) ON DELETE SET NULL
);

CREATE INDEX idx_schedule_start ON Schedule (StartTime);
CREATE INDEX idx_membership_status ON Membership (Status, EndDate);

-- ---------------------------------------------------------------------
-- Accounts. One row per person who can log in: staff, trainers, members.
-- PasswordHash is a placeholder until hashing is added.
-- ---------------------------------------------------------------------

INSERT INTO
    UserAccount (Email, PasswordHash, Role)
VALUES (
        'staff@fittrack.test',
        'REPLACE_WITH_HASH',
        'STAFF'
    ),
    (
        'john.doe@fittrack.test',
        'REPLACE_WITH_HASH',
        'TRAINER'
    ),
    (
        'jane.doe@fittrack.test',
        'REPLACE_WITH_HASH',
        'TRAINER'
    ),
    (
        'robert.pattinson@fittrack.test',
        'REPLACE_WITH_HASH',
        'TRAINER'
    ),
    (
        'thai.nguyen@example.com',
        'REPLACE_WITH_HASH',
        'MEMBER'
    ),
    (
        'jack.nicholson@example.com',
        'REPLACE_WITH_HASH',
        'MEMBER'
    ),
    (
        'cara.silva@example.com',
        'REPLACE_WITH_HASH',
        'MEMBER'
    );


-- Trainers (TrainerId 1, 2, 3 in this order)
INSERT INTO
    Trainer (
        UserId,
        FullName,
        Bio,
        HireDate
    )
VALUES (
        (
            SELECT UserId
            FROM UserAccount
            WHERE
                Email = 'john.doe@fittrack.test'
        ),
        'John Doe',
        'Strength and conditioning, 8 years.',
        '2021-03-01'
    ),
    (
        (
            SELECT UserId
            FROM UserAccount
            WHERE
                Email = 'jane.doe@fittrack.test'
        ),
        'Jane Doe',
        'Cycling and endurance coaching.',
        '2022-07-15'
    ),
    (
        (
            SELECT UserId
            FROM UserAccount
            WHERE
                Email = 'robert.pattinson@fittrack.test'
        ),
        'Robert Pattinson',
        'Functional training and sports performance.',
        '2023-01-09'
    );

-- Members (MemberId 1, 2, 3 in this order)

INSERT INTO
    Member (
        UserId,
        FullName,
        Phone,
        DateOfBirth
    )
VALUES (
        (
            SELECT UserId
            FROM UserAccount
            WHERE
                Email = 'thai.nguyen@example.com'
        ),
        'Thai Nguyen',
        '408-555-0155',
        '1998-04-12'
    ),
    (
        (
            SELECT UserId
            FROM UserAccount
            WHERE
                Email = 'jack.nicholson@example.com'
        ),
        'Jack Nicholson',
        '408-555-0177',
        '1937-04-22'
    ),
    (
        (
            SELECT UserId
            FROM UserAccount
            WHERE
                Email = 'cara.silva@example.com'
        ),
        'Cara Silva',
        '669-555-0110',
        '2000-06-27'
    );


-- Membership tiers (TierId 1 = Basic, 2 = Silver, 3 = Gold)

INSERT INTO
    MembershipTier (
        TierName,
        TierLevel,
        MonthlyFee,
        Description
    )
VALUES (
        'Basic',
        1,
        29.00,
        'Gym floor access during staffed hours.'
    ),
    (
        'Silver',
        2,
        49.00,
        'Gym floor plus up to 8 booked sessions a month.'
    ),
    (
        'Gold',
        3,
        79.00,
        'Unlimited sessions and guest passes.'
    );

-- Memberships: two active, one expired, so the active-member count on the
-- home page is doing real work instead of counting every row.

INSERT INTO
    Membership (
        MemberId,
        TierId,
        StartDate,
        EndDate,
        Status
    )
VALUES (
        1,
        2,
        DATE_SUB(CURDATE(), INTERVAL 40 DAY),
        DATE_ADD(CURDATE(), INTERVAL 325 DAY),
        'ACTIVE'
    ),
    (
        2,
        3,
        DATE_SUB(CURDATE(), INTERVAL 10 DAY),
        DATE_ADD(CURDATE(), INTERVAL 355 DAY),
        'ACTIVE'
    ),
    (
        3,
        1,
        DATE_SUB(CURDATE(), INTERVAL 400 DAY),
        DATE_SUB(CURDATE(), INTERVAL 35 DAY),
        'EXPIRED'
    );

-- Payments record amount, date, and method only. No card data is stored.
INSERT INTO
    Payment (MembershipId, Amount, Method)
VALUES (1, 49.00, 'CARD'),
    (2, 79.00, 'ONLINE'),
    (3, 29.00, 'CASH');

-- Session types and the upcoming schedule

INSERT INTO
    `Session` (
        Title,
        Description,
        DurationMinutes
    )
VALUES (
        'Barbell Strength',
        'Squat, press, and deadlift technique.',
        60
    ),
    (
        'Spin 45',
        'Indoor cycling intervals.',
        45
    ),
    (
        'Mobility Flow',
        'Guided stretching and joint work.',
        50
    ),
    (
        'HIIT Circuit',
        'Timed stations, full body.',
        40
    );

-- Hours are counted from midnight today: 30 = tomorrow 6am, 42 = tomorrow 6pm,
-- and so on through the next five days.
INSERT INTO
    Schedule (
        SessionId,
        TrainerId,
        RoomNumber,
        StartTime,
        Capacity
    )
VALUES (
        1,
        1,
        'Studio A',
        DATE_ADD(DATE(NOW()), INTERVAL 30 HOUR),
        12
    ),
    (
        2,
        2,
        'Cycle',
        DATE_ADD(DATE(NOW()), INTERVAL 42 HOUR),
        20
    ),
    (
        3,
        3,
        'Studio B',
        DATE_ADD(DATE(NOW()), INTERVAL 55 HOUR),
        15
    ),
    (
        4,
        1,
        'Studio A',
        DATE_ADD(DATE(NOW()), INTERVAL 66 HOUR),
        3
    ),
    (
        2,
        2,
        'Cycle',
        DATE_ADD(DATE(NOW()), INTERVAL 78 HOUR),
        20
    ),
    (
        1,
        1,
        'Studio A',
        DATE_ADD(
            DATE(NOW()),
            INTERVAL 102 HOUR
        ),
        12
    ),
    (
        3,
        3,
        'Studio B',
        DATE_ADD(
            DATE(NOW()),
            INTERVAL 114 HOUR
        ),
        15
    ),
    (
        4,
        2,
        'Studio A',
        DATE_ADD(
            DATE(NOW()),
            INTERVAL 127 HOUR
        ),
        10
    );

-- Bookings. Only MemberId 1 to 3 exist, so every row points at a real
-- member. Schedule 4 has capacity 3 and three booked rows, which makes it
-- show as Full on the home page. Schedule 1 has one cancellation, so its
-- open spots prove the count ignores cancelled rows.
INSERT INTO
    SessionBooking (MemberId, ScheduleId, Status)
VALUES (1, 1, 'BOOKED'),
    (2, 1, 'BOOKED'),
    (3, 1, 'CANCELLED'),
    (1, 2, 'BOOKED'),
    (3, 2, 'BOOKED'),
    (2, 3, 'BOOKED'),
    (1, 4, 'BOOKED'),
    (2, 4, 'BOOKED'),
    (3, 4, 'BOOKED'),
    (1, 5, 'BOOKED'),
    (2, 6, 'BOOKED'),
    (3, 6, 'BOOKED');

-- Past gym check-ins, not tied to a class
INSERT INTO
    Attendance (
        MemberId,
        ScheduleId,
        CheckInTime
    )
VALUES (
        1,
        NULL,
        DATE_SUB(NOW(), INTERVAL 2 DAY)
    ),
    (
        2,
        NULL,
        DATE_SUB(NOW(), INTERVAL 1 DAY)
    ),
    (
        3,
        NULL,
        DATE_SUB(NOW(), INTERVAL 4 HOUR)
    );


-- Setup check. Every count should be greater than zero.
SELECT 'User accounts' AS TableName, COUNT(*) AS Loaded
FROM UserAccount
UNION ALL
SELECT 'Members', COUNT(*)
FROM Member
UNION ALL
SELECT 'Trainers', COUNT(*)
FROM Trainer
UNION ALL
SELECT 'Membership tiers', COUNT(*)
FROM MembershipTier
UNION ALL
SELECT 'Memberships', COUNT(*)
FROM Membership
UNION ALL
SELECT 'Sessions', COUNT(*)
FROM `Session`
UNION ALL
SELECT 'Scheduled slots', COUNT(*)
FROM Schedule
UNION ALL
SELECT 'Bookings', COUNT(*)
FROM SessionBooking;

-- The same rows the home page shows, so the browser can be compared to this.
SELECT
    sc.StartTime,
    s.Title,
    t.FullName AS Trainer,
    sc.Capacity,
    sc.Capacity - (
        SELECT COUNT(*)
        FROM SessionBooking b
        WHERE
            b.ScheduleId = sc.ScheduleId
            AND b.Status = 'BOOKED'
    ) AS RemainingSpots
FROM
    Schedule sc
    JOIN `Session` s ON s.SessionId = sc.SessionId
    JOIN Trainer t ON t.TrainerId = sc.TrainerId
WHERE
    sc.StartTime >= NOW()
ORDER BY sc.StartTime;