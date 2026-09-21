-- 03_seed.sql; sample data for FitTrack.
-- Run 02_fittrack_schema.sql then run this file assumes the tables exist and
-- are empty.
--
-- To reload data without rebuilding the tables, run the CLEAR section below,
-- then the rest of the file.
--
-- Schedule times are generated from NOW(), so there are always upcoming
-- sessions no matter which day we demo on.

USE fittrack;

-- CLEAR (only needed when re-seeding an already populated database).
-- Children first, then parents, so no foreign key is left dangling.

SET FOREIGN_KEY_CHECKS = 0;

TRUNCATE TABLE Attendance;

TRUNCATE TABLE SessionBooking;

TRUNCATE TABLE Payment;

TRUNCATE TABLE Membership;

TRUNCATE TABLE Schedule;

TRUNCATE TABLE `Session`;

TRUNCATE TABLE MembershipTier;

TRUNCATE TABLE Member;

TRUNCATE TABLE Trainer;

TRUNCATE TABLE UserAccount;

SET FOREIGN_KEY_CHECKS = 1;

-- Accounts. One row per person who can log in: staff, trainers, members.

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


-- Memberships: two active, one expired

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
    
-- Seed check. Every count should be greater than zero.
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