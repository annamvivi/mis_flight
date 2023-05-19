DROP TABLE	#tmp2
SELECT		a.StationOpenDate,b.TransCode, b.DocType, b.PNRR,b.TicketNumber, c.FC, c.RouteAwal, c.routeakhir, Class, DepTime, ArrTime, baggage
INTO		#tmp2 
FROM		tblsttrk a with(nolock)
			INNER JOIN tbltkt b with(nolock)
ON			b.StKey = a.StKey
			INNER JOIN tbltktcpn c with(nolock)
ON			c.StKey = b.StKey AND 
			c.StKey = a.StKey AND
			c.TicketNumber = b.TicketNumber
WHERE		a.stationopendate BETWEEN '24 Nov 2019' AND '26 Nov 2019'

---------------------------------------------------------------------------------------------------------------

UPDATE		#tmp2 
SET			class = b.Class,deptime = b.DepTime , arrtime = b.ArrTime , baggage = replace(b.baggage,'K','')
FROM		#tmp2 a 
			INNER JOIN tblTCN b
ON			b.TicketNumber = a.TicketNumber AND
			RTRIM(b.pnrr) = RTRIM(a.PNRR) 
WHERE		a.FC = 1 AND 
			a.TransCode IN ('SALE','EXCH') AND 
			a.DocType IN ('TKT','CNJ') AND
			b.TransCode LIKE 'TKT%' AND b.baggage <> 'NIL'

UPDATE		#tmp2 
SET			class = b.Class2 ,deptime = b.DepTime2 , arrtime = b.ArrTime2  , baggage = replace(b.baggage2,'K','')
FROM		#tmp2 a
			INNER JOIN tblTCN b
ON			b.TicketNumber = a.TicketNumber AND
			RTRIM(b.pnrr) = RTRIM(a.PNRR) 
WHERE		a.FC = 2 AND 
			a.TransCode IN ('SALE','EXCH') AND 
			a.DocType IN ('TKT','CNJ') AND
			b.TransCode LIKE 'TKT%' AND b.baggage2 <> 'NIL'

UPDATE		#tmp2 
SET			class = b.Class3,deptime = b.DepTime3 , arrtime = b.ArrTime3  , baggage = replace(b.baggage3,'K','')
FROM		#tmp2 a
			INNER JOIN tblTCN b
ON			b.TicketNumber = a.TicketNumber AND
			RTRIM(b.pnrr) = RTRIM(a.PNRR) 
WHERE		a.FC = 3 AND 
			a.TransCode IN ('SALE','EXCH') AND 
			a.DocType IN ('TKT','CNJ') AND
			b.TransCode LIKE 'TKT%' AND b.baggage3 <> 'NIL'

UPDATE		#tmp2 
SET			class = b.Class4 ,deptime = b.DepTime4 , arrtime = b.ArrTime4  , baggage = replace(b.baggage4,'K','')
FROM		#tmp2 a
			INNER JOIN tblTCN b
ON			b.TicketNumber = a.TicketNumber AND
			RTRIM(b.pnrr) = RTRIM(a.PNRR) 
WHERE		a.FC = 4 AND 
			a.TransCode IN ('SALE','EXCH') AND 
			a.DocType IN ('TKT','CNJ') AND
			b.TransCode LIKE 'TKT%' AND b.baggage4 <> 'NIL'
---------------------------------------------------------------------------------------------------------------

UPDATE		#tmp2 
SET			class = b.Class ,deptime = b.DepTime , arrtime = b.ArrTime  , baggage = replace(b.baggage,'K','')
FROM		#tmp2 a
			INNER JOIN tblTCN b
ON			b.TicketNumber = a.TicketNumber 
WHERE		a.stationopendate BETWEEN DATEADD(day,-31,b.insertdate) AND  DATEADD(day,31,b.insertdate)  AND
			a.FC = 1 AND 
			a.TransCode IN ('SALE','EXCH') AND 
			a.DocType IN ('TKT','CNJ') AND
			b.TransCode LIKE 'TKT%' AND
			a.DepTime IS NULL  AND b.baggage <> 'NIL'

UPDATE		#tmp2
SET			class = b.Class2 ,deptime = b.DepTime2 , arrtime = b.ArrTime2  , baggage = replace(b.baggage2,'K','')
FROM		#tmp2 a
			INNER JOIN tblTCN b
ON			b.TicketNumber = a.TicketNumber 
WHERE		a.stationopendate BETWEEN DATEADD(day,-31,b.insertdate) AND  DATEADD(day,31,b.insertdate)  AND
			a.FC = 2 AND 
			a.TransCode IN ('SALE','EXCH') AND 
			a.DocType IN ('TKT','CNJ') AND
			b.TransCode LIKE 'TKT%' AND
			a.DepTime IS NULL  AND b.baggage2 <> 'NIL'

UPDATE		#tmp2
SET			class = b.Class3,deptime = b.DepTime3 , arrtime = b.ArrTime3  , baggage = replace(b.baggage3,'K','')
FROM		#tmp2 a
			INNER JOIN tblTCN b
