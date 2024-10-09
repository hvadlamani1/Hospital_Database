DROP TABLE Stayin;
drop table roomaccess;
drop table roomservice;
drop table examine;
drop table canrepairequipment;
drop table admission;
drop table doctor;
drop table equipment;
drop table equipmenttechnician;
drop table equipmenttype;
drop table patient;
drop table room;
drop table employee;

CREATE TABLE Employee(
EmployeeID INT PRIMARY KEY,
FName Varchar(100),
LName  VarChar(100),
Salary DECIMAL(10,2),
JobTitle Varchar(100),
OfficeNumber INT,
EmpRank VarChar(20),
SupervisorID INT,
AddressStreet VARCHAR(100),
AddressCity VARCHAR(100),
FOREIGN KEY (SupervisorID) REFERENCES Employee(EmployeeID)
);

CREATE TABLE Doctor (
EmployeeID INT PRIMARY KEY,
FOREIGN KEY (EmployeeID) REFERENCES Employee(EmployeeID),
Gender CHAR(1),
Specialty VARCHAR(150),
GraduatedFrom VARCHAR(200)
);

CREATE TABLE EquipmentTechnician(
EmployeeID INT PRIMARY KEY,	
FOREIGN KEY (EmployeeID) REFERENCES Employee(EmployeeID)
);



CREATE TABLE EquipmentType (
EqID INT PRIMARY KEY,
EqDescription VARCHAR(100),
EqModel VARCHAR(50),
Instructions VARCHAR(300),
NumberOfUnits INT
);

CREATE TABLE Equipment (
SerialNo VARCHAR(50) PRIMARY KEY,
TypeID INT,
PurchaseYear INT,
RoomNum INT,
LastInspection TIMESTAMP,
FOREIGN KEY (TypeID) REFERENCES EquipmentType(EqID)
);

CREATE TABLE CanRepairEquipment(
EmployeeID INT NOT NULL,
FOREIGN KEY (EmployeeID) REFERENCES Employee(EmployeeID),
EquipmentType INT NOT NULL,
FOREIGN KEY (EquipmentType) REFERENCES EquipmentType(EqID),
PRIMARY KEY (EmployeeID, EquipmentType)
);

CREATE TABLE Room(
RoomNum INT PRIMARY KEY,
OccupiedFlag CHAR(1)
);

CREATE TABLE RoomService(
roomNum INT,
ServiceType VARCHAR(100),
FOREIGN KEY (roomNum) REFERENCES Room(RoomNum),
PRIMARY KEY (roomNum, ServiceType)
);


CREATE TABLE RoomAccess (
RoomNum INT NOT NULL,
EmpID INT NOT NULL,
FOREIGN KEY (RoomNum) REFERENCES Room(RoomNum),
FOREIGN KEY (EmpID) REFERENCES Employee(EmployeeID),
PRIMARY KEY (RoomNum, EmpID)
);


CREATE TABLE Patient (
SSN CHAR(11) PRIMARY KEY,
FirstName VARCHAR(50),
LastName VARCHAR(50),
Address VARCHAR(100),
TelNum VARCHAR(15)
);

CREATE TABLE Admission (
AdmissionNum INT PRIMARY KEY,
AdmissionDate TIMESTAMP,
LeaveDate TIMESTAMP,
TotalPayment DECIMAL(10, 2),
InsurancePayment DECIMAL(10, 2),
PatientSSN CHAR(11),
FutureVisit TIMESTAMP,
FOREIGN KEY (PatientSSN) REFERENCES Patient(SSN)
    );

CREATE TABLE Examine (
DoctorID INT,
AdmissionNum INT,
ExamineComment VarChar(200),
FOREIGN KEY (DoctorID) REFERENCES Doctor(EmployeeID),
FOREIGN KEY (AdmissionNum) REFERENCES Admission(AdmissionNum),
PRIMARY KEY (DoctorID, AdmissionNum)
);

CREATE TABLE StayIn (
AdmissionNum INT,
RoomNum INT,
StartDate TIMESTAMP,
EndDate TIMESTAMP,
FOREIGN KEY (AdmissionNum) REFERENCES Admission(AdmissionNum),
FOREIGN KEY (RoomNum) REFERENCES Room(RoomNum),
PRIMARY KEY (AdmissionNum, RoomNum, StartDate)
);

