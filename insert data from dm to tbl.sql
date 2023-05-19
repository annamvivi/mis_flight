DELETE		dmtdesc
FROM		dmtdesc a, tblTDesc b
WHERE		b.TicketNumber = a.ticketnumber

INSERT		INTO tblTDesc
			(StKey, TicketNumber, FC, RouteAwal, RouteAkhir, Airlines, Fare, QsFare, EndQRoute, EndQSFare, RemStar)
SELECT		StKey, TicketNumber, FC, RouteAwal, RouteAkhir, Airlines, Fare, QsFare, EndQRoute, EndQSFare, RemStar
FROM		dmtdesc

=========================================================================================================================

SELECT		Ticketnumber,fc
FROM		dmflown
GROUP BY	Ticketnumber,fc
HAVING		COUNT(*) > 1

UPDATE		dmflown
SET			FQTVCode = REPLACE(FQTVCode,';','')

update dmflown
set statuspax = 'INFANT'
where farebasis like '%IN%'

update dmflown
set statuspax = 'CHILD'
where farebasis like '%CH%'

update dmflown
set statuspax = 'ADULT'
where statuspax is null

INSERT		tblflown
			(Airline,CrtFile,FlightNo,OriginDate,Ticketnumber,fc,dtlFlightNo,flowndate,routefrom,routeto,
			cabin,class,farebasis,fc1Route,fc2Route,fc3Route,fc4Route,Settle,FQTVNo,statuspax)
SELECT		Airline,CrtFile,FlightNo,OriginDate,Ticketnumber,fc,dtlFlightNo,flowndate,routefrom,routeto,
			cabin,class,farebasis,fc1Route,fc2Route,fc3Route,fc4Route,Settle,FQTVCode,statuspax
FROM		dmflown

=========================================================================================================================

SELECT		TicketNumber,TcnNo 
FROM		dmTCN 
GROUP BY	TicketNumber,TcnNo  
HAVING		COUNT(*) > 1
		
INSERT		tblTCN (TicketNumber,TCNNo,PNRR,TicketAsal,TransCode,
			BookDate,StopOver,"From","To",FlightNo,Class,FlightDate,"Status",Baggage,FareBasis,Exb,
			BookDate2,StopOver2,From2,To2,FlightNo2,Class2,FlightDate2,Status2,Baggage2,FareBasis2,Exb2,
			BookDate3,StopOver3,From3,To3,FlightNo3,Class3,FlightDate3,Status3,Baggage3,FareBasis3,Exb3,
			BookDate4,StopOver4,From4,To4,FlightNo4,Class4,FlightDate4,Status4,Baggage4,FareBasis4, RemarkTCN) 
SELECT		TicketNumber,TCNNo,PNRR,TicketAsal,TransCode,
			BookDate,StopOver,"From","To",FlightNo,Class,FlightDate,"Status",Baggage,FareBasis,Exb,
			BookDate2,StopOver2,From2,To2,FlightNo2,Class2,FlightDate2,Status2,Baggage2,FareBasis2,Exb2,
			BookDate3,StopOver3,From3,To3,FlightNo3,Class3,FlightDate3,Status3,Baggage3,FareBasis3,Exb3,
			BookDate4,StopOver4,From4,To4,FlightNo4,Class4,FlightDate4,Status4,Baggage4,FareBasis4, RemarkTCN
FROM		dmTCN	

-------------------------------------------------------------------------------------------------------------------------
DROP TABLE	#tmp1
SELECT		* 
INTO		#tmp1 
FROM		dmTCNTKT 
WHERE		DocType = 'CNJ' 

UPDATE		#tmp1
SET			StKey = b.stkey
FROM		#tmp1 a, dmTCNTKT b
WHERE		b.TicketNumber = a.PreConjTicket

UPDATE		dmTCNTKT
SET			StKey = a.stkey
FROM		#tmp1 a, dmtcntkt b
WHERE		b.TicketNumber = a.TicketNumber

UPDATE		dmtcntktcpn
SET			StKey = a.stkey
FROM		#tmp1 a, dmtcntktcpn b
WHERE		b.TicketNumber = a.TicketNumber

UPDATE		dmTCNtktpr
SET			StKey = a.stkey
FROM		#tmp1 a, dmTCNtktpr b
WHERE		b.TicketNumber = a.TicketNumber

--------------

SELECT		COUNT(*) 
FROM		dmTCNTKT

SELECT		ticketnumber
FROM		dmTCNTkt
GROUP BY	TicketNumber
HAVING		COUNT(*) > 1

SELECT		COUNT(*) 
FROM		dmTCNTKT a WITH(NOLOCK) INNER JOIN tblTCNTKT b WITH(NOLOCK)
ON			b.StKey = a.StKey AND 
			b.TicketNumber = a.TicketNumber		

