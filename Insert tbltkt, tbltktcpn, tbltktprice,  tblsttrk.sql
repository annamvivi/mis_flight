--JANGAN DOUBLE INSERT -- ABIS DELETE SELECT LAGI JIKA 0 BOLE DIINSERT

--INSERT TBLSTTRK--
SELECT		COUNT(*)
FROM		dmsttrk a INNER JOIN tblStTRK b
ON			b.StKey = a.StKey 
										--- HARUS SAMA	
SELECT		COUNT(*)
FROM		dmsttrk a INNER JOIN tblStTRK b
ON			b.StKey = a.StKey
WHERE		b.CloseEmpNumber IS NULL AND
			b.EmpNumber IS NULL AND
			b.DepositAmt IS NULL	
		
--------------------------------------------------	
BEGIN TRAN		
DELETE		tblStTRK
FROM		dmsttrk a INNER JOIN tblsttrk b -- NILAI DIDELETE HARUS SAMA DENGAN DIATAS
ON			b.stkey = a.stkey


ROLLBACK
COMMIT
---------------------------------------------------------------------------
INSERT		tblsttrk
			(StKey,StationNo,StationOpenDate,StationCode,StationCurr,StationCurrDec,StationCloseDate,CloseEmpNumber,EmpNumber,
			DepositAmt,CCAmt,OvershortAmt,CashAdjustAmt,CashTktSalesAmt,TotalAmt,GrossAmt,CommisionAmt,TaxAmt)
SELECT		StKey,StationNo,StationOpenDate,StationCode,StationCurr,StationCurrDec,StationCloseDate,CloseEmpNumber,EmpNumber,
			DepositAmt,CCAmt,OvershortAmt,CashAdjustAmt,CashTktSalesAmt,TotalAmt,GrossAmt,CommisionAmt,TaxAmt
FROM		dmsttrk
=========================================================================================================================

----INSERT TBLTKT----

UPDATE		dmtkt
SET			PreConjTicket = NULL
WHERE		LEN(PreConjTicket) = 15 OR
			PreConjTicket = ' '

SELECT		COUNT(*)
FROM		dmtkt a INNER JOIN tbltkt b WITH(NOLOCK)
ON			b.TicketNumber = a.TicketNumber 
													 /*jumlah row harusnya sama */
SELECT		COUNT(*)
FROM		dmtkt a INNER JOIN tbltkt b WITH(NOLOCK)
ON			b.TicketNumber = a.TicketNumber AND 
			b.FromTCN = 'TCN'
----------------------------------------------------------------------			
BEGIN TRAN		
DELETE		tbltkt
FROM		dmtkt a INNER JOIN tbltkt b WITH(NOLOCK)
ON			b.TicketNumber = a.TicketNumber 

rollback
COMMIT

----------------------------------------------------------------------
INSERT		tbltkt
			( StKey, TransCode, DocType, TktInd, TicketNumber, PaxName, RefundTicket, IssuedDate, RouteAwal, RouteAkhir, PNRR, AgentDie, TourCode, TRKRefNo, AccAmount, 
                      AccAdm, AccCCAdm, TktBaseFare, TktPPN, TktFSurcharge, TktIWJR, TktKomisi, TktAdm, TktApoTax, CalcTotal, Descr, FOP, Total, CCNo, exchTicket, TailExchTicket, 
                      ExpDate, ApprovalCode, ExbPrasCode, ExbPrasDesc, ExbNoItems, exbPrice, PreConjTicket, Curr, CurrDec, RfndCpn, Rate, dumCCADM, IntlCode, 
                      NoDokumen, IDKeyVedal, KodeDistrict, Remarks, BankName, tktRefCancelFee, tktRefUsedPort, FromTCN, companycode, TotalTicketSale, ccKey, 
                      nodokumenPay, tglPayment, IdReference, tktYRAdm, tktXXAdm, TktAdmKenaPPN, SALEDOCTYPE, TktPPNOD, TglLaporFinance, TglSelesaiProses, 
                      AmountVou, OriginPNR, TicketEndorse, stkeySALE, KodeVoucher, VATKomisi, Discount, NoRekonsil, NoSuratRefund, ReturnTax, 
                      AddTax, TktPPNIN)
SELECT		 StKey, TransCode, DocType, TktInd, TicketNumber, PaxName, RefundTicket, IssuedDate, RouteAwal, RouteAkhir, PNRR, AgentDie, TourCode, TRKRefNo, AccAmount, 
                      AccAdm, AccCCAdm, TktBaseFare, TktPPN, TktFSurcharge, TktIWJR, TktKomisi, TktAdm, TktApoTax, CalcTotal, Descr, FOP, Total, CCNo, exchTicket, TailExchTicket, 
                      ExpDate, ApprovalCode, ExbPrasCode, ExbPrasDesc, ExbNoItems, exbPrice, PreConjTicket, Curr, CurrDec, RfndCpn, Rate, dumCCADM, IntlCode, 
                      NoDokumen, IDKeyVedal, KodeDistrict, Remarks, BankName, tktRefCancelFee, tktRefUsedPort, FromTCN, companycode, TotalTicketSale, ccKey, 
                      nodokumenPay, tglPayment, IdReference, tktYRAdm, tktXXAdm, TktAdmKenaPPN, SALEDOCTYPE, TktPPNOD, TglLaporFinance, TglSelesaiProses, 
                      AmountVou, OriginPNR, TicketEndorse, stkeySALE, KodeVoucher, VATKomisi, Discount, NoRekonsil, NoSuratRefund, ReturnTax, 
                      AddTax, TktPPNIN
