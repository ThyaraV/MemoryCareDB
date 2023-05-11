/*
El siguiente script fue desarrollado por los estudiantes:
-Estefanía Vinueza
-Thyara Vintimilla
-Alberto Valverde

Fecha de creacion: 18-04-2023 21:00
Última versión: 19-04-2023 15:38

**********************************
-- Verificacion de existencia de la base de datos y creacion de la misma
**********************************
*/

-- Usar master para creación de base.
USE Master
GO

-- Verificar si la base de datos MemoryCareSystem ya existe; si existe, eliminarla
IF EXISTS(SELECT name FROM sys.databases WHERE name = 'MemoryCareSystem')
BEGIN
    DROP DATABASE MemoryCareSystem;
END

CREATE DATABASE MemoryCareSystem;
GO

-- Usar la base de datos MemoryCareSystem
USE MemoryCareSystem
GO

-- Validar si existe el tipo de dato correo y crear tipo de dato para correo electrónico
IF EXISTS(SELECT name FROM sys.systypes WHERE name = 'correo')
BEGIN
    DROP TYPE correo;
END

CREATE TYPE correo FROM varchar(320) NOT NULL 
GO

-- Validar si existe el tipo de dato cedulaIdentidad y crear tipo de dato para cedulaIdentidad
IF EXISTS(SELECT name FROM sys.systypes WHERE name = 'cedulaIdentidad')
BEGIN
    DROP TYPE cedulaIdentidad;
END

CREATE TYPE cedulaIdentidad FROM char(10) NOT NULL
GO

--  Validar si existe la regla "cedulaIdentidad_rule" y crear la regla
IF EXISTS(SELECT name FROM sys.objects WHERE type = 'R' AND name = 'cedulaIdentidad_rule')
BEGIN
    DROP RULE cedulaIdentidad_rule;
END
GO

-- Creación de la regla que valide que el tipo de dato cedulaIdentidad siga los parámetros de una cédula de identidad Ecuatoriana
CREATE RULE cedulaIdentidad_rule AS @value LIKE '[2][0-4][0-5][0-9][0-9][0-9][0-9][0-9][0-9][0-9]'
    OR @value LIKE '[1][0-9][0-5][0-9][0-9][0-9][0-9][0-9][0-9][0-9]'
    OR @value LIKE '[0][1-9][0-5][0-9][0-9][0-9][0-9][0-9][0-9][0-9]'
    OR @value LIKE '[3][0][0-5][0-9][0-9][0-9][0-9][0-9][0-9][0-9]'
    AND SUBSTRING(@value, 3, 1) BETWEEN '0'
    AND '5'
    AND CAST(SUBSTRING(@value, 10, 1) AS INT) = (
        (
            2 * CAST(SUBSTRING(@value, 1, 1) AS INT) + 1 * CAST(SUBSTRING(@value, 2, 1) AS INT) + 2 * CAST(SUBSTRING(@value, 3, 1) AS INT) + 1 * CAST(SUBSTRING(@value, 4, 1) AS INT) + 2 * CAST(SUBSTRING(@value, 5, 1) AS INT) + 1 * CAST(SUBSTRING(@value, 6, 1) AS INT) + 2 * CAST(SUBSTRING(@value, 7, 1) AS INT) + 1 * CAST(SUBSTRING(@value, 8, 1) AS INT) + 2 * CAST(SUBSTRING(@value, 9, 1) AS INT)
        ) % 10
    )
GO

-- Asociar tipo de dato "cedulaIdentidad" con regla "cedulaIdentidad_rule"
EXEC sp_bindrule 'cedulaIdentidad_rule', 'cedulaIdentidad';
GO

--  Validar si existe la regla "cedulaIdentidad_rule" y crear la regla
IF EXISTS(SELECT name FROM sys.objects WHERE type = 'R' AND name = 'correo_rule')
BEGIN
    DROP RULE correo_rule;
END
GO

-- Creación de la regla que valide que el tipo de dato correo siga los parámetros requeridos por un email.
CREATE RULE correo_rule
AS
    @Correo LIKE '%@%' AND
    LEN(@Correo) <= 320 AND
    LEN(SUBSTRING(@Correo, 1, CHARINDEX('@', @Correo)-1)) BETWEEN 2 AND 64 AND --LA PARTE ANTES DEL '@' DEBE TENER ENTRE 2 Y 64 CARACTERES
    LEN(SUBSTRING(@Correo, CHARINDEX('@', @Correo)+1, LEN(@Correo)-CHARINDEX('@', @Correo))) BETWEEN 4 AND 255 AND --LA PARTE DESPUES DEL '@' DEBE TENER ENTRE 4 Y 255 CARACTERES
    SUBSTRING(@Correo, 1, 1) LIKE '[a-zA-Z0-9]' AND --VALIDA QUE EL PRIMER CARACTER SIEMPRE SEA UNA LETRA O NUMERO
    SUBSTRING(@Correo, LEN(@Correo), 1) NOT LIKE '[0-9]' AND --VALIDA QUE EL ULTIMO CARACTER NO SEA UN NUMERO
	SUBSTRING(@Correo, LEN(@Correo), 1) NOT LIKE '[-]' AND -- VALIDA QUE EL DOMINIO NO TERMINE CON '-'
	SUBSTRING(@Correo, CHARINDEX('@', @Correo)+1,1) NOT LIKE '[-]' AND -- VALIDA QUE EL DOMINIO NO EMPIECE CON '-'
    NOT (@Correo LIKE '%..%') AND --VALIDA QUE NO HAYAN DOS PUNTOS SEGUIDOS
	NOT (@Correo LIKE '%@%@%') AND  -- VALIDA QUE NO HAYAN DOS ARROBAS
    SUBSTRING(@Correo, CHARINDEX('@', @Correo)+1, LEN(@Correo)-CHARINDEX('@', @Correo)) LIKE '%.[a-zA-Z][a-zA-Z][a-zA-Z]' OR -- VALIDA QUE LA EXTENSION DEL DOMINIO TENGA 4 CARACTERES
    SUBSTRING(@Correo, CHARINDEX('@', @Correo)+1, LEN(@Correo)-CHARINDEX('@', @Correo)) LIKE '%.[a-zA-Z][a-zA-Z]' -- VALIDA QUE LA EXTENSION DEL DOMINIO TENGA 3 CARACTERES 
GO

-- Asociar tipo de dato "correo" con regla "correo_rule"
EXEC sp_bindrule 'correo_rule', 'correo';
GO

/*
*******************************************************
-- Creacion de tablas de la base de datos
*******************************************************
*/

--drop table if exists Sede

CREATE TABLE Sede(
	idSede TINYINT IDENTITY(1,1) NOT NULL,
	canton VARCHAR(20) NOT NULL,
	sector VARCHAR(20) NOT NULL,
	callePrincipal VARCHAR(50) NOT NULL,
	calleSecundaria VARCHAR(50) NOT NULL,
	CONSTRAINT PK_Sede PRIMARY KEY (idSede),
	CONSTRAINT CH_canton CHECK (PATINDEX('%[0-9]%', canton) = 0),
	CONSTRAINT CH_Sector CHECK (PATINDEX('%[0-9]%', sector) = 0)
	
);


--drop table if exists Administrador

CREATE TABLE Administrador(
	idAdministrador TINYINT IDENTITY(1,1) NOT NULL,
	idSede TINYINT NOT NULL,
	cedula cedulaIdentidad NOT NULL UNIQUE,
	nombre VARCHAR(45) NOT NULL,
	apellido VARCHAR(45) NOT NULL,
	telefono CHAR(10) NOT NULL,
	email correo NOT NULL UNIQUE,
	CONSTRAINT PK_Administrador PRIMARY KEY(idAdministrador),
	CONSTRAINT FK_SedeAdministrador FOREIGN KEY (idSede) REFERENCES Sede(idSede),
	CONSTRAINT CH_Nombre CHECK (PATINDEX('%[0-9]%', nombre) = 0),
    CONSTRAINT CH_Apellido CHECK (PATINDEX('%[0-9]%', apellido) = 0),
	CONSTRAINT CH_Telefono CHECK (PATINDEX('%[^+0-9 ()-]%', telefono) = 0),
   
);

--drop table if exists Medico

CREATE TABLE Medico(
	idMedico TINYINT IDENTITY(1,1) NOT NULL,
	idAdministrador TINYINT NOT NULL,
	cedula cedulaIdentidad NOT NULL UNIQUE,
	nombre VARCHAR(45) NOT NULL,
	apellido VARCHAR(45) NOT NULL,
	telefono CHAR(10) NOT NULL,
	email correo NOT NULL UNIQUE,
	fechaNacimiento DATE NOT NULL,
	direccion VARCHAR(100) NOT NULL,
	especializacion VARCHAR(50) NOT NULL,

	CONSTRAINT PK_idMedico PRIMARY KEY (idMedico),
	CONSTRAINT FK_AdministradorMedico FOREIGN KEY (idAdministrador) REFERENCES Administrador(idAdministrador),
	CONSTRAINT CH_NombreMedico CHECK (PATINDEX('%[0-9]%', nombre) = 0),
    CONSTRAINT CH_ApellidoMedico CHECK (PATINDEX('%[0-9]%', apellido) = 0),
	CONSTRAINT CH_TelefonoMedico CHECK (PATINDEX('%[^+0-9 ()-]%', telefono) = 0),
    CONSTRAINT CH_FechaNacimiento CHECK (fechaNacimiento <= GETDATE()),
	CONSTRAINT CH_Especializacion CHECK (PATINDEX('%[0-9]%', especializacion) = 0)
);


--drop table if exists Actividad

CREATE TABLE Actividad (
    idActividad TINYINT NOT NULL IDENTITY(1,1),
    nombre VARCHAR(45) NOT NULL,
    categoria VARCHAR(45) NOT NULL,
    duracionMaxima TIME NOT NULL,
    puntajeMinimo TINYINT NOT NULL,
    puntajeMaximo TINYINT NOT NULL,
	CONSTRAINT PK_Actividad PRIMARY KEY (idActividad),
    CONSTRAINT CK_nombreActividad CHECK (PATINDEX('%[0-9]%', nombre) = 0),
    CONSTRAINT CK_categoria CHECK (PATINDEX('%[0-9]%', categoria) = 0),
    CONSTRAINT CK_duracionMaxima CHECK(duracionMaxima >= '00:05:00'),
    CONSTRAINT CK_puntajeMinimo CHECK(puntajeMinimo >= 0),
    CONSTRAINT CK_puntajeMaximo CHECK(puntajeMaximo >= 10)
);


--drop table if exists PlanMedico

CREATE TABLE PlanMedico (
    idPlanMedico TINYINT IDENTITY(1,1) NOT NULL,
    idMedico TINYINT NOT NULL,
    idActividad TINYINT NOT NULL,
    fechaPlan DATE NOT NULL,
    CONSTRAINT PK_idPlanMedico PRIMARY KEY (idPlanMedico),
    CONSTRAINT FK_PlanMedicoMedico FOREIGN KEY (idMedico) REFERENCES Medico(idMedico),
    CONSTRAINT FK_PlanMedicoActividad FOREIGN KEY (idActividad) REFERENCES Actividad(idActividad),
    CONSTRAINT CK_fechaPlan CHECK (fechaPlan >= GETDATE())
);

--drop table if exists Consejero


CREATE TABLE Consejero(
	idConsejero TINYINT IDENTITY(1,1) NOT NULL,
	cedula cedulaIdentidad NOT NULL UNIQUE,
	nombre VARCHAR(45) NOT NULL,
	apellido VARCHAR(45) NOT NULL,
	telefono CHAR(10) NOT NULL,
	email correo NOT NULL UNIQUE,
	fechaNacimiento DATE NOT NULL,
	direccion VARCHAR(100) NOT NULL,
	especializacion VARCHAR(50) NOT NULL,

	CONSTRAINT PK_idConsejero PRIMARY KEY (idConsejero),
	CONSTRAINT CH_NombreConsejero CHECK (PATINDEX('%[0-9]%', nombre) = 0),
    CONSTRAINT CH_ApellidoConsejero CHECK (PATINDEX('%[0-9]%', apellido) = 0),
	CONSTRAINT CH_TelefonoConsejero CHECK (PATINDEX('%[^+0-9 ()-]%', telefono) = 0),
    CONSTRAINT CH_FechaNacimientoConsejero CHECK (fechaNacimiento <= GETDATE()),
	CONSTRAINT CH_EspecializacionConsejero CHECK (PATINDEX('%[0-9]%', especializacion) = 0)
);


--drop table if exists Acompanante


CREATE TABLE Acompanante(
	idAcompanante INT IDENTITY(1,1) NOT NULL,
	cedula cedulaIdentidad NOT NULL UNIQUE,
	nombre VARCHAR(45) NOT NULL,
	apellido VARCHAR(45) NOT NULL,
	telefono CHAR(10) NOT NULL,
	email correo NOT NULL UNIQUE,
	fechaNacimiento DATE NOT NULL,
	parentesco VARCHAR(15) NOT NULL,
	direccion VARCHAR(100) NOT NULL,
	CONSTRAINT PK_Acompanante PRIMARY KEY (idAcompanante),
	CONSTRAINT CH_NombreAcom CHECK (PATINDEX('%[0-9]%', nombre) = 0),
    CONSTRAINT CH_ApellidoAcom CHECK (PATINDEX('%[0-9]%', apellido) = 0),
	CONSTRAINT CH_TelefonoAcom CHECK (PATINDEX('%[^+0-9 ()-]%', telefono) = 0),
    CONSTRAINT CH_FechaNacimientoAcom CHECK (fechaNacimiento <= GETDATE()),
	CONSTRAINT CH_parentescoAcom CHECK (PATINDEX('%[0-9]%', parentesco) = 0),

);

--drop table if exists Paciente

CREATE TABLE Paciente(
	idPaciente INT IDENTITY(1,1) NOT NULL,
	idAcompanante INT NOT NULL,
	cedula cedulaIdentidad NOT NULL UNIQUE,
	nombre VARCHAR(45) NOT NULL,
	apellido VARCHAR(45) NOT NULL,
	fechaNacimiento DATE NOT NULL,
	genero VARCHAR(10) NOT NULL,
	etapa VARCHAR(10) NOT NULL,
	direccion VARCHAR(100) NOT NULL,

	CONSTRAINT PK_Paciente PRIMARY KEY (idPaciente),
	CONSTRAINT FK_AcompanantePaciente FOREIGN KEY (idAcompanante) REFERENCES Acompanante(idAcompanante),
	CONSTRAINT CH_NombreP CHECK (PATINDEX('%[0-9]%', nombre) = 0),
    CONSTRAINT CH_ApellidoP CHECK (PATINDEX('%[0-9]%', apellido) = 0),
	CONSTRAINT CH_FechaNacimientoP CHECK (fechaNacimiento <= GETDATE()),
	CONSTRAINT CH_genero CHECK(UPPER(genero) IN('masculino', 'femenino','hombre','mujer')),
	CONSTRAINT CH_etapa CHECK(UPPER(etapa) IN('leve','moderada','grave'))
);