INSERT		tblTCNTKT (StKey, TransCode, DocType, TktInd, TicketNumber, PaxName, RefundTicket, IssuedDate, RouteAwal, RouteAkhir, PNRR, AgentDie, TourCode, 
            TRKRefNo, AccAmount, AccAdm, AccCCAdm, TktBaseFare, TktPPN, TktFSurcharge, TktIWJR, TktKomisi, TktAdm, TktApoTax, CalcTotal, Descr, FOP, 
            Total, CCNo, exchTicket, TailExchTicket, ExpDate, ApprovalCode, ExbPrasCode, ExbPrasDesc, ExbNoItems, exbPrice, PreConjTicket, CURR, 
            CURRDEC, RFNDCPN, LOKASIBOOKING, LOKASIIssuedtkt, TAIssuedTkt, TimeIssuedTkt, TimeBookingTkt)
SELECT		StKey, TransCode, DocType, TktInd, TicketNumber, PaxName, RefundTicket, IssuedDate, RouteAwal, RouteAkhir, PNRR, AgentDie, TourCode, 
            TRKRefNo, AccAmount, AccAdm, AccCCAdm, TktBaseFare, TktPPN, TktFSurcharge, TktIWJR, TktKomisi, TktAdm, TktApoTax, CalcTotal, Descr, FOP, 
            Total, CCNo, exchTicket, TailExchTicket, ExpDate, ApprovalCode, ExbPrasCode, ExbPrasDesc, ExbNoItems, exbPrice, PreConjTicket, CURR, 
            CURRDEC, RFNDCPN, LOKASIBOOKING, LOKASIIssuedtkt, TAIssuedTkt, TimeIssuedTkt, TimeBookingTkt
FROM		dmTCNTKT

SELECT		COUNT(*) 
FROM		dmtcntktcpn

SELECT		ticketnumber,FC
FROM		dmTCNTktCpn
GROUP BY	TicketNumber,FC
HAVING		COUNT(*) > 1

SELECT		COUNT(*)
FROM		dmtcntktcpn a WITH(NOLOCK) INNER JOIN tblTCNTKTCPN b WITH(NOLOCK)
ON			b.StKey = a.StKey AND 
			b.TicketNumber = a.TicketNumber

DELETE		dmTCNtktcpn
FROM		dmtcntktcpn a INNER JOIN tblTCNTKTCPN b
ON			b.StKey = a.StKey AND 
			b.TicketNumber = a.TicketNumber			

INSERT		tblTCNTKTCPN ( StKey, TicketNumber, FC, Transit, RouteAwal, RouteAkhir, Airlines, FlightNumber, FlightDate, FareBasis, FareFromDescr, Code, FSurcharge, 
            wrongFare, QSfare, Remstar)
SELECT		StKey, TicketNumber, FC, Transit, RouteAwal, RouteAkhir, Airlines, FlightNumber, FlightDate, FareBasis, FareFromDescr, Code, FSurcharge, 
            wrongFare, QSfare, Remstar
FROM		dmTCNtktcpn

SELECT		COUNT(*) 
FROM		dmtcntktpr

update dmTCNtktpr 
set Curr = LEFT(right(stkey,4),3), CurrDec = RIGHT(stkey,1)

SELECT		ticketnumber,kodebiaya
FROM		dmTCNTktpr
GROUP BY	TicketNumber,kodebiaya
HAVING		COUNT(*) > 1

SELECT		COUNT(*)
FROM		dmTCNtktpr a WITH(NOLOCK) INNER JOIN tbltcntktpr b WITH(NOLOCK)
ON			b.ticketnumber = a.ticketnumber AND
    		b.kodebiaya = a.kodebiaya AND
			b.amount = a.amount

INSERT		tbltcntktpr (StKey, TicketNumber, KodeBiaya, Seq, Amount, Curr, CurrDec)
SELECT		StKey, TicketNumber, KodeBiaya, Seq, Amount, Curr, CurrDec
FROM		dmTCNtktpr
		

======================================================================================================================

	SELECT COUNT(*) FROM TBLFLOWN WITH(NOLOCK) where insertdate > '27 Nov 2019'
	SELECT COUNT(*) FROM tblTCN WITH(NOLOCK) where insertdate > '27 Nov 2019'
	SELECT COUNT(*) FROM tblTCNtkt WITH(NOLOCK) where insertdate > '27 Nov 2019'
	SELECT COUNT(*) FROM tblTCNtktcpn WITH(NOLOCK) where insertdate > '27 Nov 2019'
	SELECT COUNT(*) FROM tblTCNTKTPR WITH(NOLOCK) where insertdate > '27 Nov 2019'
