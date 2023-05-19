SELECT		DISTINCT StationOpenDate 
FROM		dmsttrk

---------------------------------- jalan bareng -----------------------------------------------------------------------------------------------------------------------------------------------

DROP TABLE	#tmp1
SELECT		DISTINCT b.ticketnumber,b.issueddate,b.intlcode,b.tktApoTax,b.rate,b.descr,fop,b.transcode,b.doctype,
			b.PreConjTicket,Curr=a.StationCurr,c.fc,c.ApoTax,ApoTaxUpdate = c.ApoTax,c.FareBasis,c.routeawal,c.routeakhir,c.flightnumber,
			c.domIntlCode, c.LionWingsCode, AirlineIntlCode
INTO		#tmp1
FROM		dmsttrk a WITH(NOLOCK) INNER JOIN dmtkt b WITH(NOLOCK)
ON			b.StKey = a.StKey 
			INNER JOIN dmtktcpn c WITH(NOLOCK)
ON			c.StKey = b.StKey AND
			c.StKey = a.StKey AND
			c.TicketNumber = b.TicketNumber 
WHERE		b.transcode IN ('SALE','EXCH') AND
			b.doctype IN ('TKT') 
	
UPDATE		#tmp1 
SET			ApoTaxUpdate = 0

DROP TABLE	#tmpconj
SELECT		DISTINCT b.ticketnumber,b.issueddate,b.intlcode,b.tktApoTax,b.rate,b.descr,fop,b.transcode,b.doctype,
			b.PreConjTicket,Curr=a.StationCurr,c.fc,c.ApoTax,ApoTaxUpdate=c.ApoTax,c.FareBasis,c.routeawal,c.routeakhir,c.flightnumber,
			c.DomIntlCode, c.LionWingsCode, AirlineIntlCode
INTO		#tmpconj
FROM		dmsttrk a WITH(NOLOCK) INNER JOIN dmtkt b WITH(NOLOCK)
ON			b.StKey = a.StKey 
			INNER JOIN dmtktcpn c WITH(NOLOCK)
ON			c.StKey = b.StKey AND
			c.StKey = a.StKey AND
			c.TicketNumber = b.TicketNumber 
WHERE		b.transcode in ('SALE','EXCH') AND
			b.doctype in ('CNJ') 
			--AND c.InsertDate > '26 Feb 2015'
	
UPDATE		#tmpconj 
SET			tktApoTax=b.tktApoTax
FROM		#tmpconj a INNER JOIN dmtkt b WITH(NOLOCK)
ON			b.ticketnumber = a.PreConjTicket

================================================================================================================================================================
--- KALO ADA NILAI KASIH TAU -------

SELECT		DISTINCT a.* 
FROM		#tmpconj a INNER JOIN (SELECT * FROM #tmpconj) b
ON			b.ticketnumber = a.PreConjTicket
WHERE		a.tktApoTax <> 0

--------------------------------------------------------------------------------------------------------------------------------------------------------------

/*
UPDATE		#tmpconj 
SET			tktApoTax = b.tktApoTax
FROM		#tmpconj a,(SELECT * FROM #tmpconj) b
WHERE		b.ticketnumber = a.PreConjTicket

SELECT		*	
FROM		#tmpconj a,(SELECT * FROM #tmpconj) b
WHERE		b.ticketnumber = a.PreConjTicket
*/

DROP TABLE	#Tmpmax
SELECT		ticketnumber,fc = MAX(fc)
INTO		#tmpmax
FROM		#Tmp1
GROUP BY	ticketnumber

DROP TABLE	#tmpNewAllTktCpn
SELECT		ticketnumber,issueddate,intlcode,Curr,fop,transcode,doctype,ticketasal=ticketnumber,fc,FCAsal=fc,tktApoTax,rate,
			ApoTax,ApoTaxUpdate,descr,FareBasis,RouteAwal,RouteAkhir,flightnumber,DomIntlCode, LionWingsCode, AirlineIntlCode
INTO		#tmpNewAllTktCpn
FROM		#Tmp1
UNION ALL
SELECT		ticketnumber=PreConjTicket,issueddate,intlcode,Curr,fop,transcode,doctype,ticketasal=a.ticketnumber,fc=a.fc + b.fc,
			fcAsal=a.FC,tktApoTax,rate,ApoTax,ApoTaxUpdate,a.descr,FareBasis,RouteAwal,RouteAkhir,flightnumber,DomIntlCode, LionWingsCode, AirlineIntlCode
