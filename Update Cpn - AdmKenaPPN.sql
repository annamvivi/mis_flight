SELECT		DISTINCT StationOpenDate
FROM		dmsttrk
WHERE		stationopendate <> '27 Nov 2019'
-------------------------- jalan bareng ---------------------------------------------------------------------------------------------------------------------------

DROP TABLE	#tmp1
SELECT		b.ticketnumber,b.issueddate,b.intlcode,b.tktadmkenaPPN,b.rate,b.descr,fop,b.transcode,b.doctype,
			b.PreConjTicket,Curr=a.StationCurr, CurrDec = a.StationCurrDec, c.fc,c.Adm,AdmUpdate=c.Adm,c.FareBasis,c.routeawal,c.routeakhir,c.lionwingscode,c.domIntlCode
INTO		#tmp1
FROM		dmsttrk a WITH(NOLOCK) INNER JOIN dmtkt b WITH(NOLOCK)
ON			b.stkey = a.stkey  
			INNER JOIN dmtktcpn c WITH(NOLOCK)
ON			c.stkey = b.stkey AND
			c.stkey = a.stkey AND
			c.ticketnumber = b.ticketnumber
WHERE		a.stationopendate BETWEEN '24 Nov 2019' AND '26 Nov 2019' AND
			b.transcode IN ('SALE','EXCH') AND
			b.doctype IN ('TKT') 
		
UPDATE		#tmp1 
SET			AdmUpdate = 0

DROP TABLE	#tmpconj
SELECT		b.ticketnumber,b.issueddate,b.intlcode,b.tktadmkenaPPN,b.rate,b.descr,fop,b.transcode,b.doctype,
			b.PreConjTicket,Curr=a.StationCurr,CurrDec = a.StationCurrDec, c.fc,c.Adm,AdmUpdate=c.Adm,c.FareBasis,c.routeawal,c.routeakhir,c.lionwingscode,c.domIntlCode
INTO		#tmpconj
FROM		dmsttrk a WITH(NOLOCK) INNER JOIN dmtkt b WITH(NOLOCK)
ON			b.stkey = a.stkey
			INNER JOIN dmtktcpn c WITH(NOLOCK)
ON			c.stkey = b.stkey AND
			c.stkey = a.stkey AND
			c.ticketnumber = b.ticketnumber
WHERE		a.stationopendate BETWEEN '24 Nov 2019' AND '26 Nov 2019' AND
			b.transcode IN ('SALE','EXCH') AND
			b.doctype IN ('CNJ') 

UPDATE		#tmpconj 
SET			tktadmkenaPPN = b.tktadmkenaPPN
FROM		#tmpconj a INNER JOIN dmtkt b with(nolock)
ON 			b.ticketnumber = a.PreConjTicket


------------------------------------------------------------------------------------------------------------------------------------------------------------
--================================================================================================================================================================
--- KALO ADA NILAI KASIH TAU -------

SELECT		DISTINCT a.* 
FROM		#tmpconj a INNER JOIN (SELECT * FROM #tmpconj) b
ON			b.ticketnumber = a.PreConjTicket
WHERE		a.tktadmkenaPPN <> 0
--------------------------------------------------------------------------------------------------------------------------------------------------------------

/*
UPDATE		#tmpconj 
SET			tktadmkenaPPN = b.tktadmkenaPPN
FROM		#tmpconj a,(select * from #tmpconj) b
WHERE		b.ticketnumber = a.PreConjTicket

SELECT		*
FROM		#tmpconj
*/


DROP TABLE	#Tmpmax
SELECT		ticketnumber,fc = MAX(fc)
INTO		#tmpmax
FROM		#Tmp1
GROUP BY	ticketnumber

DROP TABLE	#tmpNewAllTktCpn
SELECT		ticketnumber,issueddate,intlcode,Curr,CurrDec,fop,transcode,doctype,ticketasal=ticketnumber,fc,FCAsal=fc,tktadmkenaPPN,rate,
			Adm,AdmUpdate,descr,FareBasis,RouteAwal,RouteAkhir,lionwingscode,DomIntlCode
