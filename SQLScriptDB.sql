CREATE DATABASE TravelInformationDB;
GO
USE TravelInformationDB;
GO

CREATE TABLE Roles (
    RoleName NVARCHAR(50) PRIMARY KEY
);

INSERT INTO Roles (RoleName)
VALUES ('Admin'), ('Editor'), ('User');
GO

CREATE TABLE Users (
    UserID INT IDENTITY(1,1) PRIMARY KEY,
    Username NVARCHAR(100) UNIQUE NOT NULL,
    Email NVARCHAR(150) UNIQUE NOT NULL,
    PasswordHash VARBINARY(512) NOT NULL,
    PasswordSalt VARBINARY(128) NOT NULL,
    IsActive BIT NOT NULL DEFAULT 1,
    CreatedAt DATETIME2 NOT NULL DEFAULT SYSDATETIME(),
    LastLogin DATETIME2 NULL
);
GO

CREATE TABLE UserRoles (
    UserID INT NOT NULL,
    RoleName NVARCHAR(50) NOT NULL,
    PRIMARY KEY (UserID, RoleName),
    FOREIGN KEY (UserID) REFERENCES Users(UserID) ON DELETE CASCADE,
    FOREIGN KEY (RoleName) REFERENCES Roles(RoleName) ON DELETE CASCADE
);
GO

CREATE TABLE Countries (
    CountryID INT IDENTITY(1,1) PRIMARY KEY,
    CountryName NVARCHAR(100) NOT NULL,
    ISOCode CHAR(2) UNIQUE NOT NULL,
    Capital NVARCHAR(100),
    Currency NVARCHAR(50),
    Language NVARCHAR(50),
    Region NVARCHAR(50),
    IsSchengen BIT NOT NULL DEFAULT 0,
    CreatedAt DATETIME2 NOT NULL DEFAULT SYSDATETIME(),
    IsDeleted BIT NOT NULL DEFAULT 0
);
CREATE INDEX IX_Countries_IsDeleted ON Countries(IsDeleted);
GO

CREATE TABLE RuleTypes (
    RuleTypeID INT IDENTITY(1,1) PRIMARY KEY,
    Name NVARCHAR(100) NOT NULL
);
GO


CREATE TABLE CountryRules (
    RuleID INT IDENTITY(1,1) PRIMARY KEY,
    CountryID INT NOT NULL,
    RuleTypeID INT NOT NULL,
    Description NVARCHAR(MAX) NOT NULL,
    IsMandatory BIT NOT NULL DEFAULT 1,
    LastUpdated DATETIME2 NOT NULL DEFAULT SYSDATETIME(),
    FOREIGN KEY (CountryID) REFERENCES Countries(CountryID) ON DELETE CASCADE,
    FOREIGN KEY (RuleTypeID) REFERENCES RuleTypes(RuleTypeID) ON DELETE CASCADE
);
GO


CREATE TABLE TravelAdvisories (
    AdvisoryID INT IDENTITY(1,1) PRIMARY KEY,
    CountryID INT NOT NULL,
    RiskLevel TINYINT CHECK (RiskLevel BETWEEN 1 AND 5),
    Summary NVARCHAR(500),
    Details NVARCHAR(MAX),
    IssuedBy NVARCHAR(100),
    IssuedDate DATE,
    FOREIGN KEY (CountryID) REFERENCES Countries(CountryID) ON DELETE CASCADE
);
GO

CREATE TABLE VisaTypes (
    VisaTypeID INT IDENTITY(1,1) PRIMARY KEY,
    Name NVARCHAR(100) NOT NULL,
    MaxStayDays INT,
    IsMultipleEntry BIT NOT NULL DEFAULT 0
);
GO

CREATE TABLE CountryVisaRules (
    CountryVisaRuleID INT IDENTITY(1,1) PRIMARY KEY,
    CountryID INT NOT NULL,
    VisaTypeID INT NOT NULL,
    RequiredForNationality NVARCHAR(100) NOT NULL,
    ProcessingTimeDays INT,
    Fee DECIMAL(18,2),
    FOREIGN KEY (CountryID) REFERENCES Countries(CountryID) ON DELETE CASCADE,
    FOREIGN KEY (VisaTypeID) REFERENCES VisaTypes(VisaTypeID) ON DELETE CASCADE
);
GO