--drop table if exists Nutriologo


CREATE TABLE Nutriologo(
	idNutriologo TINYINT IDENTITY(1,1) NOT NULL,
	cedula cedulaIdentidad NOT NULL UNIQUE,
	nombre VARCHAR(45) NOT NULL,
	apellido VARCHAR(45) NOT NULL,
	telefono CHAR(10) NOT NULL,
	email correo NOT NULL UNIQUE,
	fechaNacimiento DATE NOT NULL,
	direccion VARCHAR(100) NOT NULL,
	CONSTRAINT PK_idNutriologo PRIMARY KEY (idNutriologo),
	CONSTRAINT CH_NombreNutriologo CHECK (PATINDEX('%[0-9]%', nombre) = 0),
    CONSTRAINT CH_ApellidoNutriologo CHECK (PATINDEX('%[0-9]%', apellido) = 0),
	CONSTRAINT CH_TelefonoNutriologo CHECK (PATINDEX('%[^+0-9 ()-]%', telefono) = 0),
    CONSTRAINT CH_FechaNacimientoNutriologo CHECK (fechaNacimiento <= GETDATE())
);

--drop table if exists ResultadoActividad

CREATE TABLE ResultadoActividad (
    idResultadoActividad SMALLINT IDENTITY(1,1) NOT NULL,
    idActividad TINYINT NOT NULL,
    idPaciente INT NOT NULL,
    fechaResultado DATETIME NOT NULL,
    resultado TINYINT NOT NULL, 
    duracionTotal TIME NOT NULL,
    CONSTRAINT PK_ResultadoActividad PRIMARY KEY (idResultadoActividad),
    CONSTRAINT FK_ResultadoActividadActividad FOREIGN KEY (idActividad) REFERENCES Actividad(idActividad),
    CONSTRAINT FK_ResultadoActividadPaciente FOREIGN KEY (idPaciente) REFERENCES Paciente(idPaciente),
    CONSTRAINT CK_ResultadoActividadFecha CHECK (fechaResultado >= GETDATE()),
	CONSTRAINT CK_ResultadoActividad CHECK (resultado >= 0 and resultado <= 10 ),
	CONSTRAINT CK_ResultadoDuracion CHECK (duracionTotal >= '00:00:00' AND duracionTotal <= '05:00:00'),
);


--drop table if exists Charla


CREATE TABLE Charla (
    idCharla TINYINT NOT NULL IDENTITY(1,1),
    tema VARCHAR(100) NOT NULL,
    fechaHora DATETIME NOT NULL,
    CONSTRAINT PK_Charla PRIMARY KEY (idCharla),
    CONSTRAINT CK_temaCharla CHECK (tema NOT LIKE '%[^a-zA-Z0-9 ]%'),
    CONSTRAINT CK_fechaCharla CHECK (fechaHora >= GETDATE())
);


--drop table if exists AsistenciaConsejero


CREATE TABLE AsistenciaConsejero (
    idAsistenciaConsejero TINYINT NOT NULL IDENTITY(1,1),
    idConsejero TINYINT NOT NULL,
    idCharla TINYINT NOT NULL,
    horaAsistencia TIME NOT NULL,
    registroAsiste CHAR(2) NOT NULL,
    CONSTRAINT PK_AsistenciaConsejero PRIMARY KEY (idAsistenciaConsejero),
    CONSTRAINT FK_AsistenciaConsejeroConsejero FOREIGN KEY (idConsejero) REFERENCES Consejero(idConsejero),
    CONSTRAINT FK_AsistenciaConsejeroCharla FOREIGN KEY (idCharla) REFERENCES Charla(idCharla),
    CONSTRAINT CK_registroAsiste CHECK (registroAsiste IN ('Si', 'No')),
    CONSTRAINT CK_horaAsistencia CHECK (horaAsistencia >= '00:00:00' AND horaAsistencia <= '23:59:59')
);

--drop table if exists AsistenciaAcompanante


CREATE TABLE AsistenciaAcompanante (
    idAsistenciaAcompanante TINYINT NOT NULL IDENTITY(1,1),
    idAcompanante INT NOT NULL,
    idCharla TINYINT NOT NULL,
    horaAsistencia TIME NOT NULL,
    registroAsiste CHAR(2) NOT NULL,
    CONSTRAINT PK_AsistenciaAcompanante PRIMARY KEY (idAsistenciaAcompanante),
    CONSTRAINT FK_AsistenciaAcompananteAcompanante FOREIGN KEY (idAcompanante) REFERENCES Acompanante(idAcompanante),
	CONSTRAINT FK_AsistenciaAcompananteCharla FOREIGN KEY (idCharla) REFERENCES Charla(idCharla),
    CONSTRAINT CK_registroAsisteAcompanante CHECK (registroAsiste IN ('Si', 'No')),
	CONSTRAINT CK_horaAsistenciaAcompanante CHECK (horaAsistencia >= '00:00:00' AND horaAsistencia <= '23:59:59')
);

--drop table if exists PlanNutricional

CREATE TABLE PlanNutricional (
    idPlanNutricional SMALLINT NOT NULL IDENTITY(1,1),
    idAcompanante INT NOT NULL,
    nombrePlan VARCHAR(50) NOT NULL,
    comidasDia VARCHAR(2) NOT NULL,
    caloriasDia SMALLINT NOT NULL,
    alimentosRecomendados VARCHAR(50) NOT NULL,
    CONSTRAINT PK_PlanNutricional PRIMARY KEY (idPlanNutricional),
    CONSTRAINT FK_PlanNutricionalAcompanante FOREIGN KEY (idAcompanante) REFERENCES Acompanante(idAcompanante),
    CONSTRAINT CK_nombrePlan CHECK (PATINDEX('%[0-9]%', nombrePlan) = 0),
    CONSTRAINT CK_comidasDia CHECK (PATINDEX('%[^0-9]%', comidasDia) = 0),
	CONSTRAINT CK_CaloriasDia CHECK(caloriasDia > 0)
);

--drop table if exists AsignacionPlanNutricional

CREATE TABLE AsignacionPlanNutricional (
  idAsignacionPlanNutricional SMALLINT IDENTITY(1,1) NOT NULL,
  idPlanNutricional SMALLINT NOT NULL,
  idNutriologo TINYINT NOT NULL,
  fechaAsignacion DATETIME NOT NULL,
  CONSTRAINT PK_AsignacionPlanNutricional PRIMARY KEY (idAsignacionPlanNutricional),
  CONSTRAINT FK_AsignacionPlanNutricionalNutricional FOREIGN KEY (idPlanNutricional) REFERENCES PlanNutricional(idPlanNutricional),
  CONSTRAINT FK_AsignacionPlanNutricionalNutriologo FOREIGN KEY (idNutriologo) REFERENCES Nutriologo(idNutriologo),
  CONSTRAINT CK_fechaAsignacion CHECK (fechaAsignacion >= GETDATE())
);


--drop table if exists ExamenFisico
CREATE TABLE ExamenFisico(
	idExamenFisico SMALLINT IDENTITY(1,1)NOT NULL,

	fechaExamen DATE NOT NULL,
	rangoVisualMinimo TINYINT NOT NULL,
	rangoVisualMaximo TINYINT NOT NULL,
	rangoAuditivoMinimo TINYINT NOT NULL,
	rangoAuditivoMaximo TINYINT NOT NULL,
	
	CONSTRAINT PK_idExamenFisico PRIMARY KEY (idExamenFisico),
	CONSTRAINT CH_fechaExamen CHECK (fechaExamen >= GETDATE()),
	CONSTRAINT CH_rangoVisualMinimol CHECK (rangoVisualMinimo < rangoVisualMaximo),
	CONSTRAINT CH_rangoAuditivoMinimo  CHECK (rangoAuditivoMinimo  < rangoAuditivoMaximo)
);

--drop table if exists ResultadoExamen

CREATE TABLE ResultadoExamen(
	idResultadoExamen SMALLINT IDENTITY(1,1) NOT NULL,
	idExamenFisico SMALLINT NOT NULL,
	idPaciente INT NOT NULL,
	fechaResultadoExamen DATETIME NOT NULL,
	rangoVisual TINYINT NOT NULL,
	rangoAuditivo TINYINT NOT NULL

	CONSTRAINT PK_ResultadoExamen PRIMARY KEY (idResultadoExamen),
	CONSTRAINT FK_ExamenFisicoResultado FOREIGN KEY (idExamenFisico) REFERENCES ExamenFisico(idExamenFisico),
	CONSTRAINT FK_ExamenFisicoPaciente FOREIGN KEY (idPaciente) REFERENCES Paciente(idPaciente),
	CONSTRAINT CH_fechaResultadoExamen CHECK (fechaResultadoExamen >= GETDATE()),
	CONSTRAINT CHK_RangoVisual CHECK (rangoVisual BETWEEN 0 AND 255),
	CONSTRAINT CHK_RangoAuditivo CHECK (rangoAuditivo BETWEEN 0 AND 255)
);

/*
**********************************
-- OBJETOS PROGRAMABLES
**********************************
*/

--Verificar si existe el Trigger
IF EXISTS(SELECT name FROM sys.objects WHERE type = 'TR' AND name = 'tr_ValidarNombreYCategoriaActividad')
BEGIN
    DROP TRIGGER tr_ValidarNombreYCategoriaActividad
END
GO

-- Trigger en SQL Server para verificar si el valor ingresado en la columna "nombre" y ¨categoría¨ está en la lista permitida.
CREATE TRIGGER tr_ValidarNombreYCategoriaActividad
ON Actividad
INSTEAD OF INSERT
AS
BEGIN
    IF NOT EXISTS (SELECT 1 FROM inserted WHERE nombre IN ('Comprensión lectora', 'Sumas y restas', 'Reconocimiento de colores, sonidos y figuras', 
'Juegos de memoria', 'Sopas de letras', 'Rompecabezas', 'Crucigramas', 'Juegos de mesa', 'Aprendiendo cosas nuevas',
'Vocalización'))
    BEGIN
        RAISERROR('Error: El nombre de actividad ingresado no está permitido. Por favor ingrese uno de los siguientes valores: Comprensión lectora, Sumas y restas, Reconocimiento de colores, sonidos y figuras, Juegos de memoria, Sopas de letras, Rompecabezas, Crucigramas, Juegos de mesa, Aprendiendo cosas nuevas, Vocalización.', 16, 1);
        ROLLBACK TRANSACTION
    END

    IF NOT EXISTS (SELECT 1 FROM inserted WHERE categoria IN ('Destreza mental', 'Didáctico', 'Recreativo', 'Constructivo'))
    BEGIN
        RAISERROR('Error: La categoría de actividad ingresada no está permitida. Por favor ingrese una de las siguientes categorías: Destreza mental, Didáctico, Recreativo,Constructivo.', 16, 1);
        ROLLBACK TRANSACTION
    END

    INSERT INTO Actividad (nombre, categoria, duracionMaxima, puntajeMinimo, puntajeMaximo)
    SELECT nombre, categoria, duracionMaxima, puntajeMinimo, puntajeMaximo FROM inserted;
END
GO

--Verificar si existe el Trigger
IF EXISTS(SELECT name FROM sys.objects WHERE type = 'TR' AND name = 'tr_verificar_etapa')
BEGIN
    DROP TRIGGER tr_verificar_etapa
END
GO

--Trigger que muestra un mensaje de error si no se ingresa la etapa correcta en la tabla Paciente
CREATE TRIGGER tr_verificar_etapa
ON Paciente
INSTEAD OF INSERT, UPDATE
AS
BEGIN
    IF EXISTS (SELECT 1 FROM inserted WHERE UPPER(etapa) NOT IN ('Leve', 'Moderada', 'Grave'))
    BEGIN
        RAISERROR('La etapa ingresada no es válida. Las opciones son: Leve, Moderada, Grave.', 16, 1)
        ROLLBACK TRANSACTION
    END
    ELSE
    BEGIN
        -- Realizar la operación de inserción o actualización
        INSERT INTO Paciente (idAcompanante, cedula, nombre, apellido, fechaNacimiento, genero, etapa, direccion)
        SELECT idAcompanante, cedula, nombre, apellido, fechaNacimiento, genero, etapa, direccion
        FROM inserted;
    END
END
GO

--Verificar si existe el procedimiento
IF EXISTS(SELECT name FROM sys.objects WHERE type = 'P' AND name = 'InsertarResultadoActividad')
BEGIN
    DROP PROCEDURE InsertarResultadoActividad
END
GO

--Procedimiento almacenado que permita ingresar un registro a la tabla ResultadoActividad, a través de la cedula del Paciente y del nombre de la actividad:

CREATE PROCEDURE InsertarResultadoActividad
    @cedulaPaciente cedulaIdentidad,
    @nombreActividad VARCHAR(45),
    @resultado TINYINT,
    @duracionTotal TIME
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @idActividad TINYINT;
    DECLARE @idPaciente INT;

    SELECT @idActividad = idActividad FROM Actividad WHERE nombre = @nombreActividad;
    SELECT @idPaciente = idPaciente FROM Paciente WHERE cedula = @cedulaPaciente;

    INSERT INTO ResultadoActividad (idActividad, idPaciente, fechaResultado, resultado, duracionTotal)
    VALUES (@idActividad, @idPaciente, GETDATE(), @resultado, @duracionTotal);
END
GO

--**************************************************************************************************************
--PROCEDIMIENTOS PARA INGRESO DE DATOS
--**************************************************************************************************************

--Verificar si existe el procedimiento
IF EXISTS(SELECT name FROM sys.objects WHERE type = 'P' AND name = 'InsertarSede')
BEGIN
    DROP PROCEDURE InsertarSede
END
GO
--Procedimiento para ingresar registros en la tabla sede
CREATE PROCEDURE InsertarSede
    @canton VARCHAR(20),
    @sector VARCHAR(20),
    @callePrincipal VARCHAR(50),
    @calleSecundaria VARCHAR(50)
AS
BEGIN
    SET NOCOUNT ON;

    INSERT INTO Sede (canton, sector, callePrincipal, calleSecundaria)
    VALUES (@canton, @sector, @callePrincipal, @calleSecundaria);
END
GO
--EXEC InsertarSede 'Quito', 'La Mariscal', 'Av. Amazonas', 'Av. Patria';

--**************************************************************************************************************
--**************************************************************************************************************

--Verificar si existe el procedimiento
IF EXISTS(SELECT name FROM sys.objects WHERE type = 'P' AND name = 'InsertarAdministrador')
BEGIN
    DROP PROCEDURE InsertarAdministrador
END
GO
--Procedimiento para ingresar registros en la tabla Administrador
CREATE PROCEDURE InsertarAdministrador
    @idSede TINYINT,
    @cedula cedulaIdentidad,
    @nombre VARCHAR(45),
    @apellido VARCHAR(45),
    @telefono CHAR(10),
    @email correo
