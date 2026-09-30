-- 02_fittrack_schema.sql; tables only.
-- FitTrack - CS157A Team 4, MySQL Community Server 8.0
-- Run this file first, then 03_seed.sql.
-- Drops and rebuilds the fittrack database.

DROP DATABASE IF EXISTS fittrack;
CREATE DATABASE fittrack CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE fittrack;

-- Accounts and people: UserAccount ISA Member | Trainer (total, disjoint)
-- Shared attributes live on UserAccount. Member and Trainer each have a
-- surrogate key plus UserId as a UNIQUE foreign key (the 1:1 ISA link).
CREATE TABLE UserAccount (
    UserId        INT AUTO_INCREMENT PRIMARY KEY,
    Email         VARCHAR(120) NOT NULL,
    PasswordHash  VARCHAR(255) NOT NULL,
    Role          ENUM('MEMBER','TRAINER') NOT NULL,
    Name          VARCHAR(120) NOT NULL,
    Phone         VARCHAR(20),
    DateOfBirth   DATE,
    CreatedAt     DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_useraccount_email UNIQUE (Email)
);

CREATE TABLE Member (
    MemberId              INT AUTO_INCREMENT PRIMARY KEY,
    UserId                INT NOT NULL,
    EmergencyPhoneNumber  VARCHAR(20),
    CONSTRAINT uq_member_user UNIQUE (UserId),
    CONSTRAINT fk_member_user FOREIGN KEY (UserId)
        REFERENCES UserAccount(UserId) ON DELETE CASCADE
);

CREATE TABLE Trainer (
    TrainerId     INT AUTO_INCREMENT PRIMARY KEY,
    UserId        INT NOT NULL,
    Bio           VARCHAR(500),
    HireDate      DATE,
    CONSTRAINT uq_trainer_user UNIQUE (UserId),
    CONSTRAINT fk_trainer_user FOREIGN KEY (UserId)
        REFERENCES UserAccount(UserId) ON DELETE CASCADE
);

-- ---------------------------------------------------------------------
-- Memberships and payments
-- ---------------------------------------------------------------------

CREATE TABLE MembershipTier (
    TierId        INT AUTO_INCREMENT PRIMARY KEY,
    TierName      VARCHAR(60) NOT NULL,
    TierLevel     INT NOT NULL,
    Fee           DECIMAL(8,2) NOT NULL,
    Description   VARCHAR(255),
    CONSTRAINT uq_tier_name UNIQUE (TierName),
    CONSTRAINT ck_tier_fee CHECK (Fee >= 0)
);

-- Holds (Member, exactly one) and Of tier (MembershipTier, exactly one)
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
        REFERENCES Trainer(TrainerId),
    -- a trainer cannot lead two classes at the same time
    CONSTRAINT uq_trainer_slot UNIQUE (TrainerId, StartTime),
    CONSTRAINT ck_class_capacity CHECK (Capacity > 0)
);

-- Makes (Member, exactly one) and Reserves (Class, exactly one)
-- Capacity rule (BOOKED rows <= Class.Capacity) is checked by the app
-- before INSERT, because a CHECK cannot count rows in another table
CREATE TABLE Booking (
    BookingId     INT AUTO_INCREMENT PRIMARY KEY,
    MemberId      INT NOT NULL,
    ClassId       INT NOT NULL,
    BookedAt      DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    Status        ENUM('BOOKED','CANCELLED') NOT NULL DEFAULT 'BOOKED',
    CONSTRAINT fk_booking_member FOREIGN KEY (MemberId)
        REFERENCES Member(MemberId) ON DELETE CASCADE,
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
        REFERENCES Member(MemberId) ON DELETE CASCADE,
    CONSTRAINT fk_attendance_class FOREIGN KEY (ClassId)
        REFERENCES `Class`(ClassId) ON DELETE SET NULL
);

CREATE INDEX idx_class_start ON `Class` (StartTime);
CREATE INDEX idx_membership_status ON Membership (Status, EndDate);