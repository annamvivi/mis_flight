SELECT		DISTINCT StationOpenDate
FROM		dmsttrk
WHERE		stationopendate <> '27 Nov 2019'
-------------------------- jalan bareng ---------------------------------------------------------------------------------------------------------------------------

DROP TABLE	#tmp1
SELECT		b.ticketnumber,b.issueddate,b.intlcode,b.tktYRAdm,b.rate,b.descr,fop,b.transcode,b.doctype,
			b.PreConjTicket,Curr=a.StationCurr, CurrDec = a.StationCurrDec, c.fc,c.YRAdm,AdmUpdate=c.YRAdm,c.FareBasis,c.routeawal,c.routeakhir,c.domIntlCode, b.companycode,
			c.lionwingscode
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
SELECT		b.ticketnumber,b.issueddate,b.intlcode,b.tktYRAdm,b.rate,b.descr,fop,b.transcode,b.doctype,
			b.PreConjTicket,Curr=a.StationCurr,CurrDec = a.StationCurrDec, c.fc,c.YRAdm,AdmUpdate=c.YRAdm,c.FareBasis,c.routeawal,c.routeakhir,c.DomIntlCode, b.companycode,
			c.lionwingscode
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
SET			tktYRAdm = b.tktYRAdm
FROM		#tmpconj a INNER JOIN dmtkt b WITH(NOLOCK)
ON 			b.ticketnumber = a.PreConjTicket

------------------------------------------------------------------------------------------------------------------------------------------------------------
--================================================================================================================================================================
--- KALO ADA NILAI KASIH TAU -------

SELECT		DISTINCT a.* 
FROM		#tmpconj a INNER JOIN (SELECT * FROM #tmpconj) b
ON			b.ticketnumber = a.PreConjTicket
WHERE		a.tktYRAdm <> 0

-------------------------------------------------------------------------------------------------------------------------------------------------------------

