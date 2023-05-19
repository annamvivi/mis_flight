 
------------------------- Update CREATEDATE -------------------------------------

DROP TABLE	#tmpTCN 
SELECT		a.* 
INTO		#tmpTCN 
FROM		tblTCN a INNER JOIN dmTCN b
ON			b.TcnNo = a.TCNNo
WHERE		b.TicketNumber = CONVERT(VARCHAR,a.TicketNumber) AND
			a.insertdate > '27 Nov 2019'

SELECT		DISTINCT exb 
FROM		#tmpTCN 
ORDER BY	exb

SELECT		DISTINCT CreateDate 
FROM		dmTCN 
ORDER BY	CreateDate
 
SELECT		DISTINCT LEN(CreateDate) 
FROM		dmTCN 	

UPDATE		#tmpTCN
SET			CreateDate = CONVERT(DATETIME,b.CreateDate)
FROM		#tmpTCN a INNER JOIN dmTCN b
ON			b.TicketNumber = CONVERT(VARCHAR,a.TicketNumber) AND
			b.TcnNo = a.TCNNo 
WHERE		b.CreateDate <> 00000000

--------------------------------------------------------------------------------------------------------

SELECT		DISTINCT createtime 
FROM		dmTCN 
ORDER BY	CreateTime

SELECT		DISTINCT LEN(CreateTime) 
FROM		dmTCN 

UPDATE		#tmpTCN 
SET			CreateTime = CONVERT(TIME,SUBSTRING(b.CreateTime,1,2) +':'+SUBSTRING(b.CreateTime,3,2))
FROM		#tmpTCN  a INNER JOIN dmTCN b
ON			b.TicketNumber = CONVERT(VARCHAR,a.TicketNumber) AND
			b.TcnNo = a.TCNNo 
WHERE		b.CreateTime <> 0000 AND
			b.CreateTime <> 2400 

UPDATE		#tmpTCN 
SET			CreateTime = '12am'
FROM		#tmpTCN  a INNER JOIN dmTCN b
ON			b.TicketNumber = CONVERT(VARCHAR,a.TicketNumber) AND
			b.TcnNo = a.TCNNo 
WHERE		b.CreateTime IN ('0000',2400)

----------------------------- Update DEPTIME ------------------------------------
-- hasilnya x4 --
DROP TABLE	#tmpDepTimeAll
SELECT		TicketNumber,TCNNo,DepTimeAll = REPLACE(DepTime,' ',''),Ket='DepTime' 
INTO		#tmpDepTimeAll 
FROM		dmTCN 
UNION ALL
SELECT		TicketNumber,TCNNo,DepTimeAll = REPLACE(DepTime2,' ',''),Ket='DepTime2'
FROM		dmTCN 
UNION ALL
SELECT		TicketNumber,TCNNo,DepTimeAll = REPLACE(DepTime3,' ',''),Ket='DepTime3' 
FROM		dmTCN 
UNION ALL
SELECT		TicketNumber,TCNNo,DepTimeAll = REPLACE(DepTime4,' ',''),Ket='DepTime4' 
FROM		dmTCN 

DELETE		#tmpDepTimeAll 
WHERE		DepTimeAll = 'VOID'

SELECT		COUNT(*) 
FROM		#tmpDepTimeAll 
WHERE		DepTimeAll LIKE '0%N'

SELECT		COUNT(*) 
FROM		#tmpDepTimeAll 
WHERE		DepTimeAll LIKE '0%A'

SELECT		COUNT(*) 
FROM		#tmpDepTimeAll 
WHERE		DepTimeAll LIKE '0%P'

SELECT		COUNT(*) 
FROM		#tmpDepTimeAll 
WHERE		LEN(DepTimeAll) = 4

UPDATE		#tmpDepTimeAll 
SET			DepTimeAll = '0'+ DepTimeAll 
WHERE		LEN(DepTimeAll) = 4

