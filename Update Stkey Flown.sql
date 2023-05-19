UPDATE		TBLFLOWN
SET			stkey = b.stkey
FROM		TBLFLOWN a
			INNER JOIN sales.dbo.tbltktcpn b with(nolock)
ON			b.TicketNumber = a.TicketNumber AND 
			b.RouteAwal = a.routefrom AND 
			b.RouteAkhir = a.routeto AND
			b.FlightNumber = convert(varchar,a.FlightNo) AND
			YEAR(b.dateofFlight) = YEAR(a.flowndate)
WHERE		a.stkey IS NULL 

UPDATE		TBLFLOWN
SET			stkey = b.stkey
FROM		TBLFLOWN a
			INNER JOIN sales.dbo.tbltktcpn b with(nolock)
ON			b.TicketNumber = a.TicketNumber AND 
			b.RouteAwal = a.routefrom AND 
			b.FlightNumber = convert(varchar,a.FlightNo) AND
			YEAR(b.dateofFlight) = YEAR(a.flowndate)
WHERE		a.stkey IS NULL 

UPDATE		TBLFLOWN
SET			stkey = b.stkey
FROM		TBLFLOWN a
			INNER JOIN sales.dbo.tbltktcpn b with(nolock)
ON			b.TicketNumber = a.TicketNumber AND 
			b.RouteAwal = a.routefrom AND 
			b.RouteAkhir = a.routeto AND
			YEAR(b.dateofFlight) = YEAR(a.flowndate)
WHERE		a.stkey IS NULL

UPDATE		TBLFLOWN
SET			stkey = b.stkey
FROM		TBLFLOWN a
			INNER JOIN sales.dbo.tbltktcpn b with(nolock)
ON			b.TicketNumber = a.TicketNumber AND 
			YEAR(b.dateofFlight) = YEAR(a.flowndate)
WHERE		a.stkey IS NULL 
	-----------------------------------------------------------------------------------------------------
UPDATE		TBLFLOWN
SET			stkey = b.stkey
FROM		TBLFLOWN a
			INNER JOIN salesOD.dbo.tbltktcpn b with(nolock)
ON			b.TicketNumber = a.TicketNumber AND 
			b.RouteAwal = a.routefrom AND 
			b.RouteAkhir = a.routeto AND
			b.FlightNumber = convert(varchar,a.FlightNo) AND
			YEAR(b.dateofFlight) = YEAR(a.flowndate)
WHERE		a.stkey IS NULL

UPDATE		TBLFLOWN
SET			stkey = b.stkey
FROM		TBLFLOWN a
			INNER JOIN salesOD.dbo.tbltktcpn b with(nolock)
ON			b.TicketNumber = a.TicketNumber AND 
			b.RouteAwal = a.routefrom AND 
			b.FlightNumber = convert(varchar,a.FlightNo) AND
			YEAR(b.dateofFlight) = YEAR(a.flowndate)
WHERE		a.stkey IS NULL

UPDATE		TBLFLOWN
SET			stkey = b.stkey
FROM		TBLFLOWN a
			INNER JOIN salesOD.dbo.tbltktcpn b with(nolock)
ON			b.TicketNumber = a.TicketNumber AND 
			b.RouteAwal = a.routefrom AND 
			b.RouteAkhir = a.routeto AND
			YEAR(b.dateofFlight) = YEAR(a.flowndate)
WHERE		a.stkey IS NULL

UPDATE		TBLFLOWN
SET			stkey = b.stkey
FROM		TBLFLOWN a
			INNER JOIN salesOD.dbo.tbltktcpn b with(nolock)
ON			b.TicketNumber = a.TicketNumber AND 
			YEAR(b.dateofFlight) = YEAR(a.flowndate)
WHERE		a.stkey IS NULL
--------------------------------------------------------------------------------------------------------------------------------------------------------------------

UPDATE		TBLFLOWN
SET			stkey = b.stkey
FROM		TBLFLOWN a
			INNER JOIN salesod.dbo.tbltktcpn b with(nolock)
ON			b.TicketNumber = a.TicketNumber AND 
			YEAR(b.dateofFlight) = YEAR(a.flowndate)
WHERE		a.stkey IS NULL

UPDATE		TBLFLOWN
SET			stkey = b.stkey
FROM		TBLFLOWN a
			INNER JOIN SALESSL.dbo.tbltktcpn b with(nolock)
ON			b.TicketNumber = a.TicketNumber AND 
			YEAR(b.dateofFlight) = YEAR(a.flowndate)
WHERE		a.stkey IS NULL

UPDATE		TBLFLOWN
SET			stkey = b.stkey
FROM		TBLFLOWN a
			INNER JOIN salesiw.dbo.tbltktcpn b with(nolock)
ON			b.TicketNumber = a.TicketNumber AND 
			YEAR(b.dateofFlight) = YEAR(a.flowndate)
WHERE		a.stkey IS NULL
------------------------------------------------------------------------------------------------------------------------------
update tblflown
set stkey = b.stkey
FROM		TBLFLOWN a, salesod.dbo.tbltkt b with(nolock)
WHERE		b.ticketnumber = a.ticketnumber AND
			a.insertdate > '27 Nov 2019' AND 
			a.stkey IS NULL		

update tblflown
set stkey = b.stkey
FROM		TBLFLOWN a, salesid.dbo.tbltkt b with(nolock)
WHERE		b.ticketnumber = a.ticketnumber AND
			a.insertdate > '27 Nov 2019' AND 
			a.stkey IS NULL		

update tblflown
set stkey = b.stkey
FROM		TBLFLOWN a, salesiw.dbo.tbltkt b with(nolock)
WHERE		b.ticketnumber = a.ticketnumber AND
			a.insertdate > '27 Nov 2019' AND 
			a.stkey IS NULL		
			
update tblflown
set stkey = b.stkey
FROM		TBLFLOWN a, sales.dbo.dmtkt b with(nolock)
WHERE		b.ticketnumber = a.ticketnumber AND
			a.insertdate > '27 Nov 2019' AND 
			a.stkey IS NULL	
			
SELECT		*
FROM		TBLFLOWN WITH(NOLOCK)
WHERE		insertdate > '27 Nov 2019' AND 
			stkey IS NULL


