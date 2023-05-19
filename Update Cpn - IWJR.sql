
DROP TABLE	#tmp1
SELECT		a.StationOpenDate,b.TicketNumber,b.IssuedDate,b.IntlCode,b.TktIWJR,b.Rate,b.Descr,FOP,b.TransCode,b.DocType,
			b.PreConjTicket,Curr=a.StationCurr, CurrDec = a.StationCurrDec, c.FC,c.IWJR,IWJRUpdate=ISNULL(c.IWJR,0),c.FareBasis,c.RouteAwal,c.RouteAkhir,c.DomIntlCode,
			c.LionWingsCode
INTO		#tmp1
FROM		dmsttrk a WITH(NOLOCK) INNER JOIN dmtkt b WITH(NOLOCK)
ON			b.StKey = a.StKey
			INNER JOIN dmtktcpn c WITH(NOLOCK)
ON			c.StKey = a.StKey AND
			c.StKey = b.StKey AND
			c.TicketNumber = b.TicketNumber
WHERE		a.stationopendate BETWEEN '24 Nov 2019' AND '26 Nov 2019' AND
			b.TransCode IN ('SALE','EXCH') AND
			b.DocType IN ('TKT') 

UPDATE		#tmp1
SET			IWJRUpdate = 0

DROP TABLE	#tmpconj
SELECT		a.StationOpenDate,b.TicketNumber,b.IssuedDate,b.IntlCode,b.TktIWJR,b.Rate,b.Descr,FOP,b.TransCode,b.DocType,
			b.PreConjTicket,Curr = a.StationCurr,CurrDec = a.StationCurrDec, c.FC,c.IWJR,IWJRUpdate = c.IWJR,c.FareBasis,c.RouteAwal,c.RouteAkhir,c.DomIntlCode,
			c.LionWingsCode
INTO		#tmpconj
FROM		dmsttrk a WITH(NOLOCK) INNER JOIN dmtkt b WITH(NOLOCK)
ON			b.StKey = a.StKey
			INNER JOIN dmtktcpn c WITH(NOLOCK)
ON			c.StKey = a.StKey AND
			c.StKey = b.StKey AND
			c.TicketNumber = b.TicketNumber
WHERE		a.stationopendate BETWEEN '24 Nov 2019' AND '26 Nov 2019' AND
			b.TransCode IN ('SALE','EXCH') AND
			b.DocType IN ('CNJ')

UPDATE		#tmpconj 
SET			TktIWJR = b.TktIWJR
FROM		#tmpconj a INNER JOIN dmtkt b WITH(NOLOCK)
ON			b.TicketNumber = a.PreConjTicket


------------------------------------------------------------------------------------------------------------------------------------------------------------
--================================================================================================================================================================
--- KALO ADA NILAI KASIH TAU -------

SELECT		DISTINCT a.* 
FROM		#tmpconj a INNER JOIN(SELECT * FROM #tmpconj) b
ON			b.TicketNumber = a.PreConjTicket
------------------------------------------------------------------------------------------------------------------------------------------------------------

/*
UPDATE		#tmpconj 
SET			tktIWJR = b.tktIWJR
FROM		#tmpconj a,(SELECT * FROM #tmpconj) b
WHERE		b.ticketnumber = a.PreConjTicket

*/
--reset--

DROP TABLE	#Tmpmax
SELECT		TicketNumber,fc=MAX(fc)
INTO		#tmpmax
FROM		#Tmp1
GROUP BY	TicketNumber

DROP TABLE	#tmpNewAllTktCpn
SELECT		StationOpenDate,TicketNumber,IssuedDate,IntlCode,Curr,CurrDec,FOP,TransCode,DocType,ticketasal = TicketNumber,FC,FCAsal=FC,TktIWJR,Rate,
			IWJR,IWJRUpdate,Descr,FareBasis,RouteAwal,RouteAkhir,DomIntlCode, LionWingsCode
INTO		#tmpNewAllTktCpn
FROM		#Tmp1
UNION ALL
SELECT		a.StationOpenDate,ticketnumber=PreConjTicket,IssuedDate,IntlCode,Curr,CurrDec,FOP,TransCode,DocType,ticketasal=a.TicketNumber,fc=a.FC + b.fc,
			fcAsal=a.FC,tktIWJR,rate,IWJR,IWJRUpdate,a.descr,FareBasis,RouteAwal,RouteAkhir,DomIntlCode, LionWingsCode
FROM		#tmpconj a LEFT JOIN #tmpmax b
ON			b.ticketnumber = a.PreConjTicket