AS
BEGIN
    SET NOCOUNT ON;

    INSERT INTO Administrador (idSede, cedula, nombre, apellido, telefono, email)
    VALUES (@idSede, @cedula, @nombre, @apellido, @telefono, @email);
END
GO
--EXEC InsertarAdministrador 1, '1234567890', 'Juan', 'Pérez', '0987654321', 'juan.perez@example.com';

--**************************************************************************************************************
--**************************************************************************************************************

--Verificar si existe el procedimiento
IF EXISTS(SELECT name FROM sys.objects WHERE type = 'P' AND name = 'InsertarMedico')
BEGIN
    DROP PROCEDURE InsertarMedico
END
GO
--Procedimiento para ingresar registros en la tabla Medico
CREATE PROCEDURE InsertarMedico
    @idAdministrador TINYINT,
    @cedula cedulaIdentidad,
    @nombre VARCHAR(45),
    @apellido VARCHAR(45),
    @telefono CHAR(10),
    @email correo,
    @fechaNacimiento DATE,
    @direccion VARCHAR(100),
    @especializacion VARCHAR(50)
AS
BEGIN
    SET NOCOUNT ON;

    INSERT INTO Medico (idAdministrador, cedula, nombre, apellido, telefono, email, fechaNacimiento, direccion, especializacion)
    VALUES (@idAdministrador, @cedula, @nombre, @apellido, @telefono, @email, 
            @fechaNacimiento, @direccion, @especializacion);
END
GO
--EXEC InsertarMedico 1, '1234568090', 'Juan', 'Pérez', '0987654321', 'juan.perez@gmail.com', '1990-01-01', 'Av. Amazonas', 'Cardiología';


--**************************************************************************************************************
--**************************************************************************************************************

--Verificar si existe el procedimiento
IF EXISTS(SELECT name FROM sys.objects WHERE type = 'P' AND name = 'InsertarActividad')
BEGIN
    DROP PROCEDURE InsertarActividad
END
GO
--Procedimiento para ingresar registros en la tabla Actividad
CREATE PROCEDURE InsertarActividad
    @nombre VARCHAR(45),
    @categoria VARCHAR(45),
    @duracionMaxima TIME,
    @puntajeMinimo TINYINT,
    @puntajeMaximo TINYINT
AS
BEGIN
    SET NOCOUNT ON;

    INSERT INTO Actividad (nombre, categoria, duracionMaxima, puntajeMinimo, puntajeMaximo)
    VALUES (@nombre, @categoria, @duracionMaxima, @puntajeMinimo, @puntajeMaximo);
END
GO
--EXEC InsertarActividad 'Rompecabezas', 'Didáctico', '00:30:00', 5, 10;

--**************************************************************************************************************
--**************************************************************************************************************

--Verificar si existe el procedimiento
IF EXISTS(SELECT name FROM sys.objects WHERE type = 'P' AND name = 'InsertarConsejero')
BEGIN
    DROP PROCEDURE InsertarConsejero
END
GO
--Procedimiento para ingresar registros en la tabla Consejero
CREATE PROCEDURE InsertarConsejero
    @cedula cedulaIdentidad,
    @nombre VARCHAR(45),
    @apellido VARCHAR(45),
    @telefono CHAR(10),
    @email correo,
    @fechaNacimiento DATE,
    @direccion VARCHAR(100),
    @especializacion VARCHAR(50)
AS
BEGIN
    SET NOCOUNT ON;

    INSERT INTO Consejero (cedula, nombre, apellido, telefono, email, fechaNacimiento, direccion, especializacion)
    VALUES (@cedula, @nombre, @apellido, @telefono, @email,
            @fechaNacimiento, @direccion, @especializacion);
END
GO
--EXEC InsertarConsejero '1234067890', 'Ana', 'Pérez', '0987654321', 'anita.perez@example.com', '1990-01-01', 'Av. Amazonas', 'Psicología';

--**************************************************************************************************************
--**************************************************************************************************************

--Verificar si existe el procedimiento
IF EXISTS(SELECT name FROM sys.objects WHERE type = 'P' AND name = 'InsertarAcompanante')
BEGIN
    DROP PROCEDURE InsertarAcompanante
END
GO
--Procedimiento para ingresar registros en la tabla Acompanante
CREATE PROCEDURE InsertarAcompanante
    @cedula cedulaIdentidad,
    @nombre VARCHAR(45),
    @apellido VARCHAR(45),
    @telefono CHAR(10),
    @email correo,
    @fechaNacimiento DATE,
    @parentesco VARCHAR(15),
    @direccion VARCHAR(100)
AS
BEGIN
    SET NOCOUNT ON;

    INSERT INTO Acompanante (cedula, nombre, apellido, telefono, email, fechaNacimiento, parentesco, direccion)
    VALUES (@cedula, @nombre, @apellido, @telefono, @email,
            @fechaNacimiento, @parentesco, @direccion);
END
GO
--EXEC InsertarAcompanante '2234557890', 'Stefano', 'Carrera', '0987654321', 'carrera.Stefano@example.com', '1990-01-01', 'Padre', 'Av. Amazonas';

--**************************************************************************************************************
--**************************************************************************************************************

--Verificar si existe el procedimiento
IF EXISTS(SELECT name FROM sys.objects WHERE type = 'P' AND name = 'InsertarPaciente')
BEGIN
    DROP PROCEDURE InsertarPaciente
END
GO
--Procedimiento para ingresar registros en la tabla Paciente
CREATE PROCEDURE InsertarPaciente
    @idAcompanante INT,
    @cedula cedulaIdentidad,
    @nombre VARCHAR(45),
    @apellido VARCHAR(45),
    @fechaNacimiento DATE,
    @genero VARCHAR(10),
    @etapa VARCHAR(10),
    @direccion VARCHAR(100)
AS
BEGIN
    SET NOCOUNT ON;

    INSERT INTO Paciente (idAcompanante, cedula, nombre, apellido, fechaNacimiento, genero, etapa, direccion)
    VALUES (@idAcompanante, @cedula, @nombre, @apellido, @fechaNacimiento, @genero, @etapa, @direccion);
END
GO
--EXEC InsertarPaciente 1, '0236667890', 'Alberto', 'Valverde', '1990-01-01', 'masculino', 'leve', 'Av. Amazonas';

--**************************************************************************************************************
--**************************************************************************************************************

--Verificar si existe el procedimiento
IF EXISTS(SELECT name FROM sys.objects WHERE type = 'P' AND name = 'InsertarNutriologo')
BEGIN
    DROP PROCEDURE InsertarNutriologo
END
GO
--Procedimiento para ingresar registros en la tabla Nutriologo
CREATE PROCEDURE InsertarNutriologo
    @cedula cedulaIdentidad,
    @nombre VARCHAR(45),
    @apellido VARCHAR(45),
    @telefono CHAR(10),
    @email correo,
    @fechaNacimiento DATE,
    @direccion VARCHAR(100)
AS
BEGIN
    SET NOCOUNT ON;

    INSERT INTO Nutriologo (cedula, nombre, apellido, telefono, email, fechaNacimiento, direccion)
    VALUES (@cedula, @nombre, @apellido, @telefono, @email,
            @fechaNacimiento, @direccion);
END
GO
--EXEC InsertarNutriologo '1234567890', 'Juan', 'Pérez', '0987654321', 'juan.perez@example.com', '1990-01-01', 'Av. Amazonas';

--**************************************************************************************************************
--**************************************************************************************************************


--Verificar si existe el procedimiento
IF EXISTS(SELECT name FROM sys.objects WHERE type = 'P' AND name = 'InsertarCharla')
BEGIN
    DROP PROCEDURE InsertarCharla
END
GO
--Procedimiento para ingresar registros en la tabla Charla
CREATE PROCEDURE InsertarCharla
    @tema VARCHAR(100),
    @fechaHora DATETIME
AS
BEGIN
    SET NOCOUNT ON;

    INSERT INTO Charla (tema, fechaHora)
    VALUES (@tema, @fechaHora);
END
GO
--EXEC InsertarCharla 'Alimentación saludable', '2023-05-15 10:00:00';

--**************************************************************************************************************
--**************************************************************************************************************

--Verificar si existe el procedimiento
IF EXISTS(SELECT name FROM sys.objects WHERE type = 'P' AND name = 'InsertarPlanNutricional')
BEGIN
    DROP PROCEDURE InsertarPlanNutricional
END
GO
--Procedimiento para ingresar registros en la tabla PlanNutricional
CREATE PROCEDURE InsertarPlanNutricional
    @idAcompanante INT,
    @nombrePlan VARCHAR(50),
    @comidasDia VARCHAR(50),
    @caloriasDia SMALLINT,
    @alimentosRecomendados VARCHAR(50)
AS
BEGIN
    SET NOCOUNT ON;

    INSERT INTO PlanNutricional (idAcompanante, nombrePlan, comidasDia, caloriasDia, alimentosRecomendados)
    VALUES (@idAcompanante, @nombrePlan, @comidasDia, @caloriasDia, @alimentosRecomendados);
END
GO
--EXEC InsertarPlanNutricional 1, 'Plan para bajar de peso', '3', 1500, 'Frutas, verduras, proteínas magras';

--**************************************************************************************************************
--**************************************************************************************************************

--Verificar si existe el procedimiento
IF EXISTS(SELECT name FROM sys.objects WHERE type = 'P' AND name = 'InsertarExamenFisico')
BEGIN
    DROP PROCEDURE InsertarExamenFisico
END
GO
--Procedimiento para ingresar registros en la tabla ExamenFisico
CREATE PROCEDURE InsertarExamenFisico
    @fechaExamen DATE,
    @rangoVisualMinimo TINYINT,
    @rangoVisualMaximo TINYINT,
    @rangoAuditivoMinimo TINYINT,
    @rangoAuditivoMaximo TINYINT
AS
BEGIN
    SET NOCOUNT ON;

    INSERT INTO ExamenFisico (fechaExamen, rangoVisualMinimo, rangoVisualMaximo, rangoAuditivoMinimo, rangoAuditivoMaximo)
    VALUES (@fechaExamen, @rangoVisualMinimo, @rangoVisualMaximo, @rangoAuditivoMinimo, @rangoAuditivoMaximo);
END
GO
--EXEC InsertarExamenFisico '2023-05-15', 20, 100, 10, 100;


--**************************************************************************************************************
--PROCEDIMIENTOS PARA NOTIFICACIÓN DE REGISTRO DE NUEVOS USUARIOS
--**************************************************************************************************************

--Verificar si existe el procedimiento
IF EXISTS(SELECT name FROM sys.objects WHERE type = 'P' AND name = 'EnviarNotificacionNuevoUsuario')
BEGIN
    DROP PROCEDURE EnviarNotificacionNuevoUsuario
END
GO
--Procedimiento almacenado que envíe un correo electrónico con la información del nuevo usuario:
CREATE PROCEDURE EnviarNotificacionNuevoUsuario
    @tabla VARCHAR(50),
    @nombreUsuario VARCHAR(50),
    @correoElectronico VARCHAR(100)
AS
BEGIN
    DECLARE @mensaje VARCHAR(1000);
    SET @mensaje = 'Se ha registrado un nuevo usuario en la tabla ' + @tabla + ' con el nombre ' + @nombreUsuario + ' y el correo electrónico ' + @correoElectronico + '.';
    EXEC msdb.dbo.sp_send_dbmail
        @profile_name = 'PerfilCorreo', -- Nombre del perfil de correo electrónico configurado en SQL Server
        @recipients = 'thyara.vintimilla@udla.edu.ec', -- Dirección de correo electrónico del destinatario
        @subject = 'REGISTRO DE NUEVO USUARIO', -- Asunto del correo electrónico
        @body = @mensaje; -- Cuerpo del correo electrónico
END
GO
--Trigger que llame al procedimiento almacenado cuando se inserte un nuevo registro en cualquiera de las tablas:

--Verificar si existe el Trigger
IF EXISTS(SELECT name FROM sys.objects WHERE type = 'TR' AND name = 'tr_NuevoMedicoTrigger')
BEGIN
    DROP TRIGGER tr_NuevoMedicoTrigger
END
GO
--Trigger para registro de nuevo usuario Medico
CREATE TRIGGER tr_NuevoMedicoTrigger
ON Medico
AFTER INSERT
AS
BEGIN
    DECLARE @nombreUsuario VARCHAR(50);
    DECLARE @correoElectronico VARCHAR(100);
    SELECT @nombreUsuario = nombre + ' ' + apellido, @correoElectronico = email FROM inserted;
    EXEC EnviarNotificacionNuevoUsuario 'Medico', @nombreUsuario, @correoElectronico;
END

--Verificar si existe el Trigger
IF EXISTS(SELECT name FROM sys.objects WHERE type = 'TR' AND name = 'tr_NuevoConsejeroTrigger')
BEGIN
    DROP TRIGGER tr_NuevoConsejeroTrigger
END
GO
--Trigger para registro de nuevo usuario Consejero
CREATE TRIGGER tr_NuevoConsejeroTrigger
ON Consejero
AFTER INSERT
AS
BEGIN
    DECLARE @nombreUsuario VARCHAR(50);
    DECLARE @correoElectronico VARCHAR(100);
    SELECT @nombreUsuario = nombre + ' ' + apellido, @correoElectronico = email FROM inserted;
    EXEC EnviarNotificacionNuevoUsuario 'Consejero', @nombreUsuario, @correoElectronico;
END

--Verificar si existe el Trigger
IF EXISTS(SELECT name FROM sys.objects WHERE type = 'TR' AND name = 'tr_NuevoAcompananteTrigger')
BEGIN
    DROP TRIGGER tr_NuevoAcompananteTrigger
END
GO
--Trigger para registro de nuevo usuario Acompanante
CREATE TRIGGER tr_NuevoAcompananteTrigger
ON Acompanante
AFTER INSERT
AS
BEGIN
    DECLARE @nombreUsuario VARCHAR(50);
    DECLARE @correoElectronico VARCHAR(100);
    SELECT @nombreUsuario = nombre + ' ' + apellido, @correoElectronico = email FROM inserted;
    EXEC EnviarNotificacionNuevoUsuario 'Acompanante', @nombreUsuario, @correoElectronico;
END

--Verificar si existe el Trigger
IF EXISTS(SELECT name FROM sys.objects WHERE type = 'TR' AND name = 'tr_NuevoPacienteTrigger')
BEGIN
    DROP TRIGGER tr_NuevoPacienteTrigger
END
GO
--Trigger para registro de nuevo usuario Paciente
CREATE TRIGGER tr_NuevoPacienteTrigger
ON Paciente
AFTER INSERT
AS
BEGIN
    DECLARE @nombreUsuario VARCHAR(50);
    DECLARE @correoElectronico VARCHAR(100);
    DECLARE @idAcompanante INT;
    SELECT @nombreUsuario = nombre + ' ' + apellido, @idAcompanante = idAcompanante FROM inserted;
    SELECT @correoElectronico = email FROM Acompanante WHERE idAcompanante = @idAcompanante;
    EXEC EnviarNotificacionNuevoUsuario 'Paciente', @nombreUsuario, @correoElectronico;
