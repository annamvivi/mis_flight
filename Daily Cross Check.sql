--/* All Amount */

SELECT		DISTINCT StationOpenDate
FROM		tblStTRK with(nolock)
WHERE		insertdate > '27 Nov 2019' AND StationOpenDate <> '27 Nov 2019'
		
SELECT		MAX(DISTINCT insertdate) 
FROM		tblTktRfndPax
------------------------------------------------------------------------------------------------------------------------------------------------------------

UPDATE		tbltktcpn
SET			total = ISNULL(fareupdate,0) + ISNULL(fsurcharge,0) + ISNULL(IWJR,0) + ISNULL(adm,0) + ISNULL(Apotax,0) + ISNULL(PPN,0) + ISNULL(ppnfsurcharge,0) +
			ISNULL(admkenappn,0) + ISNULL(ppnadm,0)  + ISNULL(PPNOD,0) + ISNULL(PPnin,0)
FROM		tblsttrk a
			INNER JOIN tbltktcpn b
ON			b.StKey = a.StKey 
WHERE		a.StationOpenDate BETWEEN '24 Nov 2019' AND '26 Nov 2019'

------------------------------------------------------------------------------------------------------------------------------------------------------------

DROP TABLE	#tmp1
SELECT		b.ticketnumber,b.issueddate,b.intlcode,b.TktBaseFare,b.tktppn, b.tktppnOD, b.TktFSurcharge,b.tktIWJR,b.TktAdm,b.TktApoTax,b.TktAdmKenaPPN,b.tktppnIN,b.calctotal,b.rate,b.descr,fop,b.transcode,b.doctype,
			b.PreConjTicket,Curr=a.StationCurr,c.fc,c.FareUpdate,c.FSurcharge,c.IWJR,c.Adm,c.ApoTax,c.AdmKenaPPN,c.FareBasis,c.routeawal,c.routeakhir,c.domIntlCode, c.PPN, c.PPNOD, c.PPNAdm, c.PPNFsurcharge,c.ppnin,
			c.total
INTO		#tmp1
FROM		tblsttrk a WITH(NOLOCK) 
			INNER JOIN tbltkt b WITH(NOLOCK)
ON			b.StKey = a.StKey 
			INNER JOIN tbltktcpn c WITH(NOLOCK)
ON			c.StKey = b.StKey AND
			c.StKey = a.StKey AND
			c.TicketNumber = b.TicketNumber
WHERE		a.StationOpenDate BETWEEN '24 Nov 2019' AND '26 Nov 2019'AND 
			b.transcode IN ('SALE','EXCH') AND
			b.doctype IN ('TKT')

DROP TABLE	#tmpconj
SELECT		b.ticketnumber,b.issueddate,b.intlcode,b.TktBaseFare,b.tktppn, b.tktppnOD,b.TktFSurcharge,b.tktIWJR,b.TktAdm,b.TktApoTax,b.tktadmkenappn,b.tktppnin,b.calctotal,b.rate,b.descr,fop,b.transcode,b.doctype,
			b.PreConjTicket,Curr=a.StationCurr,c.fc,c.FareUpdate,c.FSurcharge,c.IWJR,c.Adm,c.ApoTax,c.admkenappn,c.FareBasis,c.routeawal,c.routeakhir,c.DomIntlCode, c.PPN, c.PPNOD, c.PPNAdm, c.PPNFsurcharge,c.ppnin, c.total
INTO		#tmpconj
FROM		tblsttrk a WITH(NOLOCK) 
			INNER JOIN tbltkt b WITH(NOLOCK)
ON			b.StKey = a.StKey 
			INNER JOIN tbltktcpn c WITH(NOLOCK)
ON			c.StKey = b.StKey AND
			c.StKey = a.StKey AND
			c.TicketNumber = b.TicketNumber
WHERE		a.StationOpenDate BETWEEN '24 Nov 2019' AND '26 Nov 2019'AND 
			b.transcode IN ('SALE','EXCH') AND
			b.doctype IN ('CNJ')
		
UPDATE		#tmpconj 
SET			tktIWJR = b.tktIWJR
FROM		#tmpconj a 
			INNER JOIN tbltkt b with(Nolock)
ON			b.ticketnumber = a.PreConjTicket

DROP TABLE	#Tmpmax
SELECT		ticketnumber,fc = MAX(fc)
INTO		#tmpmax
FROM		#Tmp1
GROUP BY	ticketnumber

