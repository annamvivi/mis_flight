DROP TABLE	#Tmp1
SELECT		a.stkey,a.stationno,b.ticketnumber,b.tourcode,b.ApprovalCode
INTO		#tmp1
FROM		dmsttrk a WITH(NOLOCK)INNER JOIN dmtkt b WITH(NOLOCK)
ON			b.stkey = a.stkey
WHERE		a.stationopendate BETWEEN '24 Nov 2019' AND '26 Nov 2019' AND
			b.kodedistrict IS NULL 
/* b.nodokumen IS NULL AND */
---------------------------------------------------------------------
-- kosong
DROP TABLE #tmpNewStationNo
SELECT		DISTINCT StationNo,StationCode,Tglberlaku=min(stationopendate)  
INTO		#tmpNewStationNo
FROM		dmsttrk 
WHERE		( convert(varchar(10),StationNo)+StationCode  NOT IN (SELECT convert(varchar(10),StationNo)+StationName  FROM tblStationINA) AND
				convert(varchar(10),StationNo)+StationCode   NOT IN (SELECT convert(varchar(10),StationNo)+StationName FROM tblStationMAL)) 
GROUP BY	StationNo,StationCode  		


select * from #tmpNewStationNo
/* CARA INSERT STATIONNO BARU

TGL AWAL BULAN -----
kalo ada stationno baru tinggal ganti tanggalnya jadi tanggal awal bulan

begin tran
insert TblstationINA (StationNo,TglBerlaku,StationName,Lokasi,KodeDistrict,Keterangan,GLKodeDistrict)
select		       StationNo,'1 nov 19',stationcode,RIGHT(stationcode,2),LEFT(stationcode,3),null,LEFT(stationcode,3)
from	#tmpNewStationNo
commit tran
*/
----------------------------------------------------------------------
SELECT		MAX(TglBerlaku)
FROM		tblStationINA 

DROP TABLE	#tmpstation
SELECT		a.* 
INTO		#tmpstation 
FROM		tblStationINA a, 
			(SELECT stationno,tglberlaku = MAX(tglberlaku) FROM tblStationINA 
			WHERE tglberlaku <= '24 Nov 2019'
			GROUP BY stationno) b
WHERE		b.stationno = a.stationno AND b.tglberlaku = a.tglberlaku 

DROP TABLE	#tmptkt
SELECT		a.*,d.stationname,DistFromtblStation = d.kodedistrict
INTO		#tmptkt
FROM		#tmp1 a LEFT JOIN #tmpstation d
ON			d.stationno = a.stationno 

SELECT		* 
FROM		#Tmptkt 
WHERE		stationname IS NULL

ALTER TABLE	#Tmptkt ADD kodedistrict VARCHAR(3)

UPDATE		#tmptkt 
SET			kodedistrict = SUBSTRING(tourcode,5,3) 
WHERE		stationname LIKE '%ag' AND 
			kodedistrict IS NULL

UPDATE		#tmptkt 
SET			kodedistrict = LEFT(RIGHT(stkey,9),3) 
WHERE		LEFT(RIGHT(stkey,6),2) = 'AP' AND 
			kodedistrict IS NULL

UPDATE		#tmptkt 
SET			kodedistrict = LEFT(RIGHT(stkey,9),3) 
WHERE		LEFT(RIGHT(stkey,6),2) = 'TO' AND 
			kodedistrict IS NULL

UPDATE		#tmptkt 
SET			kodedistrict = LEFT(RIGHT(stkey,9),3) 
WHERE		LEFT(RIGHT(stkey,6),2) = 'TR' AND 
			kodedistrict IS NULL

/* cek apakah ada bogor, karena dianggap posisi JKT */
/* kalau hasilnya 'JKT' sebenar nya harus 'BGR' */

SELECT		* 
FROM		#tmptkt 
WHERE		StationNo = 21100052

UPDATE		#tmptkt 
SET			kodedistrict = 'BGR' 
WHERE		kodedistrict = 'JKT' AND StationNo = 95100283

SELECT		distinct agentdie
FROM		#tmptkt a, dmtkt b with(nolock)
WHERE		a.kodedistrict = 'JKT' AND 
			a.StationNo = 21100052 AND
			b.TicketNumber = a.TicketNumber AND
			b.stkey = a.stkey 