END


--Verificar si existe el Trigger
IF EXISTS(SELECT name FROM sys.objects WHERE type = 'TR' AND name = 'tr_NuevoNutriologoTrigger')
BEGIN
    DROP TRIGGER tr_NuevoNutriologoTrigger
END
GO
--Trigger para registro de nuevo usuario Paciente
CREATE TRIGGER tr_NuevoNutriologoTrigger
ON Nutriologo
AFTER INSERT
AS
BEGIN
    DECLARE @nombreUsuario VARCHAR(50);
    DECLARE @correoElectronico VARCHAR(100);
    SELECT @nombreUsuario = nombre + ' ' + apellido, @correoElectronico = email FROM inserted;
    EXEC EnviarNotificacionNuevoUsuario 'Nutriologo', @nombreUsuario, @correoElectronico;
END






INSERT INTO Paciente (idAcompanante, cedula, nombre, apellido, fechaNacimiento, genero, etapa, direccion)
VALUES (1, '1237878901', 'Estefi', 'Vinueza', '1990-01-01', 'mujer', 'Leve', 'Calle 123');


IF EXISTS (
    SELECT 1 FROM sys.configurations 
    WHERE NAME = 'Database Mail XPs' AND VALUE = 0)
BEGIN
  PRINT 'Enabling Database Mail XPs'
  EXEC sp_configure 'show advanced options', 1;  
  RECONFIGURE
  EXEC sp_configure 'Database Mail XPs', 1;  
  RECONFIGURE  
END




/*
**********************************
-- Inserción de datos en tablas de la base de datos
**********************************
*/
-- Ingreso de datos en la tabla Sede
INSERT INTO Sede (canton, sector, callePrincipal, calleSecundaria) VALUES ('Quito', 'La Mariscal', 'Av. Amazonas', 'Av. Patria');
INSERT INTO Sede (canton, sector, callePrincipal, calleSecundaria) VALUES ('Quito', 'La Floresta', 'Av. 6 de Diciembre', 'Av. Eloy Alfaro');
INSERT INTO Sede (canton, sector, callePrincipal, calleSecundaria) VALUES ('Guayaquil', 'Samborondón', 'Av. Samborondón', 'Av. Francisco de Orellana');
INSERT INTO Sede (canton, sector, callePrincipal, calleSecundaria) VALUES ('Cuenca', 'Centro Histórico', 'Calle Larga', 'Hermano Miguel');
INSERT INTO Sede (canton, sector, callePrincipal, calleSecundaria) VALUES ('Manta', 'Barrio Umiña', 'Av. 4 de Noviembre', 'Av. Flavio Reyes');
INSERT INTO Sede (canton, sector, callePrincipal, calleSecundaria) VALUES ('Ambato', 'Centro Histórico', 'Calle Bolívar', 'Calle Montalvo');
INSERT INTO Sede (canton, sector, callePrincipal, calleSecundaria) VALUES ('Loja', 'Centro Histórico', 'Calle Sucre', 'Calle Bernardo Valdivieso');
INSERT INTO Sede (canton, sector, callePrincipal, calleSecundaria) VALUES ('Esmeraldas', 'Centro Histórico', 'Calle Bolívar', 'Calle Sucre');
INSERT INTO Sede (canton, sector, callePrincipal, calleSecundaria) VALUES ('Portoviejo', 'Centro Histórico', 'Calle Olmedo', 'Calle Rocafuerte');
INSERT INTO Sede (canton, sector, callePrincipal, calleSecundaria) VALUES ('Ibarra', 'Centro Histórico', 'Calle Bolívar', 'Calle Maldonado');
INSERT INTO Sede (canton, sector, callePrincipal, calleSecundaria) VALUES ('Riobamba', 'Centro Histórico', 'Calle Veloz', 'Calle 10 de Agosto');
INSERT INTO Sede (canton, sector, callePrincipal, calleSecundaria) VALUES ('Machala', 'Centro Histórico', 'Calle Bolívar', 'Calle Sucre');
INSERT INTO Sede (canton, sector, callePrincipal, calleSecundaria) VALUES ('Tulcán', 'Centro Histórico', 'Calle Sucre', 'Calle Bolívar');
INSERT INTO Sede (canton, sector, callePrincipal, calleSecundaria) VALUES ('Santa Elena', 'Salinas', 'Av. Malecón', 'Calle 12');
INSERT INTO Sede (canton, sector, callePrincipal, calleSecundaria) VALUES ('Latacunga', 'Centro Histórico', 'Calle Quito', 'Calle Guayaquil');
INSERT INTO Sede (canton, sector, callePrincipal, calleSecundaria) VALUES ('Azogues', 'Centro Histórico', 'Calle Bolívar', 'Calle Sucre');
INSERT INTO Sede (canton, sector, callePrincipal, calleSecundaria) VALUES ('Babahoyo', 'Centro Histórico', 'Calle Rocafuerte', 'Calle 10 de Agosto');
INSERT INTO Sede (canton, sector, callePrincipal, calleSecundaria) VALUES ('Quevedo', 'Centro Histórico', 'Calle Bolívar', 'Calle Sucre');
INSERT INTO Sede (canton, sector, callePrincipal, calleSecundaria) VALUES ('Manta', 'Barrio Tarqui', 'Av. 24 de Mayo', 'Av. 4 de Noviembre');
--
PRINT 'Se insertó un registro en la tabla 1';

-- Ingreso de datos en la tabla Administrador
INSERT INTO Administrador (idSede, cedula, nombre, apellido, telefono, email) VALUES (1, '1712345678', 'Juan', 'Pérez', '0991234567', 'juan.perez@gmail.com');
INSERT INTO Administrador (idSede, cedula, nombre, apellido, telefono, email) VALUES (2, '1723456789', 'María', 'García', '0987654321', 'maria.garcia@hotmail.com');
INSERT INTO Administrador (idSede, cedula, nombre, apellido, telefono, email) VALUES (3, '1734567890', 'Pedro', 'Rodríguez', '0998765432', 'pedro.rodriguez@hotmail.com');
INSERT INTO Administrador (idSede, cedula, nombre, apellido, telefono, email) VALUES (4, '1745678901', 'Ana', 'Martínez', '0987123456', 'ana.martinez@gmail.com');
INSERT INTO Administrador (idSede, cedula, nombre, apellido, telefono, email) VALUES (5, '1756789012', 'Carlos', 'Gómez', '0998712345', 'carlos.gomez@hotmail.com');
INSERT INTO Administrador (idSede, cedula, nombre, apellido, telefono, email) VALUES (6, '2350713661', 'Laura', 'Sánchez', '0987123456', 'laura.sanchez@gmail.com');
INSERT INTO Administrador (idSede, cedula, nombre, apellido, telefono, email) VALUES (7, '1709069189', 'Jorge', 'Hernández', '0998712345', 'jorge.hernandez@outlook.com');
INSERT INTO Administrador (idSede, cedula, nombre, apellido, telefono, email) VALUES (8, '1758326503', 'Mónica', 'López', '0987123456', 'monica.lopez@outlook.com');
INSERT INTO Administrador (idSede, cedula, nombre, apellido, telefono, email) VALUES (9, '1204870963', 'Fernando', 'Díaz', '0998712345', 'fernando.diaz@hotmail.com');
INSERT INTO Administrador (idSede, cedula, nombre, apellido, telefono, email) VALUES (10, '1710234567', 'Lucía', 'Gutiérrez', '0987123456', 'lucia.gutierrez@outlook.com');
INSERT INTO Administrador (idSede, cedula, nombre, apellido, telefono, email) VALUES (11, '1711345678', 'Andrés', 'Castro', '0998712345', 'andres.castro@gmail.com');
INSERT INTO Administrador (idSede, cedula, nombre, apellido, telefono, email) VALUES (12, '1712456789', 'Sofía', 'Vargas', '0987123456', 'sofia.vargas@gmail.com');
INSERT INTO Administrador (idSede, cedula, nombre, apellido, telefono, email) VALUES (13, '1713567890', 'Diego', 'Fernández', '0998712345', 'diego.fernandez@outlook.com');
INSERT INTO Administrador (idSede, cedula, nombre, apellido, telefono, email) VALUES (14, '1714678901', 'Valeria', 'Ramírez', '0987123456', 'valeria.ramirez@hotmail.com');
INSERT INTO Administrador (idSede, cedula, nombre, apellido, telefono, email) VALUES (15, '1715789012', 'Gabriel', 'Moreno', '0998712345', 'gabriel.moreno@outlook.com');
INSERT INTO Administrador (idSede, cedula, nombre, apellido, telefono, email) VALUES (16, '1716890123', 'Isabel', 'González', '0987123456', 'isabel.gonzalez@gmail.com');
INSERT INTO Administrador (idSede, cedula, nombre, apellido, telefono, email) VALUES (17, '1717901234', 'Ricardo', 'Pérez', '0998712345', 'ricardo.perez@outlook.com');
INSERT INTO Administrador (idSede, cedula, nombre, apellido, telefono, email) VALUES (18, '1718012345', 'Marcela', 'Hernández', '0987123456', 'marcela.hernandez@gmail.com');
INSERT INTO Administrador (idSede, cedula, nombre, apellido, telefono, email) VALUES (19, '1719123456', 'Pablo', 'López', '0998712345', 'pablo.lopez@hotmail.com');



-- Ingreso de datos en la tabla Medico
INSERT INTO Medico (idAdministrador, cedula, nombre, apellido, telefono, email, fechaNacimiento, direccion, especializacion) 
VALUES (1, '1712345678', 'Juan', 'Pérez', '0987654321', 'juan.perez@example.com', '1990-01-01', 'Av. 10 de Agosto y Naciones Unidas', 'Cardiología');
INSERT INTO Medico (idAdministrador, cedula, nombre, apellido, telefono, email, fechaNacimiento, direccion, especializacion) 
VALUES (2, '1723456789', 'María', 'García', '0987654322', 'maria.garcia@example.com', '1992-02-02', 'Av. Amazonas y Naciones Unidas', 'Pediatría');
INSERT INTO Medico (idAdministrador, cedula, nombre, apellido, telefono, email, fechaNacimiento, direccion, especializacion) 
VALUES (3, '1734567890', 'Pedro', 'Rodríguez', '0987654323', 'pedro.rodriguez@example.com', '1994-03-03', 'Av. 6 de Diciembre y Eloy Alfaro', 'Oftalmología');
INSERT INTO Medico (idAdministrador, cedula, nombre, apellido, telefono, email, fechaNacimiento, direccion, especializacion) 
VALUES (4, '1745678901', 'Ana', 'Martínez', '0987654324', 'ana.martinez@example.com', '1996-04-04', 'Av. América y Naciones Unidas', 'Dermatología');
INSERT INTO Medico (idAdministrador, cedula, nombre, apellido, telefono, email, fechaNacimiento, direccion, especializacion) 
VALUES (5, '1756789012', 'Carlos', 'Gómez', '0987654325', 'carlos.gomez@example.com', '1998-05-05', 'Av. 12 de Octubre y Patria', 'Ginecología');
INSERT INTO Medico (idAdministrador, cedula, nombre, apellido, telefono, email, fechaNacimiento, direccion, especializacion) 
VALUES (6, '1718012345', 'Laura', 'Sánchez', '0987654326', 'laura.sanchez@example.com', '2000-06-06', 'Av. 6 de Diciembre y Naciones Unidas', 'Neurología');
INSERT INTO Medico (idAdministrador, cedula, nombre, apellido, telefono, email, fechaNacimiento, direccion, especializacion) 
VALUES (7, '1719123456', 'Jorge', 'Hernández', '0987654327', 'jorge.hernandez@example.com', '2002-07-07', 'Av. Amazonas y Eloy Alfaro', 'Oncología');
INSERT INTO Medico (idAdministrador, cedula, nombre, apellido, telefono, email, fechaNacimiento, direccion, especializacion) 
VALUES (8, '1716890123', 'Mónica', 'López', '0987654328', 'monica.lopez@example.com', '2004-08-08', 'Av. 10 de Agosto y Patria', 'Psiquiatría');
INSERT INTO Medico (idAdministrador, cedula, nombre, apellido, telefono, email, fechaNacimiento, direccion, especializacion) 
VALUES (9, '1719123458', 'Fernando', 'Díaz', '0987654329', 'fernando.diaz@example.com', '2006-09-09', 'Av. América y Eloy Alfaro', 'Traumatología');
INSERT INTO Medico (idAdministrador, cedula, nombre, apellido, telefono, email, fechaNacimiento, direccion, especializacion) 
VALUES (10, '1710234567', 'Lucía', 'Gutiérrez', '0987654330', 'lucia.gutierrez@example.com', '2008-10-10', 'Av. 12 de Octubre y Naciones Unidas', 'Urología');
INSERT INTO Medico (idAdministrador, cedula, nombre, apellido, telefono, email, fechaNacimiento, direccion, especializacion) 
VALUES (11, '1711345678', 'Andrés', 'Castro', '0987654331', 'andres.castro@example.com', '2010-11-11', 'Av. Amazonas y Patria', 'Cardiología');
INSERT INTO Medico (idAdministrador, cedula, nombre, apellido, telefono, email, fechaNacimiento, direccion, especializacion) 
VALUES (12, '1712456789', 'Sofía', 'Vargas', '0987654332', 'sofia.vargas@example.com', '2012-12-12', 'Av. 6 de Diciembre y Patria', 'Pediatría');
INSERT INTO Medico (idAdministrador, cedula, nombre, apellido, telefono, email, fechaNacimiento, direccion, especializacion) 
VALUES (13, '1713567890', 'Diego', 'Fernández', '0987654333', 'diego.fernandez@example.com', '2014-01-01', 'Av. América y Naciones Unidas', 'Oftalmología');
INSERT INTO Medico (idAdministrador, cedula, nombre, apellido, telefono, email, fechaNacimiento, direccion, especializacion) 
VALUES (14, '1714678901', 'Valeria', 'Ramírez', '0987654334', 'valeria.ramirez@example.com', '2016-02-02', 'Av. 12 de Octubre y Eloy Alfaro', 'Dermatología');
INSERT INTO Medico (idAdministrador, cedula, nombre, apellido, telefono, email, fechaNacimiento, direccion, especializacion) 
VALUES (15, '1715789012', 'Gabriel', 'Moreno', '0987654335', 'gabriel.moreno@example.com', '2018-03-03', 'Av. Amazonas y Naciones Unidas', 'Ginecología');
INSERT INTO Medico (idAdministrador, cedula, nombre, apellido, telefono, email, fechaNacimiento, direccion, especializacion) 
VALUES (16, '1716890222', 'Isabel', 'González', '0987654336', 'isabel.gonzalez@example.com', '2020-04-04', 'Av. 6 de Diciembre y Eloy Alfaro', 'Neurología');
INSERT INTO Medico (idAdministrador, cedula, nombre, apellido, telefono, email, fechaNacimiento, direccion, especializacion) 
VALUES (17, '1717901234', 'Ricardo', 'Pérez', '0987654337', 'ricardo.perez@example.com', '2022-05-05', 'Av. América y Patria', 'Oncología');
INSERT INTO Medico (idAdministrador, cedula, nombre, apellido, telefono, email, fechaNacimiento, direccion, especializacion) 
VALUES (18, '1718012775', 'Marcela', 'Hernández', '0987654338', 'marcela.hernandez@example.com', '2020-06-06', 'Av. 10 de Agosto y Eloy Alfaro', 'Psiquiatría');
INSERT INTO Medico (idAdministrador, cedula, nombre, apellido, telefono, email, fechaNacimiento, direccion, especializacion) 
VALUES (19, '1719123446', 'Pablo', 'López', '0987654339', 'pablo.lopez@example.com', '2020-07-07', 'Av. Amazonas y Patria', 'Traumatología');

