DROP TABLE	#tmpRFND
SELECT		b.* 
INTO		#tmpRFND 
FROM		tblsttrk a WITH(NOLOCK), tbltkt b WITH(NOLOCK)
WHERE		b.stkey = a.stkey AND
			a.stationopendate BETWEEN '24 Nov 2019' AND '26 Nov 2019'AND
			((b.TransCode LIKE 'rf%') OR (b.TransCode = 'SALE' AND b.DocType = 'VOU')) 
--------------------------------------------------------------------------------

UPDATE		#tmpRFND
SET			stkeySALE = b.stkey
FROM		#tmpRFND a, sales.dbo.tbltkt b WITH(NOLOCK)
WHERE		b.TicketNumber = a.RefundTicket AND
			a.stkeySALE IS NULL

UPDATE		#tmpRFND
SET			stkeySALE = b.stkey
FROM		#tmpRFND a, sales.dbo.tbltkt b WITH(NOLOCK), sales.dbo.tbltkt c WITH(NOLOCK)
WHERE		b.TicketNumber = a.RefundTicket AND
			a.stkeySALE IS NULL AND 
			c.TicketNumber = b.RefundTicket

UPDATE		#tmpRFND
SET			PNRR = b.pnrr
FROM		#tmpRFND a, sales.dbo.tbltkt b WITH(NOLOCK)
WHERE		b.TicketNumber = a.RefundTicket AND
			a.PNRR = '' 

UPDATE		#tmpRFND
SET			PNRR = c.pnrr
FROM		#tmpRFND a, sales.dbo.tbltkt b WITH(NOLOCK), sales.dbo.tbltkt c WITH(NOLOCK)
WHERE		b.TicketNumber = a.RefundTicket AND
			a.PNRR = '' AND 
			c.TicketNumber = b.RefundTicket

UPDATE		#tmpRFND
SET			stkeySALE = b.stkey
FROM		#tmpRFND a, salesiw.dbo.tbltkt b WITH(NOLOCK)
WHERE		b.TicketNumber = a.RefundTicket AND
			a.stkeySALE IS NULL

UPDATE		#tmpRFND
SET			stkeySALE = b.stkey
FROM		#tmpRFND a, salesiw.dbo.tbltkt b WITH(NOLOCK), salesiw.dbo.tbltkt c WITH(NOLOCK)
WHERE		b.TicketNumber = a.RefundTicket AND
			a.stkeySALE IS NULL AND 
			c.TicketNumber = b.RefundTicket

UPDATE		#tmpRFND
SET			PNRR = b.pnrr
FROM		#tmpRFND a, salesiw.dbo.tbltkt b WITH(NOLOCK)
WHERE		b.TicketNumber = a.RefundTicket AND
			a.PNRR = '' 

UPDATE		#tmpRFND
SET			PNRR = c.pnrr
FROM		#tmpRFND a, salesiw.dbo.tbltkt b WITH(NOLOCK), salesiw.dbo.tbltkt c WITH(NOLOCK)
WHERE		b.TicketNumber = a.RefundTicket AND
			a.PNRR = '' AND 
			c.TicketNumber = b.RefundTicket


----------------------------------------------------------------------------------------
SELECT		* 
FROM		#tmpRFND
WHERE		PNRR = ''

SELECT		* 
FROM		#tmpRFND
WHERE		stkeySALE IS NULL

----------------------------------------------------------------------------------------
UPDATE		tbltkt
SET			PNRR = b.PNRR, stkeySALE = b.stkeySALE 
FROM		tbltkt a, #tmpRFND b
WHERE		b.TicketNumber = a.TicketNumber AND
			a.stkey = a.stkey 

