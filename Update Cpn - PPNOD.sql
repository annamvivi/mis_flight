
DROP TABLE	#tmp1
SELECT		b.stkey, b.ticketnumber, b.tktppnOD, c.FareUpdate, c.IWJR,c.Apotax, b.transcode, b.doctype, 
			b.PreConjTicket, c.fc, c.PPNOD, c.FareBasis, c.AirlineIntlCode, c.routeawal, c.routeakhir, b.Curr
INTO		#tmp1
FROM		dmsttrk a WITH(NOLOCK) INNER JOIN dmtkt b WITH(NOLOCK)
ON			b.stkey = a.stkey 
			INNER JOIN dmtktcpn c WITH(NOLOCK)
ON			c.stkey = b.stkey AND
			c.stkey = a.stkey AND
			c.ticketnumber = b.ticketnumber
WHERE		a.stationopendate BETWEEN '24 Nov 2019' AND '26 Nov 2019' AND
			b.transcode in ('SALE', 'EXCH') AND
			b.doctype in ('TKT')

DROP TABLE	#tmpconj
SELECT		b.stkey, b.ticketnumber,b.tktppnOD, c.FareUpdate, c.IWJR,c.Apotax,b.transcode, b.doctype, 
			b.PreConjTicket, c.fc, c.PPNOD, c.FareBasis, c.AirlineIntlCode, c.routeawal, c.routeakhir, b.Curr
INTO		#tmpconj
FROM		dmsttrk a WITH(NOLOCK) INNER JOIN dmtkt b WITH(NOLOCK)
ON			b.stkey = a.stkey 
			INNER JOIN dmtktcpn c WITH(NOLOCK)
ON			c.stkey = b.stkey AND
			c.stkey = a.stkey AND
			c.ticketnumber = b.ticketnumber 
WHERE		a.stationopendate BETWEEN '24 Nov 2019' AND '26 Nov 2019' AND
			b.transcode in ('SALE', 'EXCH') AND
			b.doctype in ('CNJ')

UPDATE		#tmpconj 
SET			tktppnOD = b.tktppnOD
FROM		#tmpconj a INNER JOIN dmtkt b WITH(NOLOCK)
ON			b.ticketnumber = a.PreConjTicket

================================================================================================================================================================
--- KALO ADA NILAI KASIH TAU -------

SELECT		distinct a.* 
FROM		#tmpconj a INNER JOIN (SELECT * FROM #tmpconj) b
ON			b.ticketnumber = a.PreConjTicket 

UPDATE		#tmpconj 
SET			tktppnOD = b.tktppnOD
FROM		#tmpconj a,(select * from #tmpconj) b
WHERE		b.ticketnumber = a.PreConjTicket
--------------------------------------------------------------------------------------------------------------------------------------------------------------
DROP TABLE	#Tmpmax
SELECT		ticketnumber, fc = MAX(fc)
INTO		#tmpmax
FROM		#Tmp1
GROUP BY	ticketnumber

DROP TABLE	#tmpNewAllTktCpn
SELECT		stkey, ticketnumber, tktppnOD, FareUpdate, IWJR, Apotax, transcode, doctype,ticketasal = ticketnumber, fc, fcasal = fc, ppnOD, FareBasis, AirlineIntlCode, RouteAwal, routeakhir, curr
INTO		#tmpNewAllTktCpn
FROM		#Tmp1
UNION ALL
SELECT		stkey, ticketnumber = PreConjTicket, tktppnOD,FareUpdate, IWJR, Apotax, transcode, doctype, ticketasal = a.ticketnumber, fc = a.fc + b.fc, 
			fcAsal = a.FC, ppnOD, FareBasis, AirlineIntlCode, RouteAwal, routeakhir, curr
FROM		#tmpconj a LEFT JOIN #tmpmax b
ON			b.ticketnumber = a.PreConjTicket