FROM		#tmpconj a LEFT JOIN #tmpmax b
ON			b.ticketnumber = a.PreConjTicket

UPDATE		#tmpNewAllTktCpn 
SET			ApoTaxupdate = apotax

/*
select * from #tmpNewAllTktCpn where ticketnumber = '9902172387931'
select * from #tmpNewAllTktCpn where ticketnumber = '9902172387932'
select * from #tmpNewAllTktCpn where ticketnumber = '9902172387933'

UPDATE		#tmpNewAllTktCpn 
SET			ticketnumber = 9902187870513, fc=8+fcasal 
WHERE		ticketnumber = 9902187870514
*/
===============================================================================================================================

DROP TABLE	#tmptktprice
SELECT		b.stkey, b.ticketnumber, b.KodeBiaya, TotalAmount = SUM(amount)
INTO		#tmptktprice
FROM		dmsttrk a WITH(NOLOCK), dmtktpr b WITH(NOLOCK)
WHERE		b.stkey = a.stkey 
GROUP BY	b.stkey, b.ticketnumber, b.KodeBiaya

DROP TABLE	#tmpApotaxbyCountry
SELECT		c.kodebiaya, a.TicketNumber, c.country, Totaltiket = COUNT(*)
INTO		#tmpApotaxbyCountry
FROM		#tmpNewAllTktCpn a, sales.dbo.tblmasterdistrict b, salesod.dbo.tblmastercategory c
WHERE		b.kodedistrict = a.RouteAwal AND 
			c.country = b.country AND 
			a.FareBasis <> 'VOID'
GROUP BY	c.kodebiaya, a.TicketNumber, c.country

ALTER TABLE	#tmpApotaxbyCountry ADD Apotaxupdate MONEY

UPDATE		#tmpApotaxbyCountry 
SET			apotaxupdate = ROUND((b.totalamount / a.totaltiket),2)
FROM		#tmpApotaxbyCountry a, #tmptktprice b
WHERE		b.TicketNumber = a.TicketNumber AND 
			b.KodeBiaya = a.KodeBiaya

UPDATE		#tmpApotaxbyCountry
SET			apotaxupdate = 0
WHERE		apotaxupdate IS NULL

DROP TABLE	#tmpakhir
SELECT		TicketNumber, country, TotalApotax = SUM(apotaxupdate) 
INTO		#tmpakhir
FROM		#tmpApotaxbyCountry
GROUP BY	TicketNumber, country

UPDATE		#tmpNewAllTktCpn
SET			ApoTaxUpdate = a.TotalApotax
FROM		#tmpakhir a, #tmpNewAllTktCpn b, sales.dbo.tblmasterdistrict c 
WHERE		c.kodedistrict = b.routeawal AND 
			b.TicketNumber = a.TicketNumber AND 
			c.country = a.country AND
			b.FareBasis <> 'VOID' 

UPDATE		#tmpNewAllTktCpn
SET			ApoTaxUpdate = b.amountintl
FROM		#tmpNewAllTktCpn a, sales.dbo.tblMasterApotax b, sales.dbo.tblmasterdistrict c
WHERE		b.KodeDistrict = a.RouteAwal AND 
			a.domintlcode = 'I' AND 
			c.kodedistrict = b.KodeDistrict AND 
			c.kodedistrict = a.RouteAwal AND 
			c.country = 'INDONESIA' AND 
			a.apotaxupdate > 0 

UPDATE		#tmpNewAllTktCpn
SET			ApoTaxUpdate = b.amountdom
FROM		#tmpNewAllTktCpn a, sales.dbo.tblMasterApotax b, sales.dbo.tblmasterdistrict c
WHERE		b.KodeDistrict = a.RouteAwal AND 
			a.domintlcode = 'D' AND 
			c.kodedistrict = b.KodeDistrict AND 
			c.kodedistrict = a.RouteAwal AND 
			c.country = 'INDONESIA' AND 
			a.apotaxupdate > 0 
			
UPDATE		#tmpNewAllTktCpn
SET			ApoTaxUpdate = 0
WHERE		TktApoTax = 0

----------------------------------------- masih jalan bareng ----------------------------------------------------------------------------------------
===============================LOOPING======================