UPDATE		#tmpNewAllTktCpn 
SET			IWJRupdate = 0

ALTER TABLE #tmpNewAllTktCpn 
ADD			sudahupdate int default 0

SELECT		DISTINCT COUNT(*), RouteAwal, RouteAkhir
FROM		#tmpNewAllTktCpn
WHERE 		DomIntlCode IS NULL AND
			FareBasis <> 'VOID'
GROUP BY	RouteAwal, RouteAkhir

UPDATE		#tmpNewAllTktCpn
SET			DomIntlCode = 'D'
WHERE 		DomIntlCode IS NULL AND
			FareBasis <> 'VOID'

/*


select * from #tmpNewAllTktCpn where ticketnumber = '9902187870513'
select * from #tmpNewAllTktCpn where ticketnumber = '9902187870514'
select * from #tmpNewAllTktCpn where ticketnumber = '9902187870515'

UPDATE		#tmpNewAllTktCpn 
SET			ticketnumber = 9902187870513, fc=8+fcasal 
WHERE		ticketnumber = 9902187870514


*/


=====================================================================================================================================================
/************************** Looping *********************************/
DROP TABLE	#tmpUpdate
SELECT		TicketNumber, TktIWJR, IWJRUpdate = SUM(IWJRUpdate)
INTO		#tmpUpdate
FROM		#tmpNewAllTktCpn
GROUP BY	TicketNumber, TktIWJR

DROP TABLE	#tmpUpdate00
SELECT *
INTO		#tmpUpdate00
FROM		#tmpUpdate
WHERE		TktIWJR <> IWJRUpdate

DROP TABLE	#tmpTktCpnDom
SELECT		DISTINCT a.TicketNumber, Jumlah = COUNT(*)
INTO		#TmpTktCpnDom
FROM		#tmpNewAllTktCpn a INNER JOIN #tmpUpdate00 b
ON	 		b.TicketNumber = a.TicketNumber
WHERE		a.tktIWJR <> 0 AND
			a.FareBasis <> 'void' AND
			a.DomIntlCode = 'D'
GROUP BY	a.TicketNumber

DROP TABLE	#tmpTktCpnInt
SELECT		DISTINCT a.TicketNumber, Jumlah = COUNT(*)
INTO		#tmpTktCpnInt
FROM		#tmpNewAllTktCpn a INNER JOIN #tmpUpdate00 b
ON	 		b.TicketNumber = a.TicketNumber 
WHERE		a.tktIWJR <> 0 AND
			a.FareBasis <> 'void' AND
			a.DomIntlCode = 'I'
GROUP BY	a.TicketNumber

ALTER TABLE #TmpTktCpnDom 
ADD			IWJRUpdate money default 0

ALTER TABLE #TmpTktCpnInt 
ADD			IWJRUpdate money default 0

UPDATE		#tmpNewAllTktCpn
SET			IWJRUpdate = ROUND(IWJRUpdate, 2)
WHERE		CurrDec = 2

UPDATE		#tmpNewAllTktCpn
SET			IWJRUpdate = ROUND(IWJRUpdate, 0)
WHERE		CurrDec = 0


-------------------------------------------------------------------------------------
/* 1-  Update IWJR Domestik International */
/*gljkt.dbo.*/

DROP TABLE	#tmpKurs
SELECT *
INTO		#tmpKurs
FROM		sales.dbo.tblKurs 

UPDATE		#tmpKurs
SET			CurrencyCode = 'MYR'
WHERE		CurrencyCode = 'RM'

UPDATE		#TmpTktCpnDom
SET			IWJRUpdate = 5000 / c.Rate
FROM		#tmpTktCpnDom a, #tmpNewAllTktCpn b, #tmpKurs c
WHERE		b.TicketNumber = a.TicketNumber AND
			c.CurrencyCode = LEFT(b.Curr,3) AND
			c.tglkurs = b.stationopendate AND
			b.TktIWJR < 5000

UPDATE		#tmpTktCpnInt
SET			IWJRUpdate = (a.TktIWJR - c.IWJRUpdate) / b.Jumlah
FROM		#tmpNewAllTktCpn a INNER JOIN #tmpTktCpnInt b
ON			b.TicketNumber = a.TicketNumber 
			INNER JOIN #tmpTktCpnDom c
ON			c.TicketNumber = b.TicketNumber AND
			c.TicketNumber = a.TicketNumber
WHERE		a.TktIWJR < 5000