DROP TABLE	#tmpNewAllTktCpn
SELECT		ticketnumber,issueddate,intlcode,Curr,fop,transcode,doctype,ticketasal=ticketnumber,fc,FCAsal=fc,TktBaseFare,TKTPPN,TKTPPNOD,TktFSurcharge,tktIWJR,TktAdm,TktApoTax,tktadmkenappn,tktppnin,calctotal,rate,
			FareUpdate,FSurcharge,IWJR,Adm,ApoTax,admkenappn,descr,FareBasis,RouteAwal,RouteAkhir,DomIntlCode, PPN, PPNOD, PPNAdm, PPNFsurcharge,ppnin, total
INTO		#tmpNewAllTktCpn
FROM		#Tmp1
UNION ALL
SELECT		ticketnumber=PreConjTicket,issueddate,intlcode,Curr,fop,transcode,doctype,ticketasal=a.ticketnumber,fc=a.fc + b.fc,
			fcAsal=a.FC,TktBaseFare,TKTPPN,TKTPPNOD,TktFSurcharge,tktIWJR,TktAdm,TktApoTax,tktadmkenappn,tktppnin,calctotal,rate,FareUpdate,FSurcharge,IWJR,Adm,ApoTax,AdmKenaPPN,a.descr,FareBasis,RouteAwal,RouteAkhir,DomIntlCode, 
			PPN, PPNOD, PPNAdm, PPNFsurcharge,ppnin, total
FROM		#tmpconj a 
			LEFT JOIN #tmpmax b
ON			b.ticketnumber = a.PreConjTicket

------------------------------------------------------------------------------------------------------------------------------------------------------------

DROP TABLE	#tmpz
SELECT		b.* 
INTO		#tmpz 
FROM		tblsttrk a WITH(NOLOCK)
			INNER JOIN tbltkt b WITH(NOLOCK)
ON			b.StKey = a.StKey 
WHERE		a.StationOpenDate BETWEEN '24 Nov 2019' AND '26 Nov 2019'AND 
			b.TransCode LIKE 'rf%'

DELETE		tbltktcpn 
FROM		#tmpz a
			INNER JOIN tbltktcpn b
ON			b.TicketNumber = a.TicketNumber
------------------------------------------------------------------------------------------------------------------------------------------------------------

DROP TABLE	#tmpzz
SELECT		b.* 
INTO		#tmpzz 
FROM		tblsttrk a WITH(NOLOCK)
			INNER JOIN tbltkt b WITH(NOLOCK)
ON			b.StKey = a.StKey 
WHERE		a.StationOpenDate BETWEEN '24 Nov 2019' AND '26 Nov 2019'AND 
			b.TransCode = 'SALE' AND 
			DocType = 'VOU'

DELETE		tbltktcpn 
FROM		#tmpzz a
			INNER JOIN tbltktcpn b
ON			b.TicketNumber = a.TicketNumber

------------------------------------------------------------------------------------------------------------------------------------------------------------

UPDATE		tbltkt
SET			AccAmount = ISNULL(TktBaseFare,0) + ISNULL(TktPPN,0) + ISNULL(TktFSurcharge,0) + ISNULL(TktIWJR,0) + 
			 ISNULL(TktApoTax,0) + ISNULL(tktadmkenappn,0) + ISNULL(tktppnOD,0) + ISNULL(tktppnIN,0)
FROM		tblStTRK a
			INNER JOIN tbltkt b
ON			b.StKey = a.StKey
WHERE		a.StationOpenDate BETWEEN '24 Nov 2019' AND '26 Nov 2019'AND 
			b.TransCode = 'SALE' AND 
			b.DocType IN ('TKT','CNJ')

UPDATE		tbltkt
SET			accadm = ISNULL(tktadm,0)
FROM		tblStTRK a
			INNER JOIN tbltkt b
ON			b.StKey = a.StKey
WHERE		a.StationOpenDate BETWEEN '24 Nov 2019' AND '26 Nov 2019'AND 
			b.TransCode = 'SALE' AND 
			b.DocType IN ('TKT','CNJ')


UPDATE		tbltkt
SET			AccAmount = 0, AccAdm = 0, TktBaseFare = 0, TktPPN = 0, TktFSurcharge = 0, TktIWJR = 0, TktKomisi = 0, TktAdm = 0, TktApoTax = 0, 
			TktPPNOD = 0, tktRefCancelFee = 0, tktRefUsedPort = 0, TotalTicketSale = 0, tktppnin = 0
FROM		tblsttrk a
			INNER JOIN tbltktcpn b
ON			b.StKey = a.StKey 
			INNER JOIN tbltkt c
ON			c.TicketNumber = b.TicketNumber AND
		    c.stkey = b.StKey AND
		    c.stkey = a.StKey	
WHERE		a.StationOpenDate BETWEEN '24 Nov 2019' AND '26 Nov 2019'AND 
			TransCode = 'VOID' 

----------------------------------------------------------------------------------

