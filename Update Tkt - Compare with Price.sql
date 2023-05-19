DROP TABLE	#tmpprice
SELECT		TicketNumber, total = SUM(amount) 
INTO		#tmpprice 
FROM		dmtktpr 
GROUP BY	TicketNumber

DROP TABLE	#tmptkt
SELECT		b.* 
INTO		#tmptkt 
FROM		#tmpprice a, dmtkt b WITH(NOLOCK)
WHERE		b.TicketNumber = a.TicketNumber AND
		    TransCode <> 'VOID'

UPDATE		dmtktpr
SET			kodebiaya = 'D5'
WHERE		kodebiaya like 'PSC%'			
UPDATE		dmtktpr
SET			kodebiaya = 'D8'
WHERE		kodebiaya like 'D8%'
UPDATE		dmtktpr
SET			kodebiaya = 'K3'
WHERE		kodebiaya like 'K3%'
UPDATE		dmtktpr
SET			kodebiaya = 'WY'
WHERE		kodebiaya like 'WY%'
UPDATE		dmtktpr
SET			kodebiaya = 'WG'
WHERE		kodebiaya like 'WG%'
UPDATE		dmtktpr
SET			kodebiaya = 'E7'
WHERE		kodebiaya like 'E7%'	
UPDATE		dmtktpr
SET			kodebiaya = 'G8'
WHERE		kodebiaya like 'G8%'		
UPDATE		dmtktpr
SET			kodebiaya = 'UT'
WHERE		kodebiaya like 'UT%'
UPDATE		dmtktpr
SET			kodebiaya = 'RG'
WHERE		kodebiaya like 'RG%'				
UPDATE		dmtktpr
SET			kodebiaya = 'OW'
WHERE		kodebiaya like 'OW%'	
UPDATE		dmtktpr
SET			kodebiaya = 'C7'
WHERE		kodebiaya like 'C7%'
UPDATE		dmtktpr
SET			kodebiaya = 'E3'
WHERE		kodebiaya like 'E3%'	
UPDATE		dmtktpr
SET			kodebiaya = 'IO'
WHERE		kodebiaya like 'IO%'	
UPDATE		dmtktpr
SET			kodebiaya = 'YRI'
WHERE		kodebiaya like 'YR%'	


--------------CEK KALO ADA KODEBIAYA BARU KONFIRMASI SILVANA-----------------
SELECT		DISTINCT KodeBiaya 
FROM		dmtktpr
WHERE		KodeBiaya NOT IN (SELECT KodeBiaya FROM salesod.dbo.tblmastercategory) AND
			KodeBiaya NOT IN ('BSF','D8','E7','G8','ID','ID1','K3','YQF','YR','YRI','CP','YQ','Z3','TAX','IYR') 
			
--kalo ada kode biaya baru buat ngecek nol atau gak, kalo nol biarin aja
--select * from dmtktpr where kodebiaya = 'ER'
---------------------------------------------------------------------------------------------------------
DROP TABLE	#tmp1
SELECT		b.* 
INTO		#tmp1 
FROM		#tmptkt a, dmtkt b WITH(NOLOCK)
WHERE		b.TicketNumber = a.TicketNumber

DROP TABLE	#tmp2
SELECT		b.* 
INTO		#tmp2 
FROM		#tmp1 a, dmtkt b WITH(NOLOCK)
WHERE		b.TicketNumber = a.TicketNumber 

UPDATE		#tmp2
SET			AccAmount = 0, AccAdm = 0, TktBaseFare = 0, TktPPN = 0, TktFSurcharge = 0, TktIWJR = 0,
			TktAdm = 0, TktApoTax = 0, TktPPNOD = 0, tktRefCancelFee = 0, tktadmkenappn = 0, tktppnin = 0
			