UPDATE		#tmpNewAllTktCpn
SET			IWJRUpdate = b.IWJRUpdate
FROM		#tmpNewAllTktCpn a INNER JOIN #tmpTktCpnDom b
ON			b.TicketNumber = a.TicketNumber
WHERE		a.TktIWJR < 5000 AND
			a.DomIntlCode = 'D' 
			
UPDATE		#tmpNewAllTktCpn
SET			IWJRUpdate = b.IWJRUpdate
FROM		#tmpNewAllTktCpn a INNER JOIN #tmpTktCpnInt b
ON			b.TicketNumber = a.TicketNumber
WHERE		a.TktIWJR < 5000 AND
			a.DomIntlCode = 'I' AND
			b.IWJRUpdate IS NOT NULL

UPDATE		#tmpNewAllTktCpn
SET			IWJRUpdate = ROUND(IWJRUpdate, 2)
WHERE		CurrDec = 2

UPDATE		#tmpNewAllTktCpn
SET			IWJRUpdate = ROUND(IWJRUpdate, 0)
WHERE		CurrDec = 0

DROP TABLE	#tmpUpdateSelisihDec
SELECT		DISTINCT b.TicketNumber, b.TktIWJR
INTO		#tmpUpdateSelisihDec
FROM		#tmpTktCpnInt a INNER JOIN #tmpNewAllTktCpn b
ON			b.TicketNumber = a.TicketNumber
WHERE		a.IWJRUpdate <> 0

ALTER TABLE	#tmpUpdateSelisihDec 
ADD			Selisih MONEY DEFAULT 0

DROP TABLE	#tmpUpdateSelisihDec001
SELECT		DISTINCT b.TicketNumber, IWJRUpdate = SUM(ISNULL(b.IWJRUpdate,0))
INTO		#tmpUpdateSelisihDec001
FROM		#tmpTktCpnInt a INNER JOIN #tmpNewAllTktCpn b
ON			b.TicketNumber = a.TicketNumber
WHERE		a.IWJRUpdate <> 0
GROUP BY	b.TicketNumber
ORDER BY	b.TicketNumber

UPDATE		#tmpUpdateSelisihDec
SET			Selisih = TktIWJR - IWJRUpdate
FROM		#tmpUpdateSelisihDec a INNER JOIN #tmpUpdateSelisihDec001 b
ON			b.TicketNumber = a.TicketNumber

DROP TABLE	#tmpTktMinFC
SELECT		a.TicketNumber, FC = MIN(a.FC)
INTO		#tmpTktMinFC
FROM		#tmpNewAllTktCpn a INNER JOIN #tmpUpdateSelisihDec b
ON			b.TicketNumber = a.TicketNumber 
WHERE		a.DomIntlCode = 'I'
GROUP BY	a.TicketNumber
ORDER BY	a.TicketNumber

UPDATE		#tmpNewAllTktCpn
SET			IWJRUpdate = IWJRUpdate + Selisih
FROM		#tmpNewAllTktCpn a INNER JOIN #tmpUpdateSelisihDec b
ON			b.TicketNumber = a.TicketNumber
			INNER JOIN #tmpTktMinFC c
ON			c.TicketNumber = b.TicketNumber AND
			c.FC = a.FC
------------------------------------------------------------------------------------------------------------
/* 2- Update IWJR Domestik International */

UPDATE		#TmpTktCpnDom
SET			IWJRUpdate = Jumlah * 5000

UPDATE		#tmpTktCpnInt
SET			IWJRUpdate = (a.TktIWJR - c.IWJRUpdate) / b.Jumlah
FROM		#tmpNewAllTktCpn a INNER JOIN #tmpTktCpnInt b
ON			b.TicketNumber = a.TicketNumber
			INNER JOIN #tmpTktCpnDom c
ON			c.TicketNumber = b.TicketNumber AND
			c.TicketNumber = a.TicketNumber
WHERE		a.TktIWJR >= 5000

UPDATE		#tmpNewAllTktCpn
SET			IWJRUpdate = b.IWJRUpdate / Jumlah
FROM		#tmpNewAllTktCpn a INNER JOIN #tmpTktCpnDom b
ON			b.TicketNumber = a.TicketNumber
WHERE		a.TktIWJR >= 5000 AND
			a.DomIntlCode = 'D'

UPDATE		#tmpNewAllTktCpn
SET			IWJRUpdate = b.IWJRUpdate
FROM		#tmpNewAllTktCpn a INNER JOIN #tmpTktCpnInt b
ON			b.TicketNumber = a.TicketNumber
WHERE		a.TktIWJR >= 5000 AND
			a.DomIntlCode = 'I' AND
			b.IWJRUpdate IS NOT NULL
		