/*
select * from #tmpNewAllTktCpn where ticketnumber = '9902186762593'
select * from #tmpNewAllTktCpn where ticketnumber = '9902186762594'
select * from #tmpNewAllTktCpn where ticketnumber = '9902186762595'

UPDATE		#tmpNewAllTktCpn 
SET			ticketnumber = 9902187870513, fc=8+fcasal 
WHERE		ticketnumber = 9902187870514

*/
--------------------------------------------------------------------------------------------------------------------------------------------------------------
UPDATE		#tmpNewAllTktCpn
SET			tktppnOD = 0
WHERE		tktppnOD IS NULL

UPDATE		#tmpNewAllTktCpn
SET			PPNOD = 0
WHERE		tktppnOD = 0

SELECT		*	
FROM		#tmpNewAllTktCpn a, sales.dbo.tblMasterDistrict b
WHERE		b.Kodedistrict = a.RouteAwal AND 
			b.Country = 'MALAYSIA' AND
			a.tktppnOD > 0

UPDATE		#tmpNewAllTktCpn
SET			ppnOD = ROUND((0.06 * (FareUpdate + IWJR + Apotax)),2)
FROM		#tmpNewAllTktCpn a, sales.dbo.tblMasterDistrict b
WHERE		b.Kodedistrict = a.RouteAwal AND 
			b.Country = 'MALAYSIA' AND
			a.tktppnOD > 0 AND
			a.airlineintlcode = 'D' AND 
			a.FareBasis <> 'VOID'
			
UPDATE		#tmpNewAllTktCpn
SET			ppnOD = ROUND((0.06 * (Apotax)),2)
FROM		#tmpNewAllTktCpn a, sales.dbo.tblMasterDistrict b
WHERE		b.Kodedistrict = a.RouteAwal AND 
			b.Country = 'MALAYSIA' AND
			a.tktppnOD > 0 AND
			a.airlineintlcode = 'I' AND 
			a.FareBasis <> 'VOID'

ALTER TABLE #tmpNewAllTktCpn ADD RealPPN MONEY
--------------------------------------------------------------------------------------------------------------------------------------------------------------
--LOOPING--

DROP TABLE	#TmptktPPNOD
SELECT		TicketNumber, tktPPNOD, curr
INTO		#TmptktPPNOD
FROM		#tmpNewAllTktCpn 
WHERE		FC = 1
ORDER BY	TicketAsal

DROP TABLE	#TmpPPNupdate
SELECT		TicketNumber, PPNODUpdate =SUM(ISNULL(PPNOD,0)), curr
INTO		#TmpPPNupdate
FROM		#tmpNewAllTktCpn 
GROUP BY	TicketNumber, curr
ORDER BY	TicketNumber, curr

DROP TABLE  #tmpPPNODTidakSama
SELECT		a.*, b.PPNODUpdate
INTO		#tmpPPNODTidakSama
FROM		#TmptktPPNOD a INNER JOIN #TmpPPNupdate b
ON			b.TicketNumber = a.TicketNumber			 ---HARUS KOSONG---
WHERE		b.PPNODUpdate<> a.tktPPNOD
ORDER BY	a.TicketNumber

SELECT		* 
FROM		#tmpPPNODTidakSama

-----------------------------------------------------------------------------------------			
/*
/*1*/

DROP TABLE	#tmpSALE
SELECT		a.TicketNumber, b.tktppnod,totaltiket = COUNT(*)
INTO		#tmpSALE
FROM		#tmpPPNODTidakSama a
			INNER JOIN #tmpNewAllTktCpn b
ON			b.TicketNumber = a.TicketNumber 
WHERE		b.TransCode IN ('SALE','EXCH') AND 
			PPNOD IS NOT NULL AND 
			b.RouteAwal IN (SELECT kodedistrict FROM sales.dbo.tblMasterDistrict WHERE Country = 'MALAYSIA')
GROUP BY	a.TicketNumber, b.tktppnod

DELETE		#tmpSALE 
WHERE		totaltiket > 1
			