DROP TABLE	#tmpUpdate
SELECT		TicketNumber, TktBaseFare, TKTPPN, TKTPPNOD,TktFSurcharge, TktIWJR, TktAdm, TktApoTax,TktAdmKenaPPN,tktppnIN,calctotal,
			FareUpdate = SUM(ISNULL(FareUpdate,0)), FSurcharge = SUM(ISNULL(FSurcharge,0)),
			IWJR = SUM(ISNULL(IWJR,0)), Adm = SUM(ISNULL(Adm,0)), ApoTax = SUM(ISNULL(ApoTax,0)), AdmKenaPPN = SUM(ISNULL(admkenappn,0)),
			PPN = SUM(ISNULL(PPN,0)),PPNFsurcharge = SUM(ISNULL(PPNFsurcharge,0)),PPNadm = SUM(ISNULL(PPNadm,0)),PPNOD = SUM(ISNULL(PPNOD,0)),
			PPNIN= SUM(ISNULL(PPNIN,0)), Total = SUM(ISNULL(total,0))
INTO		#tmpUpdate
FROM		#tmpNewAllTktCpn
GROUP BY	TicketNumber, TktBaseFare, TKTPPN, TKTPPNOD,TktFSurcharge, TktIWJR, TktAdm, TktApoTax,TktAdmKenaPPN, calctotal, tktppnin
ORDER BY	TicketNumber, TktBaseFare, TKTPPN, TKTPPNOD,TktFSurcharge, TktIWJR, TktAdm, TktApoTax,TktAdmKenaPPN, calctotal, tktppnin

DROP TABLE	#tmpUpdate000
SELECT		TicketNumber, TktBaseFare = SUM(ISNULL(TktBaseFare,0)),TKTPPN = SUM(ISNULL(TKTPPN,0)),
			TKTPPNOD = SUM(ISNULL(TKTPPNOD,0)), TktFSurcharge = SUM(ISNULL(TktFSurcharge,0)),
			TktIWJR = SUM(ISNULL(TktIWJR,0)), TktAdm = SUM(ISNULL(TktAdm,0)), TktApoTax = SUM(ISNULL(TktApoTax,0)),
			TktAdmKenaPPN = SUM(ISNULL(TktAdmKenaPPN,0)),TKTPPNIN = SUM(ISNULL(TKTPPNIN,0)),CalcTotal = SUM(ISNULL(calctotal,0)),FareUpdate = SUM(ISNULL(FareUpdate,0)), FSurcharge = SUM(ISNULL(FSurcharge,0)),
			IWJR = SUM(ISNULL(IWJR,0)), Adm = SUM(ISNULL(Adm,0)), ApoTax = SUM(ISNULL(ApoTax,0)), AdmKenaPPN = SUM(ISNULL(admkenappn,0)),
			PPN = SUM(ISNULL(PPN,0)),PPNFsurcharge = SUM(ISNULL(PPNFsurcharge,0)),PPNadm = SUM(ISNULL(PPNadm,0)),PPNOD = SUM(ISNULL(PPNOD,0)),PPNIN = SUM(ISNULL(PPNIN,0)),
			total = sum(isnull(total,0))
INTO		#tmpUpdate000
FROM		#tmpUpdate
GROUP BY	TicketNumber
ORDER BY	TicketNumber

--------------------------------------------------------------------------------------------------------------------------------------------------

/* Ulang Proses 17 Fare*/ HARUS KOSONG

DROP TABLE	#tmpUpdate00
SELECT		*
INTO		#tmpUpdate00
FROM		#tmpUpdate000
WHERE		TktBaseFare <> FareUpdate

SELECT		a.StationOpenDate, b.TransCode, c.*
FROM		tblStTRK a WITH(NOLOCK) 
			INNER JOIN tbltkt b WITH(NOLOCK)
ON			b.StKey = a.StKey 
			INNER JOIN #tmpUpdate00 c WITH(NOLOCK) 
ON			c.ticketnumber = b.TicketNumber AND 
			b.fromtcn IS NULL

----------------------------------------------------------------------------------------------------------------
/* Ulang Proses 18 Fssurcharge */ HARUS KOSONG

DROP TABLE	#tmpUpdate00
SELECT		*
INTO		#tmpUpdate00
FROM		#tmpUpdate000
WHERE		TktFSurcharge <> FSurcharge

SELECT		* 
FROM		#tmpUpdate00

SELECT		DISTINCT StationOpenDate,TransCode,IssuedDate 
FROM		tblStTRK a WITH(NOLOCK) INNER JOIN tbltkt b WITH(NOLOCK) 
ON			b.stkey = a.stkey 
			INNER JOIN #tmpUpdate00 c WITH(NOLOCK)