/*
UPDATE		#tmpconj 
SET			tktYRAdm = b.tktYRAdm
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
SELECT		ticketnumber,issueddate,intlcode,Curr,CurrDec,fop,transcode,doctype,ticketasal=ticketnumber,fc,FCAsal=fc,tktYRAdm,rate,
			YRAdm,AdmUpdate,descr,FareBasis,RouteAwal,RouteAkhir,DomIntlCode, companycode, lionwingscode
INTO		#tmpNewAllTktCpn
FROM		#Tmp1
UNION ALL
SELECT		ticketnumber=PreConjTicket,issueddate,intlcode,Curr,CurrDec,fop,transcode,doctype,ticketasal=a.ticketnumber,fc=a.fc + b.fc,
			fcAsal=a.FC,tktYRAdm,rate,YRAdm,AdmUpdate,a.descr,FareBasis,RouteAwal,RouteAkhir,DomIntlCode, companycode, lionwingscode
FROM		#tmpconj a LEFT JOIN #tmpmax b
ON			b.ticketnumber = a.PreConjTicket

UPDATE		#tmpNewAllTktCpn 
SET			Admupdate = 0

ALTER TABLE	#tmpNewAllTktCpn ADD sudahupdate int default 0

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
update #tmpnewalltktcpn
set admupdate = NULL, sudahupdate = NULL

drop table #tmpkurs
select * into #tmpkurs
from sales.dbo.tblkurs

update #tmpkurs
set currencycode = 'MYR'
where currencycode = 'RM'

update #tmpnewalltktcpn
set admupdate = round(15000 / b.rate,2)
from #tmpnewalltktcpn a, #tmpkurs b
where domintlcode = 'D' AND companycode = 'INA' AND b.tglkurs = a.issueddate AND b.currencycode = a.curr AND
a.TKTYRAdm > 0 AND lionwingscode in ('','IW') AND farebasis <> 'VOID'

update #tmpnewalltktcpn
set admupdate = round(20000 / b.rate,2)
from #tmpnewalltktcpn a, #tmpkurs b
where domintlcode = 'D' AND companycode = 'INA' AND b.tglkurs = a.issueddate AND b.currencycode = a.curr AND
a.tktyradm >= 20000 AND lionwingscode in ('ID') AND farebasis <> 'VOID'

-------------------------------------------------------------------------------------------------------------------------------------

DROP TABLE	#tmpUpdate
SELECT		TicketNumber, TKTYRAdm, AdmUpdate = SUM(ISNULL(AdmUpdate,0))
INTO		#tmpUpdate
FROM		#tmpNewAllTktCpn
GROUP BY	TicketNumber, TKTYRAdm

DROP TABLE	#tmpUpdate00
SELECT		*
INTO		#tmpUpdate00
FROM		#tmpUpdate
WHERE		TKTYRAdm <> AdmUpdate

alter table #tmpupdate00 add selisih money

update #tmpupdate00
set selisih = tktyradm - admupdate

select * from #tmpupdate00
order by selisih desc

drop table #tmpfc 
select b.ticketnumber, jumlah = count(FC) 
into #tmpfc
from #tmpupdate00 a , #tmpnewalltktcpn b
where b.ticketnumber = a.ticketnumber AND 
b.admupdate IS NOT NULL AND b.domintlcode = 'D'
group by b.ticketnumber

alter table #tmpfc add additional money

update #tmpfc
set additional = selisih / jumlah
from #tmpfc a, #tmpupdate00 b
where b.ticketnumber = a.ticketnumber

update #tmpnewalltktcpn
set admupdate = isnull(admupdate,0) + additional
from #tmpnewalltktcpn a, #tmpfc b
where b.ticketnumber = a.ticketnumber AND a.admupdate IS NOT NULL AND domintlcode = 'D'
-------------------------------------------------------------------------------------------------------------------------------------

DROP TABLE	#tmpUpdate
SELECT		TicketNumber, TKTYRAdm, AdmUpdate = SUM(ISNULL(AdmUpdate,0))
INTO		#tmpUpdate
FROM		#tmpNewAllTktCpn
GROUP BY	TicketNumber, TKTYRAdm

DROP TABLE	#tmpUpdate00
SELECT		*
INTO		#tmpUpdate00
FROM		#tmpUpdate
WHERE		TKTYRAdm <> AdmUpdate

alter table #tmpupdate00 add selisih money

update #tmpupdate00
set selisih = tktyradm - admupdate

select * from #tmpupdate00
order by selisih desc

drop table #tmpfc 
select b.ticketnumber, jumlah = count(FC) 
into #tmpfc
from #tmpupdate00 a , #tmpnewalltktcpn b
where b.ticketnumber = a.ticketnumber AND 
 b.domintlcode = 'I' AND b.admupdate IS NULL
group by b.ticketnumber

select * from #tmpfc

alter table #tmpfc add additional money

select * from #tmpfc a, #tmpupdate00 b
where b.ticketnumber = a.ticketnumber

update #tmpfc
set additional = selisih / jumlah
from #tmpfc a, #tmpupdate00 b
where b.ticketnumber = a.ticketnumber

update #tmpnewalltktcpn
set admupdate = isnull(admupdate,0) + additional
from #tmpnewalltktcpn a, #tmpfc b
where b.ticketnumber = a.ticketnumber AND a.admupdate IS NULL AND a.domintlcode = 'I'
-------------------------------------------------------------------------------------------------------------------------------------

DROP TABLE  #tmpTktAdm
SELECT		DISTINCT a.TicketNumber, Jumlah = COUNT(*)
INTO		#tmpTktAdm
FROM		#tmpNewAllTktCpn a INNER JOIN #tmpUpdate00 b
ON			b.TicketNumber = a.TicketNumber
WHERE 		a.TKTYRAdm <> 0 AND
			a.FareBasis <> 'void' AND a.domintlcode = 'I' AND b.admupdate > 0
GROUP BY	a.TicketNumber

ALTER TABLE #tmpTktAdm ADD AdmUpdate money default 0
-------------------------------------------------------------------------------------------------------------------------------------
/* Update Adm */

UPDATE		#tmpTktAdm
SET			AdmUpdate = (c.TKTYRAdm - c.admupdate) / b.Jumlah
FROM		#tmpNewAllTktCpn a INNER JOIN #tmpTktAdm b
ON			b.TicketNumber = a.TicketNumber
			INNER JOIN #tmpupdate00 c
ON			c.ticketnumber = a.ticketnumber AND 
			c.ticketnumber = b.ticketnumber
