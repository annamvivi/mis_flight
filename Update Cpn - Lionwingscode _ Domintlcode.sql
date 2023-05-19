/******************* 
		PENENTUAN LION/WINGS BERDASARKAN FLIGHT NUMBER NYA , AMBIL DARI TBLFLIGHTCODE SALAH harus dari TBLAIRLINEROUTE
*******************************/

SELECT		DISTINCT StationOpenDate 
FROM		dmsttrk
WHERE		stationopendate <> '27 Nov 2019'
ORDER BY	StationOpenDate
======================================================================================================================
DROP TABLE	#tmpAirlinesTemp
SELECT		DISTINCT Partition= a.Airlines,
			Tglberlaku = min((DATEADD(dd,-(DAY(DATEADD(mm,1,c.stationopendate))-1),DATEADD(mm,0,c.stationopendate)))),
			Code = a.Airlines, FlightNo = a.FlightNumber,Dep = a.RouteAwal, Arr = a.routeakhir
INTO		#tmpAirlinesTemp
FROM		dmtktcpn a WITH(NOLOCK) INNER JOIN dmtkt b WITH(NOLOCK)
ON			b.ticketnumber = a.ticketnumber 
			INNER JOIN dmsttrk c 
ON			c.stkey = b.stkey
WHERE 		c.stationopendate BETWEEN '24 Nov 2019' AND '26 Nov 2019' AND
			b.TransCode in ('SALE','EXCH') AND
			b.DocType in ('TKT','CNJ') AND
			FlightNumber not in ('VOID','ARNK','')
GROUP BY	a.FlightNumber,a.Airlines,a.RouteAwal, a.routeakhir

DELETE		#tmpAirlinesTemp
FROM		#tmpAirlinesTemp a, tblairlineroute b
WHERE		b.partition = a.partition AND
			b.Dep = a.dep AND
			b.Arr = a.arr AND
			b.FlightNo = a.FlightNo

SELECT		* 
FROM		#tmpAirlinesTemp 
======================================================================================================================

/* CEK 3 LETTER CODE BARU -- KALO ADA DIDAFTARIN DI SALES.DBO.TBLMASTERDISTRICT -- UNTUK COUNTRY TANYA SISIL-- */

SELECT		DISTINCT DEP 
FROM		#tmpAirlinesTemp 
WHERE		Dep not in (select kodedistrict from sales.dbo.tblMasterDistrict) 

SELECT		DISTINCT ARR 
FROM		#tmpAirlinesTemp 
WHERE		ARR not in (select kodedistrict from sales.dbo.tblMasterDistrict) 

/* INSERT INTO SALES.DBO.TBLMASTERDISTRICT VALUES ('WDB','INDONESIA') */
======================================================================================================================

/* CEK ROUTE INTERNATIONAL BARU -- KALO ADA DIDAFTARIN DI TBLINTLROUTE -- TANYA SISIL UNTUK ROUTE TERSEBUT International / BUKAN */

DROP TABLE	#tmpIntlroute1
SELECT		DISTINCT Route = Dep  
INTO		#tmpIntlroute1 
FROM		#tmpAirlinesTemp 
WHERE		Dep not in (select Route from tblIntlRoute) AND
			Dep not in (select kodedistrict from sales.dbo.tblmasterdistrict where Country = 'INDONESIA')

INSERT 		tblIntlRoute (Route)
SELECT		Route 
FROM		#tmpIntlroute1

DROP TABLE	#tmpIntlroute2
SELECT		DISTINCT Route = Arr  
INTO		#tmpIntlroute2
FROM		#tmpAirlinesTemp 
WHERE		arr not in (select Route from tblIntlRoute) AND
			arr not in (select kodedistrict from sales.dbo.tblmasterdistrict where Country = 'INDONESIA')
		
INSERT 		tblIntlRoute (Route)
SELECT		Route 
FROM		#tmpIntlroute2
======================================================================================================================

/* CEK ROUTE INTERNATIONAL OD -- KALO ADA DIDAFTARIN DI TBLINTLROUTEOD -- TANYA SISIL UNTUK ROUTE TERSEBUT International / BUKAN */

DROP TABLE	#tmpIntlroute1
SELECT		DISTINCT Route = Dep  
INTO		#tmpIntlroute1 
FROM		#tmpAirlinesTemp 
WHERE		Dep not in (select Route from tblIntlRouteOD) AND
			Dep not in (select kodedistrict from sales.dbo.tblmasterdistrict where Country = 'MALAYSIA')

INSERT 		tblIntlRouteOD (Route)
SELECT		Route 
FROM		#tmpIntlroute1

DROP TABLE	#tmpIntlroute2
SELECT		DISTINCT Route = Arr  
INTO		#tmpIntlroute2
FROM		#tmpAirlinesTemp 
WHERE		arr not in (select Route from tblIntlRouteOD) AND
			arr not in (select kodedistrict from sales.dbo.tblmasterdistrict where Country = 'MALAYSIA')
		
INSERT 		tblIntlRouteOD (Route)
SELECT		Route 
FROM		#tmpIntlroute2

======================================================================================================================

/* CEK ROUTE INTERNATIONAL SL -- KALO ADA DIDAFTARIN DI TBLINTLROUTEOD -- TANYA SISIL UNTUK ROUTE TERSEBUT International / BUKAN */