-- Ingreso de datos en la tabla Nutriologo
INSERT INTO Nutriologo (cedula, nombre, apellido, telefono, email, fechaNacimiento, direccion) 
VALUES ('1712345678', 'Ana', 'García', '0987654321', 'ana.garcia@hotmail.com', '1990-01-01', 'Av. 10 de Agosto y Naciones Unidas');
INSERT INTO Nutriologo (cedula, nombre, apellido, telefono, email, fechaNacimiento, direccion) 
VALUES ('1723456789', 'Pedro', 'Martínez', '0987654322', 'pedro.martinez@gmail.com', '1992-02-02', 'Av. Amazonas y Naciones Unidas');
INSERT INTO Nutriologo (cedula, nombre, apellido, telefono, email, fechaNacimiento, direccion) 
VALUES ('1723456889', 'María', 'Hernández', '0987654323', 'maria.hernandez@hotmail.com', '1994-03-03', 'Av. 6 de Diciembre y Eloy Alfaro');
INSERT INTO Nutriologo (cedula, nombre, apellido, telefono, email, fechaNacimiento, direccion) 
VALUES ('1745678901', 'Juan', 'Pérez', '0987654324', 'juan.perez@hotmail.com', '1996-04-04', 'Av. América y Naciones Unidas');
INSERT INTO Nutriologo (cedula, nombre, apellido, telefono, email, fechaNacimiento, direccion) 
VALUES ('1756789012', 'Laura', 'Gómez', '0987654325', 'laura.gomez@hotmail.com', '1998-05-05', 'Av. 12 de Octubre y Patria');
INSERT INTO Nutriologo (cedula, nombre, apellido, telefono, email, fechaNacimiento, direccion) 
VALUES ('1723456559', 'Carlos', 'Sánchez', '0987654326', 'carlos.sanchez@hotmail.com', '2000-06-06', 'Av. 6 de Diciembre y Naciones Unidas');
INSERT INTO Nutriologo (cedula, nombre, apellido, telefono, email, fechaNacimiento, direccion) 
VALUES ('1719123456', 'Mónica', 'Gutiérrez', '0987654327', 'monica.gutierrez@hotmail.com', '2002-07-07', 'Av. Amazonas y Eloy Alfaro');
INSERT INTO Nutriologo (cedula, nombre, apellido, telefono, email, fechaNacimiento, direccion) 
VALUES ('1734567890', 'Jorge', 'López', '0987654328', 'jorge.lopez@gmail.com', '2004-08-08', 'Av. 10 de Agosto y Patria');
INSERT INTO Nutriologo (cedula, nombre, apellido, telefono, email, fechaNacimiento, direccion) 
VALUES ('1719123454', 'Sofía', 'Díaz', '0987654329', 'sofia.diaz@hotmail.com', '2006-09-09', 'Av. América y Eloy Alfaro');
INSERT INTO Nutriologo (cedula, nombre, apellido, telefono, email, fechaNacimiento, direccion) 
VALUES ('1710234567', 'Diego', 'Ramírez', '0987654330', 'diego.ramirez@gmail.com', '2008-10-10', 'Av. 12 de Octubre y Naciones Unidas');
INSERT INTO Nutriologo (cedula, nombre, apellido, telefono, email, fechaNacimiento, direccion) 
VALUES ('1711345678', 'Valeria', 'Castro', '0987654331', 'valeria.castro@hotmail.com', '2010-11-11', 'Av. Amazonas y Patria');
INSERT INTO Nutriologo (cedula, nombre, apellido, telefono, email, fechaNacimiento, direccion) 
VALUES ('1712456789', 'Andrés', 'Vargas', '0987654332', 'andres.vargas@hotmail.com', '2012-12-12', 'Av. 6 de Diciembre y Patria');
INSERT INTO Nutriologo (cedula, nombre, apellido, telefono, email, fechaNacimiento, direccion) 
VALUES ('1713567890', 'Lucía', 'Fernández', '0987654333', 'lucia.fernandez@gmail.com', '2014-01-01', 'Av. América y Naciones Unidas');
INSERT INTO Nutriologo (cedula, nombre, apellido, telefono, email, fechaNacimiento, direccion) 
VALUES ('1714678901', 'Gabriel', 'Ramírez', '0987654334', 'gabriel.ramirez@gmail.com', '2016-02-02', 'Av. 12 de Octubre y Eloy Alfaro');
INSERT INTO Nutriologo (cedula, nombre, apellido, telefono, email, fechaNacimiento, direccion) 
VALUES ('1715789012', 'Isabel', 'Moreno', '0987654335', 'isabel.moreno@hotmail.com', '2018-03-03', 'Av. Amazonas y Naciones Unidas');
INSERT INTO Nutriologo (cedula, nombre, apellido, telefono, email, fechaNacimiento, direccion) 
VALUES ('1716890123', 'Ricardo', 'González', '0987654336', 'ricardo.gonzalez@hotmail.com', '2020-04-04', 'Av. 6 de Diciembre y Eloy Alfaro');
INSERT INTO Nutriologo (cedula, nombre, apellido, telefono, email, fechaNacimiento, direccion) 
VALUES ('1717901234', 'Marcela', 'Pérez', '0987654337', 'marcela.perez@hotmail.com', '2022-05-05', 'Av. América y Patria');
INSERT INTO Nutriologo (cedula, nombre, apellido, telefono, email, fechaNacimiento, direccion) 
VALUES ('1718012345', 'Pablo', 'Hernández', '0987654338', 'pablo.hernandez@gmail.com', '2019-06-06', 'Av. 10 de Agosto y Eloy Alfaro');
INSERT INTO Nutriologo (cedula, nombre, apellido, telefono, email, fechaNacimiento, direccion) 
VALUES ('1719123416', 'Carla', 'López', '0987654339', 'carla.lopez@hotmail.com', '2015-07-07', 'Av. Amazonas y Patria');
INSERT INTO Nutriologo (cedula, nombre, apellido, telefono, email, fechaNacimiento, direccion) 
VALUES ('1720234567', 'Fernando', 'Díaz', '0987654340', 'fernando.diaz@gmail.com', '2012-08-08', 'Av. 12 de Octubre y Naciones Unidas');

-- Ingreso de datos en la tabla Actividades
--SELECT *FROM Actividad
INSERT INTO Actividad (nombre, categoria, duracionMaxima, puntajeMinimo, puntajeMaximo)
VALUES ('Comprensión lectora', 'Destreza Mental', '00:10:00', 5, 20);
INSERT INTO Actividad (nombre, categoria, duracionMaxima, puntajeMinimo, puntajeMaximo)
VALUES ('Sumas y restas', 'Destreza Mental', '00:05:00', 10, 30);
INSERT INTO Actividad (nombre, categoria, duracionMaxima, puntajeMinimo, puntajeMaximo)
VALUES ('Reconocimiento de colores, sonidos y figuras', 'Destreza Mental', '00:08:00', 8, 25);
INSERT INTO Actividad (nombre, categoria, duracionMaxima, puntajeMinimo, puntajeMaximo)
VALUES ('Juegos de memoria', 'Destreza Mental', '00:12:00', 6, 22);
INSERT INTO Actividad (nombre, categoria, duracionMaxima, puntajeMinimo, puntajeMaximo)
VALUES ('Sopas de letras', 'Didáctico', '00:07:00', 7, 24);
INSERT INTO Actividad (nombre, categoria, duracionMaxima, puntajeMinimo, puntajeMaximo)
VALUES ('Rompecabezas', 'Constructivo', '00:15:00', 4, 18);
INSERT INTO Actividad (nombre, categoria, duracionMaxima, puntajeMinimo, puntajeMaximo)
VALUES ('Crucigramas', 'Didáctico', '00:10:00', 6, 23);
INSERT INTO Actividad (nombre, categoria, duracionMaxima, puntajeMinimo, puntajeMaximo)
VALUES ('Juegos de mesa', 'Recreativo', '00:20:00', 3, 15);
INSERT INTO Actividad (nombre, categoria, duracionMaxima, puntajeMinimo, puntajeMaximo)
VALUES ('Aprendiendo cosas nuevas', 'Recreativo', '00:25:00', 2, 12);
INSERT INTO Actividad (nombre, categoria, duracionMaxima, puntajeMinimo, puntajeMaximo)
VALUES ('Vocalización', 'Constructivo', '00:05:00', 12, 35);
INSERT INTO Actividad (nombre, categoria, duracionMaxima, puntajeMinimo, puntajeMaximo)
VALUES ('Comprensión lectora', 'Destreza Mental', '00:10:00', 5, 20);
INSERT INTO Actividad (nombre, categoria, duracionMaxima, puntajeMinimo, puntajeMaximo)
VALUES ('Sumas y restas', 'Destreza Mental', '00:05:00', 10, 30);
INSERT INTO Actividad (nombre, categoria, duracionMaxima, puntajeMinimo, puntajeMaximo)
VALUES ('Reconocimiento de colores, sonidos y figuras', 'Destreza Mental', '00:08:00', 8, 25);
INSERT INTO Actividad (nombre, categoria, duracionMaxima, puntajeMinimo, puntajeMaximo)
VALUES ('Juegos de memoria', 'Destreza Mental', '00:12:00', 6, 22);
INSERT INTO Actividad (nombre, categoria, duracionMaxima, puntajeMinimo, puntajeMaximo)
VALUES ('Sopas de letras', 'Didáctico', '00:07:00', 7, 24);
INSERT INTO Actividad (nombre, categoria, duracionMaxima, puntajeMinimo, puntajeMaximo)
VALUES ('Rompecabezas', 'Constructivo', '00:15:00', 4, 18);
INSERT INTO Actividad (nombre, categoria, duracionMaxima, puntajeMinimo, puntajeMaximo)
VALUES ('Crucigramas', 'Didáctico', '00:10:00', 6, 23);
INSERT INTO Actividad (nombre, categoria, duracionMaxima, puntajeMinimo, puntajeMaximo)
VALUES ('Juegos de mesa', 'Recreativo', '00:20:00', 3, 15);
INSERT INTO Actividad (nombre, categoria, duracionMaxima, puntajeMinimo, puntajeMaximo)
VALUES ('Aprendiendo cosas nuevas', 'Recreativo', '00:25:00', 2, 12);
INSERT INTO Actividad (nombre, categoria, duracionMaxima, puntajeMinimo, puntajeMaximo)
VALUES ('Vocalización', 'Constructivo', '00:05:00', 12, 35);

-- Ingreso de datos en la tabla Acompanante