CREATE TABLE Vaccines (
    VaccineID INT IDENTITY(1,1) PRIMARY KEY,
    Name NVARCHAR(100) NOT NULL,
    IsMandatory BIT NOT NULL DEFAULT 0
);
GO

CREATE TABLE CountryHealthRequirements (
    CountryID INT NOT NULL,
    VaccineID INT NOT NULL,
    Notes NVARCHAR(500),
    PRIMARY KEY (CountryID, VaccineID),
    FOREIGN KEY (CountryID) REFERENCES Countries(CountryID) ON DELETE CASCADE,
    FOREIGN KEY (VaccineID) REFERENCES Vaccines(VaccineID) ON DELETE CASCADE
);
GO

CREATE TABLE Airports (
    AirportID INT IDENTITY(1,1) PRIMARY KEY,
    CountryID INT NOT NULL,
    Code CHAR(3) UNIQUE NOT NULL,
    Name NVARCHAR(150),
    City NVARCHAR(100),
    FOREIGN KEY (CountryID) REFERENCES Countries(CountryID) ON DELETE CASCADE
);
GO

CREATE TABLE Trips (
    TripID INT IDENTITY(1,1) PRIMARY KEY,
    UserID INT NOT NULL,
    StartDate DATE NOT NULL,
    EndDate DATE NOT NULL,
    Purpose NVARCHAR(100),
    CreatedAt DATETIME2 NOT NULL DEFAULT SYSDATETIME(),
    CONSTRAINT CK_Trips_Dates CHECK (EndDate >= StartDate),
    FOREIGN KEY (UserID) REFERENCES Users(UserID) ON DELETE CASCADE
);
GO

CREATE TABLE TripCountries (
    TripID INT NOT NULL,
    CountryID INT NOT NULL,
    VisitOrder INT,
    PRIMARY KEY (TripID, CountryID),
    FOREIGN KEY (TripID) REFERENCES Trips(TripID) ON DELETE CASCADE,
    FOREIGN KEY (CountryID) REFERENCES Countries(CountryID) ON DELETE CASCADE
);
GO

CREATE TABLE Accommodations (
    AccommodationID INT IDENTITY(1,1) PRIMARY KEY,
    CountryID INT NOT NULL,
    Name NVARCHAR(150),
    Type NVARCHAR(50),
    Address NVARCHAR(200),
    FOREIGN KEY (CountryID) REFERENCES Countries(CountryID) ON DELETE CASCADE
);
GO

CREATE TABLE Bookings (
    BookingID INT IDENTITY(1,1) PRIMARY KEY,
    TripID INT NOT NULL,
    AccommodationID INT NULL,
    BookingDate DATE,
    Cost DECIMAL(18,2),
    FOREIGN KEY (TripID) REFERENCES Trips(TripID) ON DELETE CASCADE,
    FOREIGN KEY (AccommodationID) REFERENCES Accommodations(AccommodationID) ON DELETE SET NULL
);
GO

CREATE TABLE Permissions (
    PermissionID INT IDENTITY(1,1) PRIMARY KEY,
    Name NVARCHAR(100) UNIQUE NOT NULL
);
GO

CREATE TABLE RolePermissions (
    RoleName NVARCHAR(50) NOT NULL,
    PermissionID INT NOT NULL,
    PRIMARY KEY (RoleName, PermissionID),
    FOREIGN KEY (RoleName) REFERENCES Roles(RoleName) ON DELETE CASCADE,
    FOREIGN KEY (PermissionID) REFERENCES Permissions(PermissionID) ON DELETE CASCADE
);
GO

CREATE TABLE AuditLogs (
    LogID BIGINT IDENTITY(1,1) PRIMARY KEY,
    UserID INT NULL,
    Action NVARCHAR(200),
    EntityName NVARCHAR(100),
    EntityID INT,
    ActionDate DATETIME2 NOT NULL DEFAULT SYSDATETIME(),
    IpAddress NVARCHAR(50) NULL
);
GO