---------------------------------------------------------------------------------------------------------

/* 3-  Update IWJR Domestik & Update VND */

UPDATE		#tmpTktCpnDom
SET			IWJRUpdate = a.TktIWJR / b.Jumlah
FROM		#tmpNewAllTktCpn a INNER JOIN #tmpTktCpnDom b
ON			b.TicketNumber = a.TicketNumber
WHERE		/*a.TktIWJR < 5000 AND*/
			a.DomIntlCode = 'D'

SELECT		a.IWJRUpdate, b.*
FROM		#tmpTktCpnDom a INNER JOIN #tmpNewAllTktCpn b
ON			b.TicketNumber = a.TicketNumber
WHERE		a.IWJRUpdate IS NOT NULL
		
UPDATE		#tmpNewAllTktCpn
SET			IWJRUpdate = ROUND(IWJRUpdate, 2)
WHERE		CurrDec = 2

UPDATE		#tmpNewAllTktCpn
SET			IWJRUpdate = ROUND(IWJRUpdate, 0)
WHERE		CurrDec = 0

DROP TABLE	#tmpUpdateSelisihDec
SELECT		DISTINCT b.TicketNumber, b.TktIWJR
INTO		#tmpUpdateSelisihDec
FROM		#tmpTktCpnDom a INNER JOIN #tmpNewAllTktCpn b
ON			b.TicketNumber = a.TicketNumber 
WHERE		a.IWJRUpdate <> 0

ALTER TABLE #tmpUpdateSelisihDec ADD Selisih money default 0

DROP TABLE	#tmpUpdateSelisihDec001
SELECT		DISTINCT b.TicketNumber, IWJRUpdate = SUM(ISNULL(b.IWJRUpdate,0))
INTO		#tmpUpdateSelisihDec001
FROM		#tmpTktCpnDom a INNER JOIN #tmpNewAllTktCpn b
ON			b.TicketNumber = a.TicketNumber 
WHERE		a.IWJRUpdate <> 0
GROUP BY	b.TicketNumber
ORDER BY	b.TicketNumber

UPDATE		#tmpUpdateSelisihDec
SET			Selisih = TktIWJR - IWJRUpdate
FROM		#tmpUpdateSelisihDec a INNER JOIN #tmpUpdateSelisihDec001 b
ON			b.TicketNumber = a.TicketNumber

DROP TABLE	#tmpTktMinFC
SELECT		a.TicketNumber, FC = min(a.FC)
INTO		#tmpTktMinFC
FROM		#tmpNewAllTktCpn a INNER JOIN #tmpUpdateSelisihDec b
ON			b.TicketNumber = a.TicketNumber
WHERE		a.DomIntlCode = 'D'
GROUP BY	a.TicketNumber
ORDER BY	a.TicketNumber

UPDATE		#tmpNewAllTktCpn
SET			IWJRUpdate = IWJRUpdate + Selisih
FROM		#tmpNewAllTktCpn a INNER JOIN #tmpUpdateSelisihDec b
ON			b.TicketNumber = a.TicketNumber
			INNER JOIN #tmpTktMinFC c
ON			c.TicketNumber = b.TicketNumber AND
			c.TicketNumber = a.TicketNumber AND
			c.FC = a.FC

UPDATE		#tmpNewAllTktCpn
SET			IWJRUpdate = b.IWJRUpdate
FROM		#tmpNewAllTktCpn a, #tmpTktCpnDom b
WHERE		b.TicketNumber = a.TicketNumber AND
			a.Curr = 'VND'
	
------------------------------------------------------------------------------------------------------------------------------------------------
/* 4-  Update IWJR International */
UPDATE		#tmpTktCpnInt
SET			IWJRUpdate = a.TktIWJR / b.Jumlah
FROM		#tmpNewAllTktCpn a INNER JOIN #tmpTktCpnInt b
ON			b.TicketNumber = a.TicketNumber 
WHERE		a.TktIWJR >= 5000 AND
			a.DomIntlCode = 'I'

SELECT		a.IWJRUpdate, b.*
FROM		#tmpTktCpnInt a INNER JOIN #tmpNewAllTktCpn b
ON			b.TicketNumber = a.TicketNumber
WHERE		a.IWJRUpdate IS NOT NULL

UPDATE		#tmpNewAllTktCpn
SET			IWJRUpdate = b.IWJRUpdate
FROM		#tmpNewAllTktCpn a INNER JOIN #tmpTktCpnInt b
ON			b.TicketNumber = a.TicketNumber
WHERE		a.TktIWJR >= 5000 AND
			a.DomIntlCode = 'I'