ON			c.ticketnumber = b.TicketNumber AND 
			b.fromtcn IS NULL

----------------------------------------------------------------------

/* Ulang Proses 12 IWJR */ HARUS KOSONG ---

DROP TABLE	#tmpUpdate
SELECT		TicketNumber, tktIWJR, IWJR = SUM(IWJR)
INTO		#tmpUpdate
FROM		#tmpNewAllTktCpn
GROUP BY	TicketNumber, tktIWJR

DROP TABLE	#tmpUpdate00
SELECT		*
INTO		#tmpUpdate00
FROM		#tmpUpdate
WHERE		tktIWJR <> IWJR

SELECT		b.* 
FROM		tblStTRK a WITH(NOLOCK) INNER JOIN tbltkt b WITH(NOLOCK)
ON			b.StKey = a.StKey 
			INNER JOIN #tmpUpdate00 c WITH(NOLOCK)
ON			c.ticketnumber = b.TicketNumber AND 
			b.fromtcn IS NULL

------------------------------------------------------------------------
/* Ulang Proses 14,15 ADM */ HARUS KOSONG--

DROP TABLE	#tmpUpdate00
SELECT		*
INTO		#tmpUpdate00
FROM		#tmpUpdate000
WHERE		TktAdm <> Adm

SELECT		b.*  
FROM		tblStTRK a WITH(NOLOCK) 
			INNER JOIN tbltkt b WITH(NOLOCK)
ON			b.StKey = a.StKey 
			INNER JOIN #tmpUpdate00 c WITH(NOLOCK) 
ON			c.ticketnumber = b.TicketNumber AND 
			b.fromtcn IS NULL
			
-----------------------------------------------------------

/* Ulang Proses 13 ADMKENAPPN */ HARUS KOSONG

DROP TABLE	#tmpUpdate00
SELECT		*
INTO		#tmpUpdate00
FROM		#tmpUpdate000
WHERE		TktAdmKenaPPN <> AdmKenaPPN

SELECT		b.* 
FROM		tblStTRK a WITH(NOLOCK) 
			INNER JOIN tbltkt b WITH(NOLOCK)
ON			b.StKey = a.StKey 
			INNER JOIN #tmpUpdate00 c WITH(NOLOCK) 
ON			c.ticketnumber = b.TicketNumber AND 
			b.fromtcn IS NULL

-------------------------------------------------------------------------
/* Ulang Proses 19 PPN */ HARUS KOSONG 

DROP TABLE	#tmpUpdate00
SELECT		*
INTO		#tmpUpdate00
FROM		#tmpUpdate000
WHERE		TKTPPN <> (PPN + PPNFsurcharge+ PPNadm)

SELECT		*
FROM		tblStTRK a WITH(NOLOCK) INNER JOIN tbltkt b WITH(NOLOCK)
ON			b.StKey = a.StKey 
			INNER JOIN #tmpUpdate00 c WITH(NOLOCK)
ON			c.ticketnumber = b.TicketNumber AND 
			b.fromtcn IS NULL

------------------------------------------------------------------------
/* Ulang Proses 20 PPNOD */ HARUS KOSONG

DROP TABLE	#tmpUpdate00
SELECT		*
INTO		#tmpUpdate00
FROM		#tmpUpdate000
WHERE		TKTPPNOD <> PPNOD

SELECT		*
FROM		tblStTRK a WITH(NOLOCK) INNER JOIN tbltkt b WITH(NOLOCK)
ON			b.StKey = a.StKey 
			INNER JOIN #tmpUpdate00 c WITH(NOLOCK)
ON			c.ticketnumber = b.TicketNumber AND 
			b.fromtcn IS NULL
		
------------------------------------------------------------------------
/* Ulang Proses 21 PPNIN */ HARUS KOSONG

DROP TABLE	#tmpUpdate00
SELECT		*
INTO		#tmpUpdate00
FROM		#tmpUpdate000
WHERE		TKTPPNIN <> PPNIN

SELECT		b.*
FROM		tblStTRK a WITH(NOLOCK) INNER JOIN tbltkt b WITH(NOLOCK)
ON			b.StKey = a.StKey 
			INNER JOIN #tmpUpdate00 c WITH(NOLOCK)
ON			c.ticketnumber = b.TicketNumber AND 
			b.fromtcn IS NULL
-------------------------------------------------------------------------
/* Ulang Proses 16 APOTAX */ HARUS KOSONG---

DROP TABLE	#tmpUpdate00
SELECT		*
INTO		#tmpUpdate00
FROM		#tmpUpdate000
WHERE		TktApoTax <> ApoTax