UPDATE		#tmpNewAllTktCpn
SET			ppnOD = b.tktppnOD, realppn = b.tktppnod
FROM		#tmpPPNODTidakSama  a, #tmpNewAllTktCpn b, #tmpSALE c
WHERE		b.TicketNumber = a.TicketNumber AND
			b.TransCode in ('SALE','EXCH') AND 
			b.PPNOD IS NOT NULL AND 
			b.RouteAwal in (SELECT kodedistrict FROM sales.dbo.tblMasterDistrict WHERE Country = 'MALAYSIA') AND
			c.TicketNumber = a.TicketNumber AND
			c.TicketNumber = b.TicketNumber
		

-----------------------------------------------------------------------------------------			
/*2*/

UPDATE		#tmpnewalltktcpn
SET			PPNOD = b.ppnod, realppn = b.realtax
FROM		#tmpnewalltktcpn a
			INNER JOIN dmtktcpn b
ON			b.TicketNumber = a.TicketNumber AND 
			b.FC = a.fc 			
			INNER JOIN #tmpPPNODTidakSama c
ON			c.TicketNumber = a.TicketNumber AND 
			c.TicketNumber = b.TicketNumber 
WHERE		b.PPNOD IS NOT NULL

-------------------------------------------------------------------------------------------------------------------------------------------------------------
/*3*/  kalo setelah no 4 masih ada nilai jalanin ini lg.

ALTER TABLE	#tmpPPNODTidakSama ADD selisihppn MONEY
--
UPDATE		#tmpPPNODTidakSama
SET			selisihPPN = tktppnOD - PPNODUpdate

UPDATE		#tmpNewAllTktCpn 
SET			realppn = b.ppnod
FROM		#tmpPPNODTidakSama a
			INNER JOIN #tmpNewAllTktCpn b
ON			b.TicketNumber = a.TicketNumber 
WHERE		a.CURR = 'IDR' AND selisihppn <= 2000


DROP TABLE	#tmp11
SELECT		a.TicketNumber,a.tktppnOD,a.PPNODUpdate,a.selisihPPN,MinFC = MIN(FC)
INTO		#tmp11
FROM		#tmpPPNODTidakSama a 
			LEFT JOIN #tmpNewAllTktCpn b 
ON			a.ticketnumber = b.ticketnumber
WHERE		b.farebasis <> 'VOID' AND
			a.selisihPPN BETWEEN '-2000' AND '2000' AND
			b.RouteAwal IN (SELECT kodedistrict FROM sales.dbo.tblMasterDistrict WHERE Country = 'MALAYSIA') AND
			b.Curr = 'IDR' AND
			b.PPNOD IS NOT NULL AND 
			b.PPNOD <> 0
GROUP BY	a.TicketNumber,a.tktppnOD,a.PPNODUpdate,a.selisihPPN

UPDATE		#tmpNewAllTktCpn 
SET			PPNOD = PPNOD + b.selisihPPN
FROM		#tmpNewAllTktCpn a, #tmp11 b
WHERE		b.ticketnumber = a.ticketnumber AND
			b.MinFC = a.fc AND
			a.FareBasis <> 'VOID'
------------------

/*3*/

UPDATE		#tmpNewAllTktCpn 
SET			realppn = b.ppnod
FROM		#tmpPPNODTidakSama a
			INNER JOIN #tmpNewAllTktCpn b
ON			b.TicketNumber = a.TicketNumber 
WHERE		a.CURR = 'MYR' AND selisihppn <= 1

DROP TABLE	#tmp12
SELECT		a.TicketNumber,a.tktppnOD,a.PPNODUpdate,a.selisihPPN,MinFC = MIN(FC)
INTO		#tmp12
FROM		#tmpPPNODTidakSama a 
			LEFT JOIN #tmpNewAllTktCpn b 
ON			a.ticketnumber = b.ticketnumber
WHERE		b.farebasis <> 'VOID' AND
			a.selisihPPN BETWEEN '-1' AND '1' AND
			b.RouteAwal IN (SELECT kodedistrict FROM sales.dbo.tblMasterDistrict WHERE Country = 'MALAYSIA') AND
			b.Curr = 'MYR' AND
			b.PPNOD IS NOT NULL AND 
			b.PPNOD <> 0