where		a.TKTYRAdm <> 0 AND
			a.FareBasis <> 'VOID'

SELECT		DISTINCT a.AdmUpdate, b.*
FROM		#tmpTktAdm a INNER JOIN #tmpNewAllTktCpn b
ON			b.TicketNumber = a.TicketNumber
WHERE		a.AdmUpdate IS NOT NULL

UPDATE		#tmpNewAllTktCpn
SET 		AdmUpdate = b.AdmUpdate, sudahupdate = 1
FROM		#tmpNewAllTktCpn a INNER JOIN #tmpTktAdm b
ON			b.TicketNumber = a.TicketNumber
WHERE		a.TKTYRAdm <> 0 AND
			a.domintlcode = 'I' AND
			a.FareBasis <> 'VOID'

UPDATE		#tmpNewAllTktCpn
SET			AdmUpdate = ROUND(AdmUpdate, 0)
WHERE		CurrDec = 0

UPDATE		#tmpNewAllTktCpn
SET			AdmUpdate = ROUND(AdmUpdate, 2)
WHERE		CurrDec = 2

DROP TABLE	#tmpUpdateSelisihDec
SELECT		DISTINCT b.TicketNumber, b.TKTYRAdm
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
SET			Selisih = TKTYRAdm - AdmUpdate
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
SELECT		TicketNumber, TKTYRAdm
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

drop table #tmpadmtidaksama
SELECT		a.*, b.Admupdate
into		#tmpadmtidaksama
FROM		#TmptktAdm a INNER JOIN #TmpAdmupdate b
ON			b.TicketNumber = a.TicketNumber			 --- affected ke 3 => tidak boleh ada nilai/harus 0 (nol) ---
WHERE		b.Admupdate<> a.TKTYRAdm
ORDER BY	a.TicketNumber

--
select * FROM		#TmptktAdm a INNER JOIN #TmpAdmupdate b
ON			b.TicketNumber = a.TicketNumber			 --- affected ke 3 => tidak boleh ada nilai/harus 0 (nol) ---
WHERE		b.Admupdate<> a.TKTYRAdm
ORDER BY	a.TicketNumber



/*

alter table #tmpadmtidaksama add selisih money

update #tmpadmtidaksama set selisih = tktyradm - admupdate

drop table #tmpfc
select a.ticketnumber, MInFC = min(fc) 
into #tmpfc 
from #tmpnewalltktcpn a, #tmpadmtidaksama b
where b.ticketnumber = a.ticketnumber  AND b.admupdate <> 0
group by a.ticketnumber

update #tmpNewAllTktCpn
set admupdate = isnull(a.admupdate,0) + b.selisih
from #tmpNewAllTktCpn a, #tmpadmtidaksama b, #tmpfc c
where b.TicketNumber = a.TicketNumber AND 
c.TicketNumber = b.TicketNumber AND a.farebasis <> 'VOID' AND
c.MInFC = a.fc

*/


-------------------------------------------------------------------------------------------------------------------------------------------------

UPDATE		#tmpNewAllTktCpn
SET			Admupdate = 0 
WHERE		AdmUpdate IS NULL

------------------------------------------------------------------------------------------------------------------------

UPDATE	dmtktcpn
SET		YRAdm = b.AdmUpdate
FROM	dmtktcpn a INNER JOIN #tmpNewAllTktCpn b
ON		b.ticketAsal = a.ticketnumber AND 
		b.fcasal = a.fc
		INNER JOIN dmtkt c with(nolock)
ON		c.StKey = a.StKey AND 
		c.TicketNumber = a.TicketNumber AND
		c.TicketNumber = b.ticketasal 
		
UPDATE	dmtktcpn
SET		Adm = isnull(b.XXadm,0) + isnull(b.YRAdm,0)
FROM	dmsttrk a WITH(NOLOCK)
		INNER JOIN dmtktcpn b WITH(NOLOCK)
ON		b.stkey = a.stkey
		INNER JOIN dmtkt c  with(nolock)
ON		c.StKey = a.StKey AND 
		c.TicketNumber = b.TicketNumber 
WHERE	a.stationopendate BETWEEN '24 Nov 2019' AND '26 Nov 2019' 
	