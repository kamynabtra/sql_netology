В задании нужно было работать с базой данны авиаперевозок

--Задание 1 Вывести названия самолетов, которые имеют менее 50 посадочных мест

select a.model, count(s.seat_no)
from seats s 
join aircrafts a on s.aircraft_code = a.aircraft_code 
group by a.aircraft_code 
having count(s.seat_no) < 50;

--Задание 2 Вывести процентное изменение ежемесячной суммы бронирования билетов, округленной до сотых

select r.booking_month, r.sum_amount, round((r.sum_amount - r.lag_month) / r.lag_month * 100, 2) "different, %"
from(
	select date_trunc('month', book_date::date) booking_month, sum(total_amount) sum_amount, 
	lag(sum(total_amount)) over (order by date_trunc('month', book_date::date)) lag_month
	from bookings b 
	group by date_trunc('month', book_date::date)) r;

--Задание 3 Вывести названия самолетов не имеющих бизнес - класс

select t.model
from(
	select a.model, array_agg(s.fare_conditions) conditions
	from seats s 
	join aircrafts a on s.aircraft_code = a.aircraft_code 
	group by a.model
) t
where not 'Business' = any(t.conditions);

--Задание 4 Найти процентное соотношение перелетов по маршрутам от общего количества перелетов

select distinct departure_airport_name, arrival_airport_name, count(flight_no) over (partition by departure_airport, arrival_airport)::numeric /
count(flight_no) over ()::numeric * 100 routes_of_flights
from flights_v fv

--Задание 5 Вывести количество пассажиров по каждому коду сотового оператора

select r."operator", count(r."operator")
from(	
	select substring(contact_data ->> 'phone', 3, 3) "operator"
	from tickets t
) r
group by r."operator"

--Задание 6 Классифицировать финансовые обороты (сумма стоимости перелетов) по маршрутам

with cte2 as (
select f.flight_no, sum(tf.amount),
case 
	when sum(tf.amount) < 50000000 then 'low'
	when sum(tf.amount) >= 150000000 then 'high'
	else 'middle'
end as range_rotes
from flights f
join ticket_flights tf on f.flight_id = tf.flight_id 
group by f.flight_no
)
select range_rotes, count(range_rotes)
from cte2
group by range_rotes

--Задание 7 Вычислить медиану стоимости перелетов, медиану размера бронирования и отношение медианы бронирования к медиане стоимости перелетов

with cte3 as (
	select	percentile_cont(0.5) within group (order by b.total_amount) median_booking
	from bookings b 
),
cte4 as (
	select percentile_cont(0.5) within group (order by tf.amount) median_flights 
	from ticket_flights tf
)
select median_flights, median_booking, round(median_booking::numeric / median_flights::numeric, 2)
from cte3, cte4

--Задание 8 Найти значение минимальной стоимости полета 1 км для пассажиров

with end_cte as (
select f.departure_airport, f.arrival_airport, f.flight_no,
(earth_distance(ll_to_earth (a.latitude, a.longitude), ll_to_earth (a2.latitude, a2.longitude))) / 1000 distance,
tf.amount, a.airport_name departure, a2.airport_name arrival
from flights f
join airports a on f.departure_airport = a.airport_code  
join airports a2 on f.arrival_airport = a2.airport_code
join ticket_flights tf on f.flight_id = tf.flight_id
)
select e.departure, e.arrival, round(e.amount / e.distance::numeric, 2) cost_km
from end_cte e
order by cost_km
limit 1