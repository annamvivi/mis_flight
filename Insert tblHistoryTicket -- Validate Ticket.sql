
SELECT		DISTINCT StationOpenDate 
FROM		dmsttrk with(nolock)
WHERE		stationopendate <> '27 Nov 2019' -- tgl hari ini
ORDER BY	StationOpenDate
========================================================================================
	select *
	FROM		dmtkt
	WHERE		TransCode = 'EXCH' AND 
				FOP = 'RA' AND 
				CalcTotal > 0 		

========================================================================================
/*DELETE		tbltkt
FROM		tbltkt a, #tmp1 b
WHERE		b.ticketnumber = a.ticketnumber

DELETE		tbltktcpn
FROM		tbltktcpn a, #tmp1 b
WHERE		b.ticketnumber = a.ticketnumber

DELETE		tbltktprice
FROM		tbltktprice a, #tmp1 b
WHERE		b.ticketnumber = a.ticketnumber

*/
========================================================================================

SELECT		*
FROM		dmtkt  WITH(NOLOCK)
WHERE		ISNULL(curr,'ZZZ') <> LEFT(RIGHT(StKey,4),3)   AND
			DocType <> 'VOU' 
			
update dmtkt
set curr = LEFT(RIGHT(StKey,4),3)
FROM		dmtkt  WITH(NOLOCK)
WHERE		ISNULL(curr,'ZZZ') <> LEFT(RIGHT(StKey,4),3)   AND
			DocType <> 'VOU' 
			
===================================================================================================================================================

--- CEK REFUNDTICKET YG KOSONG -----------

SELECT		* 
FROM		dmtkt WITH(NOLOCK)					-- kalo ada nilai harus dicari refund tiketnya --
WHERE		refundticket = '' AND
			insertdate > '27 Nov 2019' AND 
			TransCode LIKE 'rf%' 

/* JALANKAN tblXO hari ini terlebih dulu */

BEGIN TRAN
UPDATE		dmtkt
SET			RefundTicket = b.ExchangeDocumentNumber
FROM		dmtkt a WITH(NOLOCK) INNER JOIN tblXo b WITH(NOLOCK)
ON			b.DocumentNumber = CONVERT(VARCHAR,RIGHT(a.ticketnumber,9))
WHERE		a.refundticket = '' AND 
			a.insertdate > '27 Nov 2019' AND 
			a.TransCode  LIKE 'rf%' 
 
--rollback tran
 
COMMIT TRAN

===================================================================================================================================================

SELECT		*
FROM		dmtkt WITH(NOLOCK)
WHERE		TransCode LIKE 'RF%' AND
			LEN(RTRIM(RfndCpn)) = 0

/* JALANKAN tblXO hari ini terlebih dulu */


BEGIN TRAN
UPDATE		dmtkt  
SET			RfndCpn = b.fc
FROM		dmtkt a 
			INNER JOIN tblxo b 
ON			LTRIM(RTRIM(b.documentnumber)) = RIGHT(CONVERT(VARCHAR,a.ticketnumber),9)
WHERE		a.transcode LIKE 'rf%' AND
			LEN(RTRIM(RfndCpn)) = 0
	
--rollback tran

COMMIT TRAN
		

===================================================================================================================================================

-- CEK EXCHTICKET KOSONG 

SELECT		*	
FROM		dmtkt WITH(NOLOCK)
WHERE		TransCode = 'exch' AND   ----tdk boleh ada nilai---
			DocType = 'TKT' AND 
			exchTicket = ''

-- JALANKAN Script dibawah kalo ada exchticket yg kosong


DROP TABLE		#tmp
SELECT			* 
INTO			#tmp
FROM			dmtkt WITH(NOLOCK)
WHERE			TransCode = 'EXCH' AND   
				exchTicket = '' 
				
SELECT			* 
FROM			#tmp

SELECT			* 
FROM			#tmp a
				INNER JOIN dmtkt b WITH(NOLOCK)
ON				b.ticketnumber = a.preconjticket 


/* 
938 id
990 jt
513 iw
816 od
310 sl

select * from dmtkt with(nolock) where ticketnumber = 5132102388789
select * from dmtktcpn with(nolock) where ticketnumber = 5132102388789

select * from dmtkt with(nolock) where ticketnumber = 5132102388790
select * from dmtktcpn with(nolock) where ticketnumber = 5132102388790

select * from sales.dbo.tbltkt with(nolock) where ticketnumber = 9902134719340
select * from sales.dbo.tbltktcpn with(nolock) where ticketnumber = 9902134719340

select * from sales.dbo.tbltkt with(nolock) where ticketnumber = 9902134719341
select * from sales.dbo.tbltktcpn with(nolock) where ticketnumber = 9902134719341

update dmtkt
set exchticket = '9902134719340', tailexchticket = '41234'
where ticketnumber = 5132102388789	

update dmtkt
set exchticket = '9902134719341', tailexchticket = '212'
where ticketnumber = 5132102388790	
*/


BEGIN TRAN 
UPDATE			dmtkt
SET				exchTicket = b.ExchangeDocumentNumber 
FROM			dmtkt a INNER JOIN TblXO b
ON				b.DocumentNumber = RIGHT(a.TicketNumber,10) 
				INNER JOIN #tmp c
ON				c.ticketnumber = a.TicketNumber

COMMIT TRAN
		
	

		