FROM		dmtkt

INSERT		tbltktrfndpax
			(TransCode,TicketNumber,RefundTicket,CalcTotal,insertdate)
SELECT		TransCode,TicketNumber,RefundTicket,CalcTotal, GETDATE()
FROM		dmtkt WITH(NOLOCK)
WHERE		TransCode LIKE 'rf%' 

=========================================================Copy yang bawah ke query lain================================================================
--HARI INI SAMPAI SINI
---INSERT TBLTKTCPN--

SELECT		COUNT(*)
FROM		dmtktcpn a INNER JOIN tbltktcpn b WITH(NOLOCK)
ON			b.stkey = a.stkey AND
			b.ticketnumber = a.ticketnumber AND
			b.fc = a.fc                                            -- harus sama
    		
SELECT		COUNT(*) 
FROM		dmtktcpn a INNER JOIN tbltktcpn b WITH(NOLOCK)
ON			b.ticketnumber = a.ticketnumber AND
			b.fc = a.fc 

------------------------------------------------------------------------------------------	    			
BEGIN TRAN
DELETE		tbltktcpn
FROM		dmtktcpn a INNER JOIN tbltktcpn b 
ON			b.ticketnumber = a.ticketnumber  

   /*DATA YANG DIDELETE HARUS SAMA DENGAN JUMLAH DATA SAAT DIINNER JOIN */
 Rollback  
COMMIT TRAN
-----------------------------------------------------------------------------------------------------	   		
	INSERT		tbltktcpn
				( StKey, TicketNumber, FC, Transit, RouteAwal, RouteAkhir, Airlines, FlightNumber, FlightDate, FareBasis, FarefromDescr, Fare, FareUpdate, LionWingsCode, 
						  DomIntlCode, FSurcharge, IWJR, Adm, Apotax, wrongFare, dateofFlight, PjkTarif, PjkPPN, IDRFare, IDRAdm, IDRFSurcharge, IDRIWJR, Komisi, StatusVCR, 
						  TglStatusVCR, IDRIWJRRate, PPN, AirlineIntlCode, PPNFsurcharge, ReferenceFCAsal, TicketAsli, FCAsli, Price, AirCost, exbRate, exbJml, 
						  exbCurr, XXadm, YRAdm, AdmKenaPPN, PPNAdm, DepTime, ArrTime, Class, PPNOD, IDRApotax, IDRApotaxRate, noPK, Total, TglLaporFinance, AmountVou, 
						  LastStatus, ReturnTax, AddTax, PPNIN, komisiAgent, PjkTarifAfterKomisi, PjkPPNAfterKomisi, QSFare, Remstar)
	SELECT		 StKey, TicketNumber, FC, Transit, RouteAwal, RouteAkhir, Airlines, FlightNumber, FlightDate, FareBasis, FarefromDescr, Fare, FareUpdate, LionWingsCode, 
						  DomIntlCode, FSurcharge, IWJR, Adm, Apotax, wrongFare, dateofFlight, PjkTarif, PjkPPN, IDRFare, IDRAdm, IDRFSurcharge, IDRIWJR, Komisi, StatusVCR, 
						  TglStatusVCR, IDRIWJRRate, PPN, AirlineIntlCode, PPNFsurcharge, ReferenceFCAsal, TicketAsli, FCAsli, Price, AirCost, exbRate, exbJml, 
						  exbCurr, XXadm, YRAdm, AdmKenaPPN, PPNAdm, DepTime, ArrTime, Class, PPNOD, IDRApotax, IDRApotaxRate, noPK, Total, TglLaporFinance, AmountVou, 
						  LastStatus, ReturnTax, AddTax, PPNIN, komisiAgent, PjkTarifAfterKomisi, PjkPPNAfterKomisi, QSFare, Remstar
	FROM		dmtktcpn


=========================================================================================================================

--INSERT TBLTKTPRICE--

SELECT		COUNT(*)
FROM		dmtktpr a INNER JOIN tblTktPrice b WITH(NOLOCK)
ON			b.StKey = a.StKey AND
			b.ticketnumber = a.ticketnumber
    		
SELECT		COUNT(*)
FROM		dmtktpr a INNER JOIN tblTktPrice b WITH(NOLOCK)
ON			b.ticketnumber = a.ticketnumber
----------------------------------------------------------------------------------------
BEGIN TRAN  		
DELETE		tbltktprice
FROM		dmtktpr a INNER JOIN tbltktprice b WITH(NOLOCK)
ON			b.ticketnumber = a.ticketnumber  
 
COMMIT TRAN

rollback

-------------------------------------------------------------------------------------------------				
INSERT		tblTktPrice
			(StKey,TicketNumber,KodeBiaya,Seq,Amount,Curr,CurrDec)
SELECT		StKey,TicketNumber,KodeBiaya,Seq,Amount,Curr,CurrDec
FROM		dmtktpr

------------------------------------------------------------------------------
SELECT COUNT(*) FROM tblStTRK WITH(NOLOCK) where insertdate > '27 Nov 2019'
SELECT COUNT(*) FROM tbltkt WITH(NOLOCK) where insertdate > '27 Nov 2019'
SELECT COUNT(*) FROM tbltktcpn WITH(NOLOCK) where insertdate > '27 Nov 2019'
SELECT COUNT(*) FROM tblTktPrice WITH(NOLOCK) where insertdate > '27 Nov 2019'