CREATE VIEW vwCountryFullInfo AS
SELECT
    c.CountryID,
    c.CountryName,
    c.ISOCode,
    c.Region,
    rt.Name AS RuleType,
    cr.Description AS RuleDescription,
    ta.RiskLevel
FROM Countries c
LEFT JOIN CountryRules cr ON c.CountryID = cr.CountryID
LEFT JOIN RuleTypes rt ON cr.RuleTypeID = rt.RuleTypeID
LEFT JOIN TravelAdvisories ta ON c.CountryID = ta.CountryID
WHERE c.IsDeleted = 0;
GO

CREATE VIEW vwMyTravelFullInfo AS
SELECT
    u.UserID,
    u.Username,
    u.Email,
    u.CreatedAt AS UserCreatedAt,
    u.LastLogin,

    t.TripID,
    t.StartDate,
    t.EndDate,
    dbo.fnTripDuration(t.TripID) AS TripDurationDays,
    t.Purpose,

    tc.VisitOrder,
    c.CountryID,
    c.CountryName,
    c.ISOCode,
    c.Capital,
    c.Currency,
    c.Language,
    c.Region,
    c.IsSchengen,

    rt.Name AS RuleType,
    cr.Description AS RuleDescription,
    cr.IsMandatory AS RuleMandatory,

    ta.RiskLevel,
    ta.Summary AS AdvisorySummary,
    dbo.fnIsCountrySafe(c.CountryID) AS IsCountrySafe,

    a.Name AS AccommodationName,
    a.Type AS AccommodationType,
    a.Address,
    b.BookingDate,
    b.Cost AS BookingCost

FROM Users u
LEFT JOIN Trips t ON u.UserID = t.UserID
LEFT JOIN TripCountries tc ON t.TripID = tc.TripID
LEFT JOIN Countries c ON tc.CountryID = c.CountryID AND c.IsDeleted = 0
LEFT JOIN CountryRules cr ON c.CountryID = cr.CountryID
LEFT JOIN RuleTypes rt ON cr.RuleTypeID = rt.RuleTypeID
LEFT JOIN TravelAdvisories ta ON c.CountryID = ta.CountryID
LEFT JOIN Bookings b ON t.TripID = b.TripID
LEFT JOIN Accommodations a ON b.AccommodationID = a.AccommodationID
WHERE c.IsDeleted = 0;
GO

CREATE FUNCTION dbo.fnTripDuration (@TripID INT)
RETURNS INT
AS
BEGIN
    DECLARE @Days INT;
    SELECT @Days = DATEDIFF(DAY, StartDate, EndDate) + 1
    FROM Trips WHERE TripID = @TripID;
    RETURN @Days;
END;
GO

CREATE FUNCTION dbo.fnIsCountrySafe (@CountryID INT)
RETURNS BIT
AS
BEGIN
    DECLARE @Safe BIT = 1;
    IF EXISTS (
        SELECT 1 FROM TravelAdvisories
        WHERE CountryID = @CountryID AND RiskLevel >= 4
    )
        SET @Safe = 0;
    RETURN @Safe;
END;
GO

CREATE FUNCTION dbo.fnTripTotalCost (@TripID INT)
RETURNS DECIMAL(18,2)
AS
BEGIN
    DECLARE @Total DECIMAL(18,2);
    SELECT @Total = ISNULL(SUM(Cost),0)
    FROM Bookings
    WHERE TripID = @TripID;
    RETURN @Total;
END;
GO

CREATE FUNCTION dbo.fnIsVisaRequired(@CountryID INT, @Nationality NVARCHAR(100))
RETURNS BIT
AS
BEGIN
    RETURN CASE 
        WHEN EXISTS (
            SELECT 1 FROM CountryVisaRules
            WHERE CountryID = @CountryID AND RequiredForNationality = @Nationality
        ) THEN 1 ELSE 0 END;
END;
GO