DROP TABLE	#TmpTktApoTax
SELECT		TicketNumber, TktApoTax
INTO		#TmpTktApoTax
FROM		#tmpNewAllTktCpn 
WHERE		FC = 1
ORDER BY	TicketAsal

DROP TABLE	#TmpApoTaxupdate
SELECT		TicketNumber, ApoTaxupdate = SUM(ISNULL(ApoTaxupdate,0))
INTO		#TmpApoTaxupdate
FROM		#tmpNewAllTktCpn 
GROUP BY	TicketNumber
ORDER BY	TicketNumber

DROP TABLE	#tmpApoTaxTidakSama
SELECT		a.*, b.ApoTaxupdate 
INTO		#tmpApoTaxTidakSama
FROM		#TmpTktApoTax a INNER JOIN #TmpApoTaxupdate b
ON			b.TicketNumber = a.TicketNumber
WHERE		b.ApoTaxupdate <> a.TktApoTax
ORDER BY	a.TicketNumber

SELECT		* 
FROM		#tmpApoTaxTidakSama --- HARUS KOSONG ----
ORDER BY	TktApoTax DESC  --- DI SAAT YANG RUPIAH UDA ABIS JALANIN LG NO 2 UNTUK RESET

/*



select * from #tmpnewalltktcpn

WY - PER, BNE, MEL
c4 jc lnu
Kalo misalkan sampe step 3 ada isi, di cek pake ini, habis itu tanyain 
select* from #tmpNewAllTktCpn where TicketNumber in ('5132102456858')
select* from dmtktpr where TicketNumber in ('5132102456858')

update #tmpnewalltktcpn set apotaxupdate = 28000.00 + 112000.00 where TicketNumber = 5132102429013 and fc = 1
update #tmpnewalltktcpn set apotaxupdate = 0 where TicketNumber in ('5132102441307') and fc = 2
update #tmpnewalltktcpn set apotaxupdate = 0 where TicketNumber in ('5132102441307') and fc = 3
update #tmpnewalltktcpn set apotaxupdate = 0 where TicketNumber in ('5132102450120') and fc = 4
update #tmpnewalltktcpn set apotaxupdate = 0 where TicketNumber in ('5132102441307') and fc = 7

update #tmpnewalltktcpn set apotaxupdate = 0 where TicketNumber = 5132102432420 and fc = 4

--untuk yang WY
update #tmpnewalltktcpn set apotaxupdate = 200000.00 where TicketNumber in (5132102427935) and fc=2

note: kalo yang LNU tambahin yang C4 JC ke fc 1 , yang D5 ke fc 2
kalo ketemu yang fc nya sampe 6 beresin D5 nya dulu (sama kayak yang copy ke excel terus ada yang dikosongin) terus C4 JC ditambahin ke LNU
select * from sales.dbo.tblmasterapotax where kodedistrict = 'LLJ'*/
===============================================================================================================================

1.....

UPDATE		#tmpnewalltktcpn
SET			apotaxupdate = a.tktapotax
FROM		#tmpNewAllTktCpn a, #tmpApoTaxTidakSama b
WHERE		b.TicketNumber = a.TicketNumber
===============================================================================================================================

2.....

UPDATE		#tmpNewAllTktCpn
SET			ApoTaxUpdate = a.TotalApotax
FROM		#tmpakhir a, #tmpNewAllTktCpn b, sales.dbo.tblmasterdistrict c, #tmpapotaxtidaksama d
WHERE		c.kodedistrict = b.routeawal AND 
			b.TicketNumber = a.TicketNumber AND 
			c.country = a.country AND
			b.FareBasis <> 'VOID' AND 
			d.ticketnumber = b.ticketnumber

UPDATE		#tmpNewAllTktCpn
SET			ApoTaxUpdate = b.amountdom
FROM		#tmpNewAllTktCpn a, sales.dbo.tblmasterapotax b, sales.dbo.tblmasterdistrict c, #tmpapotaxtidaksama d
WHERE		b.KODEDISTRICT = a.RouteAwal AND 
			d.ticketnumber = a.ticketnumber AND 
			a.domintlcode = 'D' AND 
			c.kodedistrict = b.KODEDISTRICT AND 
			c.kodedistrict = a.RouteAwal AND 
			c.country = 'INDONESIA' 

