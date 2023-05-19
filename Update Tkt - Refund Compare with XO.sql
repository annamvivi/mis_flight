DROP TABLE		#tmp1 
SELECT			b.* 
INTO			#tmp1 
FROM			tblsttrk a 
				INNER JOIN tbltkt b WITH(NOLOCK)
ON				b.StKey = a.StKey  
WHERE			a.stationopendate BETWEEN '24 Nov 2019' AND '26 Nov 2019' AND 
				(b.TransCode LIKE 'rf%' OR  b.DocType = 'VOU') 
				
DROP TABLE		#tmpxo
SELECT			a.*
INTO			#tmpxo 
FROM			tblxo a 
				INNER JOIN #tmp1 b
ON				b.refundticket = CONVERT(VARCHAR,a.exchangedocumentnumber) 


DROP TABLE		#tmpvoid
SELECT			* 
INTO			#tmpvoid 
FROM			#tmpxo a
				INNER JOIN tbltkt b WITH(NOLOCK)
ON				b.RefundTicket = CONVERT(VARCHAR,a.ExchangeDocumentNumber) AND 
				DocumentNumber = SUBSTRING(CONVERT(varchar,ticketnumber), 5,9)
WHERE			b.TransCode = 'VOID' 
	
DELETE			#tmpxo 
FROM			#tmpvoid a
				INNER JOIN #tmpxo b
ON				b.ExchangeDocumentNumber = a.ExchangeDocumentNumber AND 
				b.TransactionControlNumber = a.TransactionControlNumber

-- Cek dulu disini, harus 9
SELECT			DISTINCT LEN(documentnumber) 
FROM			#tmpxo

SELECT			* 
FROM			#tmpxo
WHERE			DifferenceFareAmount <> DifferenceTotalAmount - DifferenceTaxAmount

UPDATE			#tmpxo
SET				DifferenceFareAmount = DifferenceTotalAmount - DifferenceTaxAmount
WHERE			DifferenceFareAmount <> DifferenceTotalAmount - DifferenceTaxAmount

DROP TABLE		#tmp2
SELECT			ExchangeDocumentNumber,
				NilaiYgMaudiRefund = exchangedocumentfare + exchangetotalTaxAmount,		
				UsedPort = NewTotalAmount,
				BelumTerpakai = differenceTotalAmount * -1,
				tktBaseFare = DifferenceFareAmount,
				tktPPN = DifferenceFareAmount * 0.1,
				tktAdm = (DifferenceTaxAmount - (DifferenceFareAmount * 0.1)),
				tktRefCancelFee = ChangeFeeAmount + OtherFeeAmount,
				PaxTerima = DifferenceFareAmount * -1 + DifferenceTaxAmount * -1 - OtherFeeAmount - ChangeFeeAmount,
				AccAmount = DifferenceFareAmount * -1 + DifferenceTaxAmount * -1, 
				AccAdmin = OtherFeeAmount + ISNULL(ChangeFeeAmount,0), 
				a.DifferenceFareCurrency, 
				a.DifferenceFareAmount
INTO			#tmp2 
FROM			#tmpxo a 
				INNER JOIN #tmp1 b
ON				b.refundticket = CONVERT(VARCHAR,a.exchangedocumentnumber) AND 
				TransactionType = 'R'		

UPDATE			#tmp1 
SET				accamount = '0', accadm = '0', accccadm = '0', tktbasefare = '0', tktppn = '0', tktfsurcharge = '0', tktiwjr = '0', tktkomisi = '0',
				tktadm = '0', tktapotax = '0'

UPDATE			#tmp1 
SET				accamount = a.AccAmount, accadm = a.AccAdmin, tktbasefare = a.tktBaseFare, tktppn = a.tktPPN, 
				tktadm = a.tktAdm, tktrefcancelfee = a.tktRefCancelFee, tktrefusedport = a.UsedPort, 
				totalticketsale = a.NilaiYgMaudiRefund
FROM			#tmp2 a
				INNER JOIN #tmp1 b
ON				b.refundticket = CONVERT(VARCHAR,a.ExchangeDocumentNumber)

---------------------------------------------------------------------------------------------------------------------------------

BEGIN TRAN	
UPDATE			tbltkt
SET				tktRefCancelFee = b.tktrefcancelfee, tktRefUsedPort = b.tktRefUsedPort, TotalTicketSale = b.TotalTicketSale
FROM			tbltkt a
				INNER JOIN #tmp1 b