UPDATE		#tmptkt
SET			kodedistrict = 'BGR'
FROM		#tmptkt a, dmtkt b with(nolock)
WHERE		a.kodedistrict = 'JKT' AND 
			a.StationNo = 21100052 AND
			b.TicketNumber = a.TicketNumber AND
			b.stkey = a.stkey AND
			b.AgentDie in ('JKTBFR','JKTBVP')
----------------------------------------------------------

UPDATE		#tmptkt 
SET			KodeDistrict = 'JKT' 
FROM		#tmptkt a INNER JOIN dmtkt b WITH(NOLOCK)
ON			b.TicketNumber = a.TicketNumber 
WHERE		LEN(ISNULL(a.kodedistrict,''))= 0 AND b.TourCode LIKE 'IT%' AND
			(
				(b.transcode = 'SALE' AND b.FOP = 'CA') OR  
				(b.TransCode = 'SALE' AND b.DocType ='cnj' AND b.FOP = '') 
			)


UPDATE		#tmptkt 
SET			kodedistrict='SIN'
FROM		#Tmptkt a, dmtkt b WITH(NOLOCK) , tblIntlRoute c
WHERE		LEN(ISNULL(a.kodedistrict,'')) = 0 AND 
			b.TicketNumber = a.TicketNumber AND 
			b.transcode = 'SALE' AND 
			LEN(LTRIM(ISNULL(b.TourCode,'')))= 0 AND 
			LEN(ISNULL(b.ApprovalCode,''))> 0 AND
			LEFT(RIGHT(a.stkey,6),2) = 'WB' AND 
			a.DistFromtblStation IN (SELECT Route FROM tblIntlRoute)
		
UPDATE		#tmptkt 
SET			kodedistrict='JKT'
FROM		#Tmptkt a, dmtkt b WITH(NOLOCK), tblIntlRoute c
WHERE		LEN(ISNULL(a.kodedistrict,'')) = 0 AND 
			b.TicketNumber = a.TicketNumber AND 
			b.transcode = 'SALE' AND 
			LEN(LTRIM(ISNULL(b.TourCode,'')))= 0 AND 
			LEN(ISNULL(b.ApprovalCode,''))> 0 AND
			LEFT(RIGHT(a.stkey,6),2) = 'WB' 
			AND a.DistFromtblStation NOT IN (SELECT Route FROM tblIntlRoute)

UPDATE		#tmptkt 
SET			kodedistrict='JKT'
FROM		#Tmptkt a, dmtkt b WITH(NOLOCK), tblIntlRoute c
WHERE		LEN(ISNULL(a.kodedistrict,'')) = 0 AND 
			b.TicketNumber = a.TicketNumber AND 
			b.transcode = 'SALE' AND 
			DocType = 'CNJ' AND 
			LEN(LTRIM(ISNULL(b.TourCode,'')))= 0 AND 
			LEN(ISNULL(b.ApprovalCode,''))= 0 AND
			LEFT(RIGHT(a.stkey,6),2) = 'WB' AND 
			a.DistFromtblStation NOT IN (SELECT Route FROM tblIntlRoute)
		
UPDATE		#tmptkt 
SET			kodedistrict='SIN'
FROM		#Tmptkt a, dmtkt b WITH(NOLOCK), tblIntlRoute c
WHERE		LEN(ISNULL(a.kodedistrict,'')) = 0 AND 
			b.TicketNumber = a.TicketNumber AND 
			b.transcode = 'SALE' AND 
			DocType = 'CNJ' AND 
			LEN(LTRIM(ISNULL(b.TourCode,'')))= 0 AND 
			LEN(ISNULL(b.ApprovalCode,''))= 0 AND
			LEFT(RIGHT(a.stkey,6),2) = 'WB' AND 
			a.DistFromtblStation IN (SELECT Route FROM tblIntlRoute)
			
