TRUNCATE TABLE  tblrfndcpnsementara

DROP TABLE	#tmp1
SELECT		distinct b.transcode, b.RefundTicket, b.RfndCpn, b.TicketNumber, b.stkey
INTO		#tmp1
FROM		tblsttrk a WITH(NOLOCK), tbltkt b WITH(NOLOCK)
where		b.stkey = a.stkey AND
			a.stationopendate BETWEEN '24 Nov 2019' AND '26 Nov 2019' AND
			b.TransCode like 'rf%'
				
DELETE		tblrfndcpn
FROM		tblrfndcpn a, #tmp1 b
WHERE		b.ticketnumber = a.ticketnumber AND 
			b.StKey = a.stkey AND
			b.RefundTicket = a.RefundTicket

/* VOUCHER	
drop table #tmp1 
select transcode,ticketnumber, stkey, RefundTicket into #tmp1 from tbltkt with(nolock)
where IssuedDate between '1 Mar 2018' AND '21 Sep 2018' AND
TransCode like 'RF%' 

delete #tmp1  from #tmp1 a, tblrfndcpn b with(nolock)
where b.TicketNumber = a.TicketNumber AND b.StKey = a.StKey
*/

DROP TABLE	#tmprfndcpn
SELECT		distinct ticketreal = a.ticketnumber,stkeyreal = a.stkey,b.*	
INTO		#tmprfndcpn
FROM		#tmp1 a 
			INNER JOIN salesiw.dbo.tbltktcpn b WITH(NOLOCK)
ON			b.TicketNumber = a.RefundTicket
WHERE		SUBSTRING(a.RfndCpn,1,1) = b.FC OR 
			SUBSTRING(a.RfndCpn,2,1) = b.FC OR
			SUBSTRING(a.RfndCpn,3,1) = b.FC OR 
			SUBSTRING(a.RfndCpn,4,1) = b.FC

------------------------------------------------------------------------------------------------------------------------
	
INSERT		tblrfndcpnSEMENTARA
			(StKey,ticketnumber, refundticket, FC, RouteAwal, RouteAkhir, Airlines, FareBasis, FareSALE, LionWingsCode, DomIntlCode, FSurchargeSALE, IWJRSALE, 
            AdmSALE, ApotaxSALE, admkenappnSALE, PPNSALE, PPNFsurchargeSALE, PPNODSale,ppninSALE, PPNAdmSale, PjkTarif, PjkPPN, IDRFare, IDRAdm, IDRFSurcharge, IDRIWJR)
SELECT		DISTINCT stkeyreal,ticketreal, TicketNumber, FC, RouteAwal, RouteAkhir, Airlines, FareBasis, FareUpdate* -1, LionWingsCode, DomIntlCode, FSurcharge* -1, IWJR* -1, 
			Adm* -1, Apotax* -1, admkenappn* -1, ppn* -1, ppnfsurcharge* -1, ppnod* -1,ppnin*-1, PPNadm* -1, PjkTarif, PjkPPN, IDRFare, IDRAdm, IDRFSurcharge, IDRIWJR
FROM		#tmprfndcpn 
------------------------------------------------------------------------------------------------------------------------
	
UPDATE		tblrfndcpnSEMENTARA
SET			AccAmountRefund = (ISNULL(FareSALE,0) + ISNULL(IWJRSALE,0) + ISNULL(FSurchargeSALE,0) + ISNULL(AdmSALE,0) + ISNULL(ApotaxSALE,0) + ISNULL(AdmkenappnSALE,0) + 
			ISNULL(PPNSALE,0) + ISNULL(PPNFsurchargeSALE,0) + ISNULL(PPNODSALE,0) + ISNULL(PPNadmSALE,0) + ISNULL(PPNINSale,0))
			
------------------------------------------------------------------------------------------------------------------------
====================
CANCELFEE
====================
	
DROP TABLE	#tmp2
SELECT		ticketnumber,stkey,refundticket, FC, fareSALE
INTO		#tmp2
FROM		tblrfndcpnSEMENTARA