CREATE FUNCTION dbo.fnMandatoryVaccineCount (@CountryID INT)
RETURNS INT
AS
BEGIN
    RETURN (SELECT COUNT(*)
            FROM CountryHealthRequirements chr
            JOIN Vaccines v ON chr.VaccineID = v.VaccineID
            WHERE chr.CountryID = @CountryID AND v.IsMandatory = 1);
END;
GO

CREATE TRIGGER trgCountryUpdate
ON Countries
AFTER UPDATE
AS
BEGIN
    INSERT INTO AuditLogs (Action, EntityName, EntityID)
    SELECT 'UPDATE', 'Countries', i.CountryID
    FROM inserted i;
END;
GO

CREATE TRIGGER trgCountrySoftDelete
ON Countries
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    INSERT INTO AuditLogs (Action, EntityName, EntityID)
    SELECT
        'Country Soft Deleted',
        'Countries',
        i.CountryID
    FROM inserted i
    JOIN deleted d ON i.CountryID = d.CountryID
    WHERE d.IsDeleted = 0 AND i.IsDeleted = 1;
END;
GO

CREATE TRIGGER trgUsers_StatusChange
ON Users
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    INSERT INTO AuditLogs (UserID, Action, EntityName, EntityID)
    SELECT
        i.UserID,
        CASE 
            WHEN d.IsActive = 1 AND i.IsActive = 0 THEN 'User Deactivated'
            WHEN d.IsActive = 0 AND i.IsActive = 1 THEN 'User Activated'
            ELSE 'User Updated'
        END,
        'Users',
        i.UserID
    FROM inserted i
    JOIN deleted d ON i.UserID = d.UserID
    WHERE i.IsActive <> d.IsActive;
END;
GO

CREATE TRIGGER trgPreventOverlappingTrips
ON Trips
INSTEAD OF INSERT
AS
BEGIN
    SET NOCOUNT ON;

    IF EXISTS (
        SELECT 1
        FROM inserted i
        JOIN Trips t
          ON i.UserID = t.UserID
         AND i.StartDate <= t.EndDate
         AND i.EndDate >= t.StartDate
    )
    BEGIN
        RAISERROR ('User already has a trip during this date range.', 16, 1);
        ROLLBACK;
        RETURN;
    END;

    INSERT INTO Trips (UserID, StartDate, EndDate, Purpose)
    SELECT UserID, StartDate, EndDate, Purpose
    FROM inserted;
END;
GO

CREATE TRIGGER trgPreventBookingDeletedCountry
ON Bookings
INSTEAD OF INSERT
AS
BEGIN
    SET NOCOUNT ON;

    IF EXISTS (
        SELECT 1
        FROM inserted i
        JOIN Trips t ON i.TripID = t.TripID
        JOIN TripCountries tc ON t.TripID = tc.TripID
        JOIN Countries c ON tc.CountryID = c.CountryID
        WHERE c.IsDeleted = 1
    )
    BEGIN
        RAISERROR ('Cannot create booking for a deleted country.', 16, 1);
        ROLLBACK;
        RETURN;
    END;

    INSERT INTO Bookings (TripID, AccommodationID, BookingDate, Cost)
    SELECT TripID, AccommodationID, BookingDate, Cost
    FROM inserted;
END;
GO

CREATE TRIGGER trgUserLoginAudit
ON Users
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    INSERT INTO AuditLogs (UserID, Action, EntityName, EntityID)
    SELECT
        i.UserID,
        'User Login',
        'Users',
        i.UserID
    FROM inserted i
    JOIN deleted d ON i.UserID = d.UserID
    WHERE i.LastLogin <> d.LastLogin;
END;
GO

CREATE PROCEDURE dbo.spCreateTrip
    @UserID INT,
    @StartDate DATE,
    @EndDate DATE,
    @Purpose NVARCHAR(100),
    @NewTripID INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRAN;
    BEGIN TRY
        INSERT INTO Trips (UserID, StartDate, EndDate, Purpose)
        OUTPUT INSERTED.TripID INTO @NewTripID
        VALUES (@UserID, @StartDate, @EndDate, @Purpose);
        COMMIT TRAN;
    END TRY
    BEGIN CATCH
        ROLLBACK TRAN;
        THROW;
    END CATCH
