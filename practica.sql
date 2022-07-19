CREATE TABLE Compay (
ID int NOT NULL PRIMARY KEY,
Name char(150) NOT NULL UNIQUE,
Address varchar(255),
);

CREATE TABLE Status (
ID int NOT NULL PRIMARY KEY,
Name char(50) UNIQUE,
);

CREATE TABLE Projects (
ID int NOT NULL PRIMARY KEY,
Name char(150) NOT NULL UNIQUE,
StartDate date,
Deadline date,
FinishedOn date,
StatusID int
);

ALTER TABLE Projects
ADD CONSTRAINT FK_Projects_Status FOREIGN KEY (StatusID)
REFERENCES Status (ID);

CREATE TABLE Employees (
ID int NOT NULL PRIMARY KEY,
FirstName char(50),
LastName char(50),
Email varchar(100) UNIQUE,
Phone varchar(12) UNIQUE,
Salary float(24),
CompanyID int NOT NULL,
);

-----Relationships

ALTER TABLE Employees
ADD CONSTRAINT FK_Employee_Company FOREIGN KEY (CompanyID)
REFERENCES Compay (ID);

CREATE TABLE EmployeesProject (
Employee_ID INT,
Project_ID INT,
CONSTRAINT FK_Employee
FOREIGN KEY (Employee_ID) REFERENCES Employees (ID),
CONSTRAINT FK_Project
FOREIGN KEY (Project_ID) REFERENCES Projects (ID)
);

-----INSERT
INSERT INTO Status (ID, Name)
VALUES 
(1 ,'Pendiente'),
(2,'En proceso'),
(3, 'Cancelado'),
(4, 'Finalizado'),
(5, 'En pausa');

INSERT INTO Compay (ID, Name, Address)
VALUES
(1, 'IMC', '5151 W 29th St #2201Greeley, Colorado(CO), 80634'),
(2, 'Atroz', '2007 Ardmore HwyArdmore, Tennessee(TN), 38449'),
(3, 'Disnei', '4226 Highgate DrHorn Lake, Mississippi(MS), 38637');


INSERT INTO Projects (ID, Name, StartDate, Deadline, FinishedOn, StatusID)
VALUES
(1, 'Dainler Learning', '1995-07-02','2050-02-22',NULL, 2),
(2, 'Provident Software', '2022-09-15','2023-02-28',NULL, 1),
(3, 'DataAnlysis', '2023-01-31','2023-05-10',NULL, 1),
(4, 'SoftCentral Migration', '2021-02-05','2022-07-25','2022-01-01', 4),
(5, 'Atoz Insigh', '2022-12-30','2024-01-10',NULL, 3);

INSERT INTO Employees (ID, FirstName, LastName, Email, Phone, Salary, CompanyID)
VALUES
(1 ,'Juan', 'Perez', 'juan@jmail.com', 9991808182, 9500, 1),
(2, 'Paco','Ochoa', 'paco@jmail.com', 9991808183, 8000, 2),
(3, 'Pedro', 'Fernandez', 'pedro@jmail.com', 9991808184, 12500, 3),
(4 ,'Sofi', 'Hernandez', 'sofi@jmail.com', 9991808185, 11000, 1),
(5, 'Isabella','Smith', 'isabella@jmail.com', 9991808186, 9000, 2),
(6, 'Eduardo', 'Jimenez', 'eduardo@jmail.com', 9991808187, 11000, 3),
(7 ,'Jose', 'Pavon', 'jose@jmail.com', 9991808188, 12000, 1),
(8, 'Pancho','Fernandez', 'pancho@jmail.com', 9991808189, 12500, 2),
(9, 'Francisco', 'Fernandez', 'francisco@jmail.com', 9991808190, 25000, 3),
(10, 'Diego', 'Olivarez', 'diego@jmail.com', 9991808191, 9000, 1);

INSERT INTO EmployeesProject (Employee_ID, Project_ID)
VALUES
(1, 1),
(2, 2),
(3, 3),
(4, 4),
(5, 5),
(6, 1),
(7, 2),
(8, 3),
(9, 4),
(10, 5);

-----QUERIES

--4.1.Devuelve todas las companias.
SELECT * FROM Compay

--4.2.Devuelvetodos los empleados.
SELECT * FROM Employees

--4.3.Devuelve los proyectos que hayan sido finalizados antes del deadline.
SELECT Name FROM Projects 
WHERE FinishedOn < Deadline

--4.4.Devuelve los proyectos que no hayan empezado a 
-- partir de la fecha actual (en que se aplica esta practica).
SELECT Name FROM Projects 
WHERE StartDate > GETDATE()

--4.5.Devuelve los empleados con salario mayor a 10,000.
SELECT * FROM Employees
WHERE Salary > 10000

--4.6.Devuelve los empleados de Atoz
SELECT * FROM Employees A
LEFT JOIN EmployeesProject B
ON A.ID = B.Employee_ID
WHERE Project_ID = 5

--4.7.Devuelve los empleados que no son de Disnei.
SELECT * FROM Employees A
LEFT JOIN Compay B
ON A.CompanyID = B.ID
WHERE CompanyID != 3

--4.8.Devuelve los empleados con sus respectivas companies, 
--ordenados primeramente por el nombre de sus companies 
--y Luego por sus apellidos.
SELECT 
Name,
LastName
FROM Compay A
LEFT JOIN Employees B
ON A.ID = B.CompanyID

