DROP TABLE	#tmp1
SELECT		b.ticketnumber, b.issueddate, b.intlcode, b.tktbasefare, b.rate, b.descr, b.fop, b.transcode, b.doctype, 
			b.preconjticket, Curr = a.StationCurr, c.fc, c.Fare, c.FareUpdate, c.FareBasis, c.routeawal, c.routeakhir, c.domIntlCode, c.FareFromDescr
INTO		#tmp1
FROM		dmsttrk a WITH(NOLOCK) INNER JOIN dmtkt b WITH(NOLOCK)
ON			b.stkey = a.stkey 
			INNER JOIN dmtktcpn c WITH(NOLOCK)
ON			c.stkey = b.stkey AND
			c.stkey = a.stkey AND
			c.ticketnumber = b.ticketnumber
WHERE		b.transcode in ('SALE','EXCH') AND
			b.doctype in ('TKT') 

DROP TABLE	#tmpconj
SELECT		b.ticketnumber, b.issueddate, b.intlcode, b.tktBaseFare, b.rate, b.descr, b.fop, b.transcode, b.doctype, 
			b.preconjticket, Curr = a.StationCurr, c.fc, c.Fare, c.FareUpdate, c.FareBasis, c.routeawal, c.routeakhir, c.DomIntlCode, c.FareFromDescr
INTO		#tmpconj
FROM		dmsttrk a WITH(NOLOCK) INNER JOIN dmtkt b WITH(NOLOCK)
ON			b.stkey = a.stkey 
			INNER JOIN dmtktcpn c WITH(NOLOCK)
ON			c.stkey = b.stkey AND
			c.stkey = a.stkey AND
			c.ticketnumber = b.ticketnumber 
WHERE		b.transcode in ('SALE','EXCH') AND
			b.doctype in ('CNJ') 

UPDATE		#tmpconj 
SET			tktBasefare = b.tktBasefare
FROM		#tmpconj a INNER JOIN dmtkt b with(nolock)
ON			b.ticketnumber = a.preconjticket
------------------------------------------------------------------------------------------------------------------------------------------------------------
--================================================================================================================================================================
--- KALO ADA NILAI KASIH TAU -------

SELECT		distinct a.*  
FROM		#tmpconj a INNER JOIN (SELECT * FROM #tmpconj) b
ON			b.ticketnumber = a.preconjticket 
--
--------------------------------------------------------------------------------------------------------------------------------------------------------------

/* JALANIN INI KALO DI ATS ADA NILAI

begin tran
UPDATE #tmpconj 
SET tktBasefare = b.tktBasefare
FROM #tmpconj a, (SELECT * FROM #tmpconj) b
WHERE b.ticketnumber = a.preconjticket

rollback
commit


*/

DROP TABLE	#Tmpmax
SELECT		ticketnumber, fc = MAX(fc)
INTO		#tmpmax
FROM		#Tmp1
GROUP BY	ticketnumber

DROP TABLE	#tmpNewAllTktCpn
SELECT		ticketnumber, issueddate, intlcode, Curr, fop, transcode, doctype, ticketasal = ticketnumber, fc, FCAsal = fc, tktBasefare, rate, 
			fare, FareUpdate, FareFromDescr, descr, FareBasis, RouteAwal, RouteAkhir, DomIntlCode
INTO		#tmpNewAllTktCpn
FROM		#Tmp1
UNION ALL
SELECT		ticketnumber = preconjticket, issueddate, intlcode, Curr, fop, transcode, doctype, ticketasal = a.ticketnumber, fc = a.fc + b.fc, 
			fcAsal = a.FC, tktBasefare, rate, fare, FareUpdate, a.FareFromDescr, descr, FareBasis, RouteAwal, RouteAkhir, DomIntlCode
FROM		#tmpconj a LEFT JOIN #tmpmax b
ON			b.ticketnumber = a.preconjticket

UPDATE		#tmpNewAllTktCpn 
SET			FareUpdate = FareFromDescr, fare = FareFromDescr
WHERE		tktbasefare <> 0 AND
			farebasis <> 'VOID'

ALTER TABLE #tmpNewAllTktCpn ADD sudahupdate INT DEFAULT 0


/*

SELECT * FROM #tmpNewAllTktCpn WHERE ticketnumber  =  9902180566798
SELECT * FROM #tmpNewAllTktCpn WHERE ticketnumber  =  9902180566799
SELECT * FROM #tmpNewAllTktCpn WHERE ticketnumber  =  9902180566800


UPDATE		#tmpNewAllTktCpn 
SET			ticketnumber = 9902187870513, fc=8+fcasal 
WHERE		ticketnumber = 9902187870514

*/
---------------------------------------------------------------------------------
 ====================================================================================================================================================== 

DROP TABLE	#tmpz1
SELECT		ticketnumber, tktbasefare, fare = SUM(ISNULL(fare, 0)), FareUpdate = SUM(ISNULL(FareUpdate, 0))
INTO		#tmpz1
FROM		#tmpNewAllTktCpn 
WHERE		tktbasefare <> 0 AND 
			farebasis <> 'void'