--PART 1 VIEWS

--1
CREATE OR REPLACE VIEW CriticalCases AS
    SELECT Patient.SSN, Patient.FirstName, Patient.LastName, COUNT(DISTINCT Admission.AdmissionNum) AS numberOfAdmissionsToICU
    FROM StayIn 
    JOIN Admission ON StayIn.AdmissionNum = Admission.AdmissionNum
    JOIN RoomService ON StayIn.RoomNum = RoomService.RoomNum
    JOIN Patient ON Admission.PatientSSN = Patient.SSN
    WHERE RoomService.ServiceType = 'ICU'
    GROUP BY Patient.SSN, Patient.FirstName, Patient.LastName
    HAVING COUNT(DISTINCT Admission.AdmissionNum) >= 2;

--2
CREATE or REPLACE VIEW DoctorsLoad AS
	-- get overloaded doctors
	(Select E.DoctorID, D.graduatedFrom, 'Overloaded' as load
	From Examine E Join Admission A on E.AdmissionNum = A.AdmissionNum
	Join Doctor D on E.DoctorID = D.EmployeeID
	Group by E.DoctorID, D.graduatedFrom
	Having count(E.AdmissionNum) > 10)
	UNION
	-- get underloaded doctors
	(Select E.DoctorID, D.graduatedFrom, 'Underloaded' as load
	From Examine E Join Admission A on E.AdmissionNum = A.AdmissionNum
	Join Doctor D on E.DoctorID = D.EmployeeID
	Group by E.DoctorID, D.graduatedFrom
	Having count(E.AdmissionNum) <= 10)
	UNION
	-- get underloaded doctors with 0 examines
	(Select D.EmployeeID, D.graduatedFrom, 'Underloaded' as load
	From Doctor D
	Where D.EmployeeID NOT IN (Select E.DoctorID From Examine E));

--3
SELECT SSN, FirstName, LastName, numberOfAdmissionsToICU
FROM CriticalCases
WHERE numberOfAdmissionsToICU > 4;

--4
CREATE OR REPLACE VIEW OverloadedWPI AS
	SELECT E.EmployeeID, E.FName, E.LName
	From Employee E
	Where EmployeeID IN (Select DoctorID from DoctorsLoad Where (GraduatedFrom = 'WPI') AND (load = 'Overloaded'));

--5
SELECT e.DoctorID, cc.SSN, e.ExamineComment
FROM CriticalCases cc JOIN Admission a on cc.ssn = a.patientssn
JOIN Examine e on a.admissionnum = e.admissionnum
JOIN DoctorsLoad dl ON e.DoctorID = dl.DoctorID
WHERE dl.load = 'Underloaded'
AND e.ExamineComment IS NOT NULL; 


--PART 2 TRIGGERS

--1
CREATE OR REPLACE TRIGGER RequireCommentOnICU
BEFORE INSERT OR UPDATE ON Examine
FOR EACH ROW
DECLARE
    icuNum NUMBER;
BEGIN
    SELECT COUNT(*)
    INTO icuNum
    FROM StayIn S
    WHERE S.AdmissionNum = :NEW.AdmissionNum
    AND S.RoomNum IN (
        SELECT R.RoomNum
        FROM RoomService R
        WHERE R.ServiceType = 'ICU');
    IF icuNum > 0 AND :NEW.ExamineComment IS NULL THEN
        RAISE_APPLICATION_ERROR(-20001, 'Doctor must leave a comment when visiting a patient in the ICU');
    END IF;
END;
/
--2
CREATE OR REPLACE TRIGGER updateInsurance
BEFORE INSERT OR UPDATE OF TotalPayment ON Admission
FOR EACH ROW
BEGIN
    :NEW.InsurancePayment := 0.65 * :NEW.TotalPayment;
END;
/

--3 and 4
CREATE OR REPLACE TRIGGER EnsureSupervisor
BEFORE INSERT OR UPDATE ON Employee
FOR EACH ROW
DECLARE
    supervisorRankForReg VARCHAR(20);
    supervisorRankForDiv VARCHAR(20);