UPDATE		#tmpNewAllTktCpn
SET			ApoTaxUpdate = b.amountintl
FROM		#tmpNewAllTktCpn a, sales.dbo.tblmasterapotax b, sales.dbo.tblmasterdistrict c, #tmpapotaxtidaksama d
WHERE		b.KODEDISTRICT = a.RouteAwal AND 
			d.ticketnumber = a.ticketnumber AND 
			a.domintlcode = 'I' AND 
			c.kodedistrict = b.KODEDISTRICT AND 
			c.kodedistrict = a.RouteAwal AND 
			c.country = 'INDONESIA' 

update #tmpNewAllTktCpn
set apotaxupdate = 85000.00
from #tmpnewalltktcpn a, #tmpapotaxtidaksama b
where b.ticketnumber = a.ticketnumber AND
a.RouteAwal = 'CGK' AND a.lionwingscode = 'ID' AND domintlcode = 'D'

update #tmpNewAllTktCpn
set apotaxupdate = 20000.00
from #tmpnewalltktcpn a, #tmpapotaxtidaksama b
where b.ticketnumber = a.ticketnumber AND
a.RouteAwal = 'OJU' 

update #tmpNewAllTktCpn
set apotaxupdate = 15000.00
from #tmpnewalltktcpn a, #tmpapotaxtidaksama b
where b.ticketnumber = a.ticketnumber AND
a.RouteAwal = 'TFY' 

DROP TABLE	#tmpkurs
SELECT		* 
INTO		#tmpkurs 
FROM		sales.dbo.tblkurs 

UPDATE		#tmpkurs
SET			CurrencyCode = 'MYR'
WHERE		CurrencyCode = 'RM'

UPDATE		#tmpNewAllTktCpn 
SET			ApoTaxUpdate = ROUND((a.ApoTaxUpdate / c.Rate),2)
FROM		#tmpNewAllTktCpn a, #tmpApoTaxTidakSama b, #tmpkurs c, sales.dbo.tblmasterdistrict d
WHERE		b.TicketNumber = a.TicketNumber AND 
			c.tglKurs = a.IssuedDate AND
			c.CurrencyCode = a.Curr AND 
			d.kodedistrict = a.routeawal AND 
			d.country = 'INDONESIA'
			
UPDATE		#tmpNewAllTktCpn 
SET			ApoTaxUpdate =0
WHERE		farebasis = 'VOID'	
===============================================================================================================================

3.....		

DROP TABLE	#tmpzz
SELECT		a.ticketnumber, a.TktApoTax, jumlah = sum(isnull(a.apotaxupdate,0))
INTO		#tmpzz
FROM		#tmpNewAllTktCpn a 
			INNER JOIN #tmpApoTaxTidakSama b
ON			b.ticketnumber = a.ticketnumber
WHERE		FareBasis <> 'VOID' AND 
			fc in (1)
GROUP BY	a.ticketnumber, a.TktApoTax

UPDATE		#tmpNewAllTktCpn
SET			ApoTaxUpdate = '0'
FROM		#tmpNewAllTktCpn a 
			INNER JOIN #tmpzz b
ON			b.ticketnumber = a.ticketnumber 
			INNER JOIN #tmpzz c
ON			c.ticketnumber = a.ticketnumber 
WHERE		a.fc in (2,3,4,5,6,7,8) AND 
			c.jumlah = c.TktApoTax

DROP TABLE	#tmpzz1
SELECT		a.ticketnumber, a.TktApoTax, jumlah = sum(isnull(a.apotaxupdate,0))
INTO		#tmpzz1
FROM		#tmpNewAllTktCpn a 
			INNER JOIN #tmpApoTaxTidakSama b
ON			b.ticketnumber = a.ticketnumber
WHERE		FareBasis <> 'VOID' AND 
			fc in (2)
GROUP BY	a.ticketnumber, a.TktApoTax

UPDATE		#tmpNewAllTktCpn
SET			ApoTaxUpdate = '0'
FROM		#tmpNewAllTktCpn a 
			INNER JOIN #tmpzz1 b
ON			b.ticketnumber = a.ticketnumber 
			INNER JOIN #tmpzz1 c
ON			c.ticketnumber = a.ticketnumber 
WHERE		a.fc in (1,3,4,5,6,7,8) AND 
			c.jumlah = c.TktApoTax

DROP TABLE	#tmpzz2
SELECT		a.ticketnumber, a.TktApoTax, jumlah = sum(isnull(a.apotaxupdate,0))
INTO		#tmpzz2
FROM		#tmpNewAllTktCpn a 
			INNER JOIN #tmpApoTaxTidakSama b