GROUP BY	a.TicketNumber,a.tktppnOD,a.PPNODUpdate,a.selisihPPN

UPDATE		#tmpNewAllTktCpn 
SET			PPNOD = PPNOD + b.selisihPPN
FROM		#tmpNewAllTktCpn a, #tmp12 b
WHERE		b.ticketnumber = a.ticketnumber AND
			b.MinFC = a.fc AND
			a.FareBasis <> 'VOID'

-----------------------------------------------------------------------------------------			
/*6*/

DROP TABLE	#tmpexch
SELECT		DISTINCT a.TicketNumber, b.tktppnod,totaltiket = COUNT(*)
INTO		#tmpexch
FROM		#tmpPPNODTidakSama a
			INNER JOIN #tmpNewAllTktCpn b
ON			b.TicketNumber = a.TicketNumber
WHERE		b.TransCode IN ('SALE','EXCH') AND 
			ppnod IS NOT NULL AND 
			b.routeawal IN (SELECT kodedistrict FROM sales.dbo.tblmasterdistrict WHERE country = 'MALAYSIA') AND
			farebasis <> 'VOID'
GROUP BY    a.TicketNumber, b.tktppnod

ALTER TABLE #tmpexch ADD additional MONEY

UPDATE		#tmpexch 
SET			additional = ROUND((tktppnod / totaltiket),2)

UPDATE		#tmpNewAllTktCpn
SET			ppnOD = c.additional, realppn = c.additional
FROM		#tmpPPNODTidakSama a
			INNER JOIN #tmpNewAllTktCpn b
ON			b.TicketNumber = a.TicketNumber 			
			INNER JOIN #tmpexch c
ON			c.TicketNumber = a.TicketNumber AND
			c.TicketNumber = b.TicketNumber 
WHERE		b.TransCode IN ('SALE','EXCH') AND 
			b.routeawal IN (SELECT kodedistrict FROM sales.dbo.tblmasterdistrict WHERE country = 'MALAYSIA') AND
			PPNOD IS NOT NULL AND 
			farebasis <> 'VOID'
------------------------------------------------------------
/*7*/

UPDATE		#tmpNewAllTktCpn
SET			PPNOD = a.TktPPNOD 
FROM		#tmpPPNODTidakSama a, #tmpNewAllTktCpn b
WHERE		b.TicketNumber = a.TicketNumber AND 
			b.RouteAwal NOT IN (SELECT Kodedistrict FROM tblMasterDistrict WHERE Country = 'INDONESIA')
*/
================================================================================================================

UPDATE		#tmpNewAllTktCpn
SET			realppn = ppnod
WHERE		realppn > ppnod AND 
			ABS(realppn)-ABS(ppnOD) > 0.03

UPDATE		#tmpNewAllTktCpn
SET			realppn = ppnOD
WHERE		realppn = 0 AND 
			ppnOD > 0

UPDATE		#tmpNewAllTktCpn
SET			ppnOD = 0
WHERE		ppnod IS NULL

UPDATE		#tmpNewAllTktCpn
SET			RealPPN = 0
WHERE		RealPPN IS NULL

UPDATE		#tmpNewAllTktCpn
SET			realppn = ppnod
WHERE		realppn > ppnod AND 
			ABS(realppn)-ABS(ppnOD) > 0.03

UPDATE		#tmpNewAllTktCpn
SET			realppn = ppnOD
WHERE		realppn = 0 AND 
			ppnOD > 0
================================================================================================================

BEGIN TRAN
UPDATE		dmtktcpn
SET			ppnOD = b.PPNod, RealTax = b.realPPN
FROM		dmtktcpn a 
			INNER JOIN #tmpNewAllTktCpn b
ON			b.ticketasal = a.ticketnumber AND
			b.fcasal = a.fc

COMMIT TRAN