SELECT		DISTINCT LEN(DepTimeAll) 
FROM		#tmpDepTimeAll
--------------------------------------------------------------------------------------------------------
DROP TABLE	#tmpDepTime0000 
SELECT		*
INTO		#tmpDepTime0000  
FROM		#tmpDepTimeAll
WHERE		DepTimeAll NOT LIKE '%N' AND 
			DepTimeAll NOT LIKE '%A' AND
			DepTimeAll NOT LIKE '%P' AND
			DepTimeAll <> ' '

UPDATE		#tmpDepTime0000 
SET			DepTimeAll = SUBSTRING(DepTimeAll,2,4)

UPDATE		#tmpDepTime0000
SET			DepTimeAll = '1215'
WHERE		Ket IN ('DepTime2','DepTime3','Deptime4') AND 
			DepTimeAll = '9215'

UPDATE		#tmpTCN 
SET			DepTime = CONVERT(time,SUBSTRING(b.DepTimeAll,1,2) +':'+SUBSTRING(b.DepTimeAll,3,2))
FROM		#tmpTCN  a INNER JOIN #tmpDepTime0000  b
ON			b.TicketNumber = CONVERT(varchar,a.TicketNumber) AND
			b.TcnNo = a.TCNNo
WHERE		b.Ket = 'DepTime'

UPDATE		#tmpTCN 
SET			DepTime2 = CONVERT(time,SUBSTRING(b.DepTimeAll,1,2) +':'+SUBSTRING(b.DepTimeAll,3,2))
FROM		#tmpTCN  a INNER JOIN #tmpDepTime0000  b
ON			b.TicketNumber = CONVERT(varchar,a.TicketNumber) AND
			b.TcnNo = a.TCNNo
WHERE		b.Ket = 'DepTime2' 

UPDATE		#tmpTCN 
SET			DepTime3 = CONVERT(time,SUBSTRING(b.DepTimeAll,1,2) +':'+SUBSTRING(b.DepTimeAll,3,2))
FROM		#tmpTCN  a INNER JOIN #tmpDepTime0000  b
ON			b.TicketNumber = CONVERT(varchar,a.TicketNumber) AND
			b.TcnNo = a.TCNNo
WHERE		b.Ket = 'DepTime3'

UPDATE		#tmpTCN 
SET			DepTime4 = CONVERT(time,substring(b.DepTimeAll,1,2) +':'+substring(b.DepTimeAll,3,2))
FROM		#tmpTCN  a INNER JOIN #tmpDepTime0000  b
ON			b.TicketNumber = CONVERT(varchar,a.TicketNumber) AND
			b.TcnNo = a.TCNNo
WHERE		b.Ket = 'DepTime4'
--------------------------------------------------------------------------------------------------------

DROP TABLE	#tmpDepTimeNoon 
SELECT		* 
INTO		#tmpDepTimeNoon 
FROM		#tmpDepTimeAll 
WHERE		DepTimeAll LIKE '%N'

UPDATE		#tmpTCN 
SET			DepTime = '12 pm'
FROM		#tmpTCN a INNER JOIN #tmpDepTimeNoon b
ON			b.TicketNumber = CONVERT(VARCHAR,a.TicketNumber) AND
			b.TcnNo = a.TCNNo
WHERE		b.Ket = 'DepTime'

UPDATE		#tmpTCN 
SET			DepTime2 = '12 pm'
FROM		#tmpTCN a INNER JOIN #tmpDepTimeNoon b
ON			b.TicketNumber = CONVERT(VARCHAR,a.TicketNumber) AND
			b.TcnNo = a.TCNNo
WHERE		b.Ket = 'DepTime2' 
		
UPDATE		#tmpTCN 
SET			DepTime3 = '12 pm'
FROM		#tmpTCN a INNER JOIN #tmpDepTimeNoon b
ON			b.TicketNumber = CONVERT(VARCHAR,a.TicketNumber) AND
			b.TcnNo = a.TCNNo
WHERE		b.Ket = 'DepTime3' 