INTO		#tmpNewAllTktCpn
FROM		#Tmp1
UNION ALL
SELECT		ticketnumber=PreConjTicket,issueddate,intlcode,Curr,CurrDec,fop,transcode,doctype,ticketasal=a.ticketnumber,fc=a.fc + b.fc,
			fcAsal=a.FC,tktadmkenaPPN,rate,Adm,AdmUpdate,a.descr,FareBasis,RouteAwal,RouteAkhir,lionwingscode,DomIntlCode
FROM		#tmpconj a LEFT JOIN #tmpmax b
ON			b.ticketnumber = a.PreConjTicket

ALTER TABLE	#tmpNewAllTktCpn ADD sudahupdate int default 0

drop table #tmpkurs
select * into #tmpkurs from sales.dbo.tblkurs

update #tmpkurs
set CurrencyCode = 'MYR'
where CurrencyCode = 'RM'

update #tmpNewAllTktCpn
set admupdate = '20000' / b.rate
from #tmpNewAllTktCpn a, #tmpkurs b
where b.tglKurs = a.IssuedDate AND b.CurrencyCode = a.Curr AND LionWingsCode = 'ID' AND TktAdmKenaPPN > 0

update #tmpNewAllTktCpn
set admupdate = '60000' / b.rate
from #tmpNewAllTktCpn a, #tmpkurs b
where b.tglKurs = a.IssuedDate AND b.CurrencyCode = a.Curr AND LionWingsCode in ('','IW') AND TktAdmKenaPPN > 0

update #tmpNewAllTktCpn
set admupdate = '60000' 
where AdmUpdate = 0 AND LionWingsCode in ('','IW') AND TktAdmKenaPPN > 0

update #tmpNewAllTktCpn
set admupdate = '20000' 
where AdmUpdate = 0 AND LionWingsCode in ('ID') AND TktAdmKenaPPN > 0

/*
select * from #tmpNewAllTktCpn where ticketnumber = '9902145695370'
select * from #tmpNewAllTktCpn where ticketnumber = '9902145695371'
select * from #tmpNewAllTktCpn where ticketnumber = '9902145695372'

UPDATE		#tmpNewAllTktCpn 
SET			ticketnumber = 9902186762593, fc=8+fcasal 
WHERE		ticketnumber = 9902186762594
*/	


=====================================================================================================================================================================
/* GOOO */

DROP TABLE	#tmpUpdate
SELECT		TicketNumber, tktadmkenaPPN, AdmUpdate = SUM(ISNULL(AdmUpdate,0))
INTO		#tmpUpdate
FROM		#tmpNewAllTktCpn
GROUP BY	TicketNumber, tktadmkenaPPN

DROP TABLE	#tmpUpdate00
SELECT		*
INTO		#tmpUpdate00
FROM		#tmpUpdate
WHERE		tktadmkenaPPN <> AdmUpdate

DROP TABLE  #tmpTktAdm
SELECT		DISTINCT a.TicketNumber, Jumlah = COUNT(*)
INTO		#tmpTktAdm
FROM		#tmpNewAllTktCpn a INNER JOIN #tmpUpdate00 b
ON			b.TicketNumber = a.TicketNumber
WHERE 		a.tktadmkenaPPN <> 0 AND
			a.FareBasis <> 'void'
GROUP BY	a.TicketNumber

ALTER TABLE #tmpTktAdm ADD AdmUpdate money default 0

-------------------------------------------------------------------------------------------------------------------------------------
/* Update Adm */

UPDATE		#tmpTktAdm
SET			AdmUpdate = a.tktadmkenaPPN / b.Jumlah
FROM		#tmpNewAllTktCpn a INNER JOIN #tmpTktAdm b
ON			b.TicketNumber = a.TicketNumber
where		a.tktadmkenaPPN <> 0 AND
			a.FareBasis <> 'VOID'

SELECT		DISTINCT a.AdmUpdate, b.*
FROM		#tmpTktAdm a INNER JOIN #tmpNewAllTktCpn b
ON			b.TicketNumber = a.TicketNumber
WHERE		a.AdmUpdate IS NOT NULL

UPDATE		#tmpNewAllTktCpn
SET 		AdmUpdate = b.AdmUpdate, sudahupdate = 1
FROM		#tmpNewAllTktCpn a INNER JOIN #tmpTktAdm b
ON			b.TicketNumber = a.TicketNumber
WHERE		a.tktadmkenaPPN <> 0 AND
			a.FareBasis <> 'VOID'