UPDATE		#tmpNewAllTktCpn
SET			IWJRUpdate = ROUND(IWJRUpdate, 2)
WHERE		CurrDec = 2

UPDATE		#tmpNewAllTktCpn
SET			IWJRUpdate = ROUND(IWJRUpdate, 0)
WHERE		CurrDec = 0

DROP TABLE	#tmpUpdateSelisihDec
SELECT		DISTINCT b.TicketNumber, b.TktIWJR
INTO		#tmpUpdateSelisihDec
FROM		#tmpTktCpnInt a INNER JOIN #tmpNewAllTktCpn b
ON			b.TicketNumber = a.TicketNumber
WHERE		a.IWJRUpdate <> 0

ALTER TABLE #tmpUpdateSelisihDec 
ADD			Selisih money default 0

DROP TABLE	#tmpUpdateSelisihDec001
SELECT DISTINCT b.TicketNumber, IWJRUpdate = SUM(ISNULL(b.IWJRUpdate,0))
INTO		#tmpUpdateSelisihDec001
FROM		#tmpTktCpnInt a INNER JOIN #tmpNewAllTktCpn b
ON			b.TicketNumber = a.TicketNumber 
WHERE		a.IWJRUpdate <> 0
GROUP BY	b.TicketNumber
ORDER BY	b.TicketNumber

UPDATE		#tmpUpdateSelisihDec
SET			Selisih = TktIWJR - IWJRUpdate
FROM		#tmpUpdateSelisihDec a INNER JOIN #tmpUpdateSelisihDec001 b
ON			b.TicketNumber = a.TicketNumber

DROP TABLE	#tmpTktMinFC
SELECT		a.TicketNumber, FC = MIN(a.FC)
INTO		#tmpTktMinFC
FROM		#tmpNewAllTktCpn a INNER JOIN #tmpUpdateSelisihDec b
ON			b.TicketNumber = a.TicketNumber 
WHERE		a.DomIntlCode = 'I'
GROUP BY	a.TicketNumber
ORDER BY	a.TicketNumber

UPDATE		#tmpNewAllTktCpn
SET			IWJRUpdate = IWJRUpdate + Selisih
FROM		#tmpNewAllTktCpn a INNER JOIN #tmpUpdateSelisihDec b
ON			b.TicketNumber = a.TicketNumber
			INNER JOIN #tmpTktMinFC c
ON			c.TicketNumber = b.TicketNumber AND
			c.TicketNumber = a.TicketNumber AND 
			c.FC = a.FC


---------------------------------------------------------------------------------------------------------------------------------------------------
/* 5 -     international                */

DROP TABLE	#tmpTktCpnSpecInt
SELECT		DISTINCT a.TicketNumber, Jumlah = COUNT(*)
INTO		#tmpTktCpnSpecInt
FROM		#tmpNewAllTktCpn a INNER JOIN #tmpUpdate00 b
ON			b.TicketNumber = a.TicketNumber
WHERE 		a.tktIWJR <> 0 AND
			a.FareBasis <> 'void' AND
			a.DomIntlCode = 'I'
GROUP BY	a.TicketNumber
ORDER BY	a.TicketNumber

DELETE		#tmpTktCpnSpecInt
FROM		#tmpTktCpnSpecInt a INNER JOIN #TmpTktCpnDom b
ON			b.TicketNumber = a.TicketNumber

ALTER TABLE #tmpTktCpnSpecInt ADD IWJRUpdate money default 0

UPDATE		#tmpTktCpnSpecInt
SET			IWJRUpdate = a.TktIWJR / b.Jumlah
FROM		#tmpNewAllTktCpn a INNER JOIN #tmpTktCpnSpecInt b
ON			b.TicketNumber = a.TicketNumber
WHERE		a.TktIWJR < 5000 AND
			a.DomIntlCode = 'I'

SELECT		a.IWJRUpdate, b.*
FROM		#tmpTktCpnSpecInt a INNER JOIN #tmpNewAllTktCpn b
ON			b.TicketNumber = a.TicketNumber
WHERE		a.IWJRUpdate IS NOT NULL

UPDATE		#tmpNewAllTktCpn
SET			IWJRUpdate = b.IWJRUpdate
FROM		#tmpNewAllTktCpn a INNER JOIN #tmpTktCpnSpecInt b
ON			b.TicketNumber = a.TicketNumber
WHERE		a.TktIWJR < 5000 AND
			a.DomIntlCode = 'I' AND
			a.FareBasis <> 'void' 

