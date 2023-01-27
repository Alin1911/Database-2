USE master;
GO

IF EXISTS(SELECT name FROM sys.databases WHERE name = N'Teatru')
    BEGIN
        ALTER DATABASE Teatru SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
        DROP DATABASE Teatru;
    END
GO

CREATE DATABASE Teatru
GO

USE Teatru;
GO

CREATE TABLE clients
(
    id INT IDENTITY(1,1) PRIMARY KEY,
    nume VARCHAR(50) NOT NULL,
    prenume VARCHAR(50) NOT NULL,
    email VARCHAR(255) NOT NULL UNIQUE,
    password VARCHAR(255) NOT NULL,
    created_at DATETIME DEFAULT GETDATE(),
    updated_at DATETIME DEFAULT GETDATE()
);

CREATE TABLE transactions
(
    id INT IDENTITY(1,1) PRIMARY KEY,
    total_price DECIMAL(18, 2) DEFAULT 0,
    status VARCHAR(50) NOT NULL,
    client_id INT NOT NULL,
    created_at DATETIME DEFAULT GETDATE(),
    updated_at DATETIME DEFAULT GETDATE()
);

CREATE TABLE actors
(
    id INT IDENTITY(1,1) PRIMARY KEY,
    nume VARCHAR(50) NOT NULL,
    prenume VARCHAR(50) NOT NULL,
    data_nastere DATE NOT NULL,
    salariu DECIMAL(10,2) NOT NULL,
    created_at DATETIME DEFAULT GETDATE(),
    updated_at DATETIME DEFAULT GETDATE()
);

CREATE TABLE pieces
(
    id INT IDENTITY(1,1) PRIMARY KEY,
    titlu VARCHAR(50) NOT NULL UNIQUE,
    autor VARCHAR(50) NOT NULL,
    descriere VARCHAR(255) NOT NULL,
    created_at DATETIME DEFAULT GETDATE(),
    updated_at DATETIME DEFAULT GETDATE()
);

CREATE TABLE roles
(
    id INT IDENTITY(1,1) PRIMARY KEY,
    titlu_rol VARCHAR(50) NOT NULL,
    id_piesa INT NOT NULL,
    id_actor INT NOT NULL,
    created_at DATETIME DEFAULT GETDATE(),
    updated_at DATETIME DEFAULT GETDATE()
);

CREATE TABLE halls
(
    id INT IDENTITY(1,1) PRIMARY KEY,
    nume VARCHAR(50) NOT NULL UNIQUE,
    capacity INT  DEFAULT 0,
    administration_cost DECIMAL(10, 2) NOT NULL,
    created_at DATETIME DEFAULT GETDATE(),
    updated_at DATETIME DEFAULT GETDATE()
);

CREATE TABLE performances (
    id INT IDENTITY(1,1) PRIMARY KEY,
    id_piesa INT NOT NULL,
    start_date DATETIME NOT NULL,
    end_date DATETIME NOT NULL,
    id_sala INT NOT NULL,
    price DECIMAL(10, 2) NOT NULL,
    ticket_max_scan INT NOT NULL,
    created_at DATETIME DEFAULT GETDATE(),
    updated_at DATETIME DEFAULT GETDATE()
);

CREATE TABLE tickets (
    id INT IDENTITY(1,1) PRIMARY KEY,
    performance_id INT NOT NULL,
    client_id INT NOT NULL,
    numar_scanari INT DEFAULT 0,
    transaction_id INT NOT NULL,
    code VARCHAR(16) DEFAULT CONVERT(VARCHAR(16), CONVERT(VARBINARY(16), NEWID()), 2),
    created_at DATETIME DEFAULT GETDATE(),
    updated_at DATETIME DEFAULT GETDATE()
);
GO


CREATE TRIGGER update_transactions_updated_at
ON transactions
AFTER UPDATE
AS
BEGIN
    UPDATE transactions
    SET updated_at = GETDATE()
    FROM inserted
    WHERE transactions.id = inserted.id;
END
GO

