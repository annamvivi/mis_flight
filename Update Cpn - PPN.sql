DROP TABLE	#tmptblkurs	
SELECT		* 
INTO		#tmptblkurs
FROM		sales.dbo.tblKurs
WHERE		tglKurs BETWEEN '24 Nov 2019' AND '26 Nov 2019'

UPDATE		#tmptblkurs
SET			CurrencyCode = 'MYR'
WHERE		CurrencyCode = 'RM'

UPDATE		dmtktcpn
SET			IDRIWJRRate = IWJR * Rate
FROM		dmsttrk a WITH(NOLOCK) 
			INNER JOIN dmtktcpn b WITH(NOLOCK)
ON			b.StKey = a.StKey 
			INNER JOIN #tmptblkurs c
ON			c.tglKurs = a.StationOpenDate AND
			c.CurrencyCode = a.StationCurr 
WHERE		a.stationopendate BETWEEN '24 Nov 2019' AND '26 Nov 2019'

=====================================================================================================================

DROP TABLE	#tmp1
SELECT		b.stkey, b.ticketnumber, b.tktppn, c.FareUpdate, c.FSurcharge, c.AdmKenaPPN, b.transcode, b.doctype, 
			b.PreConjTicket, c.fc, c.ppn, c.FareBasis, c.domIntlCode, c.PPNFsurcharge, c.ppnadm
INTO		#tmp1
FROM		dmsttrk a WITH(NOLOCK) INNER JOIN dmtkt b WITH(NOLOCK)
ON			b.stkey = a.stkey 
			INNER JOIN dmtktcpn c WITH(NOLOCK)
ON			c.stkey = b.stkey AND
			c.stkey = a.stkey AND
			c.ticketnumber = b.ticketnumber
WHERE		a.stationopendate BETWEEN '24 Nov 2019' AND '26 Nov 2019'AND
			b.transcode in ('SALE', 'EXCH') AND
			b.doctype in ('TKT') 
			--b.InsertDate > '29 Apr 2014'

DROP TABLE	#tmpconj
SELECT		b.stkey, b.ticketnumber,b.tktppn, c.FareUpdate, c.FSurcharge, c.AdmKenaPPN,b.transcode, b.doctype, 
			b.PreConjTicket, c.fc, c.ppn, c.FareBasis, c.DomIntlCode, c.PPNFsurcharge, c.ppnadm
INTO		#tmpconj
FROM		dmsttrk a WITH(NOLOCK) INNER JOIN dmtkt b WITH(NOLOCK)
ON			b.stkey = a.stkey 
			INNER JOIN dmtktcpn c WITH(NOLOCK)
ON			c.stkey = b.stkey AND
			c.stkey = a.stkey AND
			c.ticketnumber = b.ticketnumber 
WHERE		a.stationopendate BETWEEN '24 Nov 2019' AND '26 Nov 2019'AND
			b.transcode in ('SALE', 'EXCH') AND
			b.doctype in ('CNJ') 
			--b.InsertDate > '29 Apr 2014'

UPDATE		#tmpconj 
SET			tktppn = b.tktppn
FROM		#tmpconj a INNER JOIN dmtkt b WITH(NOLOCK)
ON			b.ticketnumber = a.PreConjTicket

--================================================================================================================================================================
--- KALO ADA NILAI KASIH TAU -------

SELECT		distinct a.* 
FROM		#tmpconj a INNER JOIN (SELECT * FROM #tmpconj) b
ON			b.ticketnumber = a.PreConjTicket 

UPDATE		#tmpconj 
SET			tktppn = b.tktppn
FROM		#tmpconj a,(select * from #tmpconj) b
WHERE		b.ticketnumber = a.PreConjTicket
--------------------------------------------------------------------------------------------------------------------------------------------------------------

DROP TABLE	#Tmpmax
SELECT		ticketnumber, fc = MAX(fc)
INTO		#tmpmax
FROM		#Tmp1
GROUP BY	ticketnumber

DROP TABLE	#tmpNewAllTktCpn
SELECT		stkey, ticketnumber, tktppn, FareUpdate, FSurcharge, AdmKenaPPN, transcode, doctype,ticketasal = ticketnumber, fc, fcasal = fc, ppn, FareBasis, domIntlCode, PPNFsurcharge, ppnadm
INTO		#tmpNewAllTktCpn
FROM		#Tmp1
UNION ALL
SELECT		stkey, ticketnumber = PreConjTicket, tktppn,FareUpdate, FSurcharge, AdmKenaPPN, transcode, doctype, ticketasal = a.ticketnumber, fc = a.fc + b.fc, 
			fcAsal = a.FC, PPN, FareBasis, DomIntlCode, PPNFsurcharge, ppnadm
FROM		#tmpconj a LEFT JOIN #tmpmax b
ON			b.ticketnumber = a.PreConjTicket

/*
select * from dmtkt where ticketnumber = '9902192286988'
select * from dmtktprice where ticketnumber = '9902192286988'
select * from #tmpNewAllTktCpn where ticketnumber = '9902192286988'

UPDATE		#tmpNewAllTktCpn 
SET			ticketnumber = 9902187870513, fc=8+fcasal 
WHERE		ticketnumber = 9902187870514
*/
--------------------------------------------------------------------------------------------------------------------------------------------------------------