SELECT		b.* 
FROM		tblStTRK a WITH(NOLOCK) INNER JOIN tbltkt b WITH(NOLOCK)
ON			b.StKey = a.StKey 
			INNER JOIN #tmpUpdate00 c WITH(NOLOCK)
ON			c.ticketnumber = b.TicketNumber AND 
			b.fromtcn IS NULL	
		
----------------------------------
/* Rapikan total */ HARUS KOSONG 

DROP TABLE	#tmpUpdate00
SELECT		*
INTO		#tmpUpdate00
FROM		#tmpUpdate000
WHERE		CalcTotal <> total

SELECT		b.* 
FROM		tblStTRK a WITH(NOLOCK) INNER JOIN tbltkt b WITH(NOLOCK)
ON			b.StKey = a.StKey 
			INNER JOIN #tmpUpdate00 c WITH(NOLOCK)
ON			c.ticketnumber = b.TicketNumber AND 
			b.fromtcn IS NULL	
------------------------------------------------------------------------
/* Ulang Proses 10 */	HARUS KOSONG

DROP TABLE	#tmpbeda
SELECT		a.*,b.TicketAsli 
INTO		#tmpbeda
FROM		tbltkt a WITH(NOLOCK)
			INNER JOIN tbltktcpn b WITH(NOLOCK)
ON			b.ticketnumber = a.ticketnumber
			INNER JOIN tblsttrk c WITH(NOLOCK)
ON			c.StKey = a.StKey
WHERE		c.stationopendate BETWEEN '24 Nov 2019' AND '26 Nov 2019'AND 
    		((b.routeawal IS NOT NULL AND b.routeawal IN (SELECT Route FROM sales.dbo.tblintlroute) ) OR
    		(b.routeakhir IS NOT NULL AND b.routeakhir IN (SELECT Route FROM sales.dbo.tblintlroute)) ) AND
    		ISNULL(intlcode,'D')='D' AND 
    		ISNULL(b.LionWingsCode,'') NOT IN ('SL','OD') AND
    		b.flightnumber NOT IN ('VOID ')
    	
--kalau di atas ada isi, baru jalanin ini buat cek
SELECT		a.TicketNumber,a.TicketAsli,a.IntlCode,b.IntlCode,b.DocType
FROM		#tmpbeda a
			INNER JOIN tbltkt b  WITH(NOLOCK)
ON			a.TicketAsli = b.TicketNumber
--------------------------------------------------
/* Ulang Proses 38 jika 0 */ TIDAK BOLE 0

select COUNT(*) from tblSummaryOffline where insertdate > '27 Nov 2019'
	
-------------------------------------------------------------------------

/* Ulang Proses 9 */	kosong

SELECT		*
FROM		tbltkt a WITH(NOLOCK) 
			INNER JOIN tbltktcpn b WITH(NOLOCK)
ON			b.StKey = a.StKey AND
			b.TicketNumber = a.TicketNumber 
			INNER JOIN tblsttrk c WITH(NOLOCK)
ON			c.StKey = b.StKey AND
			c.StKey = a.StKey 
WHERE		c.stationopendate BETWEEN '24 Nov 2019' AND '26 Nov 2019' AND dateofflight is null AND
farebasis <> 'VOID'
------------------------------------------------------------------------------

/* Ulang Proses 29 KALO ADA NILAI */	HARUS KOSONG


DROP TABLE  #tmpIntlcOdeRfnd
SELECT		a.* 
INTO		#tmpIntlcOdeRfnd
FROM		tbltkt a WITH(NOLOCK) 
			INNER JOIN tblStTRK b WITH(NOLOCK)
ON			b.StKey = a.StKey 
WHERE		(a.TransCode LIKE 'rf%' OR DocType IN ('VOU')) AND 
			b.stationopendate BETWEEN '24 Nov 2019' AND '26 Nov 2019'AND 
			a.IntlCode = 'D' 
		 
SELECT		*
FROM		#tmpIntlcOdeRfnd a 
			INNER JOIN tbltkt b WITH(NOLOCK)  
ON			b.TicketNumber = a.RefundTicket
WHERE		b.TransCode IN ('SALE','EXCH') AND
			b.IntlCode = 'I' AND
			b.IntlCode <> a.IntlCode 	
	
------------------------------------------------------------------------------
/* Ulang Proses 22 */	HARUS KOSONG

SELECT		*
FROM		tblsttrk a WITH(NOLOCK) 
			INNER JOIN tbltkt b WITH(NOLOCK)
ON			b.stkey = a.stkey
WHERE		a.StationOpenDate BETWEEN '24 Nov 2019' AND '26 Nov 2019'AND
			(b.kodedistrict IS NULL or b.KodeDistrict = '')
		