END;
GO

CREATE PROCEDURE dbo.spAddCountryToTrip
    @TripID INT,
    @CountryID INT,
    @VisitOrder INT
AS
BEGIN
    INSERT INTO TripCountries (TripID, CountryID, VisitOrder)
    VALUES (@TripID, @CountryID, @VisitOrder);
END;
GO

CREATE PROCEDURE dbo.spCreateBooking
    @TripID INT,
    @AccommodationID INT,
    @BookingDate DATE,
    @Cost DECIMAL(18,2)
AS
BEGIN
    INSERT INTO Bookings (TripID, AccommodationID, BookingDate, Cost)
    VALUES (@TripID, @AccommodationID, @BookingDate, @Cost);
END;
GO

CREATE PROCEDURE dbo.spDeleteCountry
    @CountryID INT
AS
BEGIN
    UPDATE Countries
    SET IsDeleted = 1
    WHERE CountryID = @CountryID;
END;
GO

INSERT INTO Users (Username, Email, PasswordHash, PasswordSalt)
VALUES
('admin', 'admin@travel.com', CAST('AdminHashPlaceholder' AS VARBINARY(512)), CAST('AdminSaltPlaceholder' AS VARBINARY(128))),
('editor1', 'editor@travel.com', CAST('EditorHashPlaceholder' AS VARBINARY(512)), CAST('EditorSaltPlaceholder' AS VARBINARY(128))),
('user1', 'user1@travel.com', CAST('User1HashPlaceholder' AS VARBINARY(512)), CAST('User1SaltPlaceholder' AS VARBINARY(128))),
('user2', 'user2@travel.com', CAST('User2HashPlaceholder' AS VARBINARY(512)), CAST('User2SaltPlaceholder' AS VARBINARY(128))),
('user3', 'user3@travel.com', CAST('User3HashPlaceholder' AS VARBINARY(512)), CAST('User3SaltPlaceholder' AS VARBINARY(128)));

INSERT INTO UserRoles (UserID, RoleName)
VALUES
(1, 'Admin'),
(2, 'Editor'),
(3, 'User'),
(4, 'User'),
(5, 'User');

INSERT INTO Countries (CountryName, ISOCode, Capital, Currency, Language, Region, IsSchengen)
VALUES
('France', 'FR', 'Paris', 'Euro', 'French', 'Europe', 1),
('Germany', 'DE', 'Berlin', 'Euro', 'German', 'Europe', 1),
('Japan', 'JP', 'Tokyo', 'Yen', 'Japanese', 'Asia', 0),
('Brazil', 'BR', 'Brasilia', 'Real', 'Portuguese', 'South America', 0),
('Canada', 'CA', 'Ottawa', 'Canadian Dollar', 'English/French', 'North America', 0),
('Australia', 'AU', 'Canberra', 'Australian Dollar', 'English', 'Oceania', 0);

INSERT INTO RuleTypes (Name)
VALUES
('Entry Requirement'),
('Customs Regulation'),
('Health Regulation'),
('Work Permit');

INSERT INTO CountryRules (CountryID, RuleTypeID, Description, IsMandatory)
VALUES
(1, 1, 'Passport must be valid for at least 6 months.', 1),
(1, 3, 'No mandatory vaccines required.', 0),
(2, 1, 'Valid passport required for all travelers.', 1),
(3, 1, 'Passport validity must cover duration of stay.', 1),
(4, 2, 'Certain food items are restricted.', 1),
(5, 3, 'Yellow fever vaccination may be required.', 0),
(6, 1, 'Electronic travel authorization required for some travelers.', 1);

INSERT INTO TravelAdvisories (CountryID, RiskLevel, Summary, Details, IssuedBy, IssuedDate)
VALUES
(1, 1, 'Low risk', 'Generally safe for travel.', 'EU Travel Board', '2025-01-01'),
(2, 2, 'Moderate risk', 'Exercise normal precautions.', 'EU Travel Board', '2025-01-05'),
(3, 3, 'Medium risk', 'Be aware of local regulations.', 'Japan Tourism', '2025-01-10'),
(4, 4, 'High risk', 'Crime levels higher in some regions.', 'WHO', '2025-01-12'),
(5, 2, 'Moderate risk', 'Exercise normal precautions.', 'Canadian Gov', '2025-01-15'),
(6, 1, 'Low risk', 'Safe for travel.', 'Australian Gov', '2025-01-18');