GROUP BY	ticketnumber, tktbasefare

UPDATE		#tmpnewalltktcpn
SET			fareupdate = ROUND(ROUND((a.fare / b.fare),2) * a.tktbasefare ,2)
FROM		#tmpnewalltktcpn a, #tmpz1 b
WHERE		b.ticketnumber = a.ticketnumber AND
			a.farebasis <> 'void' AND
			b.fare <> '0' AND
			b.fareupdate <> b.tktbasefare

UPDATE		b
SET			fareupdate = 0 
FROM		#tmpnewalltktcpn a, #tmpnewalltktcpn b
WHERE		a.farebasis <> 'VOID' AND 
			a.farefromdescr = 0 AND
			b.ticketnumber = a.ticketnumber

-----------------------------------------------------------------------------------------------
--looping

DROP TABLE	#TmpTktBaseFare
SELECT		TicketNumber, TktBaseFare
INTO		#TmpTktBaseFare
FROM		#tmpnewalltktcpn 
WHERE		FCAsal  =  1
ORDER BY	TicketNumber

DROP TABLE	#Tmpfare2update
SELECT		TicketNumber,  FareUpdate  =  SUM(ISNULL(fareupdate, 0))
INTO		#Tmpfare2update
FROM		#tmpnewalltktcpn 
GROUP BY	TicketNumber
ORDER BY	TicketNumber

DROP TABLE	#tmp10
SELECT		DISTINCT a.*,  b.FareUpdate , selisih = a.tktbasefare - b.fareupdate
INTO		#tmp10					--- affected 3  = > harus 0 (nol) ---
FROM		#tmpTktBaseFare a INNER JOIN #tmpfare2update b
ON			b.TicketNumber  =  a.TicketNumber
WHERE		b.FareUpdate <> a.TktBaseFare		--1159
ORDER BY	a.TicketNumber

select * from #tmp10
----------------------------------------------------------------------------------------------------------------------------------------------------------------
/* 1

DROP TABLE	#tmpsumFC
SELECT		b.ticketnumber,b.tktbasefare,selisih, totalFC = count(b.FC) 
INTO		#tmpsumFC 
FROM		#tmp10 a, #tmpnewalltktcpn b
WHERE		b.ticketnumber = a.ticketnumber AND
			b.farebasis <> 'VOID'
GROUP BY	b.ticketnumber, b.tktbasefare,selisih

UPDATE		#tmpnewalltktcpn
SET			fareupdate = ISNULL(fareupdate,0) + ROUND((selisih/totalFC),2) 
FROM		#tmpsumFC a, #tmpnewalltktcpn b
WHERE		b.ticketnumber = a.ticketnumber AND
			b.farebasis <> 'VOID' 

----------------------------------------------------------------------------------------------------------
2.

DROP TABLE	#tmp10 
SELECT		a.*,  b.FareUpdate 
INTO		#tmp10
FROM		#tmpTktBaseFare a INNER JOIN #tmpfare2update b
ON			b.TicketNumber  =  a.TicketNumber
WHERE		b.FareUpdate <> a.TktBaseFare AND b.fareupdate <> 0
ORDER BY	a.TicketNumber

DROP TABLE	#tmpMAXFC
SELECT		b.ticketnumber, MAXFC = MAX(b.FC), selisih = a.tktbasefare - a.fareupdate
INTO		#tmpMAXFC 
FROM		#tmp10 a, #tmpnewalltktcpn b
WHERE		b.ticketnumber = a.ticketnumber AND
			b.farebasis <> 'VOID'
GROUP BY	b.ticketnumber, a.tktbasefare, a.fareupdate

DROP TABLE	#tmpmaxticketasal
SELECT		a.ticketnumber, maxticketasal = max(ticketasal), maxFC, selisih
INTO		#tmpmaxticketasal
FROM		#tmpnewalltktcpn a, #tmpmaxFC b
WHERE		b.ticketnumber = a.ticketnumber AND
			a.farebasis <> 'VOID'
GROUP BY	a.ticketnumber, maxFC, selisih

UPDATE		#tmpnewalltktcpn
SET			fareupdate = fareupdate + b.selisih
FROM		#tmpnewalltktcpn a, #tmpmaxticketasal b
WHERE		b.ticketnumber = a.ticketnumber AND
			b.maxFC = a.fc AND
			b.maxticketasal = a.ticketasal AND
			a.farebasis <> 'VOID'
*/
----------------------------------------------------------------------------------------------------------

UPDATE		#tmpnewalltktcpn 
SET			fareupdate = 0, fare = 0 
WHERE		fareupdate IS NULL
----------------------------------------------------------------------------------------------------------

UPDATE		dmtktcpn
SET			FareUpdate = b.fareupdate, fare = b.fare
FROM		dmtktcpn a INNER JOIN #tmpNewAllTktCpn b
ON			b.ticketasal = a.ticketnumber AND
			b.fcasal = a.fc