------------------------------------------------------------------------------
/* SALEDOCTYPE 28*/	HARUS KOSONG

SELECT		*
FROM		tblsttrk a WITH(NOLOCK) 
			INNER JOIN tbltkt b WITH(NOLOCK)
ON			b.stkey = a.stkey
WHERE		a.StationOpenDate BETWEEN '24 Nov 2019' AND '26 Nov 2019'AND
			(b.saledoctype IS NULL or b.saledoctype = '')

			
------------------------------------------------------------------------------

/* Ulang Proses 8 */	HARUS KOSONG

DROP TABLE	#tmpTktCpn
SELECT		c.*
INTO		#tmpTktCpn
FROM		tblsttrk a WITH(NOLOCK) INNER JOIN tbltkt b WITH(NOLOCK)
ON			b.StKey = a.StKey 
			INNER JOIN tbltktcpn c WITH(NOLOCK) 
ON			c.StKey = b.StKey AND
			c.StKey = a.StKey AND
			c.TicketNumber = b.TicketNumber 
WHERE		a.StationOpenDate BETWEEN '24 Nov 2019' AND '26 Nov 2019'
			--b.insertdate > '15 May 2015'

UPDATE		#tmpTktCpn
SET			lionwingscode = NULL,domintlcode = NULL

UPDATE		#tmpTktCpn
SET			lionwingscode = b.code, DomIntlCode = b.Type
FROM		#tmpTktCpn a INNER JOIN tblairlineroute b WITH(NOLOCK)
ON			b.flightno = CONVERT(NUMERIC(5,0),a.flightnumber) 
			INNER JOIN tbltkt c WITH(NOLOCK)
ON			c.ticketnumber = a.ticketnumber
WHERE		a.flightnumber NOT IN ('open','arnk','VOID') AND
			b.tglberlaku = (SELECT	 MAX(tglberlaku)
							FROM	 tblairlineroute e
							WHERE	 e.arr = b.arr AND
									 e.dep = b.dep AND
									 e.flightno = b.flightno AND
									 e.tglberlaku <= DATEADD(MONTH,1,c.issueddate)) AND
									 LEN(a.flightnumber) > 0  AND
									 ((b.Dep = a.RouteAwal AND b.Arr = a.RouteAkhir) OR
									 (b.Arr = a.RouteAwal AND b.Dep = a.RouteAkhir)) AND
									 a.lionwingscode IS NULL AND a.domintlcode IS NULL AND
									 NOT (a.routeawal = 'JED' OR a.routeakhir = 'JED')

UPDATE		#tmpTktCpn
SET			lionwingscode = '',domintlcode = 'I'
WHERE		(routeawal = 'JED' OR routeakhir = 'JED') AND
			lionwingscode IS NULL

SELECT		DISTINCT TicketNumber, FlightNumber, RouteAwal, RouteAkhir
FROM		#tmpTktCpn
WHERE		lionwingscode IS NULL AND
			FareFromDescr > 0 AND
			LEN(ISNULL(routeawal,'')) > 0 AND LEN(ISNULL(routeakhir,'')) > 0 AND
			LEN(ISNULL(flightnumber,'')) > 0 AND
			FlightNumber <> 'OPEN'

SELECT		a.*
FROM		tbltktcpn a INNER JOIN #tmpTktCpn b
ON			b.TicketNumber = a.TicketNumber AND
			b.FC = a.FC AND b.Airlines = a.Airlines
WHERE		b.LionWingsCode <> a.LionWingsCode AND
			b.FlightNumber NOT IN ('OPEN') AND
			LEN(b.FlightNumber) > 0 AND a.Airlines <> a.LionWingsCode

SELECT		a.*
FROM		tbltktcpn a INNER JOIN #tmpTktCpn b
ON			b.TicketNumber = a.TicketNumber AND
			b.FC = a.FC
WHERE		b.domintlcode <> a.domintlcode AND
			b.FlightNumber NOT IN ('OPEN') AND
			LEN(b.FlightNumber) > 0 AND a.Airlines <> a.LionWingsCode
--------------------------------------------------------------------------------------------------------
/* CEK CLASS */ TOLONG INFO KALO ADA NILAI -- JALANIN 27

SELECT		* 
FROM		tblsttrk a WITH(NOLOCK), tbltktcpn b WITH(NOLOCK), tbltkt c WITH(NOLOCK)
WHERE		b.stkey = a.stkey AND
			a.StationOpenDate BETWEEN '24 Nov 2019' AND '26 Nov 2019'AND
			b.Class IS NULL AND
			c.TicketNumber = b.TicketNumber AND
			c.transcode IN ('SALE','EXCH') AND
			c.DocType IN ('TKT','CNJ') AND
			b.FareBasis <> 'VOID' 