CREATE TRIGGER update_actors_updated_at
ON actors
AFTER UPDATE
AS
BEGIN
    UPDATE actors
    SET updated_at = GETDATE()
    FROM inserted
    WHERE actors.id = inserted.id;
END
GO


CREATE TRIGGER update_pieces_updated_at
ON pieces
AFTER UPDATE
AS
BEGIN
    UPDATE pieces
    SET updated_at = GETDATE()
    FROM inserted
    WHERE pieces.id = inserted.id;
END
GO

CREATE TRIGGER update_roles_updated_at
ON roles
AFTER UPDATE
AS
BEGIN
    UPDATE roles
    SET updated_at = GETDATE()
    FROM inserted
    WHERE roles.id = inserted.id;
END
GO

CREATE TRIGGER update_performances_updated_at
ON performances
AFTER UPDATE
AS
BEGIN
    UPDATE performances
    SET updated_at = GETDATE()
    FROM inserted
    WHERE performances.id = inserted.id;
END
GO

CREATE TRIGGER update_halls_updated_at
ON halls
AFTER UPDATE
AS
BEGIN
    UPDATE halls
    SET updated_at = GETDATE()
    FROM inserted
    WHERE halls.id = inserted.id;
END
GO

CREATE TRIGGER update_tickets_updated_at
ON tickets
AFTER UPDATE
AS
BEGIN
    UPDATE tickets
    SET updated_at = GETDATE()
    FROM inserted
    WHERE tickets.id = inserted.id;
END
GO

CREATE TRIGGER check_ticket_availability
ON tickets
AFTER INSERT
AS
BEGIN
    DECLARE @performance_id INT, @ticket_count INT, @hall_capacity INT;
    SET @performance_id = (SELECT top(1) performance_id FROM inserted);
    SET @ticket_count = (SELECT COUNT(*) FROM tickets WHERE performance_id = @performance_id);
    SET @hall_capacity = (SELECT capacity FROM halls h join performances p on p.id_sala = h.id WHERE p.id = @performance_id);
    IF (@ticket_count > @hall_capacity)
    BEGIN
        RAISERROR ('Sala este plina, nu mai sunt bilete disponibile.', 16, 1);
        ROLLBACK TRANSACTION;
    END;
END;
GO

CREATE TRIGGER update_clients_updated_at
ON clients
AFTER UPDATE
AS
BEGIN
    UPDATE clients
    SET updated_at = GETDATE()
    FROM inserted
    WHERE clients.id = inserted.id;
END
GO

CREATE TRIGGER update_transaction_total_price
ON tickets
AFTER INSERT
AS
BEGIN
    DECLARE @performance_id INT;
    DECLARE @price DECIMAL(10, 2);
    DECLARE @transaction_id INT;
    DECLARE @status VARCHAR(50);

    SELECT @performance_id = performance_id, @transaction_id = transaction_id
    FROM inserted;

    SELECT @price = price, @status = status
    FROM performances JOIN transactions
    ON performances.id = @performance_id AND transactions.id = @transaction_id;

    IF @status = 'open'
    BEGIN
        UPDATE transactions
        SET total_price = total_price + @price
        WHERE id = @transaction_id;
    END
    ELSE
    BEGIN
        RAISERROR ('Ticket cannot be added because the transaction is not open', 16, 1);
        ROLLBACK TRANSACTION;
    END
END
GO

