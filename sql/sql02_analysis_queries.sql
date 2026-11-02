USE Flight;


GO
--Q1 Find the busiest airport by the number of flights take off
--output: airport, total_number_of_flights
--tables: airport, flights
--method: INNER JOIN(airport), Count(origin), GROUP BY(Airport)
SELECT   TOP 1 a.Name AS airport_name,
               COUNT(*) AS total_number_of_flights
FROM     Flights AS f
         INNER JOIN
         Airports AS a
         ON f.Origin = a.AirportID
GROUP BY a.Name
ORDER BY COUNT(*) DESC;

--Q2 Total number of tickets sold per airline
--output: airline, total_number_of_tickets
--tables: tickets, flights,airline
--method: count(*), GROUP BY(airline)
SELECT   TOP 10 a.Name,
                COUNT(*) AS total_number_of_tickets
FROM     Tickets AS t
         INNER JOIN
         Flights AS f
         ON t.FlightID = f.FlightID
         INNER JOIN
         Airlines AS a
         ON f.AirlineID = a.AirlineID
GROUP BY a.Name;

--Q3 List all flights operated by �IndiGo� with airport names (origin and destination)
--output: all flights, airport_name, origin, destination
--tables: flights, airline, airport
--method: WHERE(airline_name Like Indi)
SELECT f.FlightID,
       a.Name,
       ap.Name AS origin,
       ap1.Name AS destination
FROM   Flights AS f
       INNER JOIN
       Airlines AS A
       ON f.AirlineID = A.AirlineID
       INNER JOIN
       Airports AS ap
       ON f.Origin = ap.AirportID
       INNER JOIN
       Airports AS ap1
       ON f.Destination = ap1.AirportID
WHERE  a.Name = 'Indigo';

--Q4 For each airport, show the top airline by number of flights departing from there
--output: airport_name, airline_name, total_number_flights
--tables: Flights, Airport, Airline
WITH     cte_rank_airline
AS       (SELECT   ap.Name AS airpoty_name,
                   a.Name AS airline_name,
                   COUNT(*) AS total_flights_airline,
                   RANK() OVER (PARTITION BY ap.Name ORDER BY COUNT(*) DESC) AS rank
          FROM     Flights AS f
                   INNER JOIN
                   Airlines AS a
                   ON f.AirlineID = a.AirlineID
                   INNER JOIN
                   Airports AS ap
                   ON f.Origin = ap.AirportID
          GROUP BY a.Name, ap.Name)
SELECT   airpoty_name,
         airline_name,
         total_flights_airline
FROM     cte_rank_airline
WHERE    [rank] = 1
ORDER BY total_flights_airline DESC;

--Q5 For each flight, show time taken in hours and categorize it as Short (<2h), Medium (2�5h), or Long (>5h)
--output: flight_id, time_in_hour, hours_category
--tables: flights
--method: CTE[get the duration in hour]
SELECT FlightID,
       DepartureTime,
       ArrivalTime,
       time_taken,
       CASE WHEN time_taken < 2 THEN 'Short' WHEN time_taken BETWEEN 2 AND 5 THEN 'Medium' ELSE 'Long' END AS time_category
FROM   (SELECT FlightID,
               DepartureTime,
               ArrivalTime,
               DATEDIFF(HOUR, DepartureTime, ArrivalTime) AS time_taken
        FROM   Flights) AS t;

--Q6 Show each passenger's first and last flight dates and number of flights
--output: passenger_name, First_flight_date, last_flight_date, number_of flights
--tables: passenger, flights, tickets
--method: COUNT(flights), GROUP BY(passenger_name), MIN(first_flight), MAX(last_flight)
SELECT   p.Name,
         MIN(f.DepartureTime) AS first_flight,
         MAX(f.DepartureTime) AS last_flight,
         COUNT(*) AS total_num_of_flights
FROM     Flights AS f
         INNER JOIN
         Tickets AS t
         ON f.FlightID = t.FlightID
         INNER JOIN
         Passengers AS p
         ON t.PassengerID = p.PassengerID
GROUP BY p.Name;