ON			b.ticketnumber = a.ticketnumber
WHERE		FareBasis <> 'VOID' AND 
			fc in (3)
GROUP BY	a.ticketnumber, a.TktApoTax

UPDATE		#tmpNewAllTktCpn
SET			ApoTaxUpdate = '0'
FROM		#tmpNewAllTktCpn a 
			INNER JOIN #tmpzz2 b
ON			b.ticketnumber = a.ticketnumber 
			INNER JOIN #tmpzz2 c
ON			c.ticketnumber = a.ticketnumber 
WHERE		a.fc in (1,2,4,5,6,7,8) AND 
			c.jumlah = c.TktApoTax

DROP TABLE	#tmpzz3
SELECT		a.ticketnumber, a.TktApoTax, jumlah = sum(isnull(a.apotaxupdate,0))
INTO		#tmpzz3
FROM		#tmpNewAllTktCpn a 
			INNER JOIN #tmpApoTaxTidakSama b
ON			b.ticketnumber = a.ticketnumber
WHERE		FareBasis <> 'VOID' AND 
			fc in (4)
GROUP BY	a.ticketnumber, a.TktApoTax

UPDATE		#tmpNewAllTktCpn
SET			ApoTaxUpdate = '0'
FROM		#tmpNewAllTktCpn a 
			INNER JOIN #tmpzz3 b
ON			b.ticketnumber = a.ticketnumber 
			INNER JOIN #tmpzz3 c
ON			c.ticketnumber = a.ticketnumber 
WHERE		a.fc in (1,2,3,5,6,7,8) AND 
			c.jumlah = c.TktApoTax

DROP TABLE	#tmpzz4
SELECT		a.ticketnumber, a.TktApoTax, jumlah = sum(isnull(a.apotaxupdate,0))
INTO		#tmpzz4
FROM		#tmpNewAllTktCpn a 
			INNER JOIN #tmpApoTaxTidakSama b
ON			b.ticketnumber = a.ticketnumber
WHERE		FareBasis <> 'VOID' AND 
			fc in (1,2)
GROUP BY	a.ticketnumber, a.TktApoTax

UPDATE		#tmpNewAllTktCpn
SET			ApoTaxUpdate = '0'
FROM		#tmpNewAllTktCpn a 
			INNER JOIN #tmpzz4 b
ON			b.ticketnumber = a.ticketnumber 
			INNER JOIN #tmpzz4 c
ON			c.ticketnumber = a.ticketnumber 
WHERE		a.fc in (3,4,5,6,7,8) AND 
			c.jumlah = c.TktApoTax
			
DROP TABLE	#tmpzz5
SELECT		a.ticketnumber, a.TktApoTax, jumlah = sum(isnull(a.apotaxupdate,0))
INTO		#tmpzz5
FROM		#tmpNewAllTktCpn a 
			INNER JOIN #tmpApoTaxTidakSama b
ON			b.ticketnumber = a.ticketnumber
WHERE		FareBasis <> 'VOID' AND 
			fc in (1,5)
GROUP BY	a.ticketnumber, a.TktApoTax

UPDATE		#tmpNewAllTktCpn
SET			ApoTaxUpdate = '0'
FROM		#tmpNewAllTktCpn a 
			INNER JOIN #tmpzz5 b
ON			b.ticketnumber = a.ticketnumber 
			INNER JOIN #tmpzz5 c
ON			c.ticketnumber = a.ticketnumber 
WHERE		a.fc in (2,3,4,6,7,8) AND 
			c.jumlah = c.TktApoTax

DROP TABLE	#tmpzz6
SELECT		a.ticketnumber, a.TktApoTax, jumlah = sum(isnull(a.apotaxupdate,0))
INTO		#tmpzz6
FROM		#tmpNewAllTktCpn a 
			INNER JOIN #tmpApoTaxTidakSama b
ON			b.ticketnumber = a.ticketnumber
WHERE		FareBasis <> 'VOID' AND 
			fc in (1,3)
GROUP BY	a.ticketnumber, a.TktApoTax

UPDATE		#tmpNewAllTktCpn
SET			ApoTaxUpdate = '0'
FROM		#tmpNewAllTktCpn a 
			INNER JOIN #tmpzz6 b
ON			b.ticketnumber = a.ticketnumber 
			INNER JOIN #tmpzz6 c