INSERT INTO clients (nume, prenume, email, password)
VALUES ('Ion', 'Popescu', 'ion.popescu@example.com', 'password123'),
('Maria', 'Ionescu', 'maria.ionescu@example.com', 'password456'),
('Ana', 'Marin', 'ana.marin@example.com', 'password789'),
('George', 'Doe', 'george.doe@example.com', 'password111'),
('John', 'Smith', 'john.smith@example.com', 'password222'),
('Mihai', 'Ionescu', 'mihai.ionescu@example.com', 'password333'),
('Livia', 'Popa', 'livia.popa@example.com', 'password444'),
('Adrian', 'Nastase', 'adrian.nastase@example.com', 'password555'),
('Marius', 'Pop', 'marius.pop@example.com', 'password666'),
('Gabriel', 'Ene', 'gabriel.ene@example.com', 'password777'),
('Ioana', 'Marin', 'ioana.marin@example.com', 'password888'),
('Andreea', 'Ionescu', 'andreea.ionescu@example.com', 'password000'),
('Raul', 'Popa', 'raul.popa@example.com', 'password123'),
('Catalin', 'Marin', 'catalin.marin@example.com', 'password456'),
('Claudia', 'Popescu', 'claudia.popescu@example.com', 'password789'),
('Vasile', 'Ionescu', 'vasile.ionescu@example.com', 'password111'),
('Diana', 'Pop', 'diana.pop@example.com', 'password222'),
('Cristian', 'Marin', 'cristian.marin@example.com', 'password333'),
('Emanuel', 'Popescu', 'emanuel.popescu@example.com', 'password444'),
('Alexandra', 'Ionescu', 'alexandra.ionescu@example.com', 'password555'),
('Bogdan', 'Popa', 'bogdan.popa@example.com', 'password666'),
('Cornel', 'Marin', 'cornel.marin@example.com', 'password777'),
('Ciprian', 'Ionescu', 'ciprian.ionescu@example.com', 'password999'),
('Bianca', 'Pop', 'bianca.pop@example.com', 'password000'),
('Vasile', 'Pop', 'vasile.pop@example.com', 'password111'),
('Ioana', 'Popa', 'ioana.popa@example.com', 'password222'),
('Mihai', 'Marin', 'mihai.marin@example.com', 'password333'),
('Raluca', 'Popescu', 'raluca.popescu@example.com', 'password444'),
('Adrian', 'Ionescu', 'adrian.ionescu@example.com', 'password555'),
('Gabriela', 'Popa', 'gabriela.popa@example.com', 'password666'),
('Andrei', 'Marin', 'andrei.marin@example.com', 'password777'),
('Elena', 'Popescu', 'elena.popescu@example.com', 'password888'),
('Alin', 'Ionescu', 'alin.ionescu@example.com', 'password999'),
('Andreea', 'Pop', 'andreea.pop@example.com', 'password000'),
('Bogdan', 'Marin', 'bogdan.marin@example.com', 'password123'),
('Carmen', 'Popescu', 'carmen.popescu@example.com', 'password456'),
('Catalin', 'Ionescu', 'catalin.ionescu@example.com', 'password789'),
('Claudia', 'Pop', 'claudia.pop@example.com', 'password111'),
('Costin', 'Marin', 'costin.marin@example.com', 'password222'),
('Cristian', 'Popescu', 'cristian.popescu@example.com', 'password333'),
('Diana', 'Ionescu', 'diana.ionescu@example.com', 'password444'),
('Eduard', 'Popa', 'eduard.popa@example.com', 'password555'),
('Emilian', 'Marin', 'emilian.marin@example.com', 'password666'),
('Eugen', 'Popescu', 'eugen.popescu@example.com', 'password777'),
('Flavia', 'Ionescu', 'flavia.ionescu@example.com', 'password888'),
('Gabriel', 'Pop', 'gabriel.pop@example.com', 'password999');
GO