INSERT INTO Acompanante (cedula, nombre, apellido, telefono, email, fechaNacimiento, parentesco, direccion) VALUES ('1234567890', 'Juan', 'Pérez', '1234567890', 'juan@gmail.com', '2000-01-01', 'Padre', 'Calle 123');
INSERT INTO Acompanante (cedula, nombre, apellido, telefono, email, fechaNacimiento, parentesco, direccion) VALUES ('1712345678', 'María', 'López', '0987654321', 'maria@hotmail.com', '1995-05-10', 'Madre', 'Avenida 456');
INSERT INTO Acompanante (cedula, nombre, apellido, telefono, email, fechaNacimiento, parentesco, direccion) VALUES ('2350713661', 'Pedro', 'González', '5432167890', 'pedro@hotmail.com', '1980-12-15', 'Hermano', 'Calle 789');
INSERT INTO Acompanante (cedula, nombre, apellido, telefono, email, fechaNacimiento, parentesco, direccion) VALUES ('1734567890', 'Laura', 'Martínez', '0987654321', 'laura@hotmail.com', '1992-09-20', 'Hermana', 'Avenida 1234');
INSERT INTO Acompanante (cedula, nombre, apellido, telefono, email, fechaNacimiento, parentesco, direccion) VALUES ('1234567850', 'Carlos', 'Sánchez', '1234567890', 'carlos@gmail.com', '1975-06-05', 'Tío', 'Calle 5678');
INSERT INTO Acompanante (cedula, nombre, apellido, telefono, email, fechaNacimiento, parentesco, direccion) VALUES ('1718012345', 'Ana', 'Gómez', '5432167890', 'ana@gmail.com', '1988-03-10', 'Tía', 'Avenida 9012');
INSERT INTO Acompanante (cedula, nombre, apellido, telefono, email, fechaNacimiento, parentesco, direccion) VALUES ('1756789012', 'Luis', 'Rodríguez', '0987654321', 'luis@hotmail.com', '1965-11-25', 'Abuelo', 'Calle 3456');
INSERT INTO Acompanante (cedula, nombre, apellido, telefono, email, fechaNacimiento, parentesco, direccion) VALUES ('1234567893', 'Sofía', 'Hernández', '1234567890', 'sofia@gmail.com', '1998-08-30', 'Abuela', 'Avenida 7890');
INSERT INTO Acompanante (cedula, nombre, apellido, telefono, email, fechaNacimiento, parentesco, direccion) VALUES ('1717901234', 'Mario', 'Torres', '5432167890', 'mario@hotmail.com', '1970-04-12', 'Primo', 'Calle 1234');
INSERT INTO Acompanante (cedula, nombre, apellido, telefono, email, fechaNacimiento, parentesco, direccion) VALUES ('1720234567', 'Elena', 'Ramírez', '0987654321', 'elena@gmail.com', '1990-01-20', 'Prima', 'Avenida 5678');
INSERT INTO Acompanante (cedula, nombre, apellido, telefono, email, fechaNacimiento, parentesco, direccion) VALUES ('2350713668', 'Julio', 'Ortega', '5432167890', 'julio@example.com', '1985-07-18', 'Amigo', 'Calle 9012');
INSERT INTO Acompanante (cedula, nombre, apellido, telefono, email, fechaNacimiento, parentesco, direccion) VALUES ('1716890123', 'Carolina', 'Vargas', '0987654321', 'carolina@example.com', '1993-04-28', 'Amiga', 'Avenida 2345');
INSERT INTO Acompanante (cedula, nombre, apellido, telefono, email, fechaNacimiento, parentesco, direccion) VALUES ('1234067890', 'Roberto', 'Mendoza', '1234567890', 'roberto@example.com', '1978-09-10', 'Amigo', 'Calle 5678');
INSERT INTO Acompanante (cedula, nombre, apellido, telefono, email, fechaNacimiento, parentesco, direccion) VALUES ('2350713654', 'Camila', 'García', '5432167890', 'camila@example.com', '1997-02-15', 'Amiga', 'Avenida 9012');
INSERT INTO Acompanante (cedula, nombre, apellido, telefono, email, fechaNacimiento, parentesco, direccion) VALUES ('1716890678', 'Andrés', 'Herrera', '0987654321', 'andres@example.com', '1983-11-20', 'Amigo', 'Calle 1234');
INSERT INTO Acompanante (cedula, nombre, apellido, telefono, email, fechaNacimiento, parentesco, direccion) VALUES ('1234567895', 'Valentina', 'Silva', '1234567890', 'valentina@example.com', '1996-06-25', 'Amiga', 'Avenida 5678');
INSERT INTO Acompanante (cedula, nombre, apellido, telefono, email, fechaNacimiento, parentesco, direccion) VALUES ('2350713621', 'Felipe', 'Guzmán', '5432167890', 'felipe@example.com', '1987-03-05', 'Amigo', 'Calle 9012');
INSERT INTO Acompanante (cedula, nombre, apellido, telefono, email, fechaNacimiento, parentesco, direccion) VALUES ('1716890312', 'Mariana', 'Pérez', '0987654321', 'mariana@example.com', '1991-10-15', 'Amiga', 'Avenida 2345');
INSERT INTO Acompanante (cedula, nombre, apellido, telefono, email, fechaNacimiento, parentesco, direccion) VALUES ('0634567890', 'Ricardo', 'Vega', '1234567890', 'ricardo@example.com', '1979-07-30', 'Amigo', 'Calle 5678');
INSERT INTO Acompanante (cedula, nombre, apellido, telefono, email, fechaNacimiento, parentesco, direccion) VALUES ('1717901236', 'Daniela', 'Mendoza', '5432167890', 'daniela@example.com', '1994-04-12', 'Amiga', 'Avenida 9012');
GO
-- Ingreso de datos en la tabla Paciente
--SELECT*FROM Paciente
INSERT INTO Paciente (idAcompanante, cedula, nombre, apellido, fechaNacimiento, genero, etapa, direccion)
VALUES (1, '1717901239', 'Juan', 'Pérez', '1990-01-01', 'Masculino', 'Leve', 'Calle 123, Calle 12');
INSERT INTO Paciente (idAcompanante, cedula, nombre, apellido, fechaNacimiento, genero, etapa, direccion)
VALUES (2, '2345678901', 'María', 'Garc', '1995-02-02', 'Femenino', 'Moderada', 'Calle 456, Av.6 de diciembre');
INSERT INTO Paciente (idAcompanante, cedula, nombre, apellido, fechaNacimiento, genero, etapa, direccion)
VALUES (3, '2350713622', 'Pedro', 'Martínez', '2000-03-03', 'Masculino', 'Grave', 'Calle789, AV.Portugal');
INSERT INTO Paciente (idAcompanante, cedula, nombre, apellido, fechaNacimiento, genero, etapa, direccion)
VALUES (4, '1717901236', 'Ana', 'López', '1985-04-04', 'Femenino', 'Leve', 'Calle 012, Santo Domingo');
INSERT INTO Paciente (idAcompanante, cedula, nombre, apellido, fechaNacimiento, genero, etapa, direccion)
VALUES (5, '1717901234', 'Carlos', 'González', '1992-05-05', 'Masculino', 'Moderada', 'Calle 345, Av.Granados');
INSERT INTO Paciente (idAcompanante, cedula, nombre, apellido, fechaNacimiento, genero, etapa, direccion)
VALUES (6, '1717901245', 'Laura', 'Hernández', '1998-06-06', 'Femenino', 'Grave', 'Calle 678, Av.Simon Bolívar');
INSERT INTO Paciente (idAcompanante, cedula, nombre, apellido, fechaNacimiento, genero, etapa, direccion)
VALUES (7, '2350713661', 'Jorge', 'Díaz', '1980-07-07', 'Masculino', 'Leve', 'Calle 901, calle 23-3e');
INSERT INTO Paciente (idAcompanante, cedula, nombre, apellido, fechaNacimiento, genero, etapa, direccion)
VALUES (8, '2350713662', 'Sofía', 'Ramírez', '1987-08-08', 'Femenino', 'Moderada', 'Calle 234, Santo Domingo');
INSERT INTO Paciente (idAcompanante, cedula, nombre, apellido, fechaNacimiento, genero, etapa, direccion)
VALUES (9, '2350713663', 'Luis', 'Sánchez', '1996-09-09', 'Masculino', 'Grave', 'Calle 567, Av.Galápagos');
INSERT INTO Paciente (idAcompanante, cedula, nombre, apellido, fechaNacimiento, genero, etapa, direccion)
VALUES (10, '0123456789', 'Marta', 'Gómez', '1993-10-10', 'Femenino', 'Leve', 'Calle 890, Calle 45-E325');
INSERT INTO Paciente (idAcompanante, cedula, nombre, apellido, fechaNacimiento, genero, etapa, direccion)
VALUES (11, '2345678905', 'Diego', 'Pérez', '1983-11-11', 'Masculino', 'Moderada', 'Calle 123, Av,Granados');
INSERT INTO Paciente (idAcompanante, cedula, nombre, apellido, fechaNacimiento, genero, etapa, direccion)
VALUES (12, '2350713664', 'Lucía', 'García', '1991-12-12', 'Femenino', 'Grave', 'Calle 456, Av.Italia');
INSERT INTO Paciente (idAcompanante, cedula, nombre, apellido, fechaNacimiento, genero, etapa, direccion)
VALUES (13, '2350713665', 'Andrés', 'Martínez', '1999-01-13', 'Masculino', 'Leve', 'Calle 789, calle 345');
INSERT INTO Paciente (idAcompanante, cedula, nombre, apellido, fechaNacimiento, genero, etapa, direccion)
VALUES (14, '2350713636', 'Carla', 'López', '1986-02-14', 'Femenino', 'Moderada', 'Calle 012, Av.Simón Bolívar');
INSERT INTO Paciente (idAcompanante, cedula, nombre, apellido, fechaNacimiento, genero, etapa, direccion)
VALUES (15, '2350713625', 'Fernando', 'González', '1997-03-15', 'Masculino', 'Grave', 'Calle 345, Santo Domingo');
INSERT INTO Paciente (idAcompanante, cedula, nombre, apellido, fechaNacimiento, genero, etapa, direccion)
VALUES (16, '2350713624', 'Paola', 'Hernández', '1981-04-16', 'Femenino', 'Leve', 'Calle 678, Av. Granados');
INSERT INTO Paciente (idAcompanante, cedula, nombre, apellido, fechaNacimiento, genero, etapa, direccion)
VALUES (17, '2350713623', 'Roberto', 'Díaz', '1994-05-17', 'Masculino', 'Moderada', 'Calle 901, Av.Floresta');
INSERT INTO Paciente (idAcompanante, cedula, nombre, apellido, fechaNacimiento, genero, etapa, direccion)
VALUES (18, '2350713667', 'Valeria', 'Ramírez', '1988-06-18', 'Femenino', 'Grave', 'Calle 234, Av.Quito');
INSERT INTO Paciente (idAcompanante, cedula, nombre, apellido, fechaNacimiento, genero, etapa, direccion)
VALUES (19, '0123456779', 'Gabriel', 'Sánchez', '1995-07-19', 'Masculino', 'Leve', 'Calle , Avenido Los Laureles');
INSERT INTO Paciente (idAcompanante, cedula, nombre, apellido, fechaNacimiento, genero, etapa, direccion)
VALUES (20, '1234567890', 'Isabel', 'Gómez', '1984-08-20', 'Femenino', 'Moderada', 'Calle 890, Av.6 de diciembre');
GO


EXEC InsertarResultadoActividad '1717901239', 'Comprensión lectora', 6, '00:08:00';
EXEC InsertarResultadoActividad '2345678901', 'Sumas y restas', 4, '00:03:00';
EXEC InsertarResultadoActividad '2350713622', 'Reconocimiento de colores, sonidos y figuras', 6, '00:06:00';
EXEC InsertarResultadoActividad '1717901236', 'Juegos de memoria', 10, '00:10:00';
EXEC InsertarResultadoActividad '1717901234', 'Sopas de letras', 10, '00:05:00';

--SELECT*FROM ResultadoActividad


INSERT INTO Consejero (cedula, nombre, apellido, telefono, email, fechaNacimiento, direccion, especializacion)
VALUES ('1234567890', 'Juan', 'Pérez', '1234567890', 'juan.perez@example.com', '1990-01-01', 'Calle 1 #123', 'Psicología');

INSERT INTO Consejero (cedula, nombre, apellido, telefono, email, fechaNacimiento, direccion, especializacion)
VALUES ('2345678901', 'María', 'García', '2345678901', 'maria.garcia@example.com', '1985-05-15', 'Calle 2 #456', 'Terapia de pareja');

INSERT INTO Consejero (cedula, nombre, apellido, telefono, email, fechaNacimiento, direccion, especializacion)
VALUES ('1728174101', 'Pedro', 'López', '3456789012', 'pedro.lopez@example.com', '1995-12-31', 'Calle 3 #789', 'Psicología infantil');

INSERT INTO Consejero (cedula, nombre, apellido, telefono, email, fechaNacimiento, direccion, especializacion)
VALUES ('1728174102', 'Ana', 'Martínez', '4567890123', 'ana.martinez@example.com', '1980-07-20', 'Calle 4 #1011', 'Terapia cognitivo-conductual');

INSERT INTO Consejero (cedula, nombre, apellido, telefono, email, fechaNacimiento, direccion, especializacion)
VALUES ('1728174103', 'Carlos', 'González', '5678901234', 'carlos.gonzalez@example.com', '1992-03-05', 'Calle 5 #1213', 'Terapia de grupo');

INSERT INTO Consejero (cedula, nombre, apellido, telefono, email, fechaNacimiento, direccion, especializacion)
VALUES ('0102343613', 'Laura', 'Hernández', '6789012345', 'laura.hernandez@example.com', '1988-11-12', 'Calle 6 #1415', 'Psicología clínica');

INSERT INTO Consejero (cedula, nombre, apellido, telefono, email, fechaNacimiento, direccion, especializacion)
VALUES ('0102343614', 'Jorge', 'Díaz', '7890123456', 'jorge.diaz@example.com', '1998-06-25', 'Calle 7 #1617', 'Terapia de pareja');

INSERT INTO Consejero (cedula, nombre, apellido, telefono, email, fechaNacimiento, direccion, especializacion)
VALUES ('0102343616', 'Sofía', 'Ramírez', '8901234567', 'sofia.ramirez@example.com', '1983-09-10', 'Calle 8 #1819', 'Psicología forense');

INSERT INTO Consejero (cedula, nombre, apellido, telefono, email, fechaNacimiento, direccion, especializacion)
VALUES ('1728174111', 'Diego', 'Sánchez', '9012345678', 'diego.sanchez@example.com', '1991-02-14', 'Calle 9 #2021', 'Terapia de grupo');

INSERT INTO Consejero (cedula, nombre, apellido, telefono, email, fechaNacimiento, direccion, especializacion)
VALUES ('1707041917', 'Lucía', 'Gómez', '0123456789', 'luci.gomez@example.com', '1986-08-30', 'Calle 10 #2223', 'Psicología clínica');

INSERT INTO Consejero (cedula, nombre, apellido, telefono, email, fechaNacimiento, direccion, especializacion)
VALUES ('0102343610', 'Mario', 'Torres', '2345678901', 'mario.torres@example.com', '1993-04-17', 'Calle 11 #2425', 'Terapia cognitivo-conductual');

INSERT INTO Consejero (cedula, nombre, apellido, telefono, email, fechaNacimiento, direccion, especializacion)
VALUES ('1707041911', 'Fernanda', 'Ruiz', '3456789012', 'fernanda.ruiz@example.com', '1981-12-05', 'Calle 12 #2627', 'Psicología infantil');

INSERT INTO Consejero (cedula, nombre, apellido, telefono, email, fechaNacimiento, direccion, especializacion)
VALUES ('1707041912', 'Gabriel', 'Castro', '4567890123', 'gabriel.castro@example.com', '1997-09-22', 'Calle 13 #2829', 'Terapia de pareja');

INSERT INTO Consejero (cedula, nombre, apellido, telefono, email, fechaNacimiento, direccion, especializacion)
VALUES ('1707041915', 'Valentina', 'Fernández', '5678901234', 'valentina.fernandez@example.com', '1987-06-10', 'Calle 14 #3031', 'Psicología clínica');

INSERT INTO Consejero (cedula, nombre, apellido, telefono, email, fechaNacimiento, direccion, especializacion)
VALUES ('0102343619', 'Andrés', 'Gutiérrez', '6789012345', 'andres.gutierrez@example.com', '1994-02-27', 'Calle 15 #3233', 'Terapia de grupo');

INSERT INTO Consejero (cedula, nombre, apellido, telefono, email, fechaNacimiento, direccion, especializacion)
VALUES ('1724399991', 'Carolina', 'Navarro', '7890123456', 'carolina.navarro@example.com', '1982-11-15', 'Calle 16 #3435', 'Psicología forense');

INSERT INTO Consejero (cedula, nombre, apellido, telefono, email, fechaNacimiento, direccion, especializacion)
VALUES ('1724399992', 'David', 'Ortega', '8901234567', 'david.ortega@example.com', '1990-08-02', 'Calle 17 #3637', 'Terapia cognitivo-conductual');

INSERT INTO Consejero (cedula, nombre, apellido, telefono, email, fechaNacimiento, direccion, especializacion)
VALUES ('1724399993', 'Isabella', 'Pérez', '9012345678', 'isabella.perez@example.com', '1984-03-20', 'Calle 18 #3839', 'Psicología infantil');

INSERT INTO Consejero (cedula, nombre, apellido, telefono, email, fechaNacimiento, direccion, especializacion)
VALUES ('1724399994', 'Javier', 'García', '0123456789', 'javier.garcia@example.com', '1996-12-08', 'Calle 19 #4041', 'Terapia de pareja');

INSERT INTO Consejero (cedula, nombre, apellido, telefono, email, fechaNacimiento, direccion, especializacion)
VALUES ('1234567894', 'Mariana', 'López', '1234567890', 'mariana.lopez@example.com', '1989-09-25', 'Calle 20 #4243', 'Psicología clínica');