--Q7 Find flights with the highest price ticket sold for each route (origin -> destination)
--output: origin, destination, highest_price, ticket_id
--tables: flight, tickets
--method: find highest price ticket in Ticket_table and Partition By flight_id
WITH   cte_high_ticket_price
AS     (SELECT t.TicketID,
               f.FlightID,
               t.Price,
               RANK() OVER (PARTITION BY f.Origin, f.Destination ORDER BY t.price DESC) AS highest_ticket_price
        FROM   Flights AS f
               INNER JOIN
               Tickets AS t
               ON t.FlightID = f.FlightID)
SELECT c.FlightID,
       a.Name,
       a2.Name,
       c.Price,
       c.TicketID
FROM   cte_high_ticket_price AS c
       INNER JOIN
       Flights AS f
       ON f.FlightID = c.FlightID
       INNER JOIN
       Airports AS a
       ON a.AirportID = f.Origin
       INNER JOIN
       Airports AS a2
       ON a2.AirportID = f.Destination
WHERE  highest_ticket_price = 1;

--Q8 Find the highest spending passenger in each Frequent Flyer Status group
--output: passenger, flyer_group, total_spending
--tables: passengers, tickets
WITH   cte_total_spending
AS     (SELECT   p.PassengerID,
                 p.Name,
                 SUM(t.Price) AS total_spending
        FROM     Passengers AS p
                 INNER JOIN
                 Tickets AS t
                 ON t.PassengerID = p.PassengerID
        GROUP BY p.PassengerID, p.Name),
       cte_rank_status
AS     (SELECT c.Name,
               p.FrequentFlyerStatus,
               c.total_spending,
               RANK() OVER (PARTITION BY p.FrequentFlyerStatus ORDER BY c.total_spending DESC) AS rank_of_total_spending_status
        FROM   cte_total_spending AS c
               INNER JOIN
               Passengers AS p
               ON p.PassengerID = c.PassengerID)
SELECT Name,
       FrequentFlyerStatus,
       total_spending
FROM   cte_rank_status
WHERE  rank_of_total_spending_status = 1;

--Q9 Find the total revenue and number of tickets sold for each airline, and rank the airlines based on total revenue
--output: airline_name, total_revenue, num_of_tickets
--tables: airlines, tickets, flights
WITH   cte_numbers
AS     (SELECT   a.Name,
                 SUM(t.Price) AS total_revenue,
                 COUNT(*) AS num_of_tickets
        FROM     Airlines AS a
                 INNER JOIN
                 Flights AS f
                 ON f.AirlineID = a.AirlineID
                 INNER JOIN
                 Tickets AS t
                 ON t.FlightID = f.FlightID
        GROUP BY a.Name)
SELECT Name,
       total_revenue,
       num_of_tickets,
       RANK() OVER (ORDER BY total_revenue DESC) AS rank
FROM   cte_numbers;

--Q10. For each passenger, identify their most frequently used airline. If a passenger has multiple airlines
--     with the same highest usage, show all such airlines.
--output: passenger_name, most_frequently_used_airline,
--tables: flights, airline, passengers, tickets
WITH   cte_num_of_flights
AS     (SELECT   p.PassengerID,
                 p.Name AS passenger_name,
                 a.AirlineID,
                 a.Name AS airline_name,
                 COUNT(*) AS number_of_flights
        FROM     Passengers AS p
                 INNER JOIN
                 Tickets AS t
                 ON t.PassengerID = p.PassengerID
                 INNER JOIN
                 Flights AS f
                 ON t.FlightID = f.FlightID
                 INNER JOIN
                 Airlines AS a
                 ON f.AirlineID = a.AirlineID
        GROUP BY p.PassengerID, p.Name, a.AirlineID, a.Name),
       cte_airline_rank
AS     (SELECT PassengerID,
               passenger_name,
               airline_name,
               number_of_flights,
               RANK() OVER (PARTITION BY PassengerID ORDER BY number_of_flights DESC) AS airline_rank
        FROM   cte_num_of_flights)
SELECT PassengerID,
       passenger_name,
       airline_name,
       number_of_flights
FROM   cte_airline_rank
WHERE  airline_rank = 1;