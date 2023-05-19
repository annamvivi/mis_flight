DROP TABLE	#tmptcntkt
SELECT		*
INTO		#tmptcntkt 
FROM		dmtcntkt WITH(NOLOCK)

SELECT		DISTINCT PreConjTicket 
FROM		#tmptcntkt

UPDATE		#tmptcntkt
SET			PreConjTicket = NULL
WHERE		LEN(PreConjTicket) = 15 OR
			PreConjTicket = ' '

SELECT		COUNT(*)
FROM		#tmptcntkt a INNER JOIN tbltkt b WITH(NOLOCK)
ON			b.TicketNumber = a.TicketNumber
			
SELECT		COUNT(*)
FROM		#tmptcntkt a INNER JOIN tbltkt b WITH(NOLOCK)
ON			b.stkey = a.stkey AND
			b.ticketnumber = a.ticketnumber

SELECT		COUNT(*)
FROM		#tmptcntkt a INNER JOIN dmtkt b WITH(NOLOCK)
ON			b.TicketNumber = a.TicketNumber

--------------------------------------------------------------------			
DELETE		#tmptcntkt
FROM		#tmptcntkt a INNER JOIN tbltkt b WITH(NOLOCK)
ON			b.TicketNumber = a.TicketNumber

DELETE		#tmptcntkt
FROM		#tmptcntkt a INNER JOIN dmtkt b WITH(NOLOCK)
ON			b.TicketNumber = a.TicketNumber

INSERT		dmtkt
			(StKey,TransCode,DocType,TktInd,TicketNumber,PaxName,RefundTicket,IssuedDate,RouteAwal,RouteAkhir,
			PNRR,AgentDie,TourCode,TRKRefNo,AccAmount,AccAdm,AccCCAdm,TktBaseFare,TktPPN,TktFSurcharge,TktIWJR,
			TktKomisi,TktAdm,TktApoTax,CalcTotal,Descr,FOP,Total,CCNo,exchTicket,TailExchTicket,ExpDate,ApprovalCode,
			ExbPrasCode,ExbPrasDesc,ExbNoItems,exbPrice,PreConjTicket,Curr,CurrDec,RfndCpn, companycode)
SELECT		StKey,TransCode,DocType,TktInd,TicketNumber,PaxName,RefundTicket,IssuedDate,RouteAwal,RouteAkhir,
			PNRR,AgentDie,TourCode,TRKRefNo,AccAmount,AccAdm,AccCCAdm,TktBaseFare,TktPPN,TktFSurcharge,TktIWJR,
			TktKomisi,TktAdm,TktApoTax,CalcTotal,Descr,FOP,Total,CCNo,exchTicket,TailExchTicket,ExpDate,ApprovalCode,
			ExbPrasCode,ExbPrasDesc,ExbNoItems,exbPrice,PreConjTicket,Curr,CurrDec,RfndCPN, 'INA'
FROM		#tmptcntkt

UPDATE		dmtkt
SET			FromTCN = 'TCN'
FROM		#tmptcntkt a INNER JOIN dmtkt b WITH(NOLOCK)
ON			b.TicketNumber = a.TicketNumber AND
			b.StKey = a.StKey 
------------------------------------------------------------------------------------------------------------------------------------
DROP TABLE	#tmptcnsttrk
SELECT		*
INTO		#tmptcnsttrk 
FROM		dmsttrk
WHERE		1 = 2

SELECT		*
FROM		#tmptcnsttrk

DROP TABLE	#tmp1
SELECT		DISTINCT StKey 
INTO		#tmp1 
FROM		#tmptcntkt

INSERT		INTO #tmptcnsttrk (StKey)
SELECT		stkey FROM #tmp1

UPDATE		#tmptcnsttrk
SET			stationno = SUBSTRING(stkey,1,8),stationopendate = SUBSTRING(stkey,9,6),stationcode = SUBSTRING(stkey,15,5),
			stationcurr = SUBSTRING(stkey,20,3),stationcurrdec = SUBSTRING(stkey,23,1)

UPDATE		#tmptcnsttrk
SET			stationclosedate = stationopendate + 1