UPDATE		#tmpNewAllTktCpn
SET			AdmUpdate = ROUND(AdmUpdate, 0)
WHERE		CurrDec = 0

UPDATE		#tmpNewAllTktCpn
SET			AdmUpdate = ROUND(AdmUpdate, 2)
WHERE		CurrDec = 2
--------------------------------------------------------------
DROP TABLE	#tmpUpdateSelisihDec
SELECT		DISTINCT b.TicketNumber, b.tktadmkenaPPN
INTO		#tmpUpdateSelisihDec
FROM		#tmpTktAdm a INNER JOIN #tmpNewAllTktCpn b
ON			b.TicketNumber = a.TicketNumber
WHERE		a.AdmUpdate <> 0

ALTER TABLE #tmpUpdateSelisihDec ADD Selisih money default 0

DROP TABLE  #tmpUpdateSelisihDec001
SELECT		DISTINCT b.TicketNumber, AdmUpdate = SUM(ISNULL(b.AdmUpdate,0))
INTO		#tmpUpdateSelisihDec001
FROM		#tmpTktAdm a INNER JOIN #tmpNewAllTktCpn b
ON			b.TicketNumber = a.TicketNumber 
WHERE		a.AdmUpdate <> 0
GROUP BY	b.TicketNumber
ORDER BY	b.TicketNumber

UPDATE		#tmpUpdateSelisihDec
SET			Selisih = tktadmkenaPPN - AdmUpdate
FROM		#tmpUpdateSelisihDec a INNER JOIN #tmpUpdateSelisihDec001 b
ON			b.TicketNumber = a.TicketNumber

DROP TABLE	#tmpTktMinFC
SELECT		a.TicketNumber, FC = MIN(a.FC)
INTO		#tmpTktMinFC
FROM		#tmpNewAllTktCpn a INNER JOIN #tmpUpdateSelisihDec b
ON			b.TicketNumber = a.TicketNumber
GROUP BY	a.TicketNumber
ORDER BY	a.TicketNumber

UPDATE		#tmpNewAllTktCpn
SET			AdmUpdate = AdmUpdate + Selisih
FROM		#tmpNewAllTktCpn a INNER JOIN #tmpUpdateSelisihDec b
ON			b.TicketNumber = a.TicketNumber 
			INNER JOIN #tmpTktMinFC c
ON			c.TicketNumber = b.TicketNumber AND
			c.TicketNumber = a.TicketNumber AND
			c.FC = a.FC

--------------------------------------------------------------------------------------------------------------------------------------

DROP TABLE	#TmptktAdm
SELECT		TicketNumber, tktadmkenaPPN
INTO		#TmptktAdm
FROM		#tmpNewAllTktCpn 
WHERE		FC = 1
ORDER BY	TicketAsal

DROP TABLE	#TmpAdmupdate
SELECT		TicketNumber, Admupdate =SUM(ISNULL(Admupdate,0))
INTO		#TmpAdmupdate
FROM		#tmpNewAllTktCpn 
GROUP BY	TicketNumber
ORDER BY	TicketNumber

SELECT		a.*, b.Admupdate 
FROM		#TmptktAdm a INNER JOIN #TmpAdmupdate b
ON			b.TicketNumber = a.TicketNumber			 --- affected ke 3 => tidak boleh ada nilai/harus 0 (nol) ---
WHERE		b.Admupdate<> a.tktadmkenaPPN
ORDER BY	a.TicketNumber

-------------------------------------------------------------------------------------------------------------------------------------------------

UPDATE		#tmpNewAllTktCpn
SET			Admupdate = 0 
WHERE		AdmUpdate IS NULL
------------------------------------------------------------------------------------------------------------------------
UPDATE	dmtktcpn
SET		admkenappn = b.AdmUpdate
FROM	dmtktcpn a INNER JOIN #tmpNewAllTktCpn b
ON		b.ticketAsal = a.ticketnumber AND 
		b.fcasal = a.fc 
		INNER JOIN dmtkt c with(nolock)
ON		c.StKey = a.StKey AND 
		c.TicketNumber = a.TicketNumber AND
		c.TicketNumber = b.ticketasal 
	
	