--------------------------------------------------------------------------------------------------------------
DROP TABLE	#tmpprice
SELECT		b.TicketNumber, b.KodeBiaya, Total= SUM(b.amount)
INTO		#tmpprice 
FROM		#tmp2 a, dmtktpr b
WHERE		b.TicketNumber = a.TicketNumber
GROUP BY	b.TicketNumber, b.KodeBiaya
-----------------------------------------------------------

UPDATE		#tmp2
SET			TktAdmKenaPPN = b.total
FROM		#tmp2 a, #tmpprice b
WHERE		b.TicketNumber = a.TicketNumber AND 
			b.KodeBiaya in ('AP','APJ')

UPDATE		#tmp2
SET			TktFSurcharge = b.total
FROM		#tmp2 a, #tmpprice b
WHERE		b.TicketNumber = a.TicketNumber AND 
			b.KodeBiaya in ('YQ','YQF')

DROP TABLE	#tmpIWJR
SELECT		a.TicketNumber , totalIWJR = SUM(b.total) 
INTO		#tmpIWJR
FROM		#tmp2 a, #tmpprice b
WHERE		b.TicketNumber = a.TicketNumber AND 
			b.KodeBiaya in ('YR','YR1','YRI','IYR') 
GROUP BY	a.TicketNumber

UPDATE		#tmp2
SET			tktiwjr = b.totalIWJR
FROM		#tmp2 a, #tmpIWJR b
WHERE		b.TicketNumber = a.TicketNumber 

-----------------------------------------------------------------------------------------------------
DROP TABLE	#tmpPPNIN
SELECT		a.TicketNumber , totalppnIN = SUM(b.total) 
INTO		#tmpPPNIN
FROM		#tmp2 a, #tmpprice b
WHERE		b.TicketNumber = a.TicketNumber AND 
			b.KodeBiaya in ('K3') 
GROUP BY	a.TicketNumber

UPDATE		#tmp2
SET			tktPPNIN = b.totalppnIN
FROM		#tmp2 a, #tmpPPNIN b
WHERE		b.TicketNumber = a.TicketNumber

-----------------------------------------------------------------------------------------------------
DROP TABLE	#tmpPPNOD
SELECT		a.TicketNumber , totalppnod = SUM(b.total) 
INTO		#tmpPPNOD
FROM		#tmp2 a, #tmpprice b
WHERE		b.TicketNumber = a.TicketNumber AND 
			b.KodeBiaya like 'D8%'
GROUP BY	a.TicketNumber

UPDATE		#tmp2
SET			TktPPNOD = b.totalppnod
FROM		#tmp2 a, #tmpPPNOD b
WHERE		b.TicketNumber = a.TicketNumber
-------------------------------------------------------------------------
DROP TABLE	#tmpPPN
SELECT		a.TicketNumber , totalppn = SUM(b.total) 
INTO		#tmpPPN
FROM		#tmp2 a, #tmpprice b
WHERE		b.TicketNumber = a.TicketNumber AND 
			b.KodeBiaya IN ('ID','ID1','IDR','TAX')
GROUP BY	a.TicketNumber

UPDATE		#tmp2
SET			tktppn = b.totalppn
FROM		#tmp2 a, #tmpPPN b
WHERE		b.TicketNumber = a.TicketNumber
-----------------------------------------------------------------------
UPDATE		#tmp2
SET			TktBaseFare = b.total
FROM		#tmp2 a, #tmpprice b
WHERE		b.TicketNumber = a.TicketNumber AND 
			b.KodeBiaya in ('BSF')

DROP TABLE	#tmpCF
SELECT		a.TicketNumber , totalCF = SUM(b.total) 
INTO		#tmpCF
FROM		#tmp2 a, #tmpprice b
WHERE		b.TicketNumber = a.TicketNumber AND 
			b.KodeBiaya IN ('F1','F3')
GROUP BY	a.TicketNumber

UPDATE		#tmp2
SET			tktRefCancelFee = b.totalCF
FROM		#tmp2 a, #tmpCF b
WHERE		b.TicketNumber = a.TicketNumber  AND 
			(a.TransCode LIKE 'rf%' OR 
			(a.TransCode = 'SALE' AND a.DocType = 'VOU'))