UPDATE		#tmpNewAllTktCpn
SET			PPN = 0, PPNFsurcharge = 0, PPNAdm = 0
WHERE		tktppn = 0
--------------------------------------------------------------------------------------------------------------------------------------------------------------

UPDATE		#tmpNewAllTktCpn
SET			PPN = 0.1 * FareUpdate , PPNFsurcharge = 0.1 * ISNULL(fsurcharge,0), PPNAdm = 0.1 * ISNULL(admkenappn,0)
WHERE		TktPPN > 0 

--------------------------------------------------------------------------------------------------------------------------------------------------------------
--LOOPING

DROP TABLE	#TmptktPPN
SELECT		TicketNumber, tktPPN
INTO		#TmptktPPN
FROM		#tmpNewAllTktCpn 
WHERE		FC = 1
ORDER BY	TicketAsal

DROP TABLE	#TmpPPNupdate
SELECT		TicketNumber, PPNUpdate = (SUM(ISNULL(PPN,0)) + SUM(ISNULL(PPNFsurcharge,0)) + SUM(ISNULL(PPNAdm,0)))
INTO		#TmpPPNupdate
FROM		#tmpNewAllTktCpn 
GROUP BY	TicketNumber
ORDER BY	TicketNumber

DROP TABLE  #TmpPPNupdatetidaksama
SELECT		a.*, b.PPNUpdate 
INTO		#TmpPPNupdatetidaksama
FROM		#TmptktPPN a INNER JOIN #TmpPPNupdate b
ON			b.TicketNumber = a.TicketNumber			 ---HARUS KOSONG KALO TIDAK KOSONG JALANIN BAWAH 1 LOOPING, 2 LOOPING DST---
WHERE		b.PPNUpdate<> a.TktPPN
ORDER BY	a.TicketNumber

select * from #TmpPPNupdatetidaksama

--------------------------------------------------------------------------------------------------------------------------------------------------------------
/*
1.

UPDATE		#tmpNewAllTktCpn
SET			PPN = ROUND(ppn,0)
FROM		#TmpPPNupdatetidaksama a
			INNER JOIN #tmpNewAllTktCpn b
ON			b.TicketNumber = a.TicketNumber

-------------------------------------

2.

ALTER TABLE	#tmpPPNupdatetidaksama ADD selisih MONEY
----
UPDATE		#TmpPPNupdatetidaksama
SET			selisih = TktPPN - PPNUpdate

DROP TABLE	#tmpminFC
SELECT		a.TicketNumber, minFC = MIN(FC)
INTO		#tmpminFC 
FROM		#TmpPPNupdatetidaksama a 
			INNER JOIN #tmpNewAllTktCpn b
ON			b.TicketNumber = a.TicketNumber 
WHERE		b.FareBasis <> 'VOID' AND
			b.ppn <> 0
GROUP BY	a.TicketNumber
			
UPDATE		#tmpNewAllTktCpn
SET			PPN = ISNULL(PPN,0) + c.selisih
FROM		#tmpminFC a
			INNER JOIN #tmpNewAllTktCpn b
ON			b.TicketNumber = a.TicketNumber AND
			b.fc = a.minFC 			
			INNER JOIN #TmpPPNupdatetidaksama c
ON			c.TicketNumber = a.TicketNumber AND
			c.TicketNumber = b.TicketNumber
WHERE		b.farebasis <> 'VOID'
-------------------------------------------------------------
3.

ALTER TABLE	#tmpPPNupdatetidaksama ADD additional MONEY

DROP TABLE	#tmpFC
SELECT		a.TicketNumber, totalFC = count(FC)
INTO		#tmpFC 
FROM		#TmpPPNupdatetidaksama a 
			INNER JOIN #tmpNewAllTktCpn b
ON			b.TicketNumber = a.TicketNumber 
WHERE		b.FareBasis <> 'VOID' 
GROUP BY	a.TicketNumber
			
UPDATE		#tmpNewAllTktCpn
SET			PPN = round((ISNULL(b.tktPPN,0)/totalFC),2)
FROM		#tmpFC a
			INNER JOIN #tmpNewAllTktCpn b
ON			b.TicketNumber = a.TicketNumber	
			INNER JOIN #TmpPPNupdatetidaksama c
ON			c.TicketNumber = a.TicketNumber AND
			c.TicketNumber = b.TicketNumber	 AND
			b.farebasis <> 'VOID'		

*/

--------------------------------------------------------------------------------------------------------------------------------------------------------------

UPDATE		#tmpNewAllTktCpn 
SET			PPN = 0
WHERE		PPN IS NULL	

SELECT		* 
FROM		#tmpNewAllTktCpn
WHERE		PPN < 0	AND
			TktPPN > 0

UPDATE		#tmpNewAllTktCpn
SET			PPN = 0
WHERE		PPN < 0	AND
			TktPPN > 0
			
--------------------------------------------------------------------------------------------------------------------------------------------------------------

BEGIN TRAN
UPDATE		dmtktcpn
SET			PPN = b.PPN, PPNFsurcharge = b.PPNFsurcharge, PPNAdm = b.PPNAdm
FROM		dmtktcpn a	
			INNER JOIN #tmpNewAllTktCpn b
ON			b.ticketasal=a.ticketnumber AND
			b.fcasal=a.fc
			
COMMIT TRAN