DELETE		#tmptcnsttrk
FROM		dmsttrk a INNER JOIN #tmptcnsttrk b
ON			b.stkey = a.StKey 

INSERT		dmsttrk
			(StKey,StationNo,StationOpenDate,StationCode,StationCurr,StationCurrDec,StationCloseDate,CloseEmpNumber,EmpNumber,
			DepositAmt,CCAmt,OvershortAmt,CashAdjustAmt,CashTktSalesAmt,TotalAmt,GrossAmt,CommisionAmt,TaxAmt)
SELECT		StKey,StationNo,StationOpenDate,StationCode,StationCurr,StationCurrDec,StationCloseDate,CloseEmpNumber,EmpNumber,
			DepositAmt,CCAmt,OvershortAmt,CashAdjustAmt,CashTktSalesAmt,TotalAmt,GrossAmt,CommisionAmt,TaxAmt
FROM		#tmptcnsttrk
-----------------------------------------------------------------------------------------------------------------------------------
DROP TABLE	#tmptcntktcpn
SELECT		b.*
INTO		#tmptcntktcpn 
FROM		#tmptcntkt a, tbltcntktcpn b
WHERE		b.StKey = a.StKey AND b.TicketNumber = a.TicketNumber	
 		
DELETE		#tmptcntktcpn
FROM		#tmptcntktcpn a INNER JOIN tbltktcpn b
ON			b.ticketnumber = a.ticketnumber AND
    		b.fc = a.fc
    		
DELETE		#tmptcntktcpn
FROM		#tmptcntktcpn a INNER JOIN dmtktcpn b
ON			b.ticketnumber = a.ticketnumber AND
    		b.fc = a.fc

INSERT		dmtktcpn
			(StKey,TicketNumber,FC,Transit,RouteAwal,RouteAkhir,Airlines,FlightNumber,FlightDate,FareBasis,FarefromDescr,QSFare,RemStar)
SELECT		StKey,TicketNumber,FC,Transit,RouteAwal,RouteAkhir,Airlines,FlightNumber,FlightDate,FareBasis,FareFromDescr,QSFare,RemStar
FROM		#tmptcntktcpn

------------------------------------------------------------------------------------------------------------------------------------

DROP TABLE	#tmptcntktpr
SELECT		b.* 
INTO		#tmptcntktpr 
FROM		#tmptcntkt a,tbltcntktpr b
WHERE		b.StKey = a.StKey AND b.TicketNumber = a.TicketNumber

SELECT		COUNT(*)
FROM		#tmptcntktpr a INNER JOIN tblTktPrice b WITH(NOLOCK)
ON			b.ticketnumber = a.ticketnumber AND
    		b.kodebiaya = a.kodebiaya 

UPDATE		#tmptcntktpr
SET			Curr = SUBSTRING(StKey,20,3), CurrDec = SUBSTRING(stkey,23,1)

DELETE		#tmptcntktpr 
FROM		#tmptcntktpr a INNER JOIN tbltktprice b
ON			b.ticketnumber = a.ticketnumber AND
    		b.kodebiaya = a.kodebiaya

DELETE		#tmptcntktpr 
FROM		#tmptcntktpr a INNER JOIN dmtktpr b
ON			b.ticketnumber = a.ticketnumber AND
    		b.kodebiaya = a.kodebiaya

INSERT		dmtktpr
			(StKey,TicketNumber,KodeBiaya,Seq,Amount,Curr,CurrDec)
SELECT		distinct StKey,TicketNumber,KodeBiaya,Seq,Amount,Curr,CurrDec
FROM		#tmptcntktpr

=============================================================================================
--HARUS KOSONG--
select * from dmtktcpn where ticketnumber not in (select ticketnumber from dmtkt)
select * from dmtkt where ticketnumber not in (select ticketnumber from dmtktcpn) AND transcode in ('SALE','EXCH') AND doctype in ('TKT','CNJ')
select * from dmtkt where stkey not in (select stkey from dmsttrk)
select * from dmtkt where ticketnumber not in (select ticketnumber from dmtktpr) AND calctotal <> 0
