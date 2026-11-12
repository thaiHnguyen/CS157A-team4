-- 04_checkin_demo.sql: fresh test data for FR 1.1.7 Check In and FR 1.1.8 History.
-- Run it after 01_setup.sql (or 02 + 03). Safe to re-run at any time: it first
-- removes what the previous run added, then rebuilds it around the current time.
--
-- Seed classes never start within 30 minutes of "now", and seed check-ins are
-- all recent, so this adds, for Thai Nguyen (member 11, thai.nguyen@example.com):
--   Today's classes (all in rooms named 'Demo ...'):
--     Demo Open    starts in 10 minutes          booked    -> Check in button
--     Demo Late    started 5 minutes ago         booked    -> Check in button (late, still open)
--     Demo Later   starts in 2 hours             booked    -> "Opens ..."
--     Demo Closed  started 1 hour ago            booked    -> "Check-in closed"
--     Demo Cancel  starts in 20 minutes          CANCELLED -> not listed
--     Demo Other   starts in 15 minutes          booked by member 12 only -> not listed
--   History: gym visits 10, 20 and 60 days ago (so Last week / Last month / All differ)
--   It also clears Thai's check-ins from today, so he can check in again.
--
-- Note: classes are "today" by MySQL's date. Near midnight, the 2-hour and
-- 1-hour classes may fall on a different day and not be listed. Run it again later.

USE fittrack;
SET @old_safe = @@SQL_SAFE_UPDATES;
SET SQL_SAFE_UPDATES = 0;    

-- 1. Remove the previous run
DELETE a FROM Attendance a
  JOIN `Class` c ON c.ClassId = a.ClassId
 WHERE c.RoomNumber LIKE 'Demo %';

-- Thai's check-ins from today, and the old demo gym visits (Thai's seed visits
-- are all from the last 7 days, so nothing older than 7 days is seed data)
DELETE FROM Attendance
 WHERE MemberId = 11
   AND (CheckInTime >= CURDATE()
        OR (ClassId IS NULL AND CheckInTime < NOW() - INTERVAL 7 DAY));

DELETE b FROM Booking b
  JOIN `Class` c ON c.ClassId = b.ClassId
 WHERE c.RoomNumber LIKE 'Demo %';

DELETE FROM `Class` WHERE RoomNumber LIKE 'Demo %';

-- 2. Today's demo classes 
INSERT INTO `Class` (ClassTypeId, TrainerId, RoomNumber, StartTime, Capacity)
VALUES (1, 1, 'Demo Open', NOW() + INTERVAL 10 MINUTE, 10);
SET @open = LAST_INSERT_ID();

INSERT INTO `Class` (ClassTypeId, TrainerId, RoomNumber, StartTime, Capacity)
VALUES (2, 2, 'Demo Late', NOW() - INTERVAL 5 MINUTE, 10);
SET @late = LAST_INSERT_ID();

INSERT INTO `Class` (ClassTypeId, TrainerId, RoomNumber, StartTime, Capacity)
VALUES (3, 3, 'Demo Later', NOW() + INTERVAL 2 HOUR, 10);
SET @later = LAST_INSERT_ID();

INSERT INTO `Class` (ClassTypeId, TrainerId, RoomNumber, StartTime, Capacity)
VALUES (4, 4, 'Demo Closed', NOW() - INTERVAL 1 HOUR, 10);
SET @closed = LAST_INSERT_ID();

INSERT INTO `Class` (ClassTypeId, TrainerId, RoomNumber, StartTime, Capacity)
VALUES (5, 5, 'Demo Cancel', NOW() + INTERVAL 20 MINUTE, 10);
SET @cancel = LAST_INSERT_ID();

INSERT INTO `Class` (ClassTypeId, TrainerId, RoomNumber, StartTime, Capacity)
VALUES (6, 6, 'Demo Other', NOW() + INTERVAL 15 MINUTE, 10);
SET @other = LAST_INSERT_ID();

INSERT INTO Booking (MemberId, ClassId, Status) VALUES
    (11, @open,   'BOOKED'),
    (11, @late,   'BOOKED'),
    (11, @later,  'BOOKED'),
    (11, @closed, 'BOOKED'),
    (11, @cancel, 'CANCELLED'),
    (12, @other,  'BOOKED');

-- 3. Older gym visits for the history filter
INSERT INTO Attendance (MemberId, ClassId, CheckInTime) VALUES
    (11, NULL, NOW() - INTERVAL 10 DAY),
    (11, NULL, NOW() - INTERVAL 20 DAY),
    (11, NULL, NOW() - INTERVAL 60 DAY);

SET SQL_SAFE_UPDATES = @old_safe;

-- 4. What you should see on the Check in page 
SELECT c.RoomNumber AS DemoClass, ct.Title, c.StartTime,
       COALESCE(b.Status, 'not booked by Thai') AS ThaiBooking,
       CASE WHEN b.Status IS NULL OR b.Status <> 'BOOKED'               THEN 'not listed'
            WHEN NOW() < c.StartTime - INTERVAL 30 MINUTE               THEN 'Opens (no button yet)'
            WHEN NOW() > c.StartTime + INTERVAL 15 MINUTE               THEN 'Check-in closed'
            ELSE 'Check in button' END AS OnThePage
  FROM `Class` c
  JOIN ClassType ct ON ct.ClassTypeId = c.ClassTypeId
  LEFT JOIN Booking b ON b.ClassId = c.ClassId AND b.MemberId = 11
 WHERE c.RoomNumber LIKE 'Demo %'
 ORDER BY c.StartTime;

SELECT SUM(CheckInTime >= NOW() - INTERVAL 7 DAY)   AS LastWeek,
       SUM(CheckInTime >= NOW() - INTERVAL 1 MONTH) AS LastMonth,
       COUNT(*)                                     AS AllCheckIns
  FROM Attendance WHERE MemberId = 11;