--SELECT * FROM #tmpNewAllTktCpn WHERE ticketnumber = 9902179454815

---------------------------------------------------------------------------------------------------------------------------------------------

/* Update IWJR Domestic */

SELECT		DISTINCT b.*
FROM		#tmpTktCpnDom a INNER JOIN #tmpNewAllTktCpn b
ON			b.TicketNumber = a.TicketNumber
WHERE		b.TktIWJR >= 5000
ORDER BY	b.TicketNumber, b.FC

UPDATE		#tmpNewAllTktCpn
SET			IWJRUpdate = 0, sudahupdate = 0
FROM		#tmpTktCpnDom a INNER JOIN #tmpNewAllTktCpn b
ON			b.TicketNumber = a.TicketNumber
WHERE		b.TktIWJR >= 5000

DROP TABLE	#tmploopIWJR
SELECT		DISTINCT a.ticketnumber,a.tktIWJR
INTO		#tmploopIWJR
FROM		#tmpNewAllTktCpn a INNER JOIN #tmpTktCpnDom b
ON			b.TicketNumber = a.TicketNumber
WHERE		a.FareBasis <> 'void' AND
			tktIWJR <> 0 AND
			CONVERT(INTEGER,tktiwjr) % 5000  = 0 AND
			DomIntlCode = 'D'
ORDER BY	a.ticketnumber

DROP TABLE	#tmpmaxfc
SELECT		a.ticketnumber,fc=max(fc) 
INTO		#tmpmaxFC
FROM		#tmpNewAllTktCpn a INNER JOIN #tmploopIWJR b
ON			b.ticketnumber = a.ticketnumber
WHERE		a.FareBasis <> 'void' 
GROUP BY	a.ticketnumber

DROP TABLE	#tmpminfc
SELECT		a.ticketnumber,fc=min(fc) 
INTO		#tmpminFC
FROM		#tmpNewAllTktCpn a INNER JOIN #tmploopIWJR b
ON			b.TicketNumber = a.TicketNumber
WHERE		a.FareBasis <> 'void'  AND a.IWJRUpdate = 0 AND 1=2
GROUP BY	a.ticketnumber

WHILE 1=1
BEGIN
	TRUNCATE TABLE #tmpminFC
	INSERT		#tmpminFC
	SELECT		a.ticketnumber,fc = MIN(fc) 
	FROM		#tmpNewAllTktCpn a INNER JOIN #tmploopIWJR b
	ON			b.TicketNumber = a.TicketNumber
	WHERE		a.FareBasis <> 'void'  AND 
				ISNULL(a.IWJRUpdate,0) = 0 AND b.tktIWJR <> 0 AND CONVERT(INTEGER,b.tktiwjr) % 5000  = 0 AND
				ISNULL(a.SudahUpdate,0) = 0
	GROUP BY	a.TicketNumber

	IF @@rowcount = 0 
		BREAK

	UPDATE		#tmpNewAllTktCpn 
	SET			IWJRUpdate=5000, SudahUpdate=1
	FROM		#tmpNewAllTktCpn a INNER JOIN #tmpminFc b
	ON			b.TicketNumber = a.TicketNumber AND
				b.fc=a.fc
				INNER JOIN #tmploopIWJR c
	ON			c.TicketNumber = b.TicketNumber AND
				c.TicketNumber = a.TicketNumber 
				INNER JOIN #tmpmaxfc d		
	ON			d.TicketNumber = a.TicketNumber AND
				d.TicketNumber = c.TicketNumber AND
				d.TicketNumber = b.TicketNumber
	WHERE		a.DomIntlCode = 'D'


	UPDATE		#tmploopIWJR 
	SET			tktIWJR = a.tktIWJR - c.IWJRUpdate
	FROM		#TmploopIWJR a INNER JOIN #tmpminFC b
	ON			b.TicketNumber = a.TicketNumber
				INNER JOIN #tmpNewAllTktCpn c
	ON			c.TicketNumber = b.TicketNumber AND
				c.TicketNumber = a.TicketNumber AND
				c.fc = b.fc

	DELETE		#tmploopIWJR 
	WHERE		tktIWJR = 0
END

-----------------------------------------------------------------------------------------------------------------------------------------------

DROP TABLE #tmpCheck
SELECT *
INTO		#tmpCheck
FROM		#tmpNewAllTktCpn
WHERE		IWJRUpdate = 0 AND
			TktIWJR <> 0 AND
			TktIWJR < 5000

