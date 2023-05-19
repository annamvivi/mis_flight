DROP TABLE	#tmp1
SELECT		b.* 
INTO		#tmp1 
FROM		tblsttrk a with(nolock)
			INNER JOIN tbltktprice b
ON			b.StKey = a.StKey 
WHERE		b.KodeBiaya = 'D5' AND 
			b.Amount < 0 AND
			a.stationopendate BETWEEN '24 Nov 2019' AND '26 Nov 2019'

DROP TABLE	#tmp2
SELECT		b.* 
INTO		#tmp2 
FROM		#tmp1 a
			INNER JOIN tbltktprice b
ON			b.TicketNumber = a.TicketNumber AND 
			b.StKey = a.StKey 
WHERE		b.KodeBiaya = 'D5' AND 
			b.Amount > 0

DROP TABLE #tmptktprice
SELECT		DISTINCT b.* 
INTO		#tmptktprice 
FROM		#tmp2 a
			INNER JOIN tbltktprice b
ON			b.TicketNumber = a.TicketNumber AND 
			b.StKey = a.StKey 

DROP TABLE	#tmpsementara
SELECT		TicketNumber, totalAdm = SUM(Amount) 
INTO		#tmpsementara 
FROM		#tmptktprice 
WHERE		KodeBiaya IN ('D5','YR','YRI','Y5','ID','ID1','ID2','IDR') AND 
			Amount > 0
GROUP BY	TicketNumber

DROP TABLE	#tmpsementara2
SELECT		TicketNumber, totalapotax = SUM(Amount) 
INTO		#tmpsementara2 
FROM		#tmptktprice 
WHERE		KodeBiaya = 'D5' AND 
			Amount < 0
GROUP BY	TicketNumber

DROP TABLE	#tmpsementara3
SELECT		TicketNumber, totalIWJR = SUM(Amount) 
INTO		#tmpsementara3 
FROM		#tmptktprice 
WHERE		KodeBiaya IN ('YR','YRI','Y5') AND 
			Amount < 0
GROUP BY	TicketNumber

DROP TABLE	#tmpsementara4
SELECT		TicketNumber, totalppn = SUM(Amount) 
INTO		#tmpsementara4 
FROM		#tmptktprice 
WHERE		KodeBiaya IN ('ID','ID1','ID2','IDR') AND 
			Amount < 0
GROUP BY	TicketNumber

DROP TABLE	#tmpAkhir
SELECT		a.TicketNumber, a.totalAdm, b.totalapotax, c.totalIWJR, d.totalppn 
INTO		#tmpAkhir
FROM		#tmpsementara a
			INNER JOIN #tmpsementara2 b
ON			b.TicketNumber = a.TicketNumber			
			INNER JOIN #tmpsementara3 c
ON			c.TicketNumber = a.TicketNumber AND 
			c.TicketNumber = b.TicketNumber
			INNER JOIN #tmpsementara4 d
ON			d.TicketNumber = c.TicketNumber AND
			d.TicketNumber = b.TicketNumber

SELECT		* 
FROM		#tmpAkhir 
WHERE		ABS(totalIWJR + totalapotax+totalppn) <> ABS(totalAdm)

DELETE		#tmpAkhir 
FROM		#tmpAkhir a
			INNER JOIN tbltkt b with(nolock)
ON			b.TicketNumber = a.TicketNumber 
WHERE		transcode = 'VOID'

DROP TABLE	#tmptktedit
SELECT		b.* 
INTO		#tmptktedit 
FROM		#tmpAkhir a
			INNER JOIN tbltkt b with(nolock)
ON			b.TicketNumber = a.ticketnumber

UPDATE		tbltkt
SET			TktApoTax = a.totalapotax, TktIWJR = a.totalIWJR, TktPPN = a.totalppn
FROM		#tmpAkhir a
			INNER JOIN tbltkt b
ON			b.TicketNumber = a.ticketnumber

UPDATE		tbltkt
SET			tktadm = calctotal - (TktBaseFare + TktPPN + TktFSurcharge + TktIWJR + TktApoTax + ISNULL(tktppnod,0) + ISNULL(tktadmkenappn,0) + isnull(tktrefcancelfee,0)+ ISNULL(tktppnIN,0))
FROM		#tmpAkhir a
			INNER JOIN tbltkt b
ON			b.TicketNumber = a.ticketnumber

UPDATE		tbltkt
SET			AccAmount = TktBaseFare + TktPPN + TktFSurcharge + TktIWJR + TktApoTax + ISNULL(tktppnod,0) + ISNULL(tktadmkenappn,0) + ISNULL(tktppnIN,0), AccAdm = TktAdm + isnull(tktrefcancelfee,0)
FROM		#tmpAkhir a
			INNER JOIN tbltkt b
ON			b.TicketNumber = a.ticketnumber

================================================================

UPDATE		tbltkt
SET			TktAdm = a.totaladm 
FROM		#tmpAkhir a 
			INNER JOIN tbltkt b
ON			b.TicketNumber = a.ticketnumber 
			INNER JOIN #tmptktedit c
ON			c.TicketNumber = a.TicketNumber
WHERE		b.AccAmount + b.AccAdm <> b.CalcTotal
 
UPDATE		tbltkt
SET			AccAmount = 0, AccAdm = 0, TktIWJR = 0, TktAdm = 0, TktApoTax = 0, TktBaseFare = 0, TktPPN = 0, TktAdmKenaPPN = 0,
			TktPPNOD = 0, TktFSurcharge = 0, tktPPNIN = 0
WHERE		TransCode = 'VOID'	AND 
			insertdate > '27 Nov 2019'
			
