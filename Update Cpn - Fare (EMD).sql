/* FIRST STEP */

UPDATE		dmtktcpn
SET			total = ISNULL(fareupdate,0) + ISNULL(fsurcharge,0) + ISNULL(IWJR,0) + ISNULL(adm,0) + ISNULL(Apotax,0) + ISNULL(PPN,0) + ISNULL(ppnfsurcharge,0) +
			ISNULL(admkenappn,0) + ISNULL(ppnadm,0)  + ISNULL(PPNOD,0) + ISNULL(ppnin,0)
FROM		dmsttrk a, dmtktcpn b
WHERE		b.StKey = a.StKey AND 
			a.stationopendate BETWEEN '24 Nov 2019' AND '26 Nov 2019'
		
DROP TABLE	#tmp1
SELECT		b.* 
INTO		#tmp1 
FROM		dmsttrk a, dmtkt b with(nolock)
WHERE		b.StKey = a.StKey AND 
			a.stationopendate BETWEEN '24 Nov 2019' AND '26 Nov 2019'  AND
			b.TransCode IN ('SALE','EXCH') AND 
			b.DocType IN ('MSR','EMD','EXB')

DROP TABLE	#tmp2
SELECT		b.TicketNumber, TotalALL = SUM(b.total) 
INTO		#tmp2 
FROM		#tmp1 a, dmtktcpn b
WHERE		b.TicketNumber = a.TicketNumber AND 
			b.StKey = a.StKey
GROUP BY	b.TicketNumber

UPDATE		dmtktcpn
SET			FareUpdate = Price
FROM		#tmp1 a, dmtktcpn b
WHERE		b.TicketNumber = a.TicketNumber AND 
			b.StKey = a.StKey

UPDATE		dmtktcpn
SET			Total = ISNULL(fareupdate,0) + ISNULL(PPNOD,0) + isnull(Apotax,0) + ISNULL(adm,0)+ ISNULL(ppn,0)+ 
			ISNULL(iwjr,0) + ISNULL(ppnin,0)
FROM		#tmp1 a
			INNER JOIN dmtktcpn b
ON			b.TicketNumber = a.TicketNumber 
-----------------------------------------------------------------------------------------------
DROP TABLE	#tmp2
SELECT		b.TicketNumber, TotalALL = SUM(b.total) 
INTO		#tmp2 
FROM		#tmp1 a, dmtktcpn b
WHERE		b.TicketNumber = a.TicketNumber AND 
			b.StKey = a.StKey
GROUP BY	b.TicketNumber

UPDATE		dmtktcpn
SET			FareUpdate = FareUpdate / 100
FROM		#tmp1 a, #tmp2 b, dmtktcpn c 
WHERE		b.TicketNumber = a.TicketNumber AND 
			b.TotalALL <> a.CalcTotal AND
			c.TicketNumber = b.TicketNumber 
------------------------------------------------------------------------------------------------------------------------
DROP TABLE	#tmpbeda
SELECT		DISTINCT b.TicketNumber, a.TktBaseFare, a.TktPPNOD, a.TktApoTax, a.tktadm 
INTO		#tmpbeda 
FROM		#tmp1 a, #tmp2 b
WHERE		b.TicketNumber = a.TicketNumber AND 
			b.TotalALL <> a.CalcTotal

			
UPDATE		dmtktcpn
SET			FareUpdate = 0 , PPNOD = 0, Apotax = 0, adm = 0, ppn = 0, ppnadm = 0, PPNFsurcharge = 0, IWJR = 0, FSurcharge = 0,
			Total = 0
FROM		#tmpbeda a
			INNER JOIN dmtktcpn b
ON			b.TicketNumber = a.TicketNumber

UPDATE		dmtktcpn
SET			FareUpdate = a.TktBaseFare , PPNOD = a.TktPPNOD, Apotax = a.TktApoTax, adm = a.tktadm
FROM		#tmpbeda a
			INNER JOIN dmtktcpn b
ON			b.TicketNumber = a.TicketNumber AND 
			b.FC = '1'

UPDATE		dmtktcpn
SET			Total = ISNULL(fareupdate,0) + ISNULL(PPNOD,0) + isnull(Apotax,0) + ISNULL(adm,0)
FROM		#tmpbeda a
			INNER JOIN dmtktcpn b
ON			b.TicketNumber = a.TicketNumber AND 
			b.FC = '1'
			
UPDATE		dmtktcpn
SET			Total = ISNULL(fareupdate,0) + ISNULL(PPNOD,0) + isnull(Apotax,0) + ISNULL(adm,0)+ ISNULL(ppn,0)+ ISNULL(iwjr,0) + ISNULL(ppnin,0)
FROM		#tmp1 a
			INNER JOIN dmtktcpn b
ON			b.TicketNumber = a.TicketNumber 

DROP TABLE	#tmp2
SELECT		b.TicketNumber, TotalALL = SUM(b.total) 
INTO		#tmp2 
FROM		#tmp1 a, dmtktcpn b
WHERE		b.TicketNumber = a.TicketNumber AND 
			b.StKey = a.StKey
GROUP BY	b.TicketNumber
-----------------------------------------------------------------------------------------------

SELECT		*
FROM		#tmp1 a, #tmp2 b
WHERE		b.TicketNumber = a.TicketNumber AND  --- HARUS KOSONG ---
			b.TotalALL <> a.CalcTotal 
--------------------------------------------------------------------------------------------------

DROP TABLE		#tmptkt
SELECT			c.* 
INTO			#tmptkt 
FROM			dmsttrk b
				INNER JOIN dmtkt c with(nolock)
ON				c.StKey = b.StKey 
WHERE			c.TransCode = 'SALE' AND 
				c.DocType = 'MSR' AND
				b.stationopendate BETWEEN '24 Nov 2019' AND '26 Nov 2019' AND 
				c.TktBaseFare > 0

UPDATE			dmtkt
SET				TktApoTax = b.calctotal, SALEDOCTYPE = 'APO', TktBaseFare = 0
FROM			dmtkt a
				INNER JOIN #tmptkt b
ON				b.StKey = a.StKey AND 
				b.TicketNumber = a.TicketNumber

UPDATE			dmtktcpn
SET				Apotax = b.TktApoTax
FROM			dmtktcpn a
				INNER JOIN dmtkt b
ON				b.StKey = a.StKey AND 
				b.TicketNumber = a.TicketNumber
				INNER JOIN #tmptkt c
ON				c.TicketNumber = b.TicketNumber AND
				c.StKey = b.StKey  
				
UPDATE			dmtktcpn
SET				FareUpdate = 0
FROM			dmtktcpn a
				INNER JOIN #tmptkt b
ON				b.StKey = a.StKey AND 
				b.TicketNumber = a.TicketNumber