ON			c.ticketnumber = a.ticketnumber 
WHERE		a.fc in (2,4,5,6,7,8) AND 
			c.jumlah = c.TktApoTax
		
DROP TABLE	#tmpzz7
SELECT		a.ticketnumber, a.TktApoTax, jumlah = sum(isnull(a.apotaxupdate,0))
INTO		#tmpzz7
FROM		#tmpNewAllTktCpn a 
			INNER JOIN #tmpApoTaxTidakSama b
ON			b.ticketnumber = a.ticketnumber
WHERE		FareBasis <> 'VOID' AND 
			fc in (2,3)
GROUP BY	a.ticketnumber, a.TktApoTax

UPDATE		#tmpNewAllTktCpn
SET			ApoTaxUpdate = '0'
FROM		#tmpNewAllTktCpn a 
			INNER JOIN #tmpzz7 b
ON			b.ticketnumber = a.ticketnumber 
			INNER JOIN #tmpzz7 c
ON			c.ticketnumber = a.ticketnumber 
WHERE		a.fc in (1,4,5,6,7,8) AND 
			c.jumlah = c.TktApoTax

DROP TABLE	#tmpzz8
SELECT		a.ticketnumber, a.TktApoTax, jumlah = sum(isnull(a.apotaxupdate,0))
INTO		#tmpzz8
FROM		#tmpNewAllTktCpn a 
			INNER JOIN #tmpApoTaxTidakSama b
ON			b.ticketnumber = a.ticketnumber
WHERE		FareBasis <> 'VOID' AND 
			fc in (1,4)
GROUP BY	a.ticketnumber, a.TktApoTax

UPDATE		#tmpNewAllTktCpn
SET			ApoTaxUpdate = '0'
FROM		#tmpNewAllTktCpn a 
			INNER JOIN #tmpzz8 b
ON			b.ticketnumber = a.ticketnumber 
			INNER JOIN #tmpzz8 c
ON			c.ticketnumber = a.ticketnumber 
WHERE		a.fc in (2,3,5,6,7,8) AND 
			c.jumlah = c.TktApoTax
			
DROP TABLE	#tmpzz9
SELECT		a.ticketnumber, a.TktApoTax, jumlah = sum(isnull(a.apotaxupdate,0))
INTO		#tmpzz9
FROM		#tmpNewAllTktCpn a 
			INNER JOIN #tmpApoTaxTidakSama b
ON			b.ticketnumber = a.ticketnumber
WHERE		FareBasis <> 'VOID' AND 
			fc in (2,4)
GROUP BY	a.ticketnumber, a.TktApoTax

UPDATE		#tmpNewAllTktCpn
SET			ApoTaxUpdate = '0'
FROM		#tmpNewAllTktCpn a 
			INNER JOIN #tmpzz9 b
ON			b.ticketnumber = a.ticketnumber 
			INNER JOIN #tmpzz9 c
ON			c.ticketnumber = a.ticketnumber 
WHERE		a.fc in (1,3,5,6,7,8) AND 
			c.jumlah = c.TktApoTax


