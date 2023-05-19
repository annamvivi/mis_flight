SELECT		DISTINCT intlcode 
FROM		dmtkt 

UPDATE		dmtkt
SET			companycode = 'INA'

UPDATE		dmtkt 
SET			intlcode = 'D' 

UPDATE		dmtkt
SET			intlcode = 'I'
FROM		dmtkt a INNER JOIN dmtktcpn b WITH(NOLOCK)
ON			b.ticketnumber = a.ticketnumber
WHERE		((b.routeawal IS NOT NULL AND b.routeawal IN (SELECT Route FROM tblIntlRoute WITH(NOLOCK)) ) OR
    		(b.routeakhir IS NOT NULL AND b.routeakhir IN (SELECT Route FROM tblIntlRoute WITH(NOLOCK))) ) AND
    		ISNULL(intlcode,'D')='D' AND 
    		a.companycode in ('INA') 
    	