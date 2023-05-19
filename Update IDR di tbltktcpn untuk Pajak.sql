DROP TABLE	#tmptkt
SELECT		b.stationopendate,stationcurr,transcode,doctype,intlcode,ticketnumber,tktiwjr,tktfsurcharge,tktbasefare,
			tktppn,tktkomisi,tktadm,tktapotax,calctotal,rate
INTO		#tmptkt
FROM		tbltkt a WITH(NOLOCK) INNER JOIN tblsttrk b WITH(NOLOCK)
ON			b.stkey = a.stkey 
WHERE		b.stationopendate BETWEEN '24 Nov 2019'AND '26 Nov 2019'AND
			a.intlcode = 'D' AND 
			a.transcode IN ('SALE','EXCH') AND
			a.doctype IN ('TKT','CNJ')

DROP TABLE #tmptktcpn
CREATE		INDEX id1 
ON			#tmptkt(ticketnumber)
SELECT		a.stationopendate,a.stationcurr,a.transcode,a.doctype,a.intlcode,a.tktiwjr,a.tktfsurcharge,
			a.tktbasefare,a.tktppn,a.tktkomisi,a.tktadm,a.tktapotax,a.calctotal,a.rate,b.*
INTO		#tmptktcpn
FROM		#tmptkt a LEFT JOIN tbltktcpn b with(nolock)
ON			b.ticketnumber = a.ticketnumber

SELECT		COUNT (*) 
FROM		#tmptktcpn 

SELECT		TOP 10 * 
FROM		#tmptktcpn

------------------------------------------------------------------------------------------------
DROP TABLE	#Tmpkurs
SELECT		* 
INTO		#Tmpkurs
FROM		sales.dbo.tblkurs

UPDATE		#tmpkurs 
SET 		currencycode = 'MYR' 
WHERE		currencycode ='RM'

------------------------------------------------------------------------------------------------

UPDATE		#Tmptktcpn 
SET			rate=b.rate
FROM		#tmptktcpn a, #tmpkurs b
WHERE		b.currencycode=a.stationcurr AND
			b.tglkurs=a.stationopendate

UPDATE		#tmptktcpn
SET			idradm = ISNULL(adm,0) * rate, idrfare = ISNULL(fareupdate,0) * rate, idrfSurcharge = ISNULL(fsurcharge,0) * rate,
			idriwjr = ISNULL(iwjr,0) * rate, IDRApotaxrate = ISNULL(Apotax,0) * rate
-----------------------------------------------------------------------------------------------------

SELECT		* 
FROM		#tmptktcpn 
WHERE		idrfare = 0 AND
			farebasis <> 'void'

SELECT		DISTINCT stationcurr 
FROM		#tmptktcpn 
WHERE		idriwjr <> 5000 AND 
			idriwjr <> 0 AND 
			ABS(idriwjr-5000) > 300

SELECT		DISTINCT idriwjr  
FROM		#tmptktcpn 
WHERE		idriwjr <> 5000 AND 
			idriwjr <> 0 AND 
			ABS(idriwjr-5000) > 300

UPDATE		#tmptktcpn 
SET			idriwjr=5000
WHERE		idriwjr <> 5000 AND 
			idriwjr <> 0 

SELECT		* 
FROM		#tmptktcpn 
WHERE		idrfare = 0 AND 
			farebasis <> 'void'

SELECT		* 
FROM		#tmptktcpn 
WHERE		idrfare > 0 AND 
			farebasis <> 'void'
---------------------------------------------------------------------------------------------------

SELECT		DISTINCT fc 
FROM		#tmptktcpn 
ORDER BY	fc 

SELECT		* 
FROM		#tmptktcpn 
WHERE		fc IS NULL-- harus kosong --
---------------------------------------------------------------------------------------------------

UPDATE		tbltktcpn
SET			idrfare = b.idrfare,idradm = b.idradm,idrfsurcharge = b.idrfsurcharge,idriwjr = b.idriwjr, idrapotaxrate = b.idrapotaxrate
FROM		tbltktcpn a INNER JOIN #Tmptktcpn b
ON			b.ticketnumber = a.ticketnumber AND
			b.fc = a.fc 

UPDATE		tbltktcpn
SET			IDRApotaxRate = ISNULL(apotax,0) * c.Rate 
FROM		tblsttrk a
			INNER JOIN tbltktcpn b
ON			b.StKey = a.StKey 
			INNER JOIN #tmpkurs c 
ON			c.tglKurs = a.StationOpenDate AND c.CurrencyCode = a.StationCurr				
WHERE		a.StationOpenDate BETWEEN '24 Nov 2019'AND '26 Nov 2019'

UPDATE		tbltktcpn
SET			IDRApotax = c.AmountDom
FROM		tblsttrk a
			INNER JOIN tbltktcpn b
ON			b.StKey = a.StKey 
			INNER JOIN sales.dbo.tblMasterApotax c
ON			c.Kodedistrict = b.RouteAwal
WHERE		a.StationOpenDate BETWEEN '24 Nov 2019'AND '26 Nov 2019'AND
			b.DomIntlCode = 'D' AND 
			IDRApotax IS NULL

UPDATE		tbltktcpn
SET			IDRApotax = c.AmountIntl
FROM		tblsttrk a 
			INNER JOIN tbltktcpn b
ON			b.StKey = a.StKey
			INNER JOIN sales.dbo.tblMasterApotax c
ON			c.Kodedistrict = b.RouteAwal
WHERE		a.StationOpenDate BETWEEN '24 Nov 2019'AND '26 Nov 2019'AND
			b.DomIntlCode = 'I' AND 
			IDRApotax IS NULL