SELECT		a.*
FROM		#tmpNewAllTktCpn a INNER JOIN #tmpCheck b
ON			b.TicketNumber= a.TicketNumber
WHERE 		a.IWJRUpdate = 0
ORDER BY	a.TicketNumber
----------------------------------------------------------------------------------------------------------------------------------------------

UPDATE		#tmpNewAllTktCpn 
SET			IWJRUpdate = ROUND((50000/ b.rate),2) 
FROM		#tmpNewAllTktCpn a, #tmpKurs b
WHERE		((RouteAwal = 'CGK' AND RouteAkhir = 'KUL') OR
			(RouteAwal = 'KUL' AND RouteAkhir = 'CGK') OR
			(RouteAwal = 'CGK' AND RouteAkhir = 'SIN') OR
			(RouteAwal = 'SIN' AND RouteAkhir = 'CGK') OR
			(RouteAwal = 'BDJ' AND RouteAkhir = 'PEN') OR
			(RouteAwal = 'PEN' AND RouteAkhir = 'BDJ')) AND 
			lionwingscode = '' AND 
			TktIWJR > 0 AND
			b.tglKurs = a.StationOpenDate AND
			b.CurrencyCode = a.Curr AND
			FareBasis <> 'VOID'

----------------------------------------------------------------------------------------------------------------------------------------------

--LOOPING--

DROP TABLE	#tmptktIWJR
SELECT		TicketNumber, TktIWJR
INTO		#tmptktIWJR
FROM		#tmpNewAllTktCpn 
WHERE		FC = 1
ORDER BY	TicketNumber

DROP TABLE #tmpIWJRUpdate
SELECT		TicketNumber, IWJRUpdate = SUM(ISNULL(IWJRUpdate,0))
INTO		#tmpIWJRUpdate
FROM		#tmpNewAllTktCpn 
GROUP BY	TicketNumber
ORDER BY	TicketNumber

DROP TABLE	#tmp10 
SELECT		a.*, b.IWJRUpdate, Selisih = CONVERT(Money,NULL) 
INTO		#tmp10
FROM		#tmptktIWJR a INNER JOIN #tmpIWJRUpdate b
ON	 		b.TicketNumber = a.TicketNumber		-----------  affected ke 3 => harus kosong     -----------
WHERE		b.IWJRUpdate <> a.tktIWJR    -- KALAU KOSONG LANGSUNG KE END PROCESS -- KALO GA KOSONG LOOPING 1 LOOPING 2 --
ORDER BY	a.TicketNumber

select * from #tmp10

---#TMP10 HARUS KOSONG, KALO ADA ISI JALANIN BAWAH NO 1 BALIK KE LOOPING LALU JALANIN LG NO 2 DST BERULANG 
------------------------------------------------------------------------------------------------------------------------------
/*1

DROP TABLE	#tmpakhir
SELECT		b.* 
INTO		#tmpakhir
FROM		#tmp10 a, #tmpNewAllTktCpn b
WHERE		b.TicketNumber = a.TicketNumber 

DELETE		#tmpakhir
WHERE		((RouteAwal = 'CGK' AND RouteAkhir = 'KUL') OR
			(RouteAwal = 'KUL' AND RouteAkhir = 'CGK') OR
			(RouteAwal = 'CGK' AND RouteAkhir = 'SIN') OR
			(RouteAwal = 'SIN' AND RouteAkhir = 'CGK') OR
			(RouteAwal = 'BDJ' AND RouteAkhir = 'PEN') OR
			(RouteAwal = 'PEN' AND RouteAkhir = 'BDJ')) AND
			LionWingsCode = ''

DELETE		#tmpakhir
WHERE		DomIntlCode = 'D'

UPDATE		#tmpNewAllTktCpn 
SET			IWJRUpdate = 0
FROM		#tmpakhir a, #tmpNewAllTktCpn b
WHERE		b.TicketNumber = a.TicketNumber AND
			b.FC = a.FC

-----------------------------------------------------------------------
/*2*/

DROP TABLE	#tmpFC
SELECT		b.TicketNumber, totalFC = COUNT(FC)
INTO		#tmpFC 
FROM		#tmp10 a, #tmpNewAllTktCpn b
WHERE		b.TicketNumber = a.TicketNumber
GROUP BY	b.TicketNumber