INSERT INTO Charla (tema, fechaHora)
VALUES ('Cómo cuidar a una persona con Alzheimer en casa', '2023-05-15 10:00:00');

INSERT INTO Charla (tema, fechaHora)
VALUES ('Estrategias para mejorar la comunicación con personas con Alzheimer', '2023-05-16 14:30:00');

INSERT INTO Charla (tema, fechaHora)
VALUES ('Cómo manejar los cambios de humor en personas con Alzheimer', '2023-05-17 11:00:00');

INSERT INTO Charla (tema, fechaHora)
VALUES ('Cómo prevenir el aislamiento social en personas con Alzheimer', '2023-05-18 16:00:00');

INSERT INTO Charla (tema, fechaHora)
VALUES ('Cómo manejar los problemas de sueño en personas con Alzheimer', '2023-05-19 19:00:00');

INSERT INTO Charla (tema, fechaHora)
VALUES ('Cómo manejar los problemas de alimentación en personas con Alzheimer', '2023-05-20 10:30:00');

INSERT INTO Charla (tema, fechaHora)
VALUES ('Cómo manejar los problemas de incontinencia en personas con Alzheimer', '2023-05-21 15:00:00');

INSERT INTO Charla (tema, fechaHora)
VALUES ('Cómo manejar los problemas de movilidad en personas con Alzheimer', '2023-05-22 12:00:00');

INSERT INTO Charla (tema, fechaHora)
VALUES ('Cómo manejar los problemas de higiene en personas con Alzheimer', '2023-05-23 17:00:00');

INSERT INTO Charla (tema, fechaHora)
VALUES ('Cómo manejar los problemas de comportamiento en personas con Alzheimer', '2023-05-24 10:00:00');

INSERT INTO Charla (tema, fechaHora)
VALUES ('Cómo manejar los problemas de memoria en personas con Alzheimer', '2023-05-25 14:30:00');

INSERT INTO Charla (tema, fechaHora)
VALUES ('Cómo manejar los problemas de agitación en personas con Alzheimer', '2023-05-26 11:00:00');

INSERT INTO Charla (tema, fechaHora)
VALUES ('Cómo manejar los problemas de agresividad en personas con Alzheimer', '2023-05-27 16:00:00');

INSERT INTO Charla (tema, fechaHora)
VALUES ('Cómo manejar los problemas de desorientación en personas con Alzheimer', '2023-05-28 19:00:00');

INSERT INTO Charla (tema, fechaHora)
VALUES ('Cómo manejar los problemas de comunicación en personas con Alzheimer avanzado', '2023-05-29 10:30:00');

INSERT INTO Charla (tema, fechaHora)
VALUES ('Cómo manejar los problemas de cuidado personal en personas con Alzheimer avanzado', '2023-05-30 15:00:00');

INSERT INTO Charla (tema, fechaHora)
VALUES ('Cómo manejar los problemas de movilidad en personas con Alzheimer avanzado', '2023-05-31 12:00:00');

INSERT INTO Charla (tema, fechaHora)
VALUES ('Cómo manejar los problemas de alimentación en personas con Alzheimer avanzado', '2023-06-01 17:00:00');

INSERT INTO Charla (tema, fechaHora)
VALUES ('Cómo manejar los problemas de incontinencia en personas con Alzheimer avanzado', '2023-06-02 10:00:00');

INSERT INTO Charla (tema, fechaHora)
VALUES ('Cómo manejar los problemas de comportamiento en personas con Alzheimer avanzado', '2023-06-03 14:30:00');


INSERT INTO AsistenciaConsejero (idConsejero, idCharla, horaAsistencia, registroAsiste)
VALUES (1, 1, '10:00:00', 'Si');

INSERT INTO AsistenciaConsejero (idConsejero, idCharla, horaAsistencia, registroAsiste)
VALUES (2, 2, '14:30:00', 'Si');

INSERT INTO AsistenciaConsejero (idConsejero, idCharla, horaAsistencia, registroAsiste)
VALUES (3, 3, '11:00:00', 'No');

INSERT INTO AsistenciaConsejero (idConsejero, idCharla, horaAsistencia, registroAsiste)
VALUES (4, 4, '16:00:00', 'Si');

INSERT INTO AsistenciaConsejero (idConsejero, idCharla, horaAsistencia, registroAsiste)
VALUES (5, 5, '19:00:00', 'No');

INSERT INTO AsistenciaConsejero (idConsejero, idCharla, horaAsistencia, registroAsiste)
VALUES (6, 6, '10:30:00', 'Si');

INSERT INTO AsistenciaConsejero (idConsejero, idCharla, horaAsistencia, registroAsiste)
VALUES (7, 7, '15:00:00', 'No');

INSERT INTO AsistenciaConsejero (idConsejero, idCharla, horaAsistencia, registroAsiste)
VALUES (8, 8, '12:00:00', 'Si');

INSERT INTO AsistenciaConsejero (idConsejero, idCharla, horaAsistencia, registroAsiste)
VALUES (9, 9, '17:00:00', 'No');

INSERT INTO AsistenciaConsejero (idConsejero, idCharla, horaAsistencia, registroAsiste)
VALUES (10, 10, '10:00:00', 'Si');

INSERT INTO AsistenciaConsejero (idConsejero, idCharla, horaAsistencia, registroAsiste)
VALUES (11, 11, '14:30:00', 'No');

INSERT INTO AsistenciaConsejero (idConsejero, idCharla, horaAsistencia, registroAsiste)
VALUES (12, 12, '11:00:00', 'Si');

INSERT INTO AsistenciaConsejero (idConsejero, idCharla, horaAsistencia, registroAsiste)
VALUES (13, 13, '16:00:00', 'No');

INSERT INTO AsistenciaConsejero (idConsejero, idCharla, horaAsistencia, registroAsiste)
VALUES (14, 14, '19:00:00', 'Si');

INSERT INTO AsistenciaConsejero (idConsejero, idCharla, horaAsistencia, registroAsiste)
VALUES (15, 15, '10:30:00', 'No');

INSERT INTO AsistenciaConsejero (idConsejero, idCharla, horaAsistencia, registroAsiste)
VALUES (16, 16, '15:00:00', 'Si');

INSERT INTO AsistenciaConsejero (idConsejero, idCharla, horaAsistencia, registroAsiste)
VALUES (17, 17, '12:00:00', 'No');

INSERT INTO AsistenciaConsejero (idConsejero, idCharla, horaAsistencia, registroAsiste)
VALUES (18, 18, '17:00:00', 'Si');

INSERT INTO AsistenciaConsejero (idConsejero, idCharla, horaAsistencia, registroAsiste)
VALUES (19, 19, '10:00:00', 'No');

INSERT INTO AsistenciaConsejero (idConsejero, idCharla, horaAsistencia, registroAsiste)
VALUES (20, 20, '14:30:00', 'Si');

INSERT INTO AsistenciaAcompanante (idAcompanante, idCharla, horaAsistencia, registroAsiste)
VALUES (1, 1, '10:00:00', 'Si');

INSERT INTO AsistenciaAcompanante (idAcompanante, idCharla, horaAsistencia, registroAsiste)
VALUES (2, 2, '14:30:00', 'Si');

INSERT INTO AsistenciaAcompanante (idAcompanante, idCharla, horaAsistencia, registroAsiste)
VALUES (3, 3, '11:00:00', 'No');

INSERT INTO AsistenciaAcompanante (idAcompanante, idCharla, horaAsistencia, registroAsiste)
VALUES (4, 4, '16:00:00', 'Si');

INSERT INTO AsistenciaAcompanante (idAcompanante, idCharla, horaAsistencia, registroAsiste)
VALUES (5, 5, '19:00:00', 'No');

INSERT INTO AsistenciaAcompanante (idAcompanante, idCharla, horaAsistencia, registroAsiste)
VALUES (6, 6, '10:30:00', 'Si');

INSERT INTO AsistenciaAcompanante (idAcompanante, idCharla, horaAsistencia, registroAsiste)
VALUES (7, 7, '15:00:00', 'No');

INSERT INTO AsistenciaAcompanante (idAcompanante, idCharla, horaAsistencia, registroAsiste)
VALUES (8, 8, '12:00:00', 'Si');

INSERT INTO AsistenciaAcompanante (idAcompanante, idCharla, horaAsistencia, registroAsiste)
VALUES (9, 9, '17:00:00', 'No');

INSERT INTO AsistenciaAcompanante (idAcompanante, idCharla, horaAsistencia, registroAsiste)
VALUES (10, 10, '10:00:00', 'Si');

INSERT INTO AsistenciaAcompanante (idAcompanante, idCharla, horaAsistencia, registroAsiste)
VALUES (1, 11, '14:30:00', 'No');

INSERT INTO AsistenciaAcompanante (idAcompanante, idCharla, horaAsistencia, registroAsiste)
VALUES (2, 12, '11:00:00', 'Si');

INSERT INTO AsistenciaAcompanante (idAcompanante, idCharla, horaAsistencia, registroAsiste)
VALUES (3, 13, '16:00:00', 'No');

INSERT INTO AsistenciaAcompanante (idAcompanante, idCharla, horaAsistencia, registroAsiste)
VALUES (4, 14, '19:00:00', 'Si');

INSERT INTO AsistenciaAcompanante (idAcompanante, idCharla, horaAsistencia, registroAsiste)
VALUES (5, 15, '10:30:00', 'No');

INSERT INTO AsistenciaAcompanante (idAcompanante, idCharla, horaAsistencia, registroAsiste)
VALUES (6, 16, '15:00:00', 'Si');

INSERT INTO AsistenciaAcompanante (idAcompanante, idCharla, horaAsistencia, registroAsiste)
VALUES (7, 17, '12:00:00', 'No');

INSERT INTO AsistenciaAcompanante (idAcompanante, idCharla, horaAsistencia, registroAsiste)
VALUES (8, 18, '17:00:00', 'Si');

INSERT INTO AsistenciaAcompanante (idAcompanante, idCharla, horaAsistencia, registroAsiste)
VALUES (9, 19, '10:00:00', 'No');

INSERT INTO AsistenciaAcompanante (idAcompanante, idCharla, horaAsistencia, registroAsiste)
VALUES (10, 20, '14:30:00', 'Si');


INSERT INTO PlanMedico (idMedico, idActividad, fechaPlan)
VALUES (1, 1, '2023-05-15');

INSERT INTO PlanMedico (idMedico, idActividad, fechaPlan)
VALUES (2, 2, '2023-05-16');

INSERT INTO PlanMedico (idMedico, idActividad, fechaPlan)
VALUES (3, 3, '2023-05-17');

INSERT INTO PlanMedico (idMedico, idActividad, fechaPlan)
VALUES (4, 4, '2023-05-18');

INSERT INTO PlanMedico (idMedico, idActividad, fechaPlan)
VALUES (5, 5, '2023-05-19');

INSERT INTO PlanMedico (idMedico, idActividad, fechaPlan)
VALUES (6, 6, '2023-05-20');

INSERT INTO PlanMedico (idMedico, idActividad, fechaPlan)
VALUES (7, 7, '2023-05-21');

INSERT INTO PlanMedico (idMedico, idActividad, fechaPlan)
VALUES (8, 8, '2023-05-22');

INSERT INTO PlanMedico (idMedico, idActividad, fechaPlan)
VALUES (9, 9, '2023-05-23');

INSERT INTO PlanMedico (idMedico, idActividad, fechaPlan)
VALUES (10, 10, '2023-05-24');

INSERT INTO PlanMedico (idMedico, idActividad, fechaPlan)
VALUES (1, 11, '2023-05-25');

INSERT INTO PlanMedico (idMedico, idActividad, fechaPlan)
VALUES (2, 12, '2023-05-26');

INSERT INTO PlanMedico (idMedico, idActividad, fechaPlan)
VALUES (3, 13, '2023-05-27');

INSERT INTO PlanMedico (idMedico, idActividad, fechaPlan)
VALUES (4, 14, '2023-05-28');

INSERT INTO PlanMedico (idMedico, idActividad, fechaPlan)
VALUES (5, 15, '2023-05-29');

INSERT INTO PlanMedico (idMedico, idActividad, fechaPlan)
VALUES (6, 16, '2023-05-30');

INSERT INTO PlanMedico (idMedico, idActividad, fechaPlan)
VALUES (7, 17, '2023-05-31');

INSERT INTO PlanMedico (idMedico, idActividad, fechaPlan)
VALUES (8, 18, '2023-06-01');

INSERT INTO PlanMedico (idMedico, idActividad, fechaPlan)
VALUES (9, 19, '2023-06-02');

INSERT INTO PlanMedico (idMedico, idActividad, fechaPlan)
VALUES (10, 20, '2023-06-03');





