DROP TABLE	#tmpsaledoctype
SELECT		DISTINCT ExbPrasDesc 
INTO		#tmpsaledoctype 
FROM		tblsttrk a with(nolock), tbltkt b with(nolock)
WHERE		b.stkey = a.stkey AND	
			a.StationOpenDate BETWEEN '24 Nov 2019' AND '26 Nov 2019'

DELETE		#tmpsaledoctype 
FROM		#tmpsaledoctype a, tblmastersaledoctype b
WHERE		b.exbprasdesc = a.ExbPrasDesc

SELECT		* 
FROM		#tmpsaledoctype
WHERE		ExbPrasDesc <> ''

INSERT		INTO tblmastersaledoctype
			(exbprasdesc)
SELECT		exbprasdesc 
FROM		#tmpsaledoctype 
WHERE		ExbPrasDesc <> ''

SELECT		*
FROM		tblmastersaledoctype -- HARUS KOSONG---
WHERE		saledoctype IS NULL
 


/* TANYA DLU YA 
      
select * from dmtkt where exbprasdesc like 'DPSKOEBJW'

select * from dmtkt where exbprasdesc = 'GROUP DEPOSIT IW          '
      
--Note: kalo ada isi, copy exbprasdesc nya ke sini, terus tanyain saledoctype nya apa
               
begin tran
update tblmastersaledoctype 
set saledoctype = 'APTEXB'
where saledoctype IS NULL AND exbprasdesc like 'BAG SRGSUB           '
commit tran
     
*/

-----------------------------------------------------------------------------
update tblmastersaledoctype 
set jurnaltype = 'EXB'
where SALEDOCTYPE in ('APTEXB','PREEXB') AND jurnaltype IS NULL

update tblmastersaledoctype 
set jurnaltype = 'APO'
where SALEDOCTYPE in ('APO') AND jurnaltype IS NULL

update tblmastersaledoctype 
set jurnaltype = 'ADM'
where SALEDOCTYPE in ('HANDLE','SMS','WHC','ADM','HOTEL','SOB','DEPO') AND jurnaltype IS NULL
 
update tblmastersaledoctype 
set jurnaltype = 'MEAL'
where SALEDOCTYPE in ('MEAL') AND jurnaltype IS NULL

update tblmastersaledoctype 
set jurnaltype = 'SEAT'
where SALEDOCTYPE in ('SEAT') AND jurnaltype IS NULL

update tblmastersaledoctype 
set jurnaltype = 'INS'
where SALEDOCTYPE in ('INS') AND jurnaltype IS NULL
---------------------------------------------------------------------------------
DROP TABLE	#tmptkt
SELECT		b.* 
INTO		#tmptkt 
FROM		tblsttrk a, tbltkt b with(nolock)
WHERE		b.stkey = a.stkey AND
			a.stationopendate BETWEEN '24 Nov 2019' AND '26 Nov 2019' AND
			b.SALEDOCTYPE IS NULL

UPDATE		#tmptkt
SET			SALEDOCTYPE = b.saledoctype
FROM		#tmptkt a, tblmastersaledoctype b
WHERE		b.exbprasdesc = a.ExbPrasDesc AND
			a.SALEDOCTYPE IS NULL

UPDATE		#tmptkt
SET			SALEDOCTYPE = 'TKT'
WHERE		TransCode = 'VOID' AND 
			SALEDOCTYPE IS NULL

UPDATE		#tmptkt
SET			SALEDOCTYPE = 'TKT'
WHERE		TransCode = 'SALE' AND 
			DocType = 'TKT' AND 
			SALEDOCTYPE IS NULL

UPDATE		#tmptkt
SET			SALEDOCTYPE = 'TKT'
WHERE		TransCode = 'EXCH' AND 
			DocType = 'TKT' AND 
			SALEDOCTYPE IS NULL

UPDATE		#tmptkt
SET			SALEDOCTYPE = 'TKT'
WHERE		TransCode = 'EXCH' AND 
			DocType = 'CNJ' AND 
			SALEDOCTYPE IS NULL

UPDATE		#tmptkt
SET			SALEDOCTYPE = 'TKT'
WHERE		TransCode = 'SALE' AND 
			DocType = 'CNJ' AND 
			SALEDOCTYPE IS NULL

UPDATE		#tmptkt
SET			SALEDOCTYPE = 'ADM'
WHERE		TransCode = 'SALE' AND 
			DocType IN ('MSR','EMD') AND 
			SALEDOCTYPE IS NULL AND 
			ExbPrasDesc = ''

UPDATE		#tmptkt
SET			SALEDOCTYPE = 'EXB'
WHERE		TransCode = 'SALE' AND 
			DocType IN ('EXB') AND 
			SALEDOCTYPE IS NULL AND  
			ExbPrasDesc = ''

UPDATE		#tmptkt
SET			SALEDOCTYPE = 'EXB'
WHERE		SALEDOCTYPE = 'ADM' AND 
			DocType = 'EXB'

UPDATE		#tmptkt 
SET			saledoctype = 'TKT'
WHERE		SALEDOCTYPE IS NULL AND   
			TransCode IN ('SALE') AND 
			DocType IN ('VOU')
			
create index iddistrict on #tmptkt (ticketnumber)
create index iddistrict2 on #tmptkt (stkey)

BEGIN TRAN
UPDATE		tbltkt
SET			SALEDOCTYPE = b.saledoctype
FROM		tbltkt a, #tmptkt b 
WHERE		b.TicketNumber = a.TicketNumber AND 
			b.StKey = a.StKey 
COMMIT

DROP TABLE	#tmpNULL
SELECT		b.* 
INTO		#tmpNULL 
FROM		tblsttrk a, tbltkt b WITH(NOLOCK)
WHERE		b.stkey = a.stkey AND
			a.stationopendate BETWEEN '24 Nov 2019' AND '26 Nov 2019' AND
			b.SALEDOCTYPE IS NULL

UPDATE		#tmpNULL
SET			SALEDOCTYPE = b.saledoctype 
FROM		#tmpNULL a, tbltkt b 
WHERE		a.SALEDOCTYPE IS NULL AND 
			CONVERT(VARCHAR,b.TicketNumber) = a.refundticket 

UPDATE		#tmpNULL
SET			SALEDOCTYPE = 'TKT' 
WHERE		TransCode LIKE 'rf%' AND 
			SALEDOCTYPE IS NULL

BEGIN TRAN
UPDATE		tbltkt
SET			SALEDOCTYPE = b.saledoctype
FROM		tbltkt a, #tmpNULL b
WHERE		b.TicketNumber = a.TicketNumber AND 
			b.StKey = a.StKey

COMMIT

SELECT		* 
FROM		tblsttrk a, tbltkt b with(nolock)
WHERE		b.stkey = a.stkey AND
			a.stationopendate BETWEEN '24 Nov 2019' AND '26 Nov 2019' AND
			b.SALEDOCTYPE IS NULL

UPDATE		tbltkt
SET			SALEDOCTYPE = 'TKT'
FROM		tblsttrk a, tbltkt b with(nolock)
WHERE		b.stkey = a.stkey AND
			a.stationopendate BETWEEN '24 Nov 2019' AND '26 Nov 2019' AND
			b.SALEDOCTYPE IS NULL