BEGIN
    -- regular employee must have a supervisor that is a division manager
    IF :NEW.EmpRank = 'Regular' THEN
        IF :NEW.SupervisorID IS NULL THEN
            RAISE_APPLICATION_ERROR(-20001, 'Regular employees must have "Division Manager" supervisor.');
        END IF;
        
        SELECT EmpRank INTO supervisorRankForReg
        FROM Employee
        WHERE EmployeeID = :NEW.SupervisorID;
        
        IF supervisorRankForReg != 'Division Manager' THEN
            RAISE_APPLICATION_ERROR(-20002, 'Regular employees must have supervisor with employee rank "Division Manager."');
        END IF;
    END IF;
    -- division manager must have a supervisor that is a division manager
    IF :NEW.EmpRank = 'Division Manager' THEN
        IF :NEW.SupervisorID IS NULL THEN
            RAISE_APPLICATION_ERROR(-20003, 'Division managers must have "General Manager" supervisor.');
        END IF;
        
        SELECT EmpRank INTO supervisorRankForDiv
        FROM Employee
        WHERE EmployeeID = :NEW.SupervisorID;
        
        IF supervisorRankForDiv != 'General Manager' THEN
            RAISE_APPLICATION_ERROR(-20004, 'Division managers must have supervisor with employee rank "General Manager."');
        END IF;
    END IF;
    -- general manager must not have a supervisor
    IF :NEW.EmpRank = 'General Manager' THEN
        IF :NEW.SupervisorID IS NOT NULL THEN
            RAISE_APPLICATION_ERROR(-20005, 'General Managers must not have a supervisor.');
        END IF;
    END IF;
    -- employee rank must be a valid option
    IF :NEW.EmpRank NOT IN ('General Manager', 'Division Manager', 'Regular') THEN
        RAISE_APPLICATION_ERROR(-20006, 'Employee rank must be one of "General Manager", "Division Manager", "Regular".');
    END IF;
END;
/

--5
CREATE OR REPLACE TRIGGER SetFutureVisitDate
BEFORE INSERT ON Admission
FOR EACH ROW
DECLARE 
    serviceType VARCHAR2(50);
    futureDay NUMBER;
    newMonth NUMBER;
    newYear NUMBER;
BEGIN
    SELECT rs.ServiceType INTO serviceType
    FROM Admission a JOIN StayIN s on a.admissionnum = s.admissionnum 
    JOIN RoomService rs on rs.roomnum = s.roomnum
    WHERE ROWNUM = 1;
    

    IF serviceType = 'Emergency' THEN
        futureDay := EXTRACT(DAY FROM :NEW.AdmissionDate);
        newMonth := EXTRACT(MONTH FROM :NEW.AdmissionDate) + 2;
        newYear := EXTRACT(YEAR FROM :NEW.AdmissionDate);

        IF newMonth > 12 THEN
            newMonth := newMonth - 12;
            newYear := newYear + 1;
        END IF;

        :NEW.futureVisit := TO_DATE(newYear || '-' || newMonth || '-' || futureDay, 'YYYY-MM-DD');
    END IF;
END;
/


--6
CREATE OR REPLACE TRIGGER checkEquipmentInspection
BEFORE INSERT OR UPDATE ON Equipment
FOR EACH ROW
DECLARE
    technician_exists NUMBER;
BEGIN
    IF :NEW.LastInspection IS NULL 
       OR EXTRACT(YEAR FROM :NEW.LastInspection) < EXTRACT(YEAR FROM SYSTIMESTAMP)
       OR (EXTRACT(YEAR FROM :NEW.LastInspection) = EXTRACT(YEAR FROM SYSTIMESTAMP) 
           AND EXTRACT(MONTH FROM :NEW.LastInspection) < EXTRACT(MONTH FROM SYSTIMESTAMP)) THEN
        
        SELECT COUNT(*)
        INTO technician_exists
        FROM CanRepairEquipment C
        WHERE C.EquipmentType = :NEW.TypeID;

        IF technician_exists > 0 THEN
            :NEW.LastInspection := SYSTIMESTAMP;
        END IF;
        
    END IF;
END;
/