--4.9.Devuelve los empleados que pertenezcan a proyectos que esten en proceso.
SELECT 
FirstName,
LastName,
Name,
StatusID
FROM Employees A
LEFT JOIN EmployeesProject B
ON A.ID= B.Employee_ID
LEFT JOIN Projects C
ON B.Project_ID = C.ID
WHERE StatusID = 2

--4.10.Devuelve los empleados sin proyectos pendientes o en proceso.
SELECT 
FirstName,
LastName,
Name,
StatusID
FROM Employees A
LEFT JOIN EmployeesProject B
ON A.ID= B.Employee_ID
LEFT JOIN Projects C
ON B.Project_ID = C.ID
WHERE StatusID = 2 OR StatusID = NULL


---Triggers
--5.1.Generar un error para prevenir “inserts” de proyectos cuyo 
--Deadline sea antes que la fecha de inicio.
CREATE TRIGGER CorrectDate
ON Projects 
AFTER INSERT
AS
BEGIN
DECLARE
	@Deadline date,
	@StartDate date
SELECT
	@Deadline = inserted.Deadline,
	@StartDate = inserted.Startdate
FROM inserted
IF(@Deadline < @StartDate)
	BEGIN
	PRINT 'Deadline tiene que ser despues de la fecha de inicio.'
	ROLLBACK TRANSACTION
	END
END
GO

DROP TRIGGER CorrectDate

--TEST
INSERT INTO Projects (ID, Name, StartDate, Deadline, FinishedOn, StatusID)
VALUES
(15, 'Learning', '1995-07-02','1994-02-22',NULL, 2)

Delete from Projects where ID = 15

----5.2.Al insertar proyectos, actalizar sus estatus a “pendientes”, 
--o “en proceso” en caso que la fecha actual sea posterior a StartDate 
--y antes del deadline.

CREATE TRIGGER ActualizarEstatusAPendienteOEnProceso
ON Projects
AFTER INSERT
AS
BEGIN
DECLARE
	@ID int,
	@StartDate date,
	@Deadline date,
	@StatusID int
SELECT
	@ID = inserted.ID,
	@StartDate = inserted.StartDate,
	@Deadline = inserted.Deadline,
	@StatusID = inserted.StatusID
FROM inserted
IF (@StartDate < GETDATE() and GETDATE() < @Deadline)
	BEGIN
	PRINT('Se actualizo el estatus del proyectoa "En progreso"')
	UPDATE Projects
	SET StatusID = 2
	WHERE ID = @ID
	END
IF (@StartDate > GETDATE())
	BEGIN
	PRINT('Se actualizo el estatus del proyectoa "Pendiente"')
	UPDATE Projects
	SET StatusID = 1
	WHERE ID = @ID	
	END
 END

 --TEST
INSERT INTO Projects (ID, Name, StartDate, Deadline, FinishedOn, StatusID)
VALUES
(17, 'TESTpendiente', '2022-07-20','2022-07-22',NULL, 2)

SELECT * from Projects

Delete from Projects where ID = 15
	


--Functions
--6.1.Crea una funcion “GetLastProjetIdByEmployeeName()” 
--que reciba el nombre de un empleado y retorne el Id del proyecto 
--mas reciente del empleado ingresando.

CREATE FUNCTION GetLastProjetIdByEmployeeName
(@EmployeeName VARCHAR(50))
RETURNS INT
AS
BEGIN
DECLARE @ProjectID VARCHAR(50)
SELECT @ProjectID = Project_ID FROM Employees A 
JOIN EmployeesProject B
ON 
A.ID = B.Employee_ID
WHERE FirstName = @EmployeeName
Return @ProjectID
END

DECLARE @RESULTS AS INT
SELECT @RESULTS = dbo.GetLastProjetIdByEmployeeName('Isabella')
print @Results

--Crea una funcion “HasAnyProject()” que reciba el nombre de un 
--empleado y retorne un bit, indicando 1 en caso de que el 
--empleado pertenezca a mas de 1 proyecto o 0 en caso contrario. 

CREATE FUNCTION HasAnyProject
(@EmployeeName VARCHAR(50))
RETURNS BIT
AS
BEGIN
DECLARE 
	@COUNT INT,
	@Bit BIT
SELECT @COUNT = COUNT(Project_ID)  
FROM 
Employees A 
JOIN EmployeesProject B
ON 
A.ID = B.Employee_ID
WHERE @EmployeeName = FirstName
IF(@COUNT > 1)
	BEGIN
	SET @Bit = 1
	END
ELSE
	BEGIN
	SET @Bit = 0
	END
RETURN @Bit
END

DECLARE @HasAnyProjectRESULTS int
SELECT @HasAnyProjectRESULTS = dbo.HasAnyProject('Juan')
PRINT @HasAnyProjectRESULTS

--test
INSERT INTO EmployeesProject (Employee_ID, Project_ID)
VALUES
(1, 2)

delete from EmployeesProject where Employee_ID = 1 and Project_ID = 2
----

-----7.store-procedures.sql
CREATE PROCEDURE ComanyProject
(
	@CompanyName varchar(50),
	@ProjectName varchar(50),
	@HasAnyProjectResult BIT
)
AS
SET NOCOUNT ON
SELECT 
	FirstName,
	LastName,
	C.Name AS Company_Name,
	CompanyID,
	D.Name AS Project_Name,
	Project_ID
FROM Employees A 
JOIN EmployeesProject B
ON 
A.ID = B.Employee_ID
JOIN Compay C
ON C.ID = A.CompanyID
JOIN Projects D
ON D.ID = B.Project_ID
WHERE @CompanyName = C.Name