UPDATE		#tmpTCN 
SET			DepTime4 = '12 pm'
FROM		#tmpTCN a INNER JOIN #tmpDepTimeNoon b
ON			b.TicketNumber = CONVERT(VARCHAR,a.TicketNumber) AND
			b.TcnNo = a.TCNNo
WHERE		b.Ket = 'DepTime4' 

--------------------------------------------------------------------------------------------------------

DROP TABLE	#tmpDepTimeAM 
SELECT		* 
INTO		#tmpDepTimeAM 
FROM		#tmpDepTimeAll 
WHERE		DepTimeAll LIKE '%A'

UPDATE		#tmpDepTimeAM 
SET			DepTimeAll = SUBSTRING(DepTimeAll,1,2)+':'+SUBSTRING(DepTimeAll,3,2)+' AM'

UPDATE		#tmpTCN 
SET			DepTime = b.DepTimeAll
FROM		#tmpTCN a INNER JOIN #tmpDepTimeAM b
ON			b.TicketNumber = CONVERT(VARCHAR,a.TicketNumber) AND
			b.TcnNo = a.TCNNo
WHERE		b.Ket = 'DepTime'

UPDATE		#tmpTCN 
SET			DepTime2 = b.DepTimeAll
FROM		#tmpTCN a INNER JOIN #tmpDepTimeAM b
ON			b.TicketNumber = CONVERT(VARCHAR,a.TicketNumber) AND
			b.TcnNo = a.TCNNo
WHERE		b.Ket = 'DepTime2'

UPDATE		#tmpTCN 
SET			DepTime3 = b.DepTimeAll
FROM		#tmpTCN a INNER JOIN #tmpDepTimeAM b
ON			b.TicketNumber = CONVERT(VARCHAR,a.TicketNumber) AND
			b.TcnNo = a.TCNNo
WHERE		b.Ket = 'DepTime3'

UPDATE		#tmpTCN 
SET			DepTime4 = b.DepTimeAll
FROM		#tmpTCN a INNER JOIN #tmpDepTimeAM b
ON			b.TicketNumber = CONVERT(VARCHAR,a.TicketNumber) AND
			b.TcnNo = a.TCNNo
WHERE		b.Ket = 'DepTime4'
--------------------------------------------------------------------------------------------------------

DROP TABLE	#tmpDepTimePM 
SELECT		* 
INTO		#tmpDepTimePM 
FROM		#tmpDepTimeAll 
WHERE		DepTimeAll LIKE '%P'

UPDATE		#tmpDepTimePM 
SET			DepTimeAll = SUBSTRING(DepTimeAll,1,2)+':'+SUBSTRING(DepTimeAll,3,2)+' PM'

UPDATE		#tmpTCN
SET			DepTime = b.DepTimeAll
FROM		#tmpTCN a INNER JOIN #tmpDepTimePM b
ON			b.TicketNumber = CONVERT(VARCHAR,a.TicketNumber) AND
			b.TcnNo = a.TCNNo
WHERE		b.Ket = 'DepTime'

UPDATE		#tmpTCN
SET			DepTime2 = b.DepTimeAll
FROM		#tmpTCN a INNER JOIN #tmpDepTimePM b
ON			b.TicketNumber = CONVERT(VARCHAR,a.TicketNumber) AND
			b.TcnNo = a.TCNNo
WHERE		b.Ket = 'DepTime2'
		
UPDATE		#tmpTCN
SET			DepTime3 = b.DepTimeAll
FROM		#tmpTCN a INNER JOIN #tmpDepTimePM b
ON			b.TicketNumber = CONVERT(VARCHAR,a.TicketNumber) AND
			b.TcnNo = a.TCNNo
WHERE		b.Ket = 'DepTime3'
		
UPDATE		#tmpTCN
SET			DepTime4 = b.DepTimeAll
FROM		#tmpTCN a INNER JOIN #tmpDepTimePM b
ON			b.TicketNumber = CONVERT(VARCHAR,a.TicketNumber) AND
			b.TcnNo = a.TCNNo
