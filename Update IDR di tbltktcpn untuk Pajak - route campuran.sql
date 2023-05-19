
DROP TABLE	#tmptkt
SELECT		b.stationopendate,stationcurr,transcode,doctype,intlcode,ticketnumber,tktiwjr,tktfsurcharge,tktbasefare,tktppn,tktkomisi,tktadm,tktapotax,calctotal,rate
INTO		#tmptkt
FROM		tbltkt a WITH(NOLOCK) INNER JOIN tblsttrk b WITH(NOLOCK)
ON			b.stkey = a.stkey 
WHERE		b.stationopendate BETWEEN '24 Nov 2019' AND '26 Nov 2019'AND
			a.intlcode='I' AND 
			a.transcode IN ('SALE','EXCH') AND
			a.doctype IN ('TKT','CNJ') 

DROP TABLE	#tmptktcpn
CREATE		INDEX id1 
ON			#tmptkt(ticketnumber)
SELECT		a.stationopendate,a.stationcurr,a.transcode,a.doctype,a.intlcode,a.tktiwjr,a.tktfsurcharge,
			a.tktbasefare,a.tktppn,a.tktkomisi,a.tktadm,a.tktapotax,a.calctotal,a.rate,b.*
INTO		#tmptktcpn
FROM		#tmptkt a INNER JOIN tbltktcpn b with(nolock)
ON			b.ticketnumber = a.ticketnumber
WHERE		b.DomIntlCode ='D'

SELECT		* 
FROM		#tmptktcpn

DROP TABLE	#Tmpkurs
SELECT		* 
INTO		#Tmpkurs
FROM		sales.dbo.tblkurs
--WHERE		tglKurs BETWEEN '13 Dec 2013' AND '15 Dec 2013'

UPDATE		#tmpkurs 
SET 		currencycode = 'MYR' 
WHERE		currencycode ='RM'

SELECT		* 
FROM		#tmpkurs
ORDER BY	tglKurs 

---------------------------------------------------------------------------------------
-------- NILAI HARUS SAMA dengan jumlah row di #tmptkcpn---------

UPDATE  	#Tmptktcpn 
SET			rate = b.rate
FROM		#tmptktcpn a INNER JOIN #tmpkurs b
ON			b.currencycode = a.stationcurr AND
			b.tglkurs = a.stationopendate

UPDATE		#tmptktcpn
SET			idradm = ISNULL(adm,0) * rate, idrfare = ISNULL(fareupdate,0) * rate, idrfSurcharge = ISNULL(fsurcharge,0) * rate,
			idriwjr = ISNULL(iwjr,0) * rate, idrapotaxrate = ISNULL(apotax,0) * rate

-------------------------------------------------------------------------------------------

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

SELECT		* 
FROM		#tmptktcpn 
WHERE		idriwjr <> 5000 AND 
			idriwjr <> 0 AND ABS(idriwjr-5000) > 300

UPDATE		#tmptktcpn 
SET			idriwjr=5000
WHERE		idriwjr <> 5000 AND 
			idriwjr <> 0 

SELECT		* 
FROM		#tmptktcpn 
WHERE		idrfare = 0 AND 
			farebasis <> 'void'

/* sebelum 1 nov, ppn didapat dari fare * 10%, berarti ada penambahan biaya diluar harga ticket, 
	tapi diubah , ppn diambil dari fare sendiri, karena di internasional nga ada ppn walau utk domestik , jadi kita hitung sendiri */

UPDATE		#tmptktcpn 
SET			IDRFare = ROUND(IDRFare / 1.1,2) 

SELECT		DISTINCT fc 
FROM		#tmptktcpn 

SELECT		* 
FROM		#tmptktcpn 
WHERE		fc IS NULL -- harus kosong -- 

---------------------------------------------------------------------------------------------------------------

UPDATE		tbltktcpn
SET 		idrfare = b.idrfare,idradm = b.idradm,idrfsurcharge = b.idrfsurcharge,idriwjr = b.idriwjr, idrapotaxrate = b.idrapotaxrate
FROM		tbltktcpn a INNER JOIN #Tmptktcpn b
ON			b.ticketnumber = a.ticketnumber AND
			b.fc = a.fc