DROP TABLE	#tmpFCExcept
SELECT		b.ticketnumber, totalFC = COUNT(*)
INTO		#tmpFCExcept
FROM		#tmp10 a, #tmpNewAllTktCpn b
WHERE		b.TicketNumber = a.TicketNumber AND
			((((RouteAwal = 'CGK' AND RouteAkhir = 'KUL') OR
			(RouteAwal = 'KUL' AND RouteAkhir = 'CGK') OR
			(RouteAwal = 'CGK' AND RouteAkhir = 'SIN') OR
			(RouteAwal = 'SIN' AND RouteAkhir = 'CGK') OR
			(RouteAwal = 'BDJ' AND RouteAkhir = 'PEN') OR
			(RouteAwal = 'PEN' AND RouteAkhir = 'BDJ')) AND 
			LionWingsCode = '') OR DomIntlCode = 'D') AND 
			FareBasis <> 'VOID'
GROUP BY	b.TicketNumber

UPDATE		#tmp10 
SET			selisih = ROUND(((c.TktIWJR - IWJRUpdate)/ (a.totalfc - b.totalFC)),2) 
FROM		#tmpFC a, #tmpFCExcept b, #tmp10 c
WHERE		b.TicketNumber = a.TicketNumber AND
			c.TicketNumber = a.TicketNumber AND 
			c.TicketNumber = b.TicketNumber AND
			a.totalFC - b.totalFC <> 0 

DROP TABLE	#tmpakhir
SELECT		b.* 
INTO		#tmpakhir
FROM		#tmp10 a, #tmpNewAllTktCpn b
WHERE		b.TicketNumber = a.TicketNumber 

DELETE		#tmpakhir
WHERE		((((RouteAwal = 'CGK' AND RouteAkhir = 'KUL') OR
			(RouteAwal = 'KUL' AND RouteAkhir = 'CGK') OR
			(RouteAwal = 'CGK' AND RouteAkhir = 'SIN') OR
			(RouteAwal = 'SIN' AND RouteAkhir = 'CGK') OR
			(RouteAwal = 'BDJ' AND RouteAkhir = 'PEN') OR
			(RouteAwal = 'PEN' AND RouteAkhir = 'BDJ')) AND 
			LionWingsCode = '') or DomIntlCode = 'D')

UPDATE		#tmpakhir 
SET			IWJRUpdate = a.IWJRUpdate + b.selisih
FROM		#tmpakhir a, #tmp10 b
WHERE		b.TicketNumber = a.TicketNumber AND
			a.IWJRUpdate + b.selisih > 0

UPDATE		#tmpNewAllTktCpn
SET			IWJRUpdate = a.iwjrupdate 
FROM		#tmpakhir a, #tmpNewAllTktCpn b
WHERE		b.FC = a.FC AND 
			b.TicketNumber = a.TicketNumber AND
			b.FareBasis <> 'VOID'

-----------------------------------------------------------------------
3.

UPDATE		#tmp10 
SET			selisih = tktiwjr - iwjrupdate

DROP TABLE	#tmpfc
SELECT		a.ticketnumber, minFC = min(fc) 
INTO		#tmpfc 
FROM		#tmpnewalltktcpn a, #tmp10 b
WHERE		b.ticketnumber = a.ticketnumber AND 
			a.iwjrupdate <> 0
GROUP BY	a.ticketnumber

UPDATE		#tmpNewAllTktCpn
SET			iwjrupdate = a.iwjrupdate + selisih
FROM		#tmpNewAllTktCpn a, #tmp10 b, #tmpfc c
WHERE		b.TicketNumber = a.TicketNumber AND 
			c.TicketNumber = b.TicketNumber AND
			c.TicketNumber = a.TicketNumber AND
			c.minFC = a.FC AND
			a.iwjrupdate <> 0 AND 
			a.farebasis <> 'VOID'
*/
------------------------------------------------------------------------------------------------------

select * from #tmpNewAllTktCpn
where FareBasis = 'VOID' AND IWJRUpdate <> 0 --- GA BOLE ADA NILAI
-------------------------------------------------------------------------------------------------------------
---END PROCESS--


BEGIN TRAN

UPDATE		dmtktcpn
SET			IWJR = 0
WHERE		IWJR IS NULL

UPDATE		dmtktcpn
SET			IWJR = b.IWJRUpdate
FROM		dmtktcpn a INNER JOIN #tmpNewAllTktCpn b
ON			b.ticketasal = a.TicketNumber AND
			b.FCAsal = a.FC 
			INNER JOIN dmtkt c with(nolock)
ON			c.StKey = a.StKey AND 
			c.TicketNumber = a.TicketNumber AND
			c.TicketNumber = b.ticketasal
			
COMMIT TRAN

