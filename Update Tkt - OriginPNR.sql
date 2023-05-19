DROP TABLE	#tmptkt
SELECT		a.StationOpenDate,b.* 
INTO		#tmptkt 
FROM		dmsttrk a WITH(NOLOCK) , dmtkt b WITH(NOLOCK)
WHERE		b.stkey = a.stkey AND
			a.StationOpenDate BETWEEN '24 Nov 2019' AND '26 Nov 2019'
			
UPDATE		#tmptkt
SET			originPNR = b.PNRR
FROM		#tmptkt a, tbltcn b
WHERE		b.TicketNumber = a.TicketNumber AND 
			a.stationopendate BETWEEN DATEADD(day,-31,b.createdate) AND  DATEADD(day,31,b.createdate) AND 
			a.OriginPNR IS NULL AND 
			a.TransCode in ('SALE','EXCH') AND 
			b.TransCode in ('TKTT','EMDA','MD10','MD50')
			
UPDATE		#tmptkt
SET			originPNR = b.PNRR
FROM		#tmptkt a, tbltcn b
WHERE		b.TicketNumber = a.TicketNumber AND 
			b.PNRR = a.PNRR AND 
			a.OriginPNR IS NULL AND 
			a.TransCode in ('SALE','EXCH') AND 
			b.TransCode in ('TKTT','EMDA','MD10','MD50')
			
UPDATE		#tmptkt
SET			originPNR = b.PNRR
FROM		#tmptkt a, tbltcn b
WHERE		b.TicketNumber = a.TicketNumber AND 
			a.OriginPNR IS NULL AND 
			a.TransCode in ('SALE','EXCH') AND 
			b.TransCode in ('TKTT','EMDA','MD10','MD50')

UPDATE		#tmptkt
SET			originPNR = pnrr
WHERE		OriginPNR IS NULL AND
			((TransCode LIKE 'rf%') OR (TransCode = 'SALE' AND DocType = 'VOU') OR (TransCode = 'VOID')) 

UPDATE		#tmptkt
SET			OriginPNR = pnrr
WHERE		OriginPNR IS NULL AND 
			FromTCN IN ('BSP','AMDMAL','ABCMAL','BSPABC','BSPAMD')

UPDATE		#tmptkt
SET			OriginPNR = pnrr
WHERE		OriginPNR IS NULL AND 
			TransCode = 'SALE' AND DocType = 'EMD' 
	
UPDATE		#tmptkt
SET			originpNR = pnrr
WHERE		originPNR IS NULL

-----------------------------------------------------------------------------------		
CREATE INDEX idtkt ON #tmptkt (ticketnumber)
CREATE INDEX iddistrict ON #tmptkt (originpNR)
CREATE INDEX idstkey ON #tmptkt (stkey)
-----------------------------------------------------------------------------------			
UPDATE		dmtkt
SET			OriginPNR = b.originPNR
FROM		dmtkt a, #tmptkt b
WHERE		b.TicketNumber = a.TicketNumber AND
			b.stkey = a.stkey
-----------------------------------------------------------------------------------	
			
SELECT		* 
FROM		dmsttrk a WITH(NOLOCK), dmtkt b WITH(NOLOCK)
WHERE		b.StKey = a.StKey  AND 
			b.originPNR IS NULL AND 
			a.stationopendate BETWEEN '24 Nov 2019' AND '26 Nov 2019'