DROP TABLE	#tmpapotax
SELECT		a.TicketNumber , totalapotax = SUM(b.total) 
INTO		#tmpapotax
FROM		#tmp2 a, #tmpprice b
WHERE		b.TicketNumber = a.TicketNumber AND 
			(b.KodeBiaya IN (	SELECT	KodeBiaya 
								FROM	salesod.dbo.tblmastercategory 
								WHERE	Category = 'APOTAX') OR 
										KodeBiaya IN ('E7','G8')) AND 
										KodeBiaya NOT IN ('F1')								
GROUP BY	a.TicketNumber

UPDATE		#tmp2
SET			tktapotax = b.totalapotax 
FROM		#tmp2 a, #tmpapotax b
WHERE		b.TicketNumber = a.TicketNumber  

DROP TABLE	#tmpadm
SELECT		a.TicketNumber , totalAdm = SUM(b.total) 
INTO		#tmpadm
FROM		#tmp2 a, #tmpprice b
WHERE		b.TicketNumber = a.TicketNumber AND 
			b.KodeBiaya in ('DR','IJY','JR','Q5Q','XX','Y5','TR','OD','CP','TX','SVC','SVF',
			'F3','F1','DB','Z3')
GROUP BY	a.TicketNumber

UPDATE		#tmp2
SET			tktadm = b.totalAdm 
FROM		#tmp2 a, #tmpadm b
WHERE		b.TicketNumber = a.TicketNumber  AND 
			a.TransCode IN ('SALE','EXCH') AND 
			a.DocType NOT IN ('VOU')

DROP TABLE	#tmpadm2
SELECT		a.TicketNumber , totalAdm = SUM(b.total) 
INTO		#tmpadm2
FROM		#tmp2 a, #tmpprice b
WHERE		b.TicketNumber = a.TicketNumber AND 
			b.KodeBiaya IN ('DR','IJY','JR','Q5Q','XX','Y5','TR','OD','CP','TX','NQ','SVC','SVF','AD',
			'CF','DU','H8','MF','OA','OB','OC','OX','PK','SCV','SLS','Z3')
GROUP BY	a.TicketNumber

UPDATE		#tmp2
SET			tktadm = b.totalAdm 
FROM		#tmp2 a, #tmpadm2 b
WHERE		b.TicketNumber = a.TicketNumber  AND 
			(a.TransCode LIKE 'rf%' OR (a.TransCode = 'SALE' AND a.DocType = 'VOU'))

UPDATE		#tmp2
SET			AccAmount = 0, AccAdm = 0, TktIWJR = 0, TktAdm = 0, TktApoTax = 0, TktBaseFare = 0, TktPPN = 0, TktPPNOD = 0, Tktppnin = 0
WHERE		CalcTotal = 0

UPDATE		#tmp2 SET TktPPNOD = 0 WHERE TktPPNOD IS NULL
UPDATE		#tmp2 SET tktppnIN = 0 WHERE tktppnIN IS NULL

---------------------------------------------------------------------------------------------------------------------------
UPDATE		#tmp2
SET			TktBaseFare = CalcTotal - (ISNULL(tktadmkenappn,0) + ISNULL(tktppnod,0) + ISNULL(tktrefcancelfee,0) +
			TktPPN + tktfsurcharge + TktIWJR + tktadm + TktApoTax + ISNULL(tktPPNIN,0) )
WHERE		(ISNULL(TktBaseFare,0) + ISNULL(tktadmkenappn,0) + ISNULL(tktppnod,0) + ISNULL(tktrefcancelfee,0) +
			TktPPN + tktfsurcharge + TktIWJR + TktAdm + TktApoTax + ISNULL(tktPPNIN,0)) <> calctotal

UPDATE		#tmp2
SET			accamount = TktBaseFare + TktPPN + TktFSurcharge + TktIWJR + TktApoTax + ISNULL(tktppnOD,0) + ISNULL(tktadmkenappn,0) + ISNULL(tktPPNIN,0)