DROP TABLE	#tmpIntlroute1
SELECT		DISTINCT Route = Dep  
INTO		#tmpIntlroute1 
FROM		#tmpAirlinesTemp 
WHERE		Dep not in (select Route from tblIntlRouteSL) AND
			Dep not in (select kodedistrict from sales.dbo.tblmasterdistrict where Country = 'THAILAND')

INSERT 		tblIntlRouteSL (Route)
SELECT		Route 
FROM		#tmpIntlroute1

DROP TABLE	#tmpIntlroute2
SELECT		DISTINCT Route = Arr  
INTO		#tmpIntlroute2
FROM		#tmpAirlinesTemp 
WHERE		arr not in (select Route from tblIntlRouteSL) AND
			arr not in (select kodedistrict from sales.dbo.tblmasterdistrict where Country = 'THAILAND')
		
INSERT 		tblIntlRouteSL (Route)
SELECT		Route 
FROM		#tmpIntlroute2
======================================================================================================================

INSERT		tblairlineroute (Partition,TglBerlaku,Code,Flightno,Dep,Arr,Type)
SELECT 		Partition,TglBerlaku, Code, Flightno, Dep, Arr,'D'
FROM		#tmpAirlinesTemp

UPDATE		tblAirlineRoute 
SET			Type = 'I'
FROM		tblairlineroute a, tblintlroute b
WHERE		a.insertdate = '27 Nov 2019' AND
			((a.Dep = b.Route) OR 
			(a.Arr = b.Route )) 

======================================================================================================================

/* CEK YANG HARI INI UDA MASUK BELUM */

SELECT		distinct b.* 
FROM		#tmpAirlinesTemp a INNER JOIN tblairlineroute b
ON			b.flightno = a.flightno AND
    		b.dep = a.dep AND
    		b.arr = a.arr AND
    		InsertDate = '27 Nov 2019' 
ORDER BY	FlightNo, Code
======================================================================================================================
UPDATE		dmtktcpn
SET			lionwingscode = airlines, DomIntlCode = 'D'
FROM		dmtktcpn a INNER JOIN dmtkt b WITH(NOLOCK)
ON			b.ticketnumber = a.ticketnumber 
			INNER JOIN dmsttrk c 
ON			c.stkey = b.stkey
WHERE 		c.stationopendate BETWEEN '24 Nov 2019' AND '26 Nov 2019' AND
			a.farebasis <> 'VOID'

UPDATE		dmtktcpn
SET			DomIntlCode = 'I'
FROM		dmtktcpn a INNER JOIN dmtkt b WITH(NOLOCK)
ON			b.ticketnumber = a.ticketnumber 
			INNER JOIN dmsttrk c 
ON			c.stkey = b.stkey
WHERE 		c.stationopendate BETWEEN '24 Nov 2019' AND '26 Nov 2019' AND
			(a.RouteAwal in (select Route from tblIntlRoute) or  
			a.routeakhir in (select Route from tblIntlRoute))  AND
			a.farebasis <> 'VOID'
======================================================================================================================
UPDATE		dmtktcpn 
SET			AirlineIntlCode = 'D'
FROM		dmsttrk a WITH(NOLOCK), dmtktcpn b WITH(NOLOCK)
WHERE		b.StKey = a.StKey AND 
			a.stationopendate BETWEEN '24 Nov 2019' AND '26 Nov 2019' 

UPDATE		dmtktcpn
SET			AirlineIntlCode='I'
FROM		dmsttrk a WITH(NOLOCK), dmtktcpn b WITH(NOLOCK)
WHERE		b.StKey = a.StKey AND 
			a.stationopendate BETWEEN '24 Nov 2019' AND '26 Nov 2019' AND
			((routeawal IS NOT NULL AND routeawal IN (SELECT Route FROM tblIntlRoute) ) OR
    		(routeakhir IS NOT NULL AND routeakhir IN (SELECT Route FROM tblIntlRoute)) ) AND
    		ISNULL(AirlineIntlCode,'D')='D' AND LionWingsCode in ('','IW','ID','JT')
    		
UPDATE		dmtktcpn
SET			AirlineIntlCode='I'
FROM		dmsttrk a WITH(NOLOCK), dmtktcpn b WITH(NOLOCK)
WHERE		b.StKey = a.StKey AND 
			a.stationopendate BETWEEN '24 Nov 2019' AND '26 Nov 2019' AND
			((routeawal IS NOT NULL AND routeawal IN (SELECT Route FROM tblIntlRouteOD) ) OR
    		(routeakhir IS NOT NULL AND routeakhir IN (SELECT Route FROM tblIntlRouteOD)) ) AND
    		ISNULL(AirlineIntlCode,'D')='D' AND LionWingsCode in ('OD')
    		
UPDATE		dmtktcpn
SET			AirlineIntlCode='I'
FROM		dmsttrk a WITH(NOLOCK), dmtktcpn b WITH(NOLOCK)
WHERE		b.StKey = a.StKey AND 
			a.stationopendate BETWEEN '24 Nov 2019' AND '26 Nov 2019' AND
			((routeawal IS NOT NULL AND routeawal IN (SELECT Route FROM tblIntlRouteSL) ) OR
    		(routeakhir IS NOT NULL AND routeakhir IN (SELECT Route FROM tblIntlRouteSL)) ) AND
    		ISNULL(AirlineIntlCode,'D')='D' AND LionWingsCode in ('SL')
-------------------------------------------------------------------------------------------------