ALTER TABLE #tmp2 ADD TotalFare MONEY
ALTER TABLE #tmp2 ADD cancelfee MONEY
ALTER TABLE #tmp2 ADD Adm MONEY
ALTER TABLE #tmp2 ADD cancelfeeRefund MONEY
ALTER TABLE #tmp2 ADD AdmRefund MONEY 


DROP TABLE	#tmp
SELECT		ticketnumber, stkey,refundticket, ISNULL(SUM(ISNULL(FareSALE,0)),0) AS Total 
INTO		#tmp 
FROM		#tmp2
GROUP BY	ticketnumber, stkey,refundticket

UPDATE		#tmp2
SET			totalfare = Total
FROM		#tmp2 a INNER JOIN #tmp b
ON			b.refundticket = a.refundticket AND
			b.TicketNumber = a.ticketnumber 
			
UPDATE		#tmp2
SET			cancelfee = b.tktRefCancelFee
FROM		#tmp2 a INNER JOIN tbltkt b WITH(NOLOCK)
ON			b.RefundTicket = a.refundticket AND
			b.TicketNumber = a.TicketNumber
			
UPDATE		#tmp2
SET			cancelfeerefund = (FareSALE / totalfare) * cancelfee
WHERE		totalfare <> '0'

UPDATE		#tmp2
SET			cancelfee = '0'
WHERE		cancelfee IS NULL

UPDATE		#tmp2
SET			cancelfeerefund = '0'
WHERE		cancelfeerefund IS NULL

ALTER TABLE #tmp2 ADD totalcancelfeerefund MONEY
ALTER TABLE #tmp2 ADD selisihcancelfee MONEY

--LOOPINGNYA KESINI LAGI-- jalanin 2x yg dibawah ini

DROP TABLE	#tmp11
SELECT		ticketnumber,refundticket, ISNULL(SUM(ISNULL(cancelfeerefund,0)),0) AS Total 
INTO		#tmp11 
FROM		#tmp2
GROUP BY	ticketnumber,refundticket 

UPDATE		#tmp2
SET			totalcancelfeerefund = Total
FROM		#tmp2 a INNER JOIN #tmp11 b
ON			b.refundticket = a.refundticket AND
			b.TicketNumber = a.TicketNumber

UPDATE		#tmp2
SET			selisihcancelfee = cancelfee - totalcancelfeerefund

DROP TABLE	#tmpmax
SELECT		ticketnumber,refundticket, maxfc = MAX(FC)
INTO		#tmpmax
FROM		#tmp2
GROUP BY	ticketnumber,refundticket

UPDATE		#tmp2
SET			cancelfeerefund = a.cancelfeerefund + selisihcancelfee
FROM		#tmp2 a INNER JOIN #tmpmax b
ON			b.refundticket = a.refundticket AND
			b.maxfc = a.FC AND
			b.TicketNumber = a.TicketNumber 

SELECT		*	
FROM		#tmp2
WHERE		selisihcancelfee <> 0

-------------------------------------------------------------
BEGIN TRAN
UPDATE		tblrfndcpnSEMENTARA
SET			CancelFeeRefund = a.cancelfeerefund
FROM		#tmp2 a INNER JOIN tblrfndcpnSEMENTARA b
ON			b.refundticket = a.refundticket AND
			b.FC = a.FC AND
			b.TicketNumber = a.TicketNumber
COMMIT TRAN		

===========================================================================================

UPDATE		tblrfndcpnSEMENTARA
SET			TotalRefund = b.calctotal 
FROM		tblrfndcpnSEMENTARA a, tbltkt b with(nolock)
WHERE		b.TicketNumber = a.TicketNumber AND
			b.RefundTicket = a.RefundTicket

UPDATE		tblrfndcpnSEMENTARA
SET			AdminRefund = 0

----------------------------------------------------------------------------------------------------------------------
/*1*/
--LOOPING ABIS 1A, 1B kesini