INSERT INTO actors (nume, prenume, data_nastere, salariu)
VALUES 
('Tom', 'Hanks', '1956-07-09', 10000.00),
('Leonardo', 'DiCaprio', '1974-11-11', 11000.00),
('Robert', 'De Niro', '1943-08-17', 12000.00),
('Al', 'Pacino', '1940-04-25', 11000.00),
('Denzel', 'Washington', '1954-12-28', 12000.00),
('Meryl', 'Streep', '1949-06-22', 11000.00),
('Brad', 'Pitt', '1963-12-18', 10000.00),
('Saoirse', 'Ronan', '1994-04-12', 12000.00),
('Cate', 'Blanchett', '1969-05-14', 14000.00),
('Kate', 'Winslet', '1975-10-05', 13000.00),
('Jennifer', 'Lawrence', '1990-08-15', 16000.00),
('Charlize', 'Theron', '1975-08-07', 15000.00),
('Natalie', 'Portman', '1981-06-09', 18000.00),
('Brie', 'Larson', '1989-10-01', 10000.00),
('Scarlett', 'Johansson', '1984-11-22', 14000.00),
('Amy', 'Adams', '1974-08-20', 15000.00),
('Gal', 'Gadot', '1985-04-30', 18000.00),
('Emma', 'Stone', '1988-11-06', 19000.00),
('Anne', 'Hathaway', '1982-11-12', 20000.00),
('Johnny', 'Depp', '1963-06-09', 16000.00),
('Will', 'Smith', '1968-09-25', 17000.00),
('Adam', 'Sandler', '1966-09-09', 12000.00),
('Angelina', 'Jolie', '1975-06-04', 19000.00),
('Sylvester', 'Stallone', '1946-07-06', 18000.00);

GO

DECLARE @counter INT = 1;

WHILE @counter <= 10
BEGIN
    DECLARE @Capacity INT = 200 + @counter * 5;
    INSERT INTO halls (nume, capacity, administration_cost)
    VALUES ('Sala ' + CAST(@counter AS VARCHAR(10)), @Capacity, @Capacity * (20 + @counter));
    SET @counter = @counter + 1;
END;
GO
INSERT INTO pieces (titlu, autor, descriere) VALUES
('Hamlet', 'William Shakespeare','Piesa de teatru Hamlet este o capodoperă literară despre prințul din Danemarca care se confruntă cu dileme morale.'),
('Moartea unui comis-voiajor', 'Arthur Miller', 'Piesa Moartea unui comis-voiajor este o poveste tragică despre Willy Loman care încearcă să-și găsească locul în lume.'),
('Dorința pe strada Elizei', 'Tennessee Williams','Piesa Dorința pe strada Elizei este o dramă despre viața lui Blanche Dubois care se mută în cartierul New Orleans.'),
('Colectia de obiecte din sticlă', 'Tennessee Williams','Piesa Colectia de obiecte din sticlă este o dramă despre familia Wingfield care încearcă să-și găsească fericirea.'),
('Romeo și Julieta', 'William Shakespeare', 'Piesa Romeo și Julieta este o poveste tragică despre dragoste dintre doi tineri din familii rivalizante.'),
('Macbeth', 'William Shakespeare', 'Piesa Macbeth este o poveste despre un general scoțian care este determinat să devină rege.'),
('Othello', 'William Shakespeare', 'Piesa Othello este o poveste despre un general maur care este înșelat de unul dintre ofițerii săi.'),
('Regele Lear', 'William Shakespeare', 'Piesa Regele Lear este despre un rege în vârstă care își împarte regatul între fiicele sale.'),
('Topitorul de vrăjitoare', 'Arthur Miller', 'Piesa Topitorul de vrăjitoare este despre procesul pentru vrăjitorie din Salem.'),
('Casa de pe Strada Mîntuirii', 'Ion Luca Caragiale', 'Piesa Casa de pe Strada Mîntuirii este o comedie despre o familie de oameni de afaceri care încearcă să se ridice social.');
GO

DECLARE @counter INT = 1;
DECLARE @idPiesa INT = 1;
DECLARE @idActor INT = 1;

WHILE @counter <= 50
BEGIN
    DECLARE @titluRol VARCHAR(50);
    SET @titluRol = 'Rol ' + CAST(@counter AS VARCHAR(10));

    INSERT INTO roles (titlu_rol, id_piesa, id_actor)
    VALUES (@titluRol, @idPiesa, @idActor);

    SET @counter = @counter + 1;
    SET @idPiesa = @idPiesa + 1;
    SET @idActor = @idActor + 1;

    IF (@idPiesa > 10)
        SET @idPiesa = 1;

    IF (@idActor > 20)
        SET @idActor = 1;
END;
GO