WHERE		b.Ket = 'DepTime4'						
		
---------------------------- UpDate ArrTime -------------------------------------

DROP TABLE	#tmpArrTimeAll
SELECT		TicketNumber,TCNNo,ArrTimeAll = REPLACE(ArrTime,' ',''),Ket = 'ArrTime' 
INTO		#tmpArrTimeAll 
FROM		dmTCN 
UNION ALL
SELECT		TicketNumber,TCNNo,ArrTimeAll = REPLACE(ArrTime2,' ',''),Ket = 'ArrTime2' 
FROM		dmTCN 
UNION ALL
SELECT		TicketNumber,TCNNo,ArrTimeAll = REPLACE(ArrTime3,' ',''),Ket = 'ArrTime3' 
FROM		dmTCN 
UNION ALL
SELECT		TicketNumber,TCNNo,ArrTimeAll = REPLACE(ArrTime4,' ',''),Ket = 'ArrTime4' 
FROM		dmTCN 
--------------------------------------------------------------------------------------------------------

SELECT		COUNT(*) 
FROM		#tmpArrTimeAll 
WHERE		ArrTimeAll LIKE '0%N'

SELECT		COUNT(*) 
FROM		#tmpArrTimeAll 
WHERE		ArrTimeAll LIKE '0%A'

SELECT		COUNT(*) 
FROM		#tmpArrTimeAll 
WHERE		ArrTimeAll LIKE '0%P'

SELECT		COUNT(*) 
FROM		#tmpArrTimeAll 
WHERE		LEN(ArrTimeAll) = 4

UPDATE		#tmpArrTimeAll 
SET			ArrTimeAll = '0'+ ArrTimeAll 
WHERE		LEN(ArrTimeAll) = 4

SELECT		DISTINCT LEN(ArrTimeAll) 
FROM		#tmpArrTimeAll
--------------------------------------------------------------------------------------------------------

DROP TABLE	#tmpArrTime0000 
SELECT		* 
INTO		#tmpArrTime0000 
FROM		#tmpArrTimeAll
WHERE		ArrTimeAll NOT LIKE '%N' AND 
			ArrTimeAll NOT LIKE '%A' AND
			ArrTimeAll NOT LIKE '%P' AND
			ArrTimeAll <> ' ' 

UPDATE		#tmpArrTime0000
SET			ArrTimeAll = SUBSTRING(ArrTimeAll,2,4)

UPDATE		#tmpTCN 
SET			ArrTime = CONVERT(TIME,SUBSTRING(b.ArrTimeAll,1,2) +':'+SUBSTRING(b.ArrTimeAll,3,2))
FROM		#tmpTCN a INNER JOIN #tmpArrTime0000 b
ON			b.TicketNumber = CONVERT(VARCHAR,a.TicketNumber) AND
			b.TcnNo = a.TCNNo
WHERE		b.Ket = 'ArrTime'

UPDATE		#tmpTCN 
SET			ArrTime2 = CONVERT(TIME,SUBSTRING(b.ArrTimeAll,1,2) +':'+SUBSTRING(b.ArrTimeAll,3,2))
FROM		#tmpTCN a INNER JOIN #tmpArrTime0000 b
ON			b.TicketNumber = CONVERT(VARCHAR,a.TicketNumber) AND
			b.TcnNo = a.TCNNo
WHERE		b.Ket = 'ArrTime2'

UPDATE		#tmpTCN 
SET			ArrTime3 = CONVERT(TIME,SUBSTRING(b.ArrTimeAll,1,2) +':'+SUBSTRING(b.ArrTimeAll,3,2))
FROM		#tmpTCN a INNER JOIN #tmpArrTime0000 b
ON			b.TicketNumber = CONVERT(VARCHAR,a.TicketNumber) AND
			b.TcnNo = a.TCNNo
WHERE		b.Ket = 'ArrTime3'