-- Ingreso de datos en la tabla PlanNutricional
INSERT INTO PlanNutricional (idAcompanante, nombrePlan, comidasDia, caloriasDia, alimentosRecomendados) VALUES (1, 'Plan A', '3', 1500, 'Pollo, arroz, verduras');
INSERT INTO PlanNutricional (idAcompanante, nombrePlan, comidasDia, caloriasDia, alimentosRecomendados) VALUES (2, 'Plan B', '5', 2000, 'Pescado, quinoa, ensalada');
INSERT INTO PlanNutricional (idAcompanante, nombrePlan, comidasDia, caloriasDia, alimentosRecomendados) VALUES (3, 'Plan C', '4', 1800, 'Carne, pasta, brócoli');
INSERT INTO PlanNutricional (idAcompanante, nombrePlan, comidasDia, caloriasDia, alimentosRecomendados) VALUES (4, 'Plan D', '6', 2200, 'Huevos, avena, frutas');
INSERT INTO PlanNutricional (idAcompanante, nombrePlan, comidasDia, caloriasDia, alimentosRecomendados) VALUES (5, 'Plan E', '3', 1500, 'Tofu, arroz integral, verduras');
INSERT INTO PlanNutricional (idAcompanante, nombrePlan, comidasDia, caloriasDia, alimentosRecomendados) VALUES (6, 'Plan F', '5', 2000, 'Salmón, quinoa, ensalada');
INSERT INTO PlanNutricional (idAcompanante, nombrePlan, comidasDia, caloriasDia, alimentosRecomendados) VALUES (7, 'Plan G', '4', 1800, 'Pollo, pasta, brócoli');
INSERT INTO PlanNutricional (idAcompanante, nombrePlan, comidasDia, caloriasDia, alimentosRecomendados) VALUES (8, 'Plan H', '6', 2200, 'Huevos, avena, frutas');
INSERT INTO PlanNutricional (idAcompanante, nombrePlan, comidasDia, caloriasDia, alimentosRecomendados) VALUES (9, 'Plan I', '3', 1500, 'Tofu, arroz integral, verduras');
INSERT INTO PlanNutricional (idAcompanante, nombrePlan, comidasDia, caloriasDia, alimentosRecomendados) VALUES (10, 'Plan J', '5', 2000, 'Pescado, quinoa, ensalada');
INSERT INTO PlanNutricional (idAcompanante, nombrePlan, comidasDia, caloriasDia, alimentosRecomendados) VALUES (11, 'Plan K', '4', 1800, 'Carne, pasta, brócoli');
INSERT INTO PlanNutricional (idAcompanante, nombrePlan, comidasDia, caloriasDia, alimentosRecomendados) VALUES (12, 'Plan L', '6', 2200, 'Huevos, avena, frutas');
INSERT INTO PlanNutricional (idAcompanante, nombrePlan, comidasDia, caloriasDia, alimentosRecomendados) VALUES (13, 'Plan M', '3', 1500, 'Tofu, arroz integral, verduras');
INSERT INTO PlanNutricional (idAcompanante, nombrePlan, comidasDia, caloriasDia, alimentosRecomendados) VALUES (14, 'Plan N', '5', 2000, 'Salmón, quinoa, ensalada');
INSERT INTO PlanNutricional (idAcompanante, nombrePlan, comidasDia, caloriasDia, alimentosRecomendados) VALUES (15, 'Plan O', '4', 1800, 'Pollo, pasta, brócoli');
INSERT INTO PlanNutricional (idAcompanante, nombrePlan, comidasDia, caloriasDia, alimentosRecomendados) VALUES (16, 'Plan P', '6', 2200, 'Huevos, avena, frutas');
INSERT INTO PlanNutricional (idAcompanante, nombrePlan, comidasDia, caloriasDia, alimentosRecomendados) VALUES (17, 'Plan Q', '3', 1500, 'Tofu, arroz integral, verduras');
INSERT INTO PlanNutricional (idAcompanante, nombrePlan, comidasDia, caloriasDia, alimentosRecomendados) VALUES (18, 'Plan R', '5', 2000, 'Pescado, quinoa, ensalada');
INSERT INTO PlanNutricional (idAcompanante, nombrePlan, comidasDia, caloriasDia, alimentosRecomendados) VALUES (19, 'Plan S', '4', 1800, 'Carne, pasta, brócoli');
INSERT INTO PlanNutricional (idAcompanante, nombrePlan, comidasDia, caloriasDia, alimentosRecomendados) VALUES (20, 'Plan T', '6', 2200, 'Huevos, avena, frutas');

-- Ingreso de datos en la tabla AsignacionPlanNutricional
INSERT INTO AsignacionPlanNutricional (idPlanNutricional, idNutriologo, fechaAsignacion) VALUES (1, 1, '2023-06-11 10:00:00');
INSERT INTO AsignacionPlanNutricional (idPlanNutricional, idNutriologo, fechaAsignacion) VALUES (2, 2, '2023-06-10 16:00:00');
INSERT INTO AsignacionPlanNutricional (idPlanNutricional, idNutriologo, fechaAsignacion) VALUES (3, 3, '2023-06-10 17:45:00');
INSERT INTO AsignacionPlanNutricional (idPlanNutricional, idNutriologo, fechaAsignacion) VALUES (4, 4, '2023-06-10 18:15:00');
INSERT INTO AsignacionPlanNutricional (idPlanNutricional, idNutriologo, fechaAsignacion) VALUES (5, 5, '2023-06-10 15:30:00');
INSERT INTO AsignacionPlanNutricional (idPlanNutricional, idNutriologo, fechaAsignacion) VALUES (6, 6, '2023-06-11 13:30:00');
INSERT INTO AsignacionPlanNutricional (idPlanNutricional, idNutriologo, fechaAsignacion) VALUES (7, 7, '2023-06-11 10:45:00');
INSERT INTO AsignacionPlanNutricional (idPlanNutricional, idNutriologo, fechaAsignacion) VALUES (8, 8, '2023-06-11 08:15:00');
INSERT INTO AsignacionPlanNutricional (idPlanNutricional, idNutriologo, fechaAsignacion) VALUES (9, 9, '2023-06-11 15:00:00');
INSERT INTO AsignacionPlanNutricional (idPlanNutricional, idNutriologo, fechaAsignacion) VALUES (10, 10, '2023-06-11 12:30:00');
INSERT INTO AsignacionPlanNutricional (idPlanNutricional, idNutriologo, fechaAsignacion) VALUES (11, 1, '2023-06-11 09:45:00');
INSERT INTO AsignacionPlanNutricional (idPlanNutricional, idNutriologo, fechaAsignacion) VALUES (12, 2, '2023-06-11 07:15:00');
INSERT INTO AsignacionPlanNutricional (idPlanNutricional, idNutriologo, fechaAsignacion) VALUES (13, 3, '2023-07-11 14:00:00');
INSERT INTO AsignacionPlanNutricional (idPlanNutricional, idNutriologo, fechaAsignacion) VALUES (14, 4, '2023-07-11 11:30:00');
INSERT INTO AsignacionPlanNutricional (idPlanNutricional, idNutriologo, fechaAsignacion) VALUES (15, 5, '2023-07-11 08:45:00');
INSERT INTO AsignacionPlanNutricional (idPlanNutricional, idNutriologo, fechaAsignacion) VALUES (16, 6, '2023-07-11 06:15:00');
INSERT INTO AsignacionPlanNutricional (idPlanNutricional, idNutriologo, fechaAsignacion) VALUES (17, 7, '2023-07-11 13:00:00');
INSERT INTO AsignacionPlanNutricional (idPlanNutricional, idNutriologo, fechaAsignacion) VALUES (18, 8, '2023-07-11 10:30:00');
INSERT INTO AsignacionPlanNutricional (idPlanNutricional, idNutriologo, fechaAsignacion) VALUES (19, 9, '2023-07-11 07:45:00');
INSERT INTO AsignacionPlanNutricional (idPlanNutricional, idNutriologo, fechaAsignacion) VALUES (20, 10, '2023-07-11 05:15:00');

-- Ingreso de datos en la tabla ExamenFisico
INSERT INTO ExamenFisico (fechaExamen, rangoVisualMinimo, rangoVisualMaximo, rangoAuditivoMinimo, rangoAuditivoMaximo) VALUES ('2023-06-11', 1, 10, 1, 10);
INSERT INTO ExamenFisico (fechaExamen, rangoVisualMinimo, rangoVisualMaximo, rangoAuditivoMinimo, rangoAuditivoMaximo) VALUES ('2023-06-10', 2, 9, 2, 9);
INSERT INTO ExamenFisico (fechaExamen, rangoVisualMinimo, rangoVisualMaximo, rangoAuditivoMinimo, rangoAuditivoMaximo) VALUES ('2023-06-09', 3, 8, 3, 8);
INSERT INTO ExamenFisico (fechaExamen, rangoVisualMinimo, rangoVisualMaximo, rangoAuditivoMinimo, rangoAuditivoMaximo) VALUES ('2023-06-08', 4, 7, 4, 7);
INSERT INTO ExamenFisico (fechaExamen, rangoVisualMinimo, rangoVisualMaximo, rangoAuditivoMinimo, rangoAuditivoMaximo) VALUES ('2023-06-07', 1, 6, 1, 6);
INSERT INTO ExamenFisico (fechaExamen, rangoVisualMinimo, rangoVisualMaximo, rangoAuditivoMinimo, rangoAuditivoMaximo) VALUES ('2023-06-06', 3, 5, 4, 5);
INSERT INTO ExamenFisico (fechaExamen, rangoVisualMinimo, rangoVisualMaximo, rangoAuditivoMinimo, rangoAuditivoMaximo) VALUES ('2023-06-05', 1, 4, 2, 4);
INSERT INTO ExamenFisico (fechaExamen, rangoVisualMinimo, rangoVisualMaximo, rangoAuditivoMinimo, rangoAuditivoMaximo) VALUES ('2023-06-04', 2, 3, 1, 3);
INSERT INTO ExamenFisico (fechaExamen, rangoVisualMinimo, rangoVisualMaximo, rangoAuditivoMinimo, rangoAuditivoMaximo) VALUES ('2023-06-03', 1, 2, 1, 2);
INSERT INTO ExamenFisico (fechaExamen, rangoVisualMinimo, rangoVisualMaximo, rangoAuditivoMinimo, rangoAuditivoMaximo) VALUES ('2023-06-02', 1, 3, 1, 3);
INSERT INTO ExamenFisico (fechaExamen, rangoVisualMinimo, rangoVisualMaximo, rangoAuditivoMinimo, rangoAuditivoMaximo) VALUES ('2023-06-01', 1, 6, 1, 10);
INSERT INTO ExamenFisico (fechaExamen, rangoVisualMinimo, rangoVisualMaximo, rangoAuditivoMinimo, rangoAuditivoMaximo) VALUES ('2023-07-30', 2, 9, 2, 9);
INSERT INTO ExamenFisico (fechaExamen, rangoVisualMinimo, rangoVisualMaximo, rangoAuditivoMinimo, rangoAuditivoMaximo) VALUES ('2023-07-29', 3, 8, 3, 8);
INSERT INTO ExamenFisico (fechaExamen, rangoVisualMinimo, rangoVisualMaximo, rangoAuditivoMinimo, rangoAuditivoMaximo) VALUES ('2023-07-28', 4, 7, 4, 7);
INSERT INTO ExamenFisico (fechaExamen, rangoVisualMinimo, rangoVisualMaximo, rangoAuditivoMinimo, rangoAuditivoMaximo) VALUES ('2023-07-27', 5, 6, 5, 6);
INSERT INTO ExamenFisico (fechaExamen, rangoVisualMinimo, rangoVisualMaximo, rangoAuditivoMinimo, rangoAuditivoMaximo) VALUES ('2023-07-26', 2, 5, 6, 7);
INSERT INTO ExamenFisico (fechaExamen, rangoVisualMinimo, rangoVisualMaximo, rangoAuditivoMinimo, rangoAuditivoMaximo) VALUES ('2023-07-25', 1, 4, 7, 9);
INSERT INTO ExamenFisico (fechaExamen, rangoVisualMinimo, rangoVisualMaximo, rangoAuditivoMinimo, rangoAuditivoMaximo) VALUES ('2023-07-24', 1, 3, 8, 9);
INSERT INTO ExamenFisico (fechaExamen, rangoVisualMinimo, rangoVisualMaximo, rangoAuditivoMinimo, rangoAuditivoMaximo) VALUES ('2023-07-23', 1, 6, 2, 9);
INSERT INTO ExamenFisico (fechaExamen, rangoVisualMinimo, rangoVisualMaximo, rangoAuditivoMinimo, rangoAuditivoMaximo) VALUES ('2023-07-22', 2, 5, 1, 2);


-- Ingreso de datos en la tabla ExamenFisico
INSERT INTO ResultadoExamen (idExamenFisico, idPaciente, fechaResultadoExamen, rangoVisual, rangoAuditivo) VALUES (1, 1, '2023-06-11 10:00:00', 100, 150);
INSERT INTO ResultadoExamen (idExamenFisico, idPaciente, fechaResultadoExamen, rangoVisual, rangoAuditivo) VALUES (2, 2, '2023-06-20 11:00:00', 50, 200);
INSERT INTO ResultadoExamen (idExamenFisico, idPaciente, fechaResultadoExamen, rangoVisual, rangoAuditivo) VALUES (3, 3, '2023-06-19 12:00:00', 150, 100);
INSERT INTO ResultadoExamen (idExamenFisico, idPaciente, fechaResultadoExamen, rangoVisual, rangoAuditivo) VALUES (4, 4, '2023-06-18 13:00:00', 200, 50);
INSERT INTO ResultadoExamen (idExamenFisico, idPaciente, fechaResultadoExamen, rangoVisual, rangoAuditivo) VALUES (5, 5, '2023-06-17 14:00:00', 100, 150);
INSERT INTO ResultadoExamen (idExamenFisico, idPaciente, fechaResultadoExamen, rangoVisual, rangoAuditivo) VALUES (6, 6, '2023-06-16 15:00:00', 50, 200);
INSERT INTO ResultadoExamen (idExamenFisico, idPaciente, fechaResultadoExamen, rangoVisual, rangoAuditivo) VALUES (7, 7, '2023-06-15 16:00:00', 150, 100);
INSERT INTO ResultadoExamen (idExamenFisico, idPaciente, fechaResultadoExamen, rangoVisual, rangoAuditivo) VALUES (8, 8, '2023-06-14 17:00:00', 200, 50);
INSERT INTO ResultadoExamen (idExamenFisico, idPaciente, fechaResultadoExamen, rangoVisual, rangoAuditivo) VALUES (9, 9, '2023-06-13 18:00:00', 100, 150);
INSERT INTO ResultadoExamen (idExamenFisico, idPaciente, fechaResultadoExamen, rangoVisual, rangoAuditivo) VALUES (10, 10, '2023-06-12 19:00:00', 50, 200);
INSERT INTO ResultadoExamen (idExamenFisico, idPaciente, fechaResultadoExamen, rangoVisual, rangoAuditivo) VALUES (11, 1, '2023-06-11 20:00:00', 150, 100);
INSERT INTO ResultadoExamen (idExamenFisico, idPaciente, fechaResultadoExamen, rangoVisual, rangoAuditivo) VALUES (12, 2, '2023-06-30 21:00:00', 200, 50);
INSERT INTO ResultadoExamen (idExamenFisico, idPaciente, fechaResultadoExamen, rangoVisual, rangoAuditivo) VALUES (13, 3, '2023-06-29 22:00:00', 100, 150);
INSERT INTO ResultadoExamen (idExamenFisico, idPaciente, fechaResultadoExamen, rangoVisual, rangoAuditivo) VALUES (14, 4, '2023-07-28 23:00:00', 50, 200);
INSERT INTO ResultadoExamen (idExamenFisico, idPaciente, fechaResultadoExamen, rangoVisual, rangoAuditivo) VALUES (15, 5, '2023-07-27 00:00:00', 150, 100);
INSERT INTO ResultadoExamen (idExamenFisico, idPaciente, fechaResultadoExamen, rangoVisual, rangoAuditivo) VALUES (16, 6, '2023-07-26 01:00:00', 200, 50);
INSERT INTO ResultadoExamen (idExamenFisico, idPaciente, fechaResultadoExamen, rangoVisual, rangoAuditivo) VALUES (17, 7, '2023-07-25 02:00:00', 100, 150);
INSERT INTO ResultadoExamen (idExamenFisico, idPaciente, fechaResultadoExamen, rangoVisual, rangoAuditivo) VALUES (18, 8, '2023-06-24 03:00:00', 50, 200);
INSERT INTO ResultadoExamen (idExamenFisico, idPaciente, fechaResultadoExamen, rangoVisual, rangoAuditivo) VALUES (19, 9, '2023-06-23 04:00:00', 150, 100);
INSERT INTO ResultadoExamen (idExamenFisico, idPaciente, fechaResultadoExamen, rangoVisual, rangoAuditivo) VALUES (20, 10, '2023-07-22 05:00:00', 200, 50);



