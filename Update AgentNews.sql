 
UPDATE		tbltktcpn
SET			statuspax = 'INFANT'
FROM		tblsttrk a, tbltktcpn b
WHERE		b.stkey = a.stkey AND
			a.stationopendate BETWEEN '24 Nov 2019' AND '26 Nov 2019' AND
			farebasis LIKE '%IN'

UPDATE		tbltktcpn
SET			statuspax = 'ADULT'
FROM		tblsttrk a, tbltktcpn b
WHERE		b.stkey = a.stkey AND
			a.stationopendate BETWEEN '24 Nov 2019' AND '26 Nov 2019' AND
			statuspax IS NULL

UPDATE		tbltktcpn
SET			BaseFarePax = b.farepax, ppnpax = b.ppnpax, psc = b.psc, TotalNTA = b.totalNTA, TotalPax = b.totalpax
FROM		tbltktcpn a, sales.dbo.tblmasteragentnews b, tbltkt c, tblsttrk d
WHERE		b.dep = a.routeawal AND b.arr = a.routeakhir AND
			c.issueddate BETWEEN b.doistart and b.doiend AND
			a.dateofflight BETWEEN b.dotstart and b.dotend AND
			b.class = a.class AND
			b.airlines = a.airlines AND
			a.statuspax = b.paxstatus AND
			c.ticketnumber = a.ticketnumber AND
			d.stkey = a.stkey AND
			d.stkey = c.stkey AND
			c.transcode in ('SALE','EXCH') AND
			c.doctype in ('TKT','CNJ') AND
			d.stationopendate BETWEEN '24 Nov 2019' AND '26 Nov 2019'  

-----------------------------------------------------------------------------------------

UPDATE		tblrfndcpn
SET			statuspax = 'INFANT'
FROM		tblsttrk a, tblrfndcpn b
WHERE		b.stkey = a.stkey AND
			a.stationopendate BETWEEN '24 Nov 2019' AND '26 Nov 2019' AND
			farebasis LIKE '%IN'

UPDATE		tblrfndcpn
SET			statuspax = 'ADULT'
FROM		tblsttrk a, tblrfndcpn b
WHERE		b.stkey = a.stkey AND
			a.stationopendate BETWEEN '24 Nov 2019' AND '26 Nov 2019' AND
			statuspax IS NULL

UPDATE		tblrfndcpn
SET			BaseFarePax = b.BaseFarePax, ppnpax = b.ppnpax, psc = b.psc, TotalNTA = b.totalNTA, TotalPax = b.totalpax, QSFare = b.QSFare
FROM		tblrfndcpn a, tbltktcpn b, tblsttrk c
WHERE		b.ticketnumber = a.refundticket AND
			b.fc = a.fc AND c.stkey = a.stkey AND
			c.stationopendate BETWEEN '24 Nov 2019' AND '26 Nov 2019'  