UPDATE		#tmpTCN 
SET			ArrTime4 = CONVERT(TIME,substring(b.ArrTimeAll,1,2) +':'+substring(b.ArrTimeAll,3,2))
FROM		#tmpTCN a INNER JOIN #tmpArrTime0000 b
ON			b.TicketNumber = CONVERT(VARCHAR,a.TicketNumber) AND
			b.TcnNo = a.TCNNo
WHERE		b.Ket = 'ArrTime4'
--------------------------------------------------------------------------------------------------------

DROP TABLE	#tmpArrTimeNoon 
SELECT		* 
INTO		#tmpArrTimeNoon 
FROM		#tmpArrTimeAll
WHERE		ArrTimeAll LIKE '%N'

UPDATE		#tmpTCN 
SET			ArrTime = '12 pm'
FROM		#tmpTCN a INNER JOIN #tmpArrTimeNoon b
ON			b.TicketNumber = CONVERT(VARCHAR,a.TicketNumber) AND
			b.TcnNo = a.TCNNo
WHERE		b.Ket = 'ArrTime'

UPDATE		#tmpTCN 
SET			ArrTime2 = '12 pm'
FROM		#tmpTCN a INNER JOIN #tmpArrTimeNoon b
ON			b.TicketNumber = CONVERT(VARCHAR,a.TicketNumber) AND
			b.TcnNo = a.TCNNo
WHERE		b.Ket = 'ArrTime2' 
		
UPDATE		#tmpTCN 
SET			ArrTime3 = '12 pm'
FROM		#tmpTCN a INNER JOIN #tmpArrTimeNoon b
ON			b.TicketNumber = CONVERT(VARCHAR,a.TicketNumber) AND
			b.TcnNo = a.TCNNo
WHERE		b.Ket = 'ArrTime3' 

UPDATE		#tmpTCN 
SET			ArrTime4 = '12 pm'
FROM		#tmpTCN a INNER JOIN #tmpArrTimeNoon b
ON			b.TicketNumber = CONVERT(VARCHAR,a.TicketNumber) AND
			b.TcnNo = a.TCNNo
WHERE		b.Ket = 'ArrTime4' 
--------------------------------------------------------------------------------------------------------

DROP TABLE	#tmpArrTimeAM 
SELECT		* 
INTO		#tmpArrTimeAM 
FROM		#tmpArrTimeAll
WHERE		ArrTimeAll LIKE '%A'

UPDATE		#tmpArrTimeAM 
SET 		ArrTimeAll = SUBSTRING(ArrTimeAll,1,2)+':'+SUBSTRING(ArrTimeAll,3,2)+' AM'

UPDATE		#tmpTCN 
SET			ArrTime = b.ArrTimeAll
FROM		#tmpTCN a INNER JOIN #tmpArrTimeAM b
ON			b.TicketNumber = CONVERT(VARCHAR,a.TicketNumber) AND
			b.TcnNo = a.TCNNo
WHERE		b.Ket = 'ArrTime'

UPDATE		#tmpTCN 
SET			ArrTime2 = b.ArrTimeAll
FROM		#tmpTCN a INNER JOIN #tmpArrTimeAM b
ON			b.TicketNumber = CONVERT(VARCHAR,a.TicketNumber) AND
			b.TcnNo = a.TCNNo
WHERE		b.Ket = 'ArrTime2'

UPDATE		#tmpTCN 
SET			ArrTime3 = b.ArrTimeAll
FROM		#tmpTCN a INNER JOIN #tmpArrTimeAM b
ON			b.TicketNumber = CONVERT(VARCHAR,a.TicketNumber) AND
			b.TcnNo = a.TCNNo
WHERE		b.Ket = 'ArrTime3'

UPDATE		#tmpTCN 
SET			ArrTime4 = b.ArrTimeAll
FROM		#tmpTCN a INNER JOIN #tmpArrTimeAM b
ON			b.TicketNumber = CONVERT(VARCHAR,a.TicketNumber) AND
			b.TcnNo = a.TCNNo
