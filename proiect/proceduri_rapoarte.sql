use Teatru;
GO

CREATE PROCEDURE sp_generate_profit_report 
AS
BEGIN
    DECLARE @cost decimal(10,2) = 0,
            @revenue decimal(10,2) = 0,
            @profit decimal(10,2) = 0
    DECLARE @performance_id INT
    DECLARE @profit_results TABLE (performance_id INT, cost decimal(10,2), revenue decimal(10,2), profit decimal(10,2))

    DECLARE performance_cursor CURSOR FOR
        SELECT id FROM performances
    OPEN performance_cursor

    FETCH NEXT FROM performance_cursor INTO @performance_id

    WHILE @@FETCH_STATUS = 0
    BEGIN
        SELECT @cost = SUM(a.salariu) + h.administration_cost
        FROM performances AS p
        JOIN roles AS r ON r.id_piesa = p.id_piesa
        JOIN actors AS a ON a.id = r.id_actor
        JOIN halls AS h ON h.id = p.id_sala
        WHERE p.id = @performance_id
        GROUP BY p.id, h.administration_cost

        SELECT @revenue = SUM(tickets_count * p.price)
        FROM performances AS p
        JOIN (SELECT performance_id, COUNT(*) as tickets_count
              FROM tickets
              JOIN transactions ON tickets.transaction_id = transactions.id
              WHERE transactions.status = 'closed'
              GROUP BY performance_id
			  ) AS t
		ON t.performance_id = p.id
		WHERE p.id = @performance_id

		SET @profit = @revenue - @cost

	    INSERT INTO @profit_results(performance_id, cost, revenue, profit)
		VALUES(@performance_id, @cost, @revenue, @profit)

		FETCH NEXT FROM performance_cursor INTO @performance_id
	END

	SELECT performance_id, cost, revenue, profit FROM @profit_results

	CLOSE performance_cursor
	DEALLOCATE performance_cursor

END
GO

CREATE PROCEDURE sp_generate_actor_report
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        actors.nume, actors.prenume, COUNT(tickets.id) AS 'numarul de vizionari'
    FROM actors
    JOIN roles ON actors.id = roles.id_actor
    JOIN pieces ON roles.id_piesa = pieces.id
    JOIN performances ON pieces.id = performances.id_piesa
    JOIN tickets ON performances.id = tickets.performance_id
    JOIN transactions ON tickets.transaction_id = transactions.id
    WHERE transactions.status = 'closed'
    GROUP BY actors.nume, actors.prenume
    ORDER BY COUNT(tickets.id) DESC
END
GO

CREATE PROCEDURE sp_generate_hall_occupancy_report
AS
BEGIN
    SET NOCOUNT ON;

    SELECT 
        h.nume, 
        COUNT(tickets.id) as 'numarul de bilete vandute',
        h.capacity * (SELECT COUNT(DISTINCT performances.id) FROM performances WHERE performances.id_sala = h.id) as 'capacitatea totala',
		((100.00 * COUNT(tickets.id)) / (h.capacity * (SELECT COUNT(DISTINCT performances.id) FROM performances WHERE performances.id_sala = h.id))) as 'gradul de ocupare'
	FROM halls h
	JOIN performances ON h.id = performances.id_sala
	JOIN tickets ON performances.id = tickets.performance_id
	JOIN transactions ON tickets.transaction_id = transactions.id
	WHERE transactions.status = 'closed'
	GROUP BY h.nume, h.id, h.capacity
	ORDER BY SUM(tickets.id) DESC
END