INSERT INTO Trips (UserID, StartDate, EndDate, Purpose)
VALUES
(3, '2025-06-01', '2025-06-15', 'Tourism'),
(3, '2025-09-10', '2025-09-25', 'Business'),
(4, '2025-07-05', '2025-07-12', 'Vacation'),
(5, '2025-10-01', '2025-10-10', 'Conference');

INSERT INTO TripCountries (TripID, CountryID, VisitOrder)
VALUES
(1, 1, 1), -- France
(1, 2, 2), -- Germany
(2, 3, 1), -- Japan
(3, 4, 1), -- Brazil
(4, 1, 1); -- France

INSERT INTO Accommodations (CountryID, Name, Type, Address)
VALUES
(1, 'Hotel Paris Central', 'Hotel', '10 Rue de Paris, Paris'),
(2, 'Berlin City Hostel', 'Hostel', '5 Alexanderplatz, Berlin'),
(3, 'Tokyo Business Hotel', 'Hotel', '1 Shinjuku, Tokyo'),
(4, 'Rio Beach Resort', 'Resort', 'Copacabana Beach, Rio'),
(5, 'Maple Inn', 'Hotel', '123 Maple Street, Ottawa'),
(6, 'Sydney Harbour Hotel', 'Hotel', '1 Circular Quay, Sydney');

INSERT INTO Bookings (TripID, AccommodationID, BookingDate, Cost)
VALUES
(1, 1, '2025-05-20', 1200.00),
(1, 2, '2025-05-22', 600.00),
(2, 3, '2025-08-30', 1800.00),
(3, 4, '2025-06-25', 1500.00),
(4, 1, '2025-09-20', 1300.00);

INSERT INTO Vaccines (Name, IsMandatory)
VALUES
('Yellow Fever', 1),
('Hepatitis A', 0),
('COVID-19', 1),
('Tetanus', 0);

INSERT INTO CountryHealthRequirements (CountryID, VaccineID, Notes)
VALUES
(1, 3, 'COVID-19 vaccination recommended.'),
(3, 3, 'COVID-19 vaccination required.'),
(4, 1, 'Yellow Fever vaccination required if arriving from infected region.'),
(5, 1, 'Yellow Fever vaccination recommended.');

INSERT INTO VisaTypes (Name, MaxStayDays, IsMultipleEntry)
VALUES
('Tourist', 90, 0),
('Business', 180, 1),
('Work', 365, 1);

INSERT INTO CountryVisaRules (CountryID, VisaTypeID, RequiredForNationality, ProcessingTimeDays, Fee)
VALUES
(1, 1, 'USA', 10, 50.00),
(3, 2, 'Germany', 15, 100.00),
(4, 1, 'Canada', 7, 75.00),
(6, 1, 'India', 12, 60.00);

GO

SELECT 
    u.UserID, 
    u.Username, 
    u.Email, 
    u.IsActive,
    u.CreatedAt,
    ur.RoleName
FROM Users u
LEFT JOIN UserRoles ur
    ON u.UserID = ur.UserID
ORDER BY u.UserID;

SELECT u.Username, u.Email
FROM Users u
JOIN UserRoles ur ON u.UserID = ur.UserID
WHERE ur.RoleName = 'Admin' AND u.IsActive = 1;
-------------------------------------------------

SELECT * FROM vwCountryFullInfo;
SELECT 
    c.CountryName,
    COUNT(cr.RuleID) AS MandatoryRules
FROM Countries c
LEFT JOIN CountryRules cr 
    ON c.CountryID = cr.CountryID AND cr.IsMandatory = 1
WHERE c.IsDeleted = 0
GROUP BY c.CountryName
ORDER BY MandatoryRules DESC;
SELECT 
    c.CountryName,
    v.Name AS VaccineName,
    v.IsMandatory