WHERE		b.Ket = 'ArrTime4'
--------------------------------------------------------------------------------------------------------

DROP TABLE	#tmpArrTimePM 
SELECT		* 
INTO		#tmpArrTimePM 
FROM		#tmpArrTimeAll
WHERE		ArrTimeAll LIKE '%P'

UPDATE		#tmpArrTimePM 
SET			ArrTimeAll = SUBSTRING(ArrTimeAll,1,2)+':'+SUBSTRING(ArrTimeAll,3,2)+' PM'

UPDATE		#tmpTCN 
SET			ArrTime = b.ArrTimeAll
FROM		#tmpTCN a INNER JOIN #tmpArrTimePM b
ON			b.TicketNumber = CONVERT(VARCHAR,a.TicketNumber) AND
			b.TcnNo = a.TCNNo
WHERE		b.Ket = 'ArrTime'

UPDATE		#tmpTCN 
SET			ArrTime2 = b.ArrTimeAll
FROM		#tmpTCN a INNER JOIN #tmpArrTimePM b
ON			b.TicketNumber = CONVERT(VARCHAR,a.TicketNumber) AND
			b.TcnNo = a.TCNNo 
WHERE		b.Ket = 'ArrTime2'
		
UPDATE		#tmpTCN 
SET			ArrTime3 = b.ArrTimeAll
FROM		#tmpTCN a INNER JOIN #tmpArrTimePM  b
ON			b.TicketNumber = CONVERT(VARCHAR,a.TicketNumber) AND
			b.TcnNo = a.TCNNo
WHERE		b.Ket = 'ArrTime3'
		
UPDATE		#tmpTCN 
SET			ArrTime4 = b.ArrTimeAll
FROM		#tmpTCN a INNER JOIN #tmpArrTimePM  b
ON			b.TicketNumber = CONVERT(VARCHAR,a.TicketNumber) AND
			b.TcnNo = a.TCNNo
WHERE		b.Ket = 'ArrTime4'						

------------------------- Update FLIGHT NO  -------------------------------------

DROP TABLE	#tmpFlightNoAll
SELECT		TicketNumber,TCNNo,FlightNoAll = REPLACE(FlightNo,' ',''),Ket='FlightNo' 
INTO		#tmpFlightNoAll 
FROM		dmTCN 
UNION ALL
SELECT		TicketNumber,TCNNo,FlightNoAll = REPLACE(FlightNo2,' ',''),Ket='FlightNo2' 
FROM		dmTCN 
UNION ALL
SELECT		TicketNumber,TCNNo,FlightNoAll = REPLACE(FlightNo3,' ',''),Ket='FlightNo3' 
FROM		dmTCN 
UNION ALL
SELECT		TicketNumber,TCNNo,FlightNoAll = REPLACE(FlightNo4,' ',''),Ket='FlightNo4' 
FROM		dmTCN 

--------------------------------------------------------------------------------------------------------
SELECT		DISTINCT LEN(FlightNoAll) 
FROM		#tmpFlightNoAll 
	
SELECT		MAX(LEN(FlightNoAll)) 
FROM		#tmpFlightNoAll 
--------------------------------------------------------------------------------------------------------

DROP TABLE	#tmpFlightNo0000
SELECT		TicketNumber,TcnNo,FlightNoAll,Ket  
INTO		#tmpFlightNo0000
FROM		#tmpFlightNoAll
WHERE		1 = 2

WHILE		1=1
BEGIN

	TRUNCATE TABLE #tmpFlightNo0000
	INSERT		#tmpFlightNo0000
	SELECT		* 
	FROM		#tmpFlightNoAll
	WHERE		SUBSTRING(FlightNoAll,1,1) = '0'
	
	IF			@@ROWCOUNT = 0
	BREAK
	
	UPDATE		#tmpFlightNoAll
	SET			FlightNoAll = SUBSTRING(b.FlightNoAll,2,3)
	FROM		#tmpFlightNoAll a INNER JOIN #tmpFlightNo0000 b 
	ON			b.TicketNumber = a.TicketNumber AND
				b.TcnNo = a.TcnNo AND
				b.Ket = a.Ket 
	 