ON				b.ticketnumber = a.TicketNumber AND 
				b.CalcTotal = a.CalcTotal 

COMMIT


UPDATE			tbltkt
SET				tktadm = calctotal - TktBaseFare - TktPPN - TktFSurcharge - TktIWJR - TktApoTax - isnull(tktrefcancelfee,0) - ISNULL(tktppnod,0) - ISNULL(tktadmkenappn,0) - ISNULL(tktppnIN,0)
FROM			tblsttrk a
				INNER JOIN tbltkt b 
ON				b.StKey = a.StKey 
WHERE			tktBaseFare + TktPPN + TktFSurcharge + TktIWJR + TktApoTax + TktAdm + ISNULL(tktrefcancelfee,0) + ISNULL(tktppnod,0) + ISNULL(tktadmkenappn,0) + ISNULL(tktppnIN,0)<> CalcTotal AND 
				a.stationopendate BETWEEN '24 Nov 2019' AND '26 Nov 2019' AND 
				(b.TransCode LIKE 'rf%' OR  b.DocType = 'VOU')

UPDATE			tbltkt
SET				AccAmount = TktBaseFare + TktPPN + TktFSurcharge + TktIWJR + TktApoTax + ISNULL(tktppnod,0) + ISNULL(tktadmkenappn,0) + ISNULL(tktppnIN,0), AccAdm = TktAdm + isnull(tktrefcancelfee,0)
FROM			tblsttrk a 
				INNER JOIN tbltkt b
ON				b.StKey = a.StKey
WHERE			a.stationopendate BETWEEN '24 Nov 2019' AND '26 Nov 2019' AND 
				(b.TransCode LIKE 'rf%' OR  b.DocType = 'VOU') 
				
UPDATE			tbltkt
SET				AccAdm = TktAdm + ISNULL(tktrefcancelfee,0)
FROM			tblsttrk a
				INNER JOIN tbltkt b
ON				b.StKey = a.StKey
WHERE			a.stationopendate BETWEEN '24 Nov 2019' AND '26 Nov 2019' AND 
				(b.TransCode LIKE 'rf%' OR  b.DocType = 'VOU')
---------------------------------------------------------------------------------------------------------------------------------
--- HARUS KOSONG--

SELECT			b.* 
FROM			tblsttrk a WITH(NOLOCK)
				INNER JOIN tbltkt b WITH(NOLOCK)
ON				b.StKey = a.StKey 
WHERE			accamount <> TktBaseFare + TktPPN + TktFSurcharge + TktIWJR + TktApoTax + ISNULL(tktppnOD,0) + ISNULL(tktadmkenappn,0) + ISNULL(tktppnIN,0) AND 
				a.stationopendate BETWEEN '24 Nov 2019' AND '26 Nov 2019' AND 
				(b.TransCode LIKE 'rf%' OR  b.DocType = 'VOU')

SELECT			b.* 
FROM			tblsttrk a WITH(NOLOCK)
				INNER JOIN tbltkt b WITH(NOLOCK)
ON				b.StKey = a.StKey 
WHERE			accadm <> TktAdm + ISNULL(tktrefcancelfee,0) AND 
				a.stationopendate BETWEEN '24 Nov 2019' AND '26 Nov 2019' AND 
				(b.TransCode LIKE 'rf%' OR  b.DocType = 'VOU')

SELECT			b.* 
FROM			tblsttrk a WITH(NOLOCK)
				INNER JOIN tbltkt b WITH(NOLOCK)
ON				b.StKey = a.StKey 
WHERE			TktBaseFare + TktPPN + TktFSurcharge + TktIWJR + TktApoTax + TktAdm + isnull(tktrefcancelfee,0)+ ISNULL(tktppnOD,0)+ ISNULL(tktadmkenappn,0)+ ISNULL(tktppnIN,0) <> CalcTotal AND 
				a.stationopendate BETWEEN '24 Nov 2019' AND '26 Nov 2019' AND 
				(b.TransCode LIKE 'rf%' OR  b.DocType = 'VOU')

SELECT			b.* 
FROM			tblsttrk a WITH(NOLOCK)
				INNER JOIN tbltkt b WITH(NOLOCK)
ON				b.StKey = a.StKey 
WHERE			AccAmount + AccAdm  <> CalcTotal AND 
				a.stationopendate BETWEEN '24 Nov 2019' AND '26 Nov 2019' AND 
				(b.TransCode LIKE 'rf%' OR  b.DocType = 'VOU')
	
---------------------------------------------------------------------------------------------------------------------------------
