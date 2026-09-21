-- FitTrack - CS157A Team 4
-- Schema for MySQL Community Server 8.0
-- Run this file first, then 02_seed.sql

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