ORDER BY	c.FromTCN

SELECT		* 
FROM		tblsttrk a WITH(NOLOCK), tbltktcpn b WITH(NOLOCK), tbltkt c WITH(NOLOCK)
WHERE		b.stkey = a.stkey AND
			a.StationOpenDate BETWEEN '24 Nov 2019' AND '26 Nov 2019'AND
			b.Class = '' AND
			c.TicketNumber = b.TicketNumber AND
			c.transcode IN ('SALE','EXCH') AND
			c.DocType IN ('TKT','CNJ') AND
			b.FareBasis <> 'VOID' 
ORDER BY	c.FromTCN						

-------------------------------------------------------------------------------------------------------------------
-- HARUS KOSONG--

SELECT		b.*  
FROM		tblStTRK a WITH(NOLOCK)
			INNER JOIN tbltkt b WITH(NOLOCK)
ON			b.StKey = a.StKey 
WHERE		a.StationOpenDate BETWEEN '24 Nov 2019' AND '26 Nov 2019'AND
			ISNULL(b.TktBaseFare,0) + ISNULL(b.TktPPN,0) + ISNULL(TktFSurcharge,0) + ISNULL(TktIWJR,0) + 
			ISNULL(TktAdm,0) + ISNULL(TktApoTax,0) + ISNULL(TktPPNOD,0) + ISNULL(tktppnin,0) <> ISNULL(CalcTotal,0) AND
			b.TransCode NOT LIKE 'rf%' AND
			b.DocType <> 'VOU' 
			
SELECT		b.*  
FROM		tblStTRK a WITH(NOLOCK)
			INNER JOIN tbltkt b WITH(NOLOCK)
ON			b.StKey = a.StKey 
WHERE		a.StationOpenDate BETWEEN '24 Nov 2019' AND '26 Nov 2019'AND
			ISNULL(b.TktBaseFare,0) + ISNULL(b.TktPPN,0) + ISNULL(TktFSurcharge,0) + ISNULL(TktIWJR,0) + 
			ISNULL(TktAdm,0) + ISNULL(TktApoTax,0) + ISNULL(TktPPNOD,0) + ISNULL(tktrefcancelfee,0) + ISNULL(tktppnIN,0) <> ISNULL(CalcTotal,0) AND
			b.TransCode LIKE 'rf%' AND
			b.DocType <> 'VOU' 

SELECT		b.*  
FROM		tblStTRK a WITH(NOLOCK)
			INNER JOIN tbltkt b WITH(NOLOCK)
ON			b.StKey = a.StKey 
WHERE		a.StationOpenDate BETWEEN '24 Nov 2019' AND '26 Nov 2019'AND
			ISNULL(Accamount,0) + ISNULL(accadm,0) <> calctotal AND
			b.TransCode LIKE 'rf%' AND
			b.DocType <> 'VOU'	

========================================================================================================================================================
	
UPDATE		tbltkt
SET			tglselesaiproses = GETDATE()
FROM		tblsttrk a
			INNER JOIN tbltkt b
ON			b.StKey = a.StKey 
			INNER JOIN tblxo c
ON			convert(VARCHAR,c.ExchangeDocumentNumber) = b.RefundTicket			
WHERE		a.StationOpenDate BETWEEN '24 Nov 2019' AND '26 Nov 2019'AND
			b.tglselesaiproses IS NULL AND
			b.FromTCN IS NULL AND c.ProcessDate > '30 Mar 2019'

UPDATE		tbltkt
SET			tglselesaiproses = GETDATE()
FROM		tblsttrk a
			INNER JOIN tbltkt b
ON			b.StKey = a.StKey 
WHERE		a.StationOpenDate BETWEEN '24 Nov 2019' AND '26 Nov 2019'AND
			b.tglselesaiproses IS NULL AND
			b.FromTCN IS NULL AND
			b.TransCode IN ('SALE','VOID')
			
UPDATE		tbltkt
SET			tglselesaiproses = GETDATE()
FROM		tblsttrk a
			INNER JOIN tbltkt b
ON			b.StKey = a.StKey 
WHERE		a.StationOpenDate BETWEEN '24 Nov 2019' AND '26 Nov 2019'AND
			b.tglselesaiproses IS NULL AND
			b.FromTCN IS NULL AND
			b.DocType = 'CNJ'

UPDATE		tbltkt
set			tglselesaiproses = GETDATE()
FROM		tblsttrk a
			INNER JOIN tbltkt b
ON			b.StKey = a.StKey 
			INNER JOIN tblxo c
