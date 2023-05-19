DROP TABLE	#tmp1		
SELECT		b.stkey, b.ticketnumber, b.tktppnIN, c.FareUpdate, c.IWJR,c.Apotax, b.transcode, b.doctype, 
			b.preconjticket, c.fc, c.PPNIN, c.FareBasis, c.AirlineIntlCode, c.routeawal, c.routeakhir, b.Curr
INTO		#tmp1
FROM		dmsttrk a WITH(NOLOCK) INNER JOIN dmtkt b WITH(NOLOCK)
ON			b.stkey = a.stkey 
			INNER JOIN dmtktcpn c WITH(NOLOCK)
ON			c.stkey = b.stkey AND
			c.stkey = a.stkey AND
			c.ticketnumber = b.ticketnumber
WHERE		a.stationopendate BETWEEN '24 Nov 2019' AND '26 Nov 2019' AND
			b.transcode in ('SALE','EXCH') AND
			b.doctype in ('TKT')

DROP TABLE	#tmpconj
SELECT		b.stkey, b.ticketnumber,b.tktppnIN, c.FareUpdate, c.IWJR,c.Apotax,b.transcode, b.doctype, 
			b.preconjticket, c.fc, c.PPNIN, c.FareBasis, c.AirlineIntlCode, c.routeawal, c.routeakhir, b.Curr
INTO		#tmpconj
FROM		dmsttrk a WITH(NOLOCK) INNER JOIN dmtkt b WITH(NOLOCK)
ON			b.stkey = a.stkey 
			INNER JOIN dmtktcpn c WITH(NOLOCK)
ON			c.stkey = b.stkey AND
			c.stkey = a.stkey AND
			c.ticketnumber = b.ticketnumber 
WHERE		a.stationopendate BETWEEN '24 Nov 2019' AND '26 Nov 2019' AND
			b.transcode in ('SALE','EXCH') AND
			b.doctype in ('CNJ')

UPDATE		#tmpconj 
SET			tktPPNIN = b.tktPPNIN
FROM		#tmpconj a INNER JOIN dmtkt b WITH(NOLOCK)
ON			b.ticketnumber = a.preconjticket

================================================================================================================================================================
--- KALO ADA NILAI KASIH TAU -------

SELECT		distinct a.* --into #tmpalson
FROM		#tmpconj a INNER JOIN (SELECT * FROM #tmpconj) b
ON			b.ticketnumber = a.preconjticket 

UPDATE		#tmpconj 
SET			tktPPNIN = b.tktPPNIN
FROM		#tmpconj a,(select * from #tmpconj) b
WHERE		b.ticketnumber = a.preconjticket

--------------------------------------------------------------------------------------------------------------------------------------------------------------
/*
UPDATE #tmpconj 
SET TktPPNIN = b.TktPPNIN
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
SELECT		stkey, ticketnumber, tktppnIN, FareUpdate, IWJR, Apotax, transcode, doctype,ticketasal = ticketnumber, fc, fcasal = fc, ppnIN, FareBasis, AirlineIntlCode, RouteAwal, routeakhir, curr
INTO		#tmpNewAllTktCpn
FROM		#Tmp1
UNION ALL
SELECT		stkey, ticketnumber = preconjticket, tktppnIN,FareUpdate, IWJR, Apotax, transcode, doctype, ticketasal = a.ticketnumber, fc = a.fc + b.fc, 
			fcAsal = a.FC, PPNIN, FareBasis, AirlineIntlCode, RouteAwal, routeakhir, curr
FROM		#tmpconj a LEFT JOIN #tmpmax b
ON			b.ticketnumber = a.preconjticket
	

--begin tran
--drop table #tmpalson2
--select a.ticketnumber, maxfc= max(b.fc) into #tmpalson2 from #tmpalson a, #tmpnewAllTktCpn b
--where b.ticketnumber = a.ticketnumber-2 
--group by a.ticketnumber

--rollback

--begin tran
--update #tmpnewAllTktCpn
--set ticketnumber = a.ticketnumber-2, FC = maxfc + 1
--from #tmpalson2 a, #tmpnewAllTktCpn b
--where b.ticketnumber = a.ticketnumber-1 

/*

select * from #tmpalson a, #tmpnewalltktcpn b
where b.ticketnumber = a.ticketnumber-1 

begin tran
update #tmpnewalltktcpn
set ticketnumber = a.ticketnumber-2, fc = 9
from #tmpalson a, #tmpnewalltktcpn b
where b.ticketnumber = a.ticketnumber-1 

commit
*/