FROM Countries c
LEFT JOIN CountryHealthRequirements chr ON c.CountryID = chr.CountryID
LEFT JOIN Vaccines v ON chr.VaccineID = v.VaccineID
WHERE c.IsDeleted = 0
ORDER BY c.CountryName, v.IsMandatory DESC;
------------------------------------------------

SELECT * FROM vwMyTravelFullInfo
ORDER BY UserID, StartDate;

SELECT 
    t.TripID, 
    t.Purpose,
    dbo.fnTripDuration(t.TripID) AS TripDurationDays
FROM Trips t;

SELECT 
    t.TripID, 
    t.Purpose, 
    dbo.fnTripTotalCost(t.TripID) AS TotalCost
FROM Trips t;

SELECT 
    t.TripID, 
    t.Purpose,
    c.CountryName
FROM Trips t
JOIN TripCountries tc ON t.TripID = tc.TripID
JOIN Countries c ON tc.CountryID = c.CountryID
WHERE c.CountryName = 'France';

----------------------------------------------------

SELECT 
    CountryName,
    dbo.fnIsCountrySafe(CountryID) AS IsSafe
FROM Countries
WHERE IsDeleted = 0;
SELECT 
    c.CountryName,
    'USA' AS Nationality,
    dbo.fnIsVisaRequired(c.CountryID, 'USA') AS VisaRequired
FROM Countries c
WHERE c.IsDeleted = 0;
SELECT 
    c.CountryName,
    dbo.fnMandatoryVaccineCount(c.CountryID) AS MandatoryVaccineCount
FROM Countries c
WHERE c.IsDeleted = 0;
----------------------------------------

SELECT 
    b.BookingID,
    t.TripID,
    u.Username,
    c.CountryName,
    a.Name AS AccommodationName,
    a.Type AS AccommodationType,
    b.BookingDate,
    b.Cost
FROM Bookings b
JOIN Trips t ON b.TripID = t.TripID
JOIN Users u ON t.UserID = u.UserID
JOIN Accommodations a ON b.AccommodationID = a.AccommodationID
JOIN TripCountries tc ON t.TripID = tc.TripID
JOIN Countries c ON tc.CountryID = c.CountryID
ORDER BY b.BookingDate;
SELECT 
    u.Username,
    SUM(b.Cost) AS TotalSpent
FROM Users u
JOIN Trips t ON u.UserID = t.UserID
JOIN Bookings b ON t.TripID = b.TripID
GROUP BY u.Username
ORDER BY TotalSpent DESC;
-------------------------------------------

SELECT * 
FROM AuditLogs
WHERE EntityName = 'Countries'
ORDER BY ActionDate DESC;
INSERT INTO AuditLogs (UserID, Action, EntityName, EntityID)
VALUES (1, 'Test audit insert', 'Countries', 1);
SELECT * FROM AuditLogs
WHERE Action = 'Test audit insert';

-----------------------------------------

GO

EXEC sp_add_job
    @job_name = 'TravelDB_Log_15Min_Backup',
    @enabled = 1;
GO

EXEC sp_add_jobstep
    @job_name = 'TravelDB_Log_15Min_Backup',
    @step_name = 'Log Backup Step',
    @subsystem = 'TSQL',
    @command = '
BACKUP LOG TravelInformationDB
TO DISK = ''C:\SQLBackups\TravelInformationDB\Log\TravelDB_Log.trn''
WITH INIT, COMPRESSION, CHECKSUM, STATS = 10;';
GO

EXEC sp_add_schedule
    @schedule_name = 'Every_15_Minutes',
    @freq_type = 4,          
    @freq_interval = 1,
    @freq_subday_type = 4,   
    @freq_subday_interval = 15,
    @active_start_time = 000000;
GO

EXEC sp_attach_schedule
    @job_name = 'TravelDB_Log_15Min_Backup',
    @schedule_name = 'Every_15_Minutes';

EXEC sp_add_jobserver
    @job_name = 'TravelDB_Log_15Min_Backup';
GO