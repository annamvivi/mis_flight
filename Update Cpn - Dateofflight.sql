/* update tgl terbang di tkt cpn */

SELECT		DISTINCT StationOpenDate
FROM		dmsttrk
WHERE		stationopendate <> '27 Nov 2019'

UPDATE		dmtktcpn
SET			dateofflight = CONVERT(DATETIME,SUBSTRING(flightdate,1,2)+' '+RIGHT(flightdate,3)+CONVERT(VARCHAR(4),DATEPART(YEAR,b.issueddate)))
FROM		dmtktcpn a INNER JOIN dmtkt b WITH(NOLOCK)
ON			b.stkey = a.stkey AND
			b.ticketnumber = a.ticketnumber 
			INNER JOIN dmsttrk c
ON			c.stkey = b.stkey AND
			c.stkey = a.stkey
WHERE		c.stationopendate BETWEEN '24 Nov 2019' AND '26 Nov 2019' AND FlightDate <> '29FEB' AND
			a.dateofflight IS NULL 

SELECT * 
FROM		dmtktcpn a INNER JOIN dmtkt b WITH(NOLOCK)
ON			b.stkey = a.stkey AND
			b.ticketnumber = a.ticketnumber 
			INNER JOIN dmsttrk c
ON			c.stkey = b.stkey AND
			c.stkey = a.stkey
WHERE		c.stationopendate BETWEEN '24 Nov 2019' AND '26 Nov 2019' AND FlightDate = '29FEB' AND
			a.dateofflight IS NULL 

UPDATE		dmtktcpn
SET			dateofFlight = '29 Feb 2020'
FROM		dmtktcpn a INNER JOIN dmtkt b WITH(NOLOCK)
ON			b.stkey = a.stkey AND
			b.ticketnumber = a.ticketnumber 
			INNER JOIN dmsttrk c
ON			c.stkey = b.stkey AND
			c.stkey = a.stkey
WHERE		c.stationopendate BETWEEN '24 Nov 2019' AND '26 Nov 2019' AND FlightDate = '29FEB' AND
			a.dateofflight IS NULL 

UPDATE		dmtktcpn
SET			dateofflight = DATEADD(YEAR,1,dateofflight)
FROM		dmtktcpn a INNER JOIN dmtkt b with(nolock)
ON			b.stkey = a.stkey AND
			b.ticketnumber = a.ticketnumber
			INNER JOIN dmsttrk c
ON			c.StKey = b.StKey AND
			c.StKey = a.StKey
WHERE 		c.stationopendate BETWEEN '24 Nov 2019' AND '26 Nov 2019' AND
			a.dateofflight IS NOT NULL AND
			DATEADD(DAY,-20,b.issueddate) > a.dateofflight

DROP TABLE	#tmpBeda1Hari
SELECT		DISTINCT b.IssuedDate, a.* 
INTO		#tmpBeda1Hari
FROM		dmtktcpn a INNER JOIN dmtkt b with(nolock)
ON			b.StKey = a.StKey AND
			b.ticketnumber = a.ticketnumber
			INNER JOIN dmsttrk c
ON			c.StKey = b.StKey AND
			c.stkey = a.stkey
WHERE 		c.stationopendate BETWEEN '24 Nov 2019' AND '26 Nov 2019' AND
			a.dateofflight IS NOT NULL AND
			b.issueddate > a.dateofflight

SELECT		b.dateofflight, a.*
FROM		dmtkt a INNER JOIN #tmpBeda1Hari b
ON			b.TicketNumber = a.TicketNumber
WHERE		a.DocType <> 'EXB'

UPDATE		dmtktcpn
SET			dateofflight = NULL
FROM		dmtktcpn a INNER JOIN dmsttrk b
ON			b.stkey = a.stkey
WHERE 		b.stationopendate BETWEEN '24 Nov 2019' AND '26 Nov 2019' AND
			LEN(flightdate) = 0

DROP TABLE	#tmpEXB
SELECT		DISTINCT TicketNumber
INTO		#tmpEXB
FROM		dmtktcpn a INNER JOIN dmsttrk b
ON			b.stkey = a.stkey 
WHERE 		b.stationopendate BETWEEN '24 Nov 2019' AND '26 Nov 2019' AND
			LEN(flightdate) = 0 AND
			FareFromDescr <> 0
-----

SELECT		b.*
FROM		#tmpEXB a INNER JOIN dmtkt b with(nolock)
ON			b.TicketNumber = a.TicketNumber

SELECT *
FROM		dmtktcpn with(nolock)
WHERE		dateofflight IS NULL 

SELECT		*
FROM		dmtktcpn a with(nolock) INNER JOIN dmsttrk b with(nolock)
ON			b.stkey = a.stkey
WHERE		b.stationopendate BETWEEN '24 Nov 2019' AND '26 Nov 2019' AND  --- HARUS KOSONG--
			a.dateofFlight IS NULL AND
			farebasis <> 'VOID'