/*

select * from dmtkt where ticketnumber =8162104262322

SELECT * FROM #tmpNewAllTktCpn WHERE ticketnumber  =  9902172387931
SELECT * FROM #tmpNewAllTktCpn WHERE ticketnumber  =  9902172387932
SELECT * FROM #tmpNewAllTktCpn WHERE ticketnumber  =  9902172387933


UPDATE		#tmpNewAllTktCpn 
SET			ticketnumber = 9902187870513, fc=8+fcasal 
WHERE		ticketnumber = 9902187870514

UPDATE		#tmpNewAllTktCpn 
SET			ticketnumber = 8162109799318, fc= 8 + fcasal
WHERE		ticketnumber = 8162109799319

UPDATE		#tmpNewAllTktCpn 
SET			ticketnumber = 8162109254130, fc= 8 + fcasal
WHERE		ticketnumber = 8162109254131

UPDATE		#tmpNewAllTktCpn 
SET			ticketnumber = 8162109254130, fc= 12 + fcasal
WHERE		ticketnumber = 8162109254132

UPDATE		#tmpNewAllTktCpn 
SET			ticketnumber = 8162109125743, fc= 8 + fcasal
WHERE		ticketnumber = 8162109125744

UPDATE		#tmpNewAllTktCpn 
SET			ticketnumber = 8162109125743, fc= 12 + fcasal
WHERE		ticketnumber = 8162109125745


*/
--------------------------------------------------------------------------------------------------------------------------------------------------------------

UPDATE		#tmpNewAllTktCpn
SET			tktppnIN = 0
WHERE		tktppnIN IS NULL

UPDATE		#tmpNewAllTktCpn
SET			PPNIN = 0
WHERE		tktppnIN = 0

SELECT		*	
FROM		#tmpNewAllTktCpn a, sales.dbo.tblMasterDistrict b
WHERE		b.Kodedistrict = a.RouteAwal AND 
			b.Country = 'INDIA' AND
			a.tktppnIN > 0

UPDATE		#tmpNewAllTktCpn
SET			PPNIN = ROUND((0.06 * (FareUpdate + IWJR + Apotax)),2)
FROM		#tmpNewAllTktCpn a, sales.dbo.tblMasterDistrict b
WHERE		b.Kodedistrict = a.RouteAwal AND 
			b.Country = 'INDIA' AND
			a.tktppnIN > 0 AND
			a.airlineintlcode = 'D' AND 
			a.FareBasis <> 'VOID'
			
UPDATE		#tmpNewAllTktCpn
SET			PPNIN = ROUND((0.06 * (Apotax)),2)
FROM		#tmpNewAllTktCpn a, sales.dbo.tblMasterDistrict b
WHERE		b.Kodedistrict = a.RouteAwal AND 
			b.Country = 'INDIA' AND
			a.tktppnIN > 0 AND
			a.airlineintlcode = 'I' AND 
			a.FareBasis <> 'VOID'

ALTER TABLE	#tmpNewAllTktCpn ADD RealPPN MONEY
--------------------------------------------------------------------------------------------------------------------------------------------------------------
--LOOPING

DROP TABLE	#TmptktPPNIN --looping 3, looping 5.1
SELECT		TicketNumber, tktppnIN, curr
INTO		#TmptktPPNIN
FROM		#tmpNewAllTktCpn 
WHERE		FC = 1
ORDER BY	TicketAsal

DROP TABLE	#TmpPPNupdate
SELECT		TicketNumber, PPNINUpdate =SUM(ISNULL(PPNIN,0)), curr
INTO		#TmpPPNupdate
FROM		#tmpNewAllTktCpn 
GROUP BY	TicketNumber, curr
ORDER BY	TicketNumber, curr  

DROP TABLE  #tmpPPNINTidakSama
SELECT		a.*, b.PPNINUpdate
INTO		#tmpPPNINTidakSama
FROM		#TmptktPPNIN a INNER JOIN #TmpPPNupdate b
ON			b.TicketNumber = a.TicketNumber			 
WHERE		b.PPNINUpdate<> a.tktPPNIN
ORDER BY	a.TicketNumber

SELECT		*	
FROM		#tmpPPNINTidakSama --- HARUS KOSONG
-----------------------------------------------------------------------------------------			
/*
1.

DROP TABLE	#tmpSALE
SELECT		a.TicketNumber, b.tktPPNIN,totaltiket = COUNT(*)
INTO		#tmpSALE
FROM		#tmpPPNINTidakSama  a, #tmpNewAllTktCpn b
WHERE		b.TicketNumber = a.TicketNumber AND
			b.TransCode IN ('SALE','EXCH') AND 
			PPNIN IS NULL AND 
			b.RouteAwal IN (SELECT kodedistrict FROM sales.dbo.tblMasterDistrict WHERE Country = 'INDIA')
GROUP BY	a.TicketNumber, b.tktPPNIN

DELETE		#tmpSALE 
WHERE		totaltiket > 1
			
UPDATE		#tmpNewAllTktCpn
SET			PPNIN = b.tktPPNIN, realppn = b.tktPPNIN
FROM		#tmpPPNINTidakSama  a, #tmpNewAllTktCpn b, #tmpSALE c
WHERE		b.TicketNumber = a.TicketNumber AND
			b.TransCode IN ('SALE','EXCH') AND 
			b.PPNIN IS NULL AND 
			b.RouteAwal IN (SELECT kodedistrict FROM sales.dbo.tblMasterDistrict WHERE Country = 'INDIA') AND
			c.TicketNumber = a.TicketNumber AND
			c.TicketNumber = b.TicketNumber AND
			FareBasis <> 'VOID'

-----------------------------------------------------------------------------------------			
2.

UPDATE		#tmpnewalltktcpn
SET			PPNIN = b.PPNIN, realppn = b.realtax
FROM		#tmpnewalltktcpn a, dmtktcpn b, #tmpPPNINTidakSama c
WHERE		b.TicketNumber = a.TicketNumber AND 
			b.FC = a.fc AND 
			c.TicketNumber = a.TicketNumber AND 
			c.TicketNumber = b.TicketNumber AND 
			b.PPNIN IS NOT NULL

---------------------------------------------------------------------

DROP TABLE	#tmpexch
SELECT		a.TicketNumber, b.tktPPNIN,totaltiket = COUNT(*), additional = CONVERT(money,NULL)
INTO		#tmpexch
FROM		#tmpPPNINTidakSama  a, #tmpNewAllTktCpn b
WHERE		b.TicketNumber = a.TicketNumber AND
			b.TransCode IN ('SALE','EXCH') AND 
			b.routeawal IN (SELECT kodedistrict FROM sales.dbo.tblmasterdistrict WHERE country = 'INDIA') AND
			farebasis <> 'VOID'
GROUP BY	a.TicketNumber, b.tktPPNIN

UPDATE		#tmpexch 
SET			additional = ROUND((tktPPNIN / totaltiket),2)

UPDATE		#tmpNewAllTktCpn
SET			PPNIN = c.additional, realppn = c.additional
FROM		#tmpPPNINTidakSama  a, #tmpNewAllTktCpn b, #tmpexch c
WHERE		b.TicketNumber = a.TicketNumber AND
			b.TransCode IN ('SALE','EXCH') AND 
			b.routeawal IN (SELECT kodedistrict FROM sales.dbo.tblmasterdistrict WHERE country = 'INDIA') AND
			c.TicketNumber = a.TicketNumber AND
			c.TicketNumber = b.TicketNumber  AND 
			farebasis <> 'VOID'

*/
================================================================================================================

UPDATE		#tmpNewAllTktCpn
SET			realppn = PPNIN
WHERE		realppn > PPNIN AND 
			ABS(realppn) - ABS(PPNIN) > 0.03

UPDATE		#tmpNewAllTktCpn
SET			realppn = PPNIN
WHERE		realppn = 0 AND 
			PPNIN > 0

UPDATE		#tmpNewAllTktCpn
SET			PPNIN = 0
WHERE		PPNIN IS NULL

UPDATE		#tmpNewAllTktCpn
SET			RealPPN = 0
WHERE		RealPPN IS NULL

UPDATE		#tmpNewAllTktCpn
SET			realppn = PPNIN
WHERE		realppn > PPNIN AND 
			ABS(realppn)-ABS(PPNIN) > 0.03

================================================================================================================

UPDATE		dmtktcpn
SET			PPNIN = b.PPNIN, RealTax = b.realPPN
FROM		dmtktcpn a INNER JOIN #tmpNewAllTktCpn b
ON			b.ticketasal = a.ticketnumber AND
			b.fcasal = a.fc