UPDATE		#tmp2
SET			accadm = TktAdm + isnull(tktrefcancelfee,0) 

SELECT		* 
FROM		#tmp2 a, #tmpprice b
WHERE		b.TicketNumber = a.TicketNumber AND 
			a.TktPPNOD = 0 AND 
			b.KodeBiaya LIKE 'D8%'
			
SELECT		* 
FROM		#tmp2 a, #tmpprice b
WHERE		b.TicketNumber = a.TicketNumber AND 
			a.tktppnin = 0 AND 
			b.KodeBiaya LIKE 'K3%'
================================================================
UPDATE		dmtkt
SET			AccAmount = a.accamount, AccAdm = a.accadm, TktBaseFare= a.tktbasefare, TktPPN = a.tktppn,
			TktFSurcharge = a.tktfsurcharge, TktIWJR = a.tktiwjr , TktAdm = a.tktadm, TktApoTax = a.tktapotax, 
			tktRefCancelFee = a.tktrefcancelfee, TktPPNOD = ISNULL(a.tktppnod,0), TktAdmKenaPPN = ISNULL(a.TktAdmKenaPPN,0),
			tktppnIN = ISNULL(a.tktppnIN,0)
FROM		#tmp2 a, dmtkt b
WHERE		b.TicketNumber = a.TicketNumber AND 
			b.StKey = a.StKey

--------------------------------------------------------------------------------------------------------------
SELECT		* 
FROM		dmtkt WITH(NOLOCK) 
WHERE		TktBaseFare + TktPPN + tktfsurcharge + TktAdm + TktIWJR + TktApoTax + tktadmkenappn + ISNULL(tktppnOD,0)<> CalcTotal AND 
			TransCode = 'exch' 

UPDATE		dmtkt
set			TktApoTax = 0, TktIWJR = 0, TktPPN = 0, TktBaseFare = calctotal, TktFSurcharge = 0, TktPPNIN = 0, TktPPNOD = 0, TktAdm = 0
FROM		dmtkt 
WHERE		TktBaseFare + TktPPN + tktfsurcharge + TktAdm + TktIWJR + TktApoTax + ISNULL(tktadmkenappn,0) + ISNULL(tktppnOD,0)<> CalcTotal AND 
			TransCode = 'exch' 

UPDATE		dmtkt
SET			AccAmount = TktBaseFare + TktPPN + tktfsurcharge  + TktIWJR + TktApoTax + ISNULL(tktadmkenappn,0) + ISNULL(tktppnOD,0) + ISNULL(tktppnin,0), 
			AccAdm = TktAdm
FROM		dmtkt WITH(NOLOCK)
WHERE		TransCode IN ('SALE','EXCH')
----------------------------------------------------------------------------------------------------------------		
SELECT		*
FROM		dmtkt 
WHERE		TktBaseFare + TktPPN + tktfsurcharge + TktAdm + TktIWJR + TktApoTax + tktadmkenappn + ISNULL(tktppnOD,0) + ISNULL(TktPPNIN,0)<> CalcTotal AND 
			TransCode in ('SALE','EXCH') AND
			DocType in ('TKT','CNJ')
                                                             --HARUS KOSONG--
SELECT		*
FROM		dmtkt 
WHERE		AccAmount + AccAdm <> CalcTotal AND 
			TransCode in ('SALE','EXCH') AND
			DocType in ('TKT','CNJ')
----------------------------------------------------------------------------------------------------------------		

UPDATE		dmtkt 
SET			tktXXadm = tktadm
WHERE		TransCode in ('SALE') AND 
			DocType in ('TKT','CNJ')
			
UPDATE		dmtkt 
SET			tktXXadm = tktadm
WHERE		TransCode in ('EXCH') AND 
			DocType in ('TKT','CNJ')
----------------------------------------------------------------------------------------------------------------		