INSERT INTO performances (id_piesa, start_date, end_date, id_sala, price, ticket_max_scan)
VALUES (1, '2022-11-01 09:00:00', '2022-11-01 12:00:00', 1, 500, 1),
(2, '2022-11-15 19:00:00', '2022-11-15 22:00:00', 2, 700, 1),
(3, '2022-11-28 20:00:00', '2022-11-28 23:00:00', 3, 1000, 2),
(4, '2022-12-01 19:00:00', '2022-12-01 22:00:00', 4, 500, 1),
(5, '2022-12-15 19:00:00', '2022-12-15 22:00:00', 5, 700, 1),
(6, '2022-12-28 20:00:00', '2022-12-28 23:00:00', 6, 1000, 2),
(7, '2023-01-01 19:00:00', '2023-01-01 22:00:00', 7, 600, 1),
(8, '2023-01-10 19:00:00', '2023-01-10 22:00:00', 8, 800, 1),
(9, '2023-01-20 19:00:00', '2023-01-20 22:00:00', 9, 1100, 2),
(10, '2023-02-01 19:00:00', '2023-02-01 22:00:00', 1, 500, 1),
(1, '2023-02-15 14:00:00', '2023-02-15 17:00:00', 2, 700, 1),
(2, '2023-02-28 18:00:00', '2023-03-05 21:00:00', 3, 1000, 2),
(3, '2023-03-01 20:00:00', '2023-03-01 23:00:00', 4, 500, 1),
(4, '2023-03-15 19:00:00', '2023-03-15 22:00:00', 5, 700, 1),
(5, '2023-03-28 20:00:00', '2023-03-28 23:00:00', 6, 1000, 2),
(6, '2023-04-01 18:00:00', '2023-04-01 21:00:00', 7, 500, 1),
(7, '2023-04-15 19:00:00', '2023-04-15 22:00:00', 8, 700, 1),
(8, '2023-04-28 20:00:00', '2023-05-05 23:00:00', 9, 1000, 2),
(9, '2023-05-01 14:00:00', '2023-05-01 17:00:00', 10, 500, 1),
(10, '2023-05-15 18:00:00', '2023-05-15 21:00:00', 1, 700, 1);

INSERT INTO transactions (status, client_id)
VALUES ('closed', 1),
('closed', 2),
('reserved', 3),
('reserved', 4),
('open', 5),
('open', 6),
('closed', 7),
('reserved', 8),
('open', 9),
('closed', 10);

GO
CREATE PROCEDURE generate_tickets
@performance_id INT,
@client_id INT
AS
BEGIN
    DECLARE @hall_id INT;
    DECLARE @hall_capacity INT;
    DECLARE @transaction_id INT;

    SELECT @hall_id = id_sala FROM performances WHERE id = @performance_id;
    SELECT @hall_capacity = capacity FROM halls WHERE id = @hall_id;

    DECLARE clients_cursor CURSOR FOR
    SELECT id FROM clients;
    OPEN clients_cursor;

    INSERT INTO transactions (status, client_id) VALUES ('open', @client_id);
    SET @transaction_id = SCOPE_IDENTITY();

    DECLARE @i INT = 1;
    WHILE @i <= @hall_capacity / 2
    BEGIN
       INSERT INTO tickets (performance_id, transaction_id, client_id) VALUES (@performance_id, @transaction_id, @client_id);
        SET @i = @i + 1;
    END;

    UPDATE transactions
    SET status = 'closed'
    WHERE id = @transaction_id;


    CLOSE clients_cursor;
    DEALLOCATE clients_cursor;
END;
GO

DECLARE @client_id INT
DECLARE client_c CURSOR FOR
SELECT id FROM clients;

OPEN client_c
FETCH NEXT FROM client_c INTO @client_id
WHILE @@FETCH_STATUS = 0
BEGIN
	EXEC generate_tickets @performance_id = @client_id, @client_id = @client_id;
	FETCH NEXT FROM client_c INTO @client_id;
END
DEALLOCATE client_c;
GO