END	
--------------------------------------------------------------------------------------------------------
SELECT		DISTINCT FlightNoAll 
FROM		#tmpFlightNoAll 
ORDER BY	FlightNoAll  	

SELECT		DISTINCT FlightNo 
FROM		dmTCN 
ORDER BY	FlightNo  	
--------------------------------------------------------------------------------------------------------
UPDATE		#tmpTCN 
SET			FlightNo = b.FlightNoAll
FROM		#tmpTCN a INNER JOIN #tmpFlightNoAll b
ON			b.TicketNumber = CONVERT(VARCHAR,a.TicketNumber) AND
			b.TcnNo = a.TCNNo
WHERE		b.Ket = 'FlightNo'

UPDATE		#tmpTCN 
SET			FlightNo2 = b.FlightNoAll
FROM		#tmpTCN a INNER JOIN #tmpFlightNoAll b
ON			b.TicketNumber = CONVERT(VARCHAR,a.TicketNumber) AND
			b.TcnNo = a.TCNNo 
WHERE		b.Ket = 'FlightNo2'
		
UPDATE		#tmpTCN 
SET			FlightNo3 = b.FlightNoAll
FROM		#tmpTCN a INNER JOIN #tmpFlightNoAll b
ON			b.TicketNumber = CONVERT(VARCHAR,a.TicketNumber) AND
			b.TcnNo = a.TCNNo 
WHERE		b.Ket = 'FlightNo3'
		
UPDATE		#tmpTCN 
SET			FlightNo4 = b.FlightNoAll
FROM		#tmpTCN a INNER JOIN #tmpFlightNoAll b
ON			b.TicketNumber = CONVERT(VARCHAR,a.TicketNumber) AND
			b.TcnNo = a.TCNNo 
WHERE		b.Ket = 'FlightNo4'	
		
--------------------------------------------------------------------------------------------------------
BEGIN TRAN	
UPDATE		tblTCN
SET			CreateDate = b.CreateDate, CreateTime = b.CreateTime, 
			DepTime = b.DepTime, DepTime2 = b.DepTime2, DepTime3 = b.DepTime3, DepTime4 = b.DepTime4,
			ArrTime = b.ArrTime, ArrTime2 = b.ArrTime2, ArrTime3 = b.ArrTime3, ArrTime4 = b.ArrTime4,
			FlightNo = b.FlightNo, FlightNo2 = b.FlightNo2, FlightNo3 = b.FlightNo3, FlightNo4 = b.FlightNo4	 
FROM		tblTCN a INNER JOIN #tmpTCN b
ON			b.TicketNumber = a.TicketNumber AND
			b.TCNNo = a.TCNNo 					
COMMIT TRAN

------------------------------------------------------------------------------------------------------

--harus kosong

SELECT		* 
FROM		tbltcn
WHERE		insertdate > '27 Nov 2019' AND ((DepTime IS NULL AND ArrTime IS NOT NULL) or (DepTime IS NOT NULL AND ArrTime IS NULL))
SELECT		* 
FROM		tbltcn
WHERE		insertdate > '27 Nov 2019' AND ((DepTime IS NULL AND ArrTime IS NOT NULL) or (DepTime IS NOT NULL AND ArrTime IS NULL))
SELECT		* 
FROM		tbltcn
WHERE       insertdate > '27 Nov 2019' AND ((DepTime IS NULL AND ArrTime IS NOT NULL) or (DepTime IS NOT NULL AND ArrTime IS NULL))
SELECT		* 
FROM		tbltcn
WHERE       insertdate > '27 Nov 2019' AND ((DepTime IS NULL AND ArrTime IS NOT NULL) or (DepTime IS NOT NULL AND ArrTime IS NULL))

--kalo misalnya ada isi tapi RFND boleh, selain itu gak boleh, harus kosong