ON			b.TicketNumber = a.TicketNumber 
WHERE		a.stationopendate BETWEEN DATEADD(day,-31,b.insertdate) AND  DATEADD(day,31,b.insertdate)  AND
			a.FC = 3 AND 
			a.TransCode IN ('SALE','EXCH') AND 
			a.DocType IN ('TKT','CNJ') AND
			b.TransCode LIKE 'TKT%' AND
			a.DepTime IS NULL AND b.baggage3 <> 'NIL'
			
UPDATE		#tmp2
SET			class = b.Class4,deptime = b.DepTime4 , arrtime = b.ArrTime4 , baggage = replace(b.baggage4,'K','')
FROM		#tmp2 a
			INNER JOIN tblTCN b
ON			b.TicketNumber = a.TicketNumber 
WHERE		a.stationopendate BETWEEN DATEADD(day,-31,b.insertdate) AND  DATEADD(day,31,b.insertdate)  AND
			a.FC = 4 AND 
			a.TransCode IN ('SALE','EXCH') AND 
			a.DocType IN ('TKT','CNJ') AND
			b.TransCode LIKE 'TKT%' AND
			a.DepTime IS NULL  AND b.baggage4 <> 'NIL'



UPDATE		#tmp2 
SET			class = b.Class ,deptime = b.DepTime , arrtime = b.ArrTime  , baggage = replace(b.baggage,'K','')
FROM		#tmp2 a
			INNER JOIN tblTCN b
ON			b.TicketNumber = a.TicketNumber 
WHERE		a.stationopendate BETWEEN DATEADD(day,-31,b.insertdate) AND  DATEADD(day,31,b.insertdate)  AND
			a.FC = 1 AND 
			a.TransCode IN ('SALE','EXCH') AND 
			a.DocType IN ('TKT','CNJ') AND
			b.TransCode LIKE 'TKT%' AND
			a.baggage IS NULL AND b.baggage <> 'NIL'

UPDATE		#tmp2
SET			class = b.Class2 ,deptime = b.DepTime2 , arrtime = b.ArrTime2  , baggage = replace(b.baggage2,'K','')
FROM		#tmp2 a
			INNER JOIN tblTCN b
ON			b.TicketNumber = a.TicketNumber 
WHERE		a.stationopendate BETWEEN DATEADD(day,-31,b.insertdate) AND  DATEADD(day,31,b.insertdate)  AND
			a.FC = 2 AND 
			a.TransCode IN ('SALE','EXCH') AND 
			a.DocType IN ('TKT','CNJ') AND
			b.TransCode LIKE 'TKT%' AND
			a.baggage IS NULL AND b.baggage2 <> 'NIL'

UPDATE		#tmp2
SET			class = b.Class3,deptime = b.DepTime3 , arrtime = b.ArrTime3  , baggage = replace(b.baggage3,'K','')
FROM		#tmp2 a
			INNER JOIN tblTCN b
ON			b.TicketNumber = a.TicketNumber 
WHERE		a.stationopendate BETWEEN DATEADD(day,-31,b.insertdate) AND  DATEADD(day,31,b.insertdate)  AND
			a.FC = 3 AND 
			a.TransCode IN ('SALE','EXCH') AND 
			a.DocType IN ('TKT','CNJ') AND
			b.TransCode LIKE 'TKT%' AND
			a.baggage IS NULL AND b.baggage3 <> 'NIL'
			
UPDATE		#tmp2
SET			class = b.Class4,deptime = b.DepTime4 , arrtime = b.ArrTime4 , baggage = replace(b.baggage4,'K','')
FROM		#tmp2 a
			INNER JOIN tblTCN b
ON			b.TicketNumber = a.TicketNumber 
WHERE		a.stationopendate BETWEEN DATEADD(day,-31,b.insertdate) AND  DATEADD(day,31,b.insertdate)  AND
			a.FC = 4 AND 
			a.TransCode IN ('SALE','EXCH') AND 
			a.DocType IN ('TKT','CNJ') AND
			b.TransCode LIKE 'TKT%' AND
			a.baggage IS NULL AND b.baggage4 <> 'NIL'
			
			
UPDATE		#tmp2
SET			class = b.Class ,deptime = b.DepTime , arrtime = b.ArrTime  , baggage = 0
FROM		#tmp2 a
			INNER JOIN tblTCN b
ON			b.TicketNumber = a.TicketNumber 
WHERE		a.stationopendate BETWEEN DATEADD(day,-31,b.insertdate) AND  DATEADD(day,31,b.insertdate)  AND
			a.FC = 1 AND 
			a.TransCode IN ('SALE','EXCH') AND 
			a.DocType IN ('TKT','CNJ') AND
			b.TransCode LIKE 'TKT%' AND
			a.baggage IS NULL AND b.baggage = 'NIL'
UPDATE		#tmp2
SET			class = b.Class2 ,deptime = b.DepTime2 , arrtime = b.ArrTime2  , baggage = 0
FROM		#tmp2 a
			INNER JOIN tblTCN b
ON			b.TicketNumber = a.TicketNumber 
WHERE		a.stationopendate BETWEEN DATEADD(day,-31,b.insertdate) AND  DATEADD(day,31,b.insertdate)  AND
			a.FC = 2 AND 
			a.TransCode IN ('SALE','EXCH') AND 
			a.DocType IN ('TKT','CNJ') AND
			b.TransCode LIKE 'TKT%' AND
			a.baggage IS NULL AND b.baggage2 = 'NIL'
UPDATE		#tmp2
SET			class = b.Class3 ,deptime = b.DepTime3 , arrtime = b.ArrTime3  , baggage = 0
FROM		#tmp2 a
			INNER JOIN tblTCN b
ON			b.TicketNumber = a.TicketNumber 
WHERE		a.stationopendate BETWEEN DATEADD(day,-31,b.insertdate) AND  DATEADD(day,31,b.insertdate)  AND
			a.FC = 3 AND 
			a.TransCode IN ('SALE','EXCH') AND 
			a.DocType IN ('TKT','CNJ') AND
			b.TransCode LIKE 'TKT%' AND
			a.baggage IS NULL AND b.baggage3 = 'NIL'
UPDATE		#tmp2
SET			class = b.Class4 ,deptime = b.DepTime4 , arrtime = b.ArrTime4  , baggage = 0
FROM		#tmp2 a
			INNER JOIN tblTCN b
ON			b.TicketNumber = a.TicketNumber 
WHERE		a.stationopendate BETWEEN DATEADD(day,-31,b.insertdate) AND  DATEADD(day,31,b.insertdate)  AND
			a.FC = 4 AND 
			a.TransCode IN ('SALE','EXCH') AND 
			a.DocType IN ('TKT','CNJ') AND
			b.TransCode LIKE 'TKT%' AND
			a.baggage IS NULL AND b.baggage4 = 'NIL'

---------------------------------------------------------------------------------------------------------------

SELECT		* 
FROM		#tmp2 
WHERE		Class IS NULL AND
			(DocType NOT IN ('EMD','EXB','VOU') AND
			(TransCode NOT IN ('RFND','RFDP','VOID'))) 
			
SELECT		* 
FROM		#tmp2 
WHERE		baggage IS NULL AND
			(DocType NOT IN ('EMD','EXB','VOU') AND
			(TransCode NOT IN ('RFND','RFDP','VOID'))) 
			
SELECT		* 
FROM		#tmp2 
WHERE		deptime IS NULL AND
			(DocType NOT IN ('EMD','EXB','VOU') AND
			(TransCode NOT IN ('RFND','RFDP','VOID'))) 

---------------------------------------------------------------------------------------------------------------

UPDATE		tbltktcpn
SET			Class = b.class, DepTime = b.deptime, ArrTime = b.arrtime, baggage = b.baggage
FROM		tbltktcpn a
			INNER JOIN #tmp2 b
ON			b.TicketNumber = a.TicketNumber AND 
			b.FC = a.FC AND 
			b.RouteAwal = a.RouteAwal AND 
			b.RouteAkhir = a.RouteAkhir
			
---------------------------------------------------------------------------------------------------------------
--kosong--

SELECT		*
FROM		tblsttrk a with(nolock)
			INNER JOIN tbltktcpn b with(nolock) 
ON			b.StKey = a.StKey 
			INNER JOIN tbltkt c with(nolock)
ON			c.TicketNumber = b.TicketNumber AND
			c.stkey = a.StKey AND
			c.stkey = b.StKey 
WHERE		a.stationopendate BETWEEN '24 Nov 2019' AND '26 Nov 2019'  AND 
			b.class IS NULL AND 
			c.transcode in ('SALE','EXCH') AND c.doctype in ('TKT','CNJ') AND
			FareBasis <> 'VOID'	
			
SELECT		*
FROM		tblsttrk a with(nolock)
			INNER JOIN tbltktcpn b with(nolock) 
ON			b.StKey = a.StKey 
			INNER JOIN tbltkt c with(nolock)
ON			c.TicketNumber = b.TicketNumber AND
			c.stkey = a.StKey AND
			c.stkey = b.StKey 
WHERE		a.stationopendate BETWEEN '24 Nov 2019' AND '26 Nov 2019'  AND 
			b.deptime IS NULL AND 
			c.transcode in ('SALE','EXCH') AND c.doctype in ('TKT','CNJ') AND
			FareBasis not like '%VOID%'
			
SELECT		*
FROM		tblsttrk a with(nolock)
			INNER JOIN tbltktcpn b with(nolock) 
ON			b.StKey = a.StKey 
			INNER JOIN tbltkt c with(nolock)
ON			c.TicketNumber = b.TicketNumber AND
			c.stkey = a.StKey AND
			c.stkey = b.StKey 
WHERE		a.stationopendate BETWEEN '24 Nov 2019' AND '26 Nov 2019'  AND 
			b.baggage IS NULL AND 
			c.transcode in ('SALE','EXCH') AND c.doctype in ('TKT','CNJ') AND
			FareBasis not like '%VOID%'