DROP TABLE	#tmp1
SELECT		a.ticketnumber, TotalRefund = SUM(ISNULL(AccAmountRefund,0) + ISNULL(CancelFeeRefund,0) + ISNULL(adminrefund,0))
INTO		#tmp1
FROM		tblrfndcpnSEMENTARA a, tbltkt b with(nolock)
WHERE		b.TicketNumber = a.RefundTicket AND 
			b.TransCode = 'SALE' AND b.DocType = 'TKT' 
GROUP BY	a.ticketnumber

DROP TABLE	#tmpbeda
SELECT		a.* 
INTO		#tmpbeda 
FROM		#tmp1 a, tblrfndcpnSEMENTARA b
WHERE		b.TicketNumber = a.TicketNumber AND 
			b.TotalRefund <> a.TotalRefund
			
ALTER TABLE #tmpbeda ADD selisihadm MONEY

UPDATE		#tmpbeda
SET			selisihadm = a.TotalRefund - b.TotalRefund
FROM		#tmpbeda a, tblrfndcpnSEMENTARA b
WHERE		b.TicketNumber = a.TicketNumber AND 
			b.TotalRefund <> a.TotalRefund
			
----------------------------------------------------------------------------------------------------------------------
1A.

DROP TABLE	#tmpfc
SELECT		refundticket, totaltiket = COUNT(*)
INTO		#tmpfc
FROM		#tmp2 
GROUP BY	refundticket

UPDATE		tblrfndcpnSEMENTARA
SET			adminrefund = (ROUND((selisihadm / totaltiket),2)) * -1
FROM		#tmpbeda a, tblrfndcpnSEMENTARA b, #tmpfc c
WHERE		b.TicketNumber = a.TicketNumber AND
			b.TotalRefund <> a.TotalRefund AND
			c.RefundTicket = b.RefundTicket 
----------------------------------------------------------------------------------------------------------------------
1B.

DROP TABLE	#tmpminfc
SELECT		refundticket, MinFC = MIN(FC)
INTO		#tmpminfc
FROM		#tmp2 
GROUP BY	refundticket

UPDATE		tblrfndcpnSEMENTARA
SET			adminrefund = AdminRefund - a.selisihadm
FROM		#tmpbeda a, tblrfndcpnSEMENTARA b, #tmpminfc c
WHERE		b.TicketNumber = a.TicketNumber AND
			b.TotalRefund <> a.TotalRefund AND
			c.RefundTicket = b.RefundTicket AND
			c.MinFC = b.FC
----------------------------------------------------------------------------------------------------------------------

UPDATE		tblrfndcpnSEMENTARA
SET			FareSALE = b.TktBaseFare, FSurchargeSALE = b.TktFSurcharge , IWJRSALE= b.TktIWJR, AdmSALE = b.tktadm, ApotaxSALE = b.TktApoTax,
			PPNSale = b.tktppn, ppnodsale = b.tktppnod, admkenappnsale = b.tktadmkenappn
FROM		tblrfndcpnSEMENTARA a, tbltkt b with(nolock)
WHERE		AccAmountRefund + CancelFeeRefund <> TotalRefund AND
			b.TicketNumber = a.RefundTicket AND 
			b.TransCode = 'SALE' AND 
			b.DocType = 'VOU'

==================================================================================================================================

drop table #tmp1
select a.*, b.exchTicket
into #tmp1
from tblrfndcpnSEMENTARA a, tbltkt b with(nolock)
where b.TicketNumber = a.RefundTicket AND b.TransCode = 'EXCH' AND b.DocType = 'TKT'

drop table #tmpexch
select a.TicketNumber, a.FC, Fareakhir = a.FareSALE - c.FareUpdate, IWJRakhir = a.IWJRSALE - c.IWJR, FsurchargeAKhir = a.FSurchargeSALE - c.FSurcharge, 
admakhir = a.AdmSALE - c.adm, apotaxakhir = a.ApotaxSALE - c.Apotax, admkenappnakhir = ISNULL(a.AdmKenaPPNSALE,0) - ISNULL(c.admkenappn,0), 
ppnakhir = ISNULL(a.PPNSALE,0) - ISNULL(c.ppn,0), ppnfsurchargeakhir = ISNULL(a.PPNFSurchargeSALE,0) - ISNULL(c.ppnfsurcharge,0), 
ppnodakhir = ISNULL(a.ppnodsale,0) - ISNULL(c.ppnod,0),ppnadmakhir = ISNULL(a.ppnadmsale,0) - ISNULL(c.ppnadm,0)  into #tmpexch 
from #tmp1 a, tbltkt b with(nolock), tbltktcpn c with(nolock)
where b.TicketNumber = a.exchTicket AND
b.TransCode = 'SALE' AND 
b.DocType = 'TKT' AND
c.TicketNumber = b.TicketNumber AND c.RouteAwal = a.RouteAwal AND c.RouteAkhir = b.RouteAkhir

update tblrfndcpnSEMENTARA
set FareSALE = a.fareakhir, iwjrsale = a.IWJRakhir, FSurchargeSALE = a.FsurchargeAKhir, AdmSALE = a.admakhir, ApotaxSALE = a.apotaxakhir,
AdmKenaPPNSALE = a.admkenappnakhir, PPNSALE = a.ppnakhir, PPNFSurchargeSALE = a.ppnfsurchargeakhir, PPNODSALE = a.ppnodakhir, ppnadmsale = a.ppnadmakhir
from #tmpexch a, tblrfndcpnSEMENTARA b
where b.TicketNumber = a.TicketNumber AND b.FC = a.FC

----------------------------------------------------------------------------------------------------------------------
**********
--loop--
UPDATE		tblrfndcpnSEMENTARA
SET			AccAmountRefund = (ISNULL(a.FareSALE,0) + ISNULL(a.IWJRSALE,0) + ISNULL(a.FSurchargeSALE,0) + ISNULL(a.AdmSALE,0) + ISNULL(a.ApotaxSALE,0)
			+ ISNULL(a.AdmkenappnSALE,0) + ISNULL(a.PPNSALE,0) + ISNULL(a.PPNFsurchargeSALE,0) + ISNULL(a.PPNODSALE,0) + ISNULL(a.PPNadmSALE,0)+ ISNULL(a.PPNINSALE,0)) 
FROM		tblrfndcpnSEMENTARA a

drop table #tmp1
select ticketnumber, TotalRefund = SUM(ISNULL(AccAmountRefund,0) + ISNULL(CancelFeeRefund,0) + ISNULL(adminrefund,0))
into #tmp1
from tblrfndcpnSEMENTARA 
group by ticketnumber

drop table #tmpbeda
select a.* 
into #tmpbeda 
from #tmp1 a, tblrfndcpnSEMENTARA b
where b.TicketNumber = a.TicketNumber AND 
b.TotalRefund <> a.TotalRefund

drop table #tmpbeda2
select distinct * into #tmpbeda2  from #tmpbeda

select * from #tmpbeda2

-------------------------
/* 1

drop table #tmpFCRefund
select distinct ticketrefund = b.TicketNumber,b.FC 
into #tmpFCRefund from #tmpbeda a, tblrfndcpnSEMENTARA b
where b.TicketNumber = a.TicketNumber 

drop table #tmptotalFC
select ticketrefund, totalfc = COUNT(FC)
into #tmptotalFC 
from #tmpFCRefund
group by ticketrefund

drop table #tmpREFUNDAKHIR
select ticketrefund, FareSALE = round((b.TktBaseFare / a.totalfc),2), iwjrsale = round((b.TktIWJR / a.totalfc),2), 
FSurchargeSALE = round((b.TktFSurcharge / a.totalfc),2), AdmSALE = round((b.TktAdm / a.totalfc),2), 
ApotaxSALE = round((b.TktApoTax / a.totalfc),2), AdmKenaPPNSALE = round((b.TktAdmKenaPPN / a.totalfc),2), 
PPNSALE = round((b.tktppn / a.totalfc),2), PPNFSurchargeSALE = 0, 
PPNODSALE = round((b.tktppnod / a.totalfc),2), ppnadmsale = 0, ppnINSale = round((b.tktppnin/a.totalfc),2)
into #tmpREFUNDAKHIR
from #tmptotalFC a, tbltkt b with(nolock)
where b.TicketNumber = a.ticketrefund 

update tblrfndcpnSEMENTARA
set FareSALE = a.FareSALE, iwjrsale = a.iwjrsale, FSurchargeSALE = a.FSurchargeSALE, AdmSALE = a.AdmSALE, 
ApotaxSALE = a.ApotaxSALE, AdmKenaPPNSALE = a.AdmKenaPPNSALE, PPNSALE = a.PPNSALE, PPNFSurchargeSALE = a.PPNFSurchargeSALE, 
PPNODSALE = a.PPNODSALE, PPNAdmSALE = a.PPNAdmSALE, PPNINSale = a.ppninsale
from #tmpREFUNDAKHIR a, tblrfndcpnSEMENTARA b
where b.TicketNumber = a.ticketrefund

UPDATE		tblrfndcpnSEMENTARA
SET			AccAmountRefund = (ISNULL(a.FareSALE,0) + ISNULL(a.IWJRSALE,0) + ISNULL(a.FSurchargeSALE,0) + ISNULL(a.AdmSALE,0) + ISNULL(a.ApotaxSALE,0)
			+ ISNULL(a.AdmkenappnSALE,0) + ISNULL(a.PPNSALE,0) + ISNULL(a.PPNFsurchargeSALE,0) + ISNULL(a.PPNODSALE,0) + ISNULL(a.PPNadmSALE,0) + ISNULL(a.PPNINSale,0)) 
FROM		tblrfndcpnSEMENTARA a, #tmpREFUNDAKHIR b
WHERE		b.ticketrefund = a.ticketnumber 


-------------------------
2.
drop table #tmptambahan
select c.ticketnumber, MinFC = min(b.FC), SelisihCF = c.tktadm - SUM(ISNULL(b.admsale,0))
into #tmptambahan
from #tmpbeda2 a, tblrfndcpnSEMENTARA b, tbltkt c with(nolock)
where b.TicketNumber = a.ticketnumber AND c.ticketnumber = b.ticketnumber  
group by c.ticketnumber, c.tktadm

select * from #tmptambahan

update tblrfndcpnsementara
set admsale = admsale + SelisihCF 
from tblrfndcpnsementara a, #tmptambahan b
where b.ticketnumber = a.ticketnumber AND b.minfc = a.fc
--

drop table #tmptambahan
select c.ticketnumber, MinFC = min(b.FC), SelisihCF = c.tktbasefare - SUM(ISNULL(b.faresale,0))
into #tmptambahan
from #tmpbeda2 a, tblrfndcpnSEMENTARA b, tbltkt c with(nolock)
where b.TicketNumber = a.ticketnumber AND c.ticketnumber = b.ticketnumber  
group by c.ticketnumber, c.tktbasefare

update tblrfndcpnsementara
set faresale = faresale + SelisihCF 
from tblrfndcpnsementara a, #tmptambahan b
where b.ticketnumber = a.ticketnumber AND b.minfc = a.fc
---
drop table #tmptambahan
select c.ticketnumber, MinFC = min(b.FC), SelisihCF = c.tktiwjr - SUM(ISNULL(b.iwjrsale,0))
into #tmptambahan
from #tmpbeda2 a, tblrfndcpnSEMENTARA b, tbltkt c with(nolock)
where b.TicketNumber = a.ticketnumber AND c.ticketnumber = b.ticketnumber  
group by c.ticketnumber, c.tktiwjr

update tblrfndcpnsementara
set iwjrsale = iwjrsale + SelisihCF 
from tblrfndcpnsementara a, #tmptambahan b
where b.ticketnumber = a.ticketnumber AND b.minfc = a.fc
--
drop table #tmptambahan
select c.ticketnumber, MinFC = min(b.FC), SelisihCF = c.tktapotax - SUM(ISNULL(b.apotaxsale,0))
into #tmptambahan
from #tmpbeda2 a, tblrfndcpnSEMENTARA b, tbltkt c with(nolock)
where b.TicketNumber = a.ticketnumber AND c.ticketnumber = b.ticketnumber  
group by c.ticketnumber, c.tktapotax

update tblrfndcpnsementara
set apotaxsale = apotaxsale + SelisihCF 
from tblrfndcpnsementara a, #tmptambahan b
where b.ticketnumber = a.ticketnumber AND b.minfc = a.fc
--
drop table #tmptambahan
select c.ticketnumber, MinFC = min(b.FC), SelisihCF = c.tktppnod - SUM(ISNULL(b.ppnodsale,0))
into #tmptambahan
from #tmpbeda2 a, tblrfndcpnSEMENTARA b, tbltkt c with(nolock)
where b.TicketNumber = a.ticketnumber AND c.ticketnumber = b.ticketnumber  
group by c.ticketnumber, c.tktppnod

update tblrfndcpnsementara
set ppnodsale = ppnodsale + SelisihCF 
from tblrfndcpnsementara a, #tmptambahan b
where b.ticketnumber = a.ticketnumber AND b.minfc = a.fc
--
drop table #tmptambahan
select c.ticketnumber, MinFC = min(b.FC), SelisihCF = c.tktppn - SUM(ISNULL(b.ppnsale,0))
into #tmptambahan
from #tmpbeda2 a, tblrfndcpnSEMENTARA b, tbltkt c with(nolock)
where b.TicketNumber = a.ticketnumber AND c.ticketnumber = b.ticketnumber  
group by c.ticketnumber, c.tktppn

update tblrfndcpnsementara
set ppnsale = ppnsale + SelisihCF 
from tblrfndcpnsementara a, #tmptambahan b
where b.ticketnumber = a.ticketnumber AND b.minfc = a.fc
--
drop table #tmptambahan
select c.ticketnumber, MinFC = min(b.FC), SelisihCF = c.tktrefcancelfee - SUM(ISNULL(b.cancelfeerefund,0))
into #tmptambahan
from #tmpbeda2 a, tblrfndcpnSEMENTARA b, tbltkt c with(nolock)
where b.TicketNumber = a.ticketnumber AND c.ticketnumber = b.ticketnumber  
group by c.ticketnumber, c.tktrefcancelfee

update tblrfndcpnsementara
set cancelfeerefund = cancelfeerefund + SelisihCF 
from tblrfndcpnsementara a, #tmptambahan b
where b.ticketnumber = a.ticketnumber AND b.minfc = a.fc

--
drop table #tmptambahan
select c.ticketnumber, MinFC = min(b.FC), SelisihCF = c.tktfsurcharge - SUM(ISNULL(b.fsurchargesale,0))
into #tmptambahan
from #tmpbeda2 a, tblrfndcpnSEMENTARA b, tbltkt c with(nolock)
where b.TicketNumber = a.ticketnumber AND c.ticketnumber = b.ticketnumber  
group by c.ticketnumber, c.tktfsurcharge

update tblrfndcpnsementara
set fsurchargesale = fsurchargesale + SelisihCF 
from tblrfndcpnsementara a, #tmptambahan b
where b.ticketnumber = a.ticketnumber AND b.minfc = a.fc


*/
--loop--
DROP TABLE	#tmp1
SELECT		distinct b.*
INTO		#tmp1
FROM		tblStTRK a INNER JOIN tbltkt b WITH(NOLOCK)
ON			b.stkey = a.stkey
			INNER JOIN tblrfndcpnSEMENTARA c
ON			c.TicketNumber = b.TicketNumber
WHERE		(b.TransCode like 'rf%')

DROP TABLE	#tmpcpn	
SELECT		b.TicketNumber, TktBaseFare = SUM(ISNULL(fareSALE,0)),tktPPN = SUM(ISNULL(PPNSALE,0)) + SUM(ISNULL(PPNFsurchargeSALE,0)) +SUM(ISNULL(PPNadmSale,0)),
			TktFSurcharge = SUM(ISNULL(FSurchargeSALE,0)), TktIWJR = SUM(ISNULL(IWJRSALE,0)), TktAdm = SUM(ISNULL(AdmSALE,0)) + SUM(ISNULL(adminrefund,0)),
			TktApoTax = SUM(ISNULL(ApotaxSALE,0)), TktAdmKenaPPN = SUM(ISNULL(AdmKenaPPNSALE,0)),TktppnOD = SUM(ISNULL(PPNODSALE,0)), tktRefCancelFee = SUM(ISNULL(cancelfeerefund,0)),
			TktPPNIN = SUM(ISNULL(ppninsale,0)), Total = CONVERT(money,NULL)
INTO		#tmpcpn
FROM		#tmp1 a, tblrfndcpnSEMENTARA b
WHERE		b.TicketNumber = a.TicketNumber   
GROUP BY	b.TicketNumber

UPDATE		#tmpcpn 
SET			total = TktBaseFare + tktPPN + TktFSurcharge + TktIWJR + TktAdm + TktApoTax + TktAdmKenaPPN + TktppnOD + tktRefCancelFee + ISNULL(tktppnin,0)

-----Harus Kosong
select * from #tmpcpn a, tbltkt b with(nolock)
where b.TicketNumber = a.TicketNumber AND
b.tktRefCancelFee <> a.tktRefCancelFee 
-----Harus Kosong
select * from #tmpcpn a, tbltkt b with(nolock)
where b.TicketNumber = a.TicketNumber AND
b.CalcTotal <> a.total  

alter table #tmpcpn add accamount money
alter table #tmpcpn add accadm money

update #tmpcpn
set AccAmount = isnull(TktBaseFare,0) + isnull(TktPPN,0) + isnull(TktFSurcharge,0) + isnull(TktIWJR,0) + isnull(TktApoTax,0) + isnull(tktadmkenappn,0) + ISNULL(tktppnOD,0) + ISNULL(tktppnin,0)

update #tmpcpn
set accadm = isnull(tktadm,0) + isnull(tktRefCancelFee,0)

--HARUS KOSONG--
select * from #tmpcpn a, tbltkt b with(nolock), tblrfndcpnsementara c with(nolock)
where b.AccAmount <> a.AccAmount AND b.TicketNumber = a.TicketNumber AND c.TicketNumber = b.TicketNumber


-----------------------
/*
UPDATE tblrfndcpnSEMENTARA
set AdminRefund = 0
from #tmpcpn a, tblrfndcpnSEMENTARA b, tbltkt c with(nolock)
where b.TicketNumber = a.TicketNumber AND c.ticketnumber = a.TicketNumber AND 
c.TicketNumber = a.ticketnumber AND c.AccAmount <> a.AccAmount

drop table #tmpFCRefund
select distinct ticketrefund = b.TicketNumber,b.FC 
into #tmpFCRefund from #tmpcpn a, tblrfndcpnSEMENTARA b, tbltkt c with(nolock)
where b.TicketNumber = a.TicketNumber AND c.ticketnumber = a.TicketNumber AND 
c.TicketNumber = a.ticketnumber AND c.AccAmount <> a.AccAmount

drop table #tmptotalFC
select ticketrefund, totalfc = COUNT(FC)
into #tmptotalFC 
from #tmpFCRefund
group by ticketrefund

drop table #tmpREFUNDAKHIR
select ticketrefund, FareSALE = round((b.TktBaseFare / a.totalfc),2), iwjrsale = round((b.TktIWJR / a.totalfc),2), 
FSurchargeSALE = round((b.TktFSurcharge / a.totalfc),2), AdmSALE = round((b.TktAdm / a.totalfc),2), 
ApotaxSALE = round((b.TktApoTax / a.totalfc),2), AdmKenaPPNSALE = round((b.TktAdmKenaPPN / a.totalfc),2), 
PPNSALE = round((b.tktppn / a.totalfc),2), PPNFSurchargeSALE = 0, 
PPNODSALE = round((b.tktppnod / a.totalfc),2), ppnadmsale = 0, cancelfeerefund = round((b.tktRefCancelFee / a.totalfc),2),
ppninsale = round((b.TktPPNIN / a.totalfc),2)
into #tmpREFUNDAKHIR
from #tmptotalFC a, tbltkt b with(nolock)
where b.TicketNumber = a.ticketrefund 

update tblrfndcpnSEMENTARA
set FareSALE = a.FareSALE, iwjrsale = a.iwjrsale, FSurchargeSALE = a.FSurchargeSALE, AdmSALE = a.AdmSALE, 
ApotaxSALE = a.ApotaxSALE, AdmKenaPPNSALE = a.AdmKenaPPNSALE, PPNSALE = a.PPNSALE, PPNFSurchargeSALE = a.PPNFSurchargeSALE, 
PPNODSALE = a.PPNODSALE, PPNAdmSALE = a.ppnadmsale, CancelFeeRefund = a.cancelfeerefund, ppninsale = a.ppninsale
from #tmpREFUNDAKHIR a, tblrfndcpnSEMENTARA b
where b.TicketNumber = a.ticketrefund

UPDATE		tblrfndcpnSEMENTARA
SET			AccAmountRefund = (ISNULL(a.FareSALE,0) + ISNULL(a.IWJRSALE,0) + ISNULL(a.FSurchargeSALE,0) + ISNULL(a.AdmSALE,0) + ISNULL(a.ApotaxSALE,0)
			+ ISNULL(a.AdmkenappnSALE,0) + ISNULL(a.PPNSALE,0) + ISNULL(a.PPNFsurchargeSALE,0) + ISNULL(a.PPNODSALE,0) + ISNULL(a.PPNadmSALE,0)+ ISNULL(a.ppninsale,0)) 
FROM		tblrfndcpnSEMENTARA a, #tmpREFUNDAKHIR b
WHERE		b.ticketrefund = a.ticketnumber 

*/

--BALIK KE ATAS BATAS ***** */

--------------------------------------------------------------------------------------------------------------------------------
update tblrfndcpnsementara
set totalrefund = ISNULL(AccAmountRefund,0) + ISNULL(CancelFeeRefund,0) + ISNULL(AdminRefund,0)

insert into tblRfndCpn (StKey, TicketNumber, RefundTicket, FC, RouteAwal, RouteAkhir, Airlines, FareBasis, LionWingsCode, DomIntlCode, FareSALE, IWJRSALE, 
					  FSurchargeSALE, AdmSALE, ApotaxSALE, AdmKenaPPNSALE, PPNSALE, PPNFSurchargeSALE, PPNODSALE,PPNInSALE, ppnadmsale, PjkTarif, PjkPPN, IDRFare, IDRAdm, 
					  IDRFSurcharge, IDRIWJR, AccAmountRefund, CancelFeeRefund, AdminRefund, TotalRefund, InsertDate)
select StKey, TicketNumber, RefundTicket, FC, RouteAwal, RouteAkhir, Airlines, FareBasis, LionWingsCode, DomIntlCode, FareSALE, IWJRSALE, 
					  FSurchargeSALE, AdmSALE, ApotaxSALE, AdmKenaPPNSALE, PPNSALE, PPNFSurchargeSALE, PPNODSALE,PPNInSALE, ppnadmsale, PjkTarif, PjkPPN, IDRFare, IDRAdm, 
					  IDRFSurcharge, IDRIWJR, AccAmountRefund, CancelFeeRefund, AdminRefund, TotalRefund, GETDATE()
from tblrfndcpnSEMENTARA
---------------------------------------------------------------------------------------------------------------------------------