======================================================================================================================================================
/*
1.....
select * from #tmpapotaxtidaksama 
select * from #tmpd5
select * from #SUMtmptktcpn
select * from #tmpsementara

ALTER TABLE #tmpapotaxtidaksama ADD selisih MONEY

UPDATE		#tmpapotaxtidaksama
SET			selisih = tktapotax - apotaxupdate

DROP TABLE	#tmpd5
SELECT		a.ticketnumber, b.totalamount, b.kodebiaya
INTO		#tmpd5
FROM		#tmpapotaxtidaksama a
			INNER JOIN #tmptktprice b
ON			b.ticketnumber = a.ticketnumber AND 
			kodebiaya = 'D5'

DROP TABLE	#SUMtmptktcpn
SELECT		b.ticketnumber, totalticket = COUNT(*), total = SUM(ISNULL(b.apotaxupdate,0)) 
INTO		#SUMtmptktcpn
FROM		#tmpapotaxtidaksama a, #tmpnewalltktcpn b, sales.dbo.tblmasterdistrict c
WHERE		b.ticketnumber = a.ticketnumber AND 
			c.kodedistrict = b.routeawal AND 
			c.country = 'INDONESIA' AND 
			farebasis <> 'VOID' AND
			b.apotaxupdate <> 0
GROUP BY	b.ticketnumber

DROP TABLE	#tmpsementara
SELECT		a.ticketnumber, a.total, b.totalamount, a.totalticket, b.kodebiaya 
INTO		#tmpsementara 
FROM		#SUMtmptktcpn a, #tmpd5 b
WHERE		b.ticketnumber = a.ticketnumber

ALTER TABLE #tmpsementara ADD selisih MONEY

UPDATE		#tmpsementara 
SET			selisih = totalamount - total

UPDATE		#tmpsementara 
SET			selisih = round((selisih / totalticket),2)

UPDATE		#tmpnewalltktcpn
SET			apotaxupdate = apotaxupdate + b.selisih
FROM		#tmpnewalltktcpn a, #tmpsementara b, sales.dbo.tblmasterdistrict c
WHERE		b.ticketnumber = a.ticketnumber AND 
			a.routeawal = c.kodedistrict AND
			c.country = 'INDONESIA' AND
			a.farebasis <> 'VOID' AND
			a.apotaxupdate <> 0
			
---------------------------------------------------------------------------------------------------------------------
2...
UPDATE		#tmpnewalltktcpn
SET			apotaxupdate = 0
WHERE		apotaxupdate < 0 AND 
			tktapotax > 0 
 
ALTER TABLE #tmpapotaxtidaksama ADD Selisih MONEY

UPDATE		#tmpapotaxtidaksama
SET			selisih = tktapotax - apotaxupdate

DROP TABLE	#tmpd5
SELECT		a.ticketnumber, b.totalamount, b.kodebiaya
INTO		#tmpd5
FROM		#tmpapotaxtidaksama a
			INNER JOIN #tmptktprice b
ON			b.ticketnumber = a.ticketnumber AND 
			kodebiaya = 'D5'
--
DROP TABLE	#SUMtmptktcpn
SELECT		b.ticketnumber, minFC = min(b.FC),totalticket = count(*), total = sum(isnull(b.apotaxupdate,0)) 
INTO		#SUMtmptktcpn
FROM		#tmpapotaxtidaksama a, #tmpnewalltktcpn b, sales.dbo.tblmasterdistrict c
WHERE		b.ticketnumber = a.ticketnumber AND 
			c.kodedistrict = b.routeawal AND 
			c.country = 'INDONESIA' AND farebasis <> 'VOID' AND abs(b.apotaxupdate) > abs(selisih)
GROUP BY	b.ticketnumber
--
DROP TABLE	#tmpsementara
SELECT		a.ticketnumber,a.minFC, a.total, b.totalamount, a.totalticket, b.kodebiaya 
INTO		#tmpsementara 
FROM		#SUMtmptktcpn a, #tmpd5 b
WHERE		b.ticketnumber = a.ticketnumber

ALTER TABLE #tmpsementara ADD selisih MONEY

UPDATE		#tmpsementara 
SET			selisih = totalamount - total

UPDATE		#tmpnewalltktcpn
SET			apotaxupdate = apotaxupdate + b.selisih
FROM		#tmpnewalltktcpn a, #tmpsementara b, sales.dbo.tblmasterdistrict c
WHERE		b.ticketnumber = a.ticketnumber AND 
			a.routeawal = c.kodedistrict AND
			c.country = 'INDONESIA' AND
			a.farebasis <> 'VOID' AND
			b.minfc = a.fc AND a.apotaxupdate > selisih			
			
*/
===============================================================================================================================


UPDATE		#tmpNewAllTktCpn
SET			ApoTaxUpdate = 0 
WHERE		ApoTaxUpdate IS NULL 

SELECT		* 
FROM		#tmpNewAllTktCpn 
WHERE		apotaxupdate < 0 AND 
			tktapotax > 0

UPDATE		#tmpnewalltktcpn
SET			apotaxupdate = 0
WHERE		apotaxupdate < 0 AND 
			tktapotax > 0 
--------------------------------------------------------------------------

BEGIN TRAN
UPDATE		dmtktcpn
SET			ApoTax = b.ApoTaxUpdate
FROM		dmtktcpn a INNER JOIN #tmpNewAllTktCpn b
ON			b.ticketAsal = a.ticketnumber AND
			b.fcasal = a.fc 
			INNER JOIN dmtkt c with(nolock)
ON			c.StKey = a.StKey AND 
			c.TicketNumber = a.TicketNumber AND
			c.TicketNumber = b.ticketasal 

COMMIT TRAN