UPDATE		#tmptkt 
SET			kodedistrict='SIN'
FROM		#Tmptkt a, dmtkt b WITH(NOLOCK), tblIntlRoute c
WHERE		LEN(ISNULL(a.kodedistrict,'')) = 0 AND 
			b.TicketNumber = a.TicketNumber AND 
			b.transcode = 'SALE' AND 
			DocType = 'TKT' AND 
			LEN(LTRIM(ISNULL(b.TourCode,'')))= 0 AND 
			LEN(ISNULL(b.ApprovalCode,''))= 0 AND
			LEFT(RIGHT(a.stkey,6),2) = 'WB' AND 
			a.DistFromtblStation IN (SELECT Route FROM  tblIntlRoute)

UPDATE		#tmptkt 
SET			kodedistrict='JKT'
FROM		#Tmptkt a, dmtkt b WITH(NOLOCK), tblIntlRoute c
WHERE		LEN(ISNULL(a.kodedistrict,'')) = 0 AND 
			b.TicketNumber = a.TicketNumber AND 
			b.transcode = 'SALE' AND 
			DocType = 'TKT' AND 
			LEN(LTRIM(ISNULL(b.TourCode,'')))= 0 AND 
			LEN(ISNULL(b.ApprovalCode,''))= 0 AND
			LEFT(RIGHT(a.stkey,6),2) = 'WB' AND 
			a.DistFromtblStation NOT IN (SELECT Route FROM tblIntlRoute)

UPDATE		#tmptkt 
SET			kodedistrict = 'JKT'
WHERE		LEFT(RIGHT(StKey,6),2) = 'WB' AND 
			LEN(ISNULL(kodedistrict,'')) = 0 AND 
			LEFT(RIGHT(stkey,9),3) <> 'SIN'

UPDATE		#tmptkt 
SET			kodedistrict = 'SIN'
WHERE		LEFT(RIGHT(StKey,6),2) = 'WB' AND 
			LEN(ISNULL(kodedistrict,'')) = 0 AND 
			LEFT(RIGHT(stkey,9),3) = 'SIN'

UPDATE		#tmptkt
SET			kodedistrict = DistFromtblStation
WHERE		(kodedistrict IS NULL) or (kodedistrict = '') 

UPDATE		#tmptkt
SET			kodedistrict = SUBSTRING(stkey,15,3)
WHERE		(kodedistrict IS NULL) or (kodedistrict = '') 

SELECT		* 
FROM		#tmptkt 
WHERE		kodedistrict = 'AMI' AND 
			stationno IN ('31200013','31100016')  

UPDATE		#tmptkt
SET			KodeDistrict =  'LOP'
FROM		#tmptkt a,  dmsttrk b with (nolock)
WHERE		b.stationno IN  ('31200013','31100016')  AND
			b.StKey =  a.StKey AND
			b.StationOpenDate >=  '01 Jan 2019'  AND
			a.KodeDistrict =  'AMI'

UPDATE		#tmptkt
SET			kodedistrict = 'JED', DistFromtblStation = 'JED'
WHERE		StationNo IN (96100561,94100215) AND 
			kodedistrict <> 'JED'
			
SELECT		* 
FROM		#tmptkt 
WHERE		(kodedistrict IS NULL) or (kodedistrict = '')  -- harus kosong --

-------------------------------------------------------------------------------------------------

CREATE INDEX idtkt ON #tmptkt (ticketnumber)
CREATE INDEX iddistrict ON #tmptkt (kodedistrict)
-------------------------------------------------------------------------------------------------
UPDATE		dmtkt
SET			kodedistrict = b.kodedistrict
FROM		dmtkt a INNER JOIN #tmptkt b
ON			b.ticketnumber = a.ticketnumber
WHERE		a.KodeDistrict IS NULL
-------------------------------------------------------------------------------------------------

DROP TABLE	#Tmp8
SELECT		a.stkey,a.stationno,b.ticketnumber,b.tourcode,b.NoDokumen,b.KodeDistrict 
INTO		#tmp8
FROM		dmsttrk a WITH(NOLOCK) INNER JOIN dmtkt b WITH(NOLOCK)
ON			b.stkey = a.stkey
WHERE		a.stationopendate BETWEEN '24 Nov 2019' AND '26 Nov 2019' AND
			b.kodedistrict IS NULL 

SELECT		* 
FROM		#tmp8