ON			convert(VARCHAR,c.ExchangeDocumentNumber) = b.RefundTicket		
WHERE		a.StationOpenDate BETWEEN '24 Nov 2019' AND '26 Nov 2019'AND
			b.tglselesaiproses IS NULL AND
			b.FromTCN IS NULL AND
			c.ProcessDate > '26 Nov 2019' AND
			b.TransCode = 'EXCH'
==================================================================================================================
DROP TABLE	#tmp1
SELECT		b.* 
INTO		#tmp1 
FROM		tblsttrk a WITH(NOLOCK), tbltkt b WITH(NOLOCK)
WHERE		b.stkey = a.StKey AND 
			a.StationOpenDate > '27 Nov 2019' AND
			b.DocType = 'CNJ' AND 
			TglSelesaiProses IS NULL

UPDATE		#tmp1
SET			TglSelesaiProses = b.tglselesaiproses
FROM		#tmp1 a, tbltkt b WITH(NOLOCK)
WHERE		b.TicketNumber = a.TicketNumber - 1

UPDATE		tbltkt 
SET			TglSelesaiProses = b.tglselesaiproses
FROM		tbltkt a, #tmp1 b
WHERE		b.TicketNumber = a.TicketNumber
==============================================================================================================================================================================================

/* Ulang proses 29 */
 --HARUS KOSONG

SELECT		b.ticketnumber 
FROM		tblsttrk a WITH(NOLOCK)
			INNER JOIN tbltktcpn b with(nolock)
ON			b.stkey = a.stkey
			INNER JOIN  tbltkt c with(nolock)
ON			c.TicketNumber = b.TicketNumber
WHERE		a.StationOpenDate BETWEEN '24 Nov 2019' AND '26 Nov 2019'AND
			b.Class IS NULL AND
			c.transcode IN ('SALE','EXCH') AND
			c.DocType IN ('TKT','CNJ') AND
			b.FareBasis <> 'VOID' 
			
SELECT		b.ticketnumber 
FROM		tblsttrk a WITH(NOLOCK)
			INNER JOIN tbltktcpn b with(nolock)
ON			b.stkey = a.stkey
			INNER JOIN  tbltkt c with(nolock)
ON			c.TicketNumber = b.TicketNumber
WHERE		a.StationOpenDate BETWEEN '24 Nov 2019' AND '26 Nov 2019'AND
			b.deptime IS NULL AND
			c.transcode IN ('SALE','EXCH') AND
			c.DocType IN ('TKT','CNJ') AND
			b.FareBasis <> 'VOID' 

SELECT		b.ticketnumber 
FROM		tblsttrk a WITH(NOLOCK)
			INNER JOIN tbltktcpn b with(nolock)
ON			b.stkey = a.stkey
			INNER JOIN  tbltkt c with(nolock)
ON			c.TicketNumber = b.TicketNumber
WHERE		a.StationOpenDate BETWEEN '24 Nov 2019' AND '26 Nov 2019'AND
			b.Class = '' AND
			c.transcode IN ('SALE','EXCH') AND
			c.DocType IN ('TKT','CNJ') AND
			b.FareBasis <> 'VOID' 

==============================================================================================================================================================================================

/* VOID HARUS 0 */

SELECT		b.ticketnumber 
FROM		tblsttrk a WITH(NOLOCK)
			INNER JOIN tbltktcpn b with(nolock)
ON			b.stkey = a.stkey
			INNER JOIN  tbltkt c with(nolock)
ON			c.TicketNumber = b.TicketNumber
WHERE		a.StationOpenDate BETWEEN '24 Nov 2019' AND '26 Nov 2019'AND
			c.transcode IN ('SALE','EXCH') AND
			c.DocType IN ('TKT','CNJ') AND
			b.FareBasis = 'VOID' AND
			b.total <> 0

--harus kosong--
drop table #tmp1
select b.* into #tmp1 from tblsttrk a with(nolock), tbltkt b with(nolock)
where b.stkey = a.stkey AND a.StationOpenDate BETWEEN '24 Nov 2019' AND '26 Nov 2019'AND
b.SALEDOCTYPE = 'DEPO'

select * from #tmp1 a, tbltkt b
where b.RefundTicket  = CONVERT(varchar,a.TicketNumber) AND
b.SALEDOCTYPE <> 'DEPO'

update tbltkt
set intlcode = 'D'
from tblsttrk a with(nolock), tbltkt b with(nolock)
where b.stkey = a.stkey AND a.StationOpenDate BETWEEN '24 Nov 2019' AND '26 Nov 2019'AND
b.SALEDOCTYPE = 'DEPO'

/*begin tran
update tbltkt
set saledoctype = 'DEPO'
where ticketnumber = '5131500708907'

update tbltkt
set saledoctype = 'DEPO'
where refundticket = '5131500708907'
commit
rollback */
		