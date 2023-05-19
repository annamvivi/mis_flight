SELECT		DISTINCT StationOpenDate
FROM		dmsttrk
WHERE		stationopendate <> '27 Nov 2019'

DROP TABLE	#tmp1 
SELECT		a.* 
INTO		#tmp1
FROM		tbltkt a with(nolock) INNER JOIN tblsttrk b with(nolock)
ON			b.stkey = a.stkey
WHERE		(a.TransCode in ('SALE','EXCH') AND a.DocType in ('EMD','EXB','MSR')) AND
			b.stationopendate BETWEEN '24 Nov 2019' AND '26 Nov 2019' AND
			a.IntlCode = 'D'
						 
DROP TABLE	#tmp2 
SELECT		a.* 
INTO		#tmp2 
FROM		#tmp1 a INNER JOIN tbltkt b with(nolock)
ON			b.pnrr = a.PNRR AND
			b.stkey = a.stkey
WHERE		b.TransCode IN ('SALE','EXCH') AND
			b.IntlCode = 'I' AND
			b.IntlCode <> a.IntlCode 

------------------------------------------------------

SELECT		COUNT(*) 
FROM		#tmp2  
SELECT		DISTINCT intlcode  
FROM		#tmp2 

UPDATE		#tmp2 
SET			IntlCode = b.intlcode
FROM		#tmp2 a INNER JOIN tbltkt b with(nolock)
ON			b.pnrr = a.PNRR AND
			b.stkey = a.stkey
WHERE		b.TransCode IN ('SALE','EXCH') AND
			b.IntlCode = 'I' AND
			b.IntlCode <> a.IntlCode 

SELECT		COUNT(*) 
FROM		#tmp2 
 
SELECT		DISTINCT intlcode  
FROM		#tmp2 
------------------------------------------------------

UPDATE		tbltkt
SET			IntlCode = b.intlcode
FROM		tbltkt a INNER JOIN #tmp2 b
ON			b.ticketnumber = a.TicketNumber AND
			b.TransCode = a.TransCode AND
			b.stkey = a.stkey 
WHERE		b.IntlCode <> a.IntlCode
------------------------------------------------------
DROP TABLE	#tmpupdatecoupon
SELECT		b.stkey, b.TicketNumber, b.IntlCode
INTO		#tmpupdatecoupon 
FROM		tblsttrk a, tbltkt b with(nolock)
WHERE		b.stkey = a.stkey AND 
			a.stationopendate BETWEEN '24 Nov 2019' AND '26 Nov 2019' AND
			b.TransCode IN ('SALE','EXCH') AND
			b.DocType IN ('EMD','EXB','MSR')

UPDATE		tbltktcpn
SET			DomIntlCode = a.IntlCode, AirlineIntlCode = a.IntlCode 
FROM		#tmpupdatecoupon a, tbltktcpn b
WHERE		b.stkey = a.stkey AND
			b.TicketNumber = a.TicketNumber AND
			(b.RouteAwal = '' or b.RouteAkhir = '')


------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------


	DROP TABLE	#tmp1 
	SELECT		a.* 
	INTO		#tmp1
	FROM		tbltkt a with(nolock) INNER JOIN tblsttrk b with(nolock)
	ON			b.stkey = a.stkey
	WHERE		(a.TransCode = 'SALE' AND a.DocType = 'VOU') AND 
				b.stationopendate BETWEEN '24 Nov 2019' AND '26 Nov 2019' AND
				a.IntlCode = 'D'
							 
	DROP TABLE	#tmp2 
	SELECT		a.* 
	INTO		#tmp2 
	FROM		#tmp1 a INNER JOIN tbltkt b with(nolock)
	ON			b.TicketNumber = a.RefundTicket
	WHERE		b.TransCode IN ('SALE','EXCH') AND
				b.IntlCode = 'I' AND
				b.IntlCode <> a.IntlCode 

	------------------------------------------------------

SELECT		COUNT(*) 
FROM		#tmp2  
SELECT		DISTINCT intlcode  
FROM		#tmp2 

UPDATE		#tmp2 
SET			IntlCode = b.intlcode
FROM		#tmp2 a INNER JOIN tbltkt b with(nolock)
ON			b.TicketNumber = a.RefundTicket
WHERE		b.TransCode IN ('SALE','EXCH') AND
			b.IntlCode = 'I' AND
			b.IntlCode <> a.IntlCode 

SELECT		COUNT(*) 
FROM		#tmp2 
 
SELECT		DISTINCT intlcode  
FROM		#tmp2 
-------------------------------------------------------------------------------------------
UPDATE		tbltkt
SET			IntlCode = b.intlcode
FROM		tbltkt a INNER JOIN #tmp2 b
ON			b.ticketnumber = a.TicketNumber AND
			b.TransCode = a.TransCode AND
			b.stkey = a.stkey 
WHERE		b.IntlCode <> a.IntlCode 

==================================================================================================================
DROP TABLE	#tmp1 
SELECT		a.* 
INTO		#tmp1
FROM		tbltkt a with(nolock) INNER JOIN tblsttrk b with(nolock)
ON			b.stkey = a.stkey
WHERE		(a.TransCode like 'rf%') AND
			b.stationopendate BETWEEN '24 Nov 2019' AND '26 Nov 2019' AND
			a.IntlCode = 'D'
						 
DROP TABLE	#tmp2 
SELECT		a.* 
INTO		#tmp2 
FROM		#tmp1 a INNER JOIN tbltkt b with(nolock)
ON			b.TicketNumber = a.RefundTicket
WHERE		b.TransCode IN ('SALE','EXCH') AND
			b.IntlCode = 'I' AND
			b.IntlCode <> a.IntlCode 

------------------------------------------------------

SELECT		COUNT(*) 
FROM		#tmp2  
SELECT		DISTINCT intlcode  
FROM		#tmp2 

UPDATE		#tmp2 
SET			IntlCode = b.intlcode
FROM		#tmp2 a INNER JOIN tbltkt b with(nolock)
ON			b.TicketNumber = a.RefundTicket
WHERE		b.TransCode IN ('SALE','EXCH') AND
			b.IntlCode = 'I' AND
			b.IntlCode <> a.IntlCode 

SELECT		COUNT(*) 
FROM		#tmp2 
 
SELECT		DISTINCT intlcode  
FROM		#tmp2 

-------------------------------------------------------------------------------------------
UPDATE		tbltkt
SET			IntlCode = b.intlcode
FROM		tbltkt a INNER JOIN #tmp2 b
ON			b.ticketnumber = a.TicketNumber AND
			b.TransCode = a.TransCode AND
			b.stkey = a.stkey 
WHERE		b.IntlCode <> a.IntlCode
		
==================================================================================================================

		


