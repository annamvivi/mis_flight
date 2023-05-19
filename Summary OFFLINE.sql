DROP TABLE	#tmp1
SELECT		StationOpenDate, StationNo, District = LEFT(a.stationcode,3),
			StationCode, b.AgentDie, FOP = left(b.FOP,2), b.Curr, Total = SUM(calctotal) 
INTO		#tmp1 
FROM		tblsttrk a WITH(NOLOCK), tbltkt b WITH(NOLOCK)
WHERE		b.stkey = a.stkey AND
			a.StationOpenDate BETWEEN '24 Nov 2019' AND '26 Nov 2019' AND
			FromTCN IS NULL
GROUP BY	StationOpenDate, StationNo, LEFT(a.stationcode,3),
			StationCode, b.AgentDie, left(b.FOP,2), b.Curr

update #tmp1
set agentdie = replace(agentdie,'$','#')
where agentdie like '%$%'
			
DELETE		#tmp1
WHERE		FOP = ''

DROP TABLE	#tmp2
SELECT		DISTINCT * 
INTO		#tmp2
FROM		#tmp1

DELETE		#tmp2
FROM		#tmp2 a, tblSummaryOffline b
WHERE		b.StationOpenDate = a.StationOpenDate AND
			b.StationNo = a.StationNo AND
			b.District = a.District AND 
			b.StationCode = a.StationCode AND
			b.AgentDie = a.AgentDie AND
			b.FOP = a.FOP AND
			b.Curr = a.Curr AND
			b.Total = a.Total

DELETE		tblSummaryOffline
FROM		#tmp2 a, tblSummaryOffline b
WHERE		b.StationOpenDate = a.StationOpenDate AND
			b.StationNo = a.StationNo AND
			b.District = a.District AND 
			b.StationCode = a.StationCode AND
			b.AgentDie = a.AgentDie AND
			b.FOP = a.FOP AND
			b.Curr = a.Curr AND
			b.Total <> a.Total
			
DELETE		#tmp2 
WHERE		Total = 0
DELETE		#tmp2 
WHERE		Total < 0
DELETE		#tmp2 
WHERE		FOP = 'RA'

DELETE		#tmp2
WHERE		StationCode LIKE '%AG%'

DELETE		#tmp2
WHERE		StationCode LIKE '%WB%' AND StationCode not like '%KWB%'


INSERT		INTO tblSummaryOffline
			( ID, StationOpenDate, StationNo, District, StationCode, AgentDie, FOP, Curr, Total, InsertDate)
SELECT		'SOIW' + CONVERT(VARCHAR(50),NEWID()), StationOpenDate, StationNo, District, StationCode, AgentDie, FOP, Curr, Total, GETDATE()
FROM		#tmp2

