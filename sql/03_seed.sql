-- 03_seed.sql; sample data for FitTrack (at least 10 rows per table).
-- Run 02_fittrack_schema.sql first; this file assumes the tables exist.
--
-- The CLEAR section empties every table first, so this file can also be
-- re-run on its own to reset the sample data without rebuilding tables.
--
-- Class times and membership dates are generated from NOW(), so there are
-- always upcoming classes no matter which day we demo on.

USE fittrack;

-- CLEAR. TRUNCATE also resets AUTO_INCREMENT, so the IDs below stay fixed.
SET FOREIGN_KEY_CHECKS = 0;
TRUNCATE TABLE Attendance;
TRUNCATE TABLE Booking;
TRUNCATE TABLE `Class`;
TRUNCATE TABLE ClassType;
TRUNCATE TABLE Payment;
TRUNCATE TABLE Membership;
TRUNCATE TABLE MembershipTier;
TRUNCATE TABLE Member;
TRUNCATE TABLE Trainer;
TRUNCATE TABLE UserAccount;
SET FOREIGN_KEY_CHECKS = 1;


-- Accounts: UserId 1-10 are trainers, 11-20 are members.
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
    (20, 'linh.tran@example.com',          'demo123', 'MEMBER',  'Linh Tran',        '669-555-0146', '1990-05-25');

-- Trainers: TrainerId n belongs to UserId n.
INSERT INTO Trainer (TrainerId, UserId, Bio, HireDate) VALUES
    ( 1,  1, 'Strength and conditioning, 8 years.',              '2021-03-01'),
    ( 2,  2, 'Cycling and endurance coaching.',                  '2022-07-15'),
    ( 3,  3, 'Functional training and sports performance.',      '2023-01-09'),
    ( 4,  4, 'Vinyasa yoga and mobility, RYT-500 certified.',    '2020-09-14'),
    ( 5,  5, 'Boxing technique and conditioning, former amateur.','2019-05-20'),
    ( 6,  6, 'Pilates and core rehabilitation.',                 '2022-02-01'),
    ( 7,  7, 'Kettlebell and strongman training.',               '2021-11-08'),
    ( 8,  8, 'Dance fitness and Zumba instructor.',              '2023-06-12'),
    ( 9,  9, 'Rowing and aerobic endurance.',                    '2024-01-15'),
    (10, 10, 'HIIT and outdoor bootcamp coach.',                 '2024-08-05');

-- Members: MemberId n belongs to UserId n + 10.
INSERT INTO Member (MemberId, UserId, EmergencyPhoneNumber) VALUES
    ( 1, 11, '408-555-0156'),
    ( 2, 12, '408-555-0178'),
    ( 3, 13, '669-555-0111'),
    ( 4, 14, '408-555-0143'),
    ( 5, 15, '650-555-0124'),
    ( 6, 16, '408-555-0169'),
    ( 7, 17, '669-555-0135'),
    ( 8, 18, '650-555-0190'),
    ( 9, 19, '408-555-0192'),
    (10, 20, '669-555-0147');

-- Membership tiers. Fee is the monthly fee.
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

-- ---------------------------------------------------------------------
-- Memberships. Dates are relative to today so statuses stay correct.
-- Cara (3) renewed after her Basic expired; Sofia (8) cancelled Gold and
-- moved to Basic; Elena (6) has only an expired membership, so she has
-- no upcoming bookings.
INSERT INTO Membership (MembershipId, MemberId, TierId, StartDate, EndDate, Status) VALUES
    ( 1,  1,  5, DATE_SUB(CURDATE(), INTERVAL  40 DAY), DATE_ADD(CURDATE(), INTERVAL 325 DAY), 'ACTIVE'),
    ( 2,  2,  7, DATE_SUB(CURDATE(), INTERVAL  10 DAY), DATE_ADD(CURDATE(), INTERVAL 355 DAY), 'ACTIVE'),
    ( 3,  3,  4, DATE_SUB(CURDATE(), INTERVAL 400 DAY), DATE_SUB(CURDATE(), INTERVAL  35 DAY), 'EXPIRED'),
    ( 4,  4,  2, DATE_SUB(CURDATE(), INTERVAL  60 DAY), DATE_ADD(CURDATE(), INTERVAL 120 DAY), 'ACTIVE'),
    ( 5,  5,  9, DATE_SUB(CURDATE(), INTERVAL  20 DAY), DATE_ADD(CURDATE(), INTERVAL 345 DAY), 'ACTIVE'),
    ( 6,  6,  5, DATE_SUB(CURDATE(), INTERVAL 300 DAY), DATE_SUB(CURDATE(), INTERVAL   5 DAY), 'EXPIRED'),
    ( 7,  7,  1, DATE_SUB(CURDATE(), INTERVAL  90 DAY), DATE_ADD(CURDATE(), INTERVAL  90 DAY), 'ACTIVE'),
    ( 8,  8,  7, DATE_SUB(CURDATE(), INTERVAL 200 DAY), DATE_ADD(CURDATE(), INTERVAL 165 DAY), 'CANCELLED'),
    ( 9,  9,  3, DATE_SUB(CURDATE(), INTERVAL  15 DAY), DATE_ADD(CURDATE(), INTERVAL 350 DAY), 'ACTIVE'),
    (10, 10,  6, DATE_SUB(CURDATE(), INTERVAL  45 DAY), DATE_ADD(CURDATE(), INTERVAL 320 DAY), 'ACTIVE'),
    (11,  3,  5, DATE_SUB(CURDATE(), INTERVAL  30 DAY), DATE_ADD(CURDATE(), INTERVAL 335 DAY), 'ACTIVE'),
    (12,  8,  4, DATE_SUB(CURDATE(), INTERVAL  30 DAY), DATE_ADD(CURDATE(), INTERVAL  60 DAY), 'ACTIVE');

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


-- Bookings. Only members with an active membership book upcoming classes.
-- Class 5 has one CANCELLED row, which proves spots left ignores it.
-- Bookings for the past classes, made four days ago
INSERT INTO Booking (MemberId, ClassId, BookedAt, Status) VALUES
    ( 1, 1, DATE_SUB(NOW(), INTERVAL 4 DAY), 'BOOKED'),
    ( 2, 1, DATE_SUB(NOW(), INTERVAL 4 DAY), 'BOOKED'),
    ( 5, 1, DATE_SUB(NOW(), INTERVAL 4 DAY), 'BOOKED'),
    ( 3, 2, DATE_SUB(NOW(), INTERVAL 4 DAY), 'BOOKED'),
    ( 7, 2, DATE_SUB(NOW(), INTERVAL 4 DAY), 'BOOKED'),
    ( 4, 3, DATE_SUB(NOW(), INTERVAL 4 DAY), 'BOOKED'),
    ( 9, 3, DATE_SUB(NOW(), INTERVAL 4 DAY), 'BOOKED'),
    (10, 4, DATE_SUB(NOW(), INTERVAL 4 DAY), 'BOOKED'),
    ( 1, 4, DATE_SUB(NOW(), INTERVAL 4 DAY), 'BOOKED'),
    ( 8, 4, DATE_SUB(NOW(), INTERVAL 4 DAY), 'CANCELLED');

-- Bookings for upcoming classes, made today
INSERT INTO Booking (MemberId, ClassId, Status) VALUES
    ( 1,  5, 'BOOKED'), ( 2,  5, 'BOOKED'), ( 3,  5, 'CANCELLED'),
    ( 1,  6, 'BOOKED'), ( 3,  6, 'BOOKED'), ( 7,  6, 'BOOKED'),
    ( 5,  7, 'BOOKED'), (10,  7, 'BOOKED'),
    ( 2,  8, 'BOOKED'), ( 9,  8, 'BOOKED'),
    ( 1,  9, 'BOOKED'), ( 2,  9, 'BOOKED'), ( 4,  9, 'BOOKED'),
    ( 8, 10, 'BOOKED'), ( 4, 10, 'BOOKED'),
    ( 5, 11, 'BOOKED'), ( 7, 11, 'BOOKED'),
    (10, 12, 'BOOKED'),
    ( 3, 13, 'BOOKED'), ( 8, 13, 'BOOKED'), ( 4, 13, 'BOOKED'),
    ( 9, 14, 'BOOKED'),
    ( 2, 16, 'BOOKED'), ( 5, 16, 'BOOKED');

-- Attendance
-- Class check-ins: members who booked a past class and showed up, checked
-- in 10 minutes before it started. Member 5 booked class 1 but no-showed.
INSERT INTO Attendance (MemberId, ClassId, CheckInTime)
SELECT b.MemberId, b.ClassId, DATE_SUB(c.StartTime, INTERVAL 10 MINUTE)
    FROM Booking b
    JOIN `Class` c ON c.ClassId = b.ClassId
    WHERE b.Status = 'BOOKED'
    AND (b.MemberId, b.ClassId) IN ((1,1), (2,1), (3,2), (7,2),
                                    (4,3), (9,3), (10,4), (1,4))
    ORDER BY c.StartTime;

-- Plain gym visits, not tied to a class (ClassId is NULL)
INSERT INTO Attendance (MemberId, ClassId, CheckInTime) VALUES
    ( 6, NULL, DATE_SUB(NOW(), INTERVAL 10 DAY)),
    ( 1, NULL, DATE_SUB(NOW(), INTERVAL  3 DAY)),
    ( 5, NULL, DATE_SUB(NOW(), INTERVAL  3 DAY)),
    ( 2, NULL, DATE_SUB(NOW(), INTERVAL  1 DAY)),
    ( 8, NULL, DATE_SUB(NOW(), INTERVAL  1 DAY)),
    ( 7, NULL, DATE_SUB(NOW(), INTERVAL 20 HOUR)),
    (10, NULL, DATE_SUB(NOW(), INTERVAL  8 HOUR)),
    ( 3, NULL, DATE_SUB(NOW(), INTERVAL  4 HOUR)),
    ( 9, NULL, DATE_SUB(NOW(), INTERVAL  2 HOUR));

-- Check: all ten tables, each should show 10 or more rows.
SELECT 'UserAccount' AS TableName, COUNT(*) AS RowsLoaded FROM UserAccount
UNION ALL SELECT 'Member',          COUNT(*) FROM Member
UNION ALL SELECT 'Trainer',         COUNT(*) FROM Trainer
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
    JOIN Trainer t    ON t.TrainerId = c.TrainerId
    JOIN UserAccount u ON u.UserId = t.UserId
    WHERE c.StartTime >= NOW()
    ORDER BY c.StartTime;