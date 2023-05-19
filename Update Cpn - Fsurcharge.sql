SELECT		DISTINCT StationOpenDate
FROM		dmsttrk
WHERE		stationopendate <> '27 Nov 2019'

---------------------------------- jalan bareng ----------------------------------------------------------------------------------------------------------------------------
drop table	#tmptkt
select		distinct b.ticketnumber,b.issueddate,b.intlcode,b.tktfSurcharge,b.rate,b.descr,fop,b.transcode,b.doctype,
			b.PreConjTicket,Curr=a.StationCurr,c.fc,c.fSurcharge,c.FareBasis,c.routeawal,c.routeakhir,c.domIntlCode,
			b.companycode, LionWingsCode
into		#tmptkt
from		dmsttrk a with(noLock), dmtkt b with(noLock), dmtktcpn c with (nolock)
where		a.stationopendate BETWEEN '24 Nov 2019' AND '26 Nov 2019' AND
			b.stkey=a.stkey AND
			b.transcode in ('SALE','EXCH') AND
			b.doctype in ('TKT') AND
			c.StKey = b.stkey AND
			c.TicketNumber = b.TicketNumber AND
			c.StKey = a.StKey

drop table	#tmpconj
select		b.ticketnumber,b.issueddate,b.intlcode,b.tktfSurcharge,b.rate,b.descr,fop,b.transcode,b.doctype,
			b.PreConjTicket,Curr=a.StationCurr,c.fc,c.fSurcharge,c.FareBasis,c.routeawal,c.routeakhir,c.DomIntlCode,
			b.companycode, LionWingsCode
into		#tmpconj
from		dmsttrk a with(noLock), dmtkt b with(noLock), dmtktcpn c with (nolock)
where		a.stationopendate BETWEEN '24 Nov 2019' AND '26 Nov 2019' AND
			b.stkey=a.stkey AND
			b.transcode in ('SALE','EXCH') AND
			b.doctype in ('CNJ') AND
			c.StKey = b.stkey AND
			c.TicketNumber = b.TicketNumber AND
			c.StKey = a.StKey
		
update		#tmpconj 
set			tktfsurcharge = b.tktfsurcharge
from		#tmpconj a, dmtkt b WITH(NOLOCK)
where		b.ticketnumber=a.PreConjTicket
select		* 
from		#tmpconj

drop table	#Tmpmax
select		ticketnumber,fc=max(fc)
into		#tmpmax
from		#Tmptkt
group by	ticketnumber

drop table	#tmpAllTktCpn
select		ticketnumber,issueddate,intlcode,Curr,fop,transcode,doctype,ticketasal=ticketnumber,fc,FCAsal=fc,tktfSurcharge,rate,
			fSurcharge,descr,FareBasis,RouteAwal,RouteAkhir,DomIntlCode,companycode, LionWingsCode
into		#tmpAllTktCpn
from		#Tmptkt
union all
select		ticketnumber=PreConjTicket,issueddate,intlcode,Curr,fop,transcode,doctype,ticketasal=a.ticketnumber,fc=a.fc + b.fc,
			fcAsal=a.FC,tktfSurcharge,rate,fSurcharge,descr,FareBasis,RouteAwal,RouteAkhir,DomIntlCode,companycode, LionWingsCode
from		#tmpconj a left join #tmpmax b
on			b.ticketnumber = a.PreConjTicket

alter table #tmpalltktcpn add f2surcharge money default 0
alter table #tmpalltktcpn add fsbedarate money default 0

update		#tmpalltktcpn 
set			f2surcharge = null, fsbedarate = null
------------------------------------- jalan bareng ----------------------------------------------------------------------------------------------------------------------------------------

DROP TABLE	#TMPFS
select		a.* 
into		#tmpfs
from		tblfsurcharge a, (
				select route,curr,route1,route2,tglberlaku=max(tglberlaku) from tblfsurcharge
				group by route,curr,route1,route2 ) b
where		b.route=a.route AND
			b.curr=a.curr AND
			b.route1 = a.route1 AND
			b.route2 = a.route2 AND
			b.tglberlaku=a.tglberlaku
order by	a.route,a.curr,a.fsurcharge,a.route1,a.route2 

update		#tmpalltktcpn 
set			f2surcharge=b.fsurcharge
from		#tmpalltktcpn a, #tmpfs b
where		b.route1=a.routeawal AND b.route2= a.routeakhir AND a.f2surcharge IS NULL AND
			b.curr = left(a.curr,3) AND a.farebasis <> 'void'

update		#tmpalltktcpn 
set			f2surcharge=b.fsurcharge
from		#tmpalltktcpn a, #tmpfs b
where		b.route2=a.routeawal AND b.route1= a.routeakhir AND a.f2surcharge IS NULL AND
			b.curr = left(a.curr,3) AND a.farebasis <> 'void'

update		#tmpalltktcpn 
set			fsbedarate=b.fsurcharge
from		#tmpalltktcpn a, #tmpfs b
where		b.route1=a.routeawal AND b.route2= a.routeakhir AND a.f2surcharge IS NULL AND a.fsbedarate IS NULL
			AND a.farebasis <> 'void'

update		#tmpalltktcpn 
set			fsbedarate=b.fsurcharge
from		#tmpalltktcpn a, #tmpfs b
where		b.route2=a.routeawal AND b.route1= a.routeakhir AND a.f2surcharge IS NULL AND a.fsbedarate IS NULL
			AND a.farebasis <> 'void'

update		#tmpalltktcpn 
set			f2surcharge = null,fsbedarate= null 
where		isnull(tktfsurcharge,0)=0 

update		#tmpalltktcpn 
set			f2surcharge = round(fsbedarate / 6426.7352,1) 
where		isnull(fsbedarate,0) <> 0 AND
			left(curr,3)= 'sgd' AND domintlcode ='D'

update		#tmpalltktcpn 
set			f2surcharge = round(fsbedarate / 2428.57,1) 
where		isnull(fsbedarate,0) <> 0 AND
			left(curr,3)= 'sar' AND domintlcode ='D'

update		#tmpalltktcpn 
set			f2surcharge = round(fsbedarate / 2692.30,1) 
where		isnull(fsbedarate,0) <> 0 AND
			left(curr,3)= 'myr' AND domintlcode ='D'

update		#tmpalltktcpn 
set			f2surcharge = round(fsbedarate / 9051.72,1) 
where		isnull(fsbedarate,0) <> 0 AND
			left(curr,3)= 'usd' AND domintlcode ='D'

update		#tmpalltktcpn 
set			f2surcharge = round(fsbedarate * 2.7,1) 
where		isnull(fsbedarate,0) <> 0 AND
			left(curr,3)= 'sar' AND domintlcode ='I'

update		#tmpalltktcpn 
set			f2surcharge = round(fsbedarate * 1.3957,1) 
where		isnull(fsbedarate,0) <> 0 AND
			left(curr,3)= 'sgd' AND domintlcode ='I'

update		#tmpalltktcpn 
set			f2surcharge = round(fsbedarate * 0.475,1) 
where		isnull(fsbedarate,0) <> 0 AND
			left(curr,3)= 'VND' AND domintlcode ='I'
----------------------------------------------------------------------------------------------------------------------------------------------------------------
===========================================================================================================================================================================

drop table	#tmploopfSurcharge
select		distinct a.ticketnumber,a.tktfSurcharge
into		#tmploopfSurcharge
from		#tmpAllTktCpn a
where		a.FareBasis <> 'void' AND a.tktfSurcharge <> 0
order by	a.ticketnumber

drop table	#tmpmaxfc
select		a.ticketnumber,fc=max(fc) 
into		#tmpmaxFC
from		#tmpAllTktCpn a, #tmploopfSurcharge b
where		b.ticketnumber=a.ticketnumber AND a.FareBasis <> 'void' 
group by	a.ticketnumber

alter table #tmpAllTktCpn add fSurcharge2update money default 0
alter table #tmpAllTktCpn add sudahisifSurcharge2update money default 0

----------------------------------------------------------------------------------------------------------------------------------------------------------------------

update		#tmpalltktcpn 
set			fsurcharge2update=null,sudahisifsurcharge2update=null

drop table	#tmpminfc
select		a.ticketnumber,fc=min(fc) 
into		#tmpminFC
from		#tmpAllTktCpn a, #tmploopfSurcharge b
where		b.ticketnumber=a.ticketnumber AND a.FareBasis <> 'void'  AND a.fSurcharge2update = 0 AND 1=2
group by	a.ticketnumber

while 1=1
begin
	truncate table #tmpminFC
	insert		#tmpminFC
	select		a.ticketnumber,fc=min(fc) 
	from		#tmpAllTktCpn a, #tmploopfSurcharge b
	where		b.ticketnumber=a.ticketnumber AND a.FareBasis <> 'void'  AND isnull(a.fSurcharge2update,0) = 0 AND b.tktfSurcharge > 0 AND
				isnull(a.sudahisifSurcharge2update,0) = 0
	group by	a.ticketnumber

	if @@rowcount = 0 
		break

	update		#tmpAllTktCpn 
	set			fSurcharge2update=CASE WHEN (d.fc = b.fc) then c.tktfSurcharge else 
				( CASE WHEN (c.tktfSurcharge > a.f2Surcharge) then a.f2Surcharge else c.tktfSurcharge end ) end,
				sudahisifSurcharge2update=1
	from		#tmpAllTktCpn a, #tmpminFc b, #tmploopfSurcharge c, #tmpmaxfc d
	where		b.ticketnumber=a.ticketnumber AND
				b.fc=a.fc AND
				c.ticketnumber=b.ticketnumber AND
				d.ticketnumber=a.ticketnumber 

	update		#tmploopfSurcharge 
	set			tktfSurcharge = a.tktfSurcharge - c.fSurcharge2update
	from		#TmploopfSurcharge a, #tmpminFC b, #tmpAllTktCpn c
	where		b.ticketnumber=a.ticketnumber AND
				c.ticketnumber=b.ticketnumber AND
				c.fc = b.fc

	delete		#tmploopfSurcharge 
	where		tktfSurcharge = 0
end

select		* 
from		#tmploopfSurcharge

-----------------------------------------------------------------------------------------------------------------------------------------------------------
/* Pindahin FSurcharge I - D ke I - I */

	drop table	#tmpTktCpnInt
	select		distinct TicketNumber, Jumlah = count(*)
	into		#tmpTktCpnInt
	from		#tmpalltktcpn
	where 		TktFSurcharge <> 0 AND
				FareBasis <> 'void' AND
				IntlCode = 'I' AND
				DomIntlCode = 'I'
	group by	TicketNumber

	drop table	#TmpAllInt
	select		distinct TicketNumber, Jumlah = count(*)
	into		#TmpAllInt
	from		#tmpalltktcpn
	where 		TktFSurcharge <> 0 AND
				FareBasis <> 'void' 
	group by	TicketNumber

	delete		#tmpTktCpnInt
	from		#tmpTktCpnInt a, #tmpAllInt b
	where		b.TicketNumber = a.TicketNumber AND
				b.Jumlah = a.Jumlah

	update		#tmpAllTktCpn
	set			FSurcharge2Update = Null
	where 		TktFSurcharge <> 0 AND
				FareBasis <> 'void' AND
				IntlCode = 'I' AND
				DomIntlCode = 'D'

	alter table #TmpTktCpnInt add FSurcharge2Update money default 0
	alter table #tmpAllTktCpn add StatusUpdate int default 0

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------

update		#tmpTktCpnInt
set			FSurcharge2Update = a.TktFSurcharge / b.Jumlah
from		#tmpAllTktCpn a, #tmpTktCpnInt b
where		b.TicketNumber = a.TicketNumber AND
			a.IntlCode = 'I' AND
			a.DomIntlCode = 'I'

select		distinct a.FSurcharge2Update, b.*
from		#tmpTktCpnInt a, #tmpAllTktCpn b
where		b.TicketNumber = a.TicketNumber AND
			b.IntlCode = 'I' AND
			b.DomIntlCode = 'I' AND
			a.FSurcharge2Update IS NOT NULL
order by	b.TicketNumber, b.FC

update		#tmpAllTktCpn
set			fSurcharge2update = b.FSurcharge2Update, StatusUpdate = 1
from		#tmpAllTktCpn a, #tmpTktCpnInt b
where		b.TicketNumber = a.TicketNumber AND
			a.IntlCode = 'I' AND
			a.DomIntlCode = 'I'


--------------------------------------------
DROP TABLE	#tmpkurs
SELECT		* 
INTO		#tmpkurs 
FROM		sales.dbo.tblkurs 

UPDATE		#tmpkurs
SET			CurrencyCode = 'MYR'
WHERE		CurrencyCode = 'RM'

UPDATE		#tmpAllTktCpn 
SET			fsurcharge2update = ROUND((a.fsurcharge2update / b.Rate),2)
FROM		#tmpAllTktCpn a, #tmpkurs b
WHERE		b.tglKurs = a.IssuedDate AND
			b.CurrencyCode = a.Curr
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

----LOOPING------------

drop table	#TmpTktFSurcharge
select		TicketNumber, TktFSurcharge
into		#TmpTktFSurcharge
from		#tmpAllTktCpn 
where		FCAsal = 1
order by	TicketNumber

drop table	#TmpFSurcharge2update
select		TicketNumber, FSurcharge = sum(isnull(FSurcharge2update,0))
into		#TmpFSurcharge2update
from		#tmpAllTktCpn 
group by	TicketNumber
order by	TicketNumber

select		a.*, b.FSurcharge
from		#TmpTktFSurcharge a, #TmpFSurcharge2update b             --HARUS KOSONG--
where		b.TicketNumber = a.TicketNumber AND
			b.FSurcharge <> a.TktFSurcharge
order by	a.TktFSurcharge

drop table  #tmp10
select		distinct a.*, b.FSurcharge
into		#tmp10
from		#TmpTktFSurcharge a, #TmpFSurcharge2update b
where		b.TicketNumber = a.TicketNumber AND
			b.FSurcharge <> a.TktFSurcharge
order by	a.TicketNumber

select * from #tmp10 

----- #TMP10 HARUS KOSONG, KALO ADA ISI JALANIN BAWAH 1, LOOPING, 2 LOOPING DST
==========================================================================
/*
1.

drop table #tmpbeda2
select a.ticketnumber, a.curr, a.tktfsurcharge, a.fc, a.farebasis, a.routeawal, a.routeakhir, a.FSurcharge2update
into #tmpbeda2 from #tmpAllTktCpn a INNER JOIN #tmp10 b
on b.ticketnumber = a.ticketnumber

select ticketnumber, tktfsurcharge, jumlah = sum(isnull(FSurcharge2update,0))  from #tmpbeda2 where fc in (1,2)
group by ticketnumber, tktfsurcharge

drop table #tmpzzz
select ticketnumber, tktfsurcharge, jumlah = sum(isnull(FSurcharge2update,0)) into #tmpzzz from #tmpbeda2 where fc in (1)
group by ticketnumber, tktfsurcharge

update #tmpalltktcpn
set FSurcharge2update = '0'
from #tmpalltktcpn a INNER JOIN #tmpbeda2 b
on b.ticketnumber = a.ticketnumber 
INNER JOIN #tmpzzz c
ON c.ticketnumber = a.ticketnumber AND
a.fc in (2,3,4,5,6,7,8) AND c.jumlah = c.tktfsurcharge

--
drop table #tmpbeda3
select a.ticketnumber, a.curr, a.tktfsurcharge, a.fc, a.farebasis, a.routeawal, a.routeakhir, a.FSurcharge2update
into #tmpbeda3 from #tmpAllTktCpn a INNER JOIN #tmp10 b
on b.ticketnumber = a.ticketnumber

select ticketnumber, tktfsurcharge, jumlah = sum(isnull(FSurcharge2update,0))  from #tmpbeda3 where fc in (1,2)
group by ticketnumber, tktfsurcharge

drop table #tmpzzz1
select ticketnumber, tktfsurcharge, jumlah = sum(isnull(FSurcharge2update,0)) into #tmpzzz1 from #tmpbeda3 where fc in (2)
group by ticketnumber, tktfsurcharge

update #tmpalltktcpn
set FSurcharge2update = '0'
from #tmpalltktcpn a INNER JOIN #tmpbeda3 b
on b.ticketnumber = a.ticketnumber 
INNER JOIN #tmpzzz1 c
ON c.ticketnumber = a.ticketnumber AND
a.fc in (1,3,4,5,6,7,8) AND c.jumlah = c.tktfsurcharge
--
drop table #tmpbeda4
select a.ticketnumber, a.curr, a.tktfsurcharge, a.fc, a.farebasis, a.routeawal, a.routeakhir, a.FSurcharge2update
into #tmpbeda4 from #tmpAllTktCpn a INNER JOIN #tmp10 b
on b.ticketnumber = a.ticketnumber

drop table #tmpzzz2
select ticketnumber, tktfsurcharge, jumlah = sum(isnull(FSurcharge2update,0)) into #tmpzzz2 from #tmpbeda4 where fc in (1,2)
group by ticketnumber, tktfsurcharge

update #tmpalltktcpn
set FSurcharge2update = '0'
from #tmpalltktcpn a INNER JOIN #tmpbeda4 b
on b.ticketnumber = a.ticketnumber 
INNER JOIN #tmpzzz2 c
ON c.ticketnumber = a.ticketnumber AND
a.fc in (3,4,5,6,7,8) AND c.jumlah = c.tktfsurcharge
--
drop table #tmpbeda5
select a.ticketnumber, a.curr, a.tktfsurcharge, a.fc, a.farebasis, a.routeawal, a.routeakhir, a.FSurcharge2update
into #tmpbeda5 from #tmpAllTktCpn a INNER JOIN #tmp10 b
on b.ticketnumber = a.ticketnumber

drop table #tmpzzz3
select ticketnumber, tktfsurcharge, jumlah = sum(isnull(FSurcharge2update,0)) into #tmpzzz3 from #tmpbeda5 where fc in (3)
group by ticketnumber, tktfsurcharge

update #tmpalltktcpn
set FSurcharge2update = '0'
from #tmpalltktcpn a INNER JOIN #tmpbeda5 b
on b.ticketnumber = a.ticketnumber 
INNER JOIN #tmpzzz3 c
ON c.ticketnumber = a.ticketnumber AND
a.fc in (1,2,4,5,6,7,8) AND c.jumlah = c.tktfsurcharge

--
drop table #tmpbeda6
select a.ticketnumber, a.curr, a.tktfsurcharge, a.fc, a.farebasis, a.routeawal, a.routeakhir, a.FSurcharge2update
into #tmpbeda6 from #tmpAllTktCpn a INNER JOIN #tmp10 b
on b.ticketnumber = a.ticketnumber

drop table #tmpzzz4
select ticketnumber, tktfsurcharge, jumlah = sum(isnull(FSurcharge2update,0)) into #tmpzzz4 from #tmpbeda6 where fc in (2,5)
group by ticketnumber, tktfsurcharge

update #tmpalltktcpn
set FSurcharge2update = '0'
from #tmpalltktcpn a INNER JOIN #tmpbeda6 b
on b.ticketnumber = a.ticketnumber 
INNER JOIN #tmpzzz4 c
ON c.ticketnumber = a.ticketnumber AND
a.fc in (1,3,4,6) AND c.jumlah = c.tktfsurcharge
--
drop table #tmpbeda7
select a.ticketnumber, a.curr, a.tktfsurcharge, a.fc, a.farebasis, a.routeawal, a.routeakhir, a.FSurcharge2update
into #tmpbeda7 from #tmpAllTktCpn a INNER JOIN #tmp10 b
on b.ticketnumber = a.ticketnumber

drop table #tmpzzz5
select ticketnumber, tktfsurcharge, jumlah = sum(isnull(FSurcharge2update,0)) into #tmpzzz5 from #tmpbeda7 where fc in (1,4)
group by ticketnumber, tktfsurcharge

update #tmpalltktcpn
set FSurcharge2update = '0'
from #tmpalltktcpn a INNER JOIN #tmpbeda7 b
on b.ticketnumber = a.ticketnumber 
INNER JOIN #tmpzzz5 c
ON c.ticketnumber = a.ticketnumber AND
a.fc in (2,3,5,6,7,8) AND c.jumlah = c.tktfsurcharge

--
drop table #tmpbeda8
select a.ticketnumber, a.curr, a.tktfsurcharge, a.fc, a.farebasis, a.routeawal, a.routeakhir, a.FSurcharge2update
into #tmpbeda8 from #tmpAllTktCpn a INNER JOIN #tmp10 b
on b.ticketnumber = a.ticketnumber

drop table #tmpzzz6
select ticketnumber, tktfsurcharge, jumlah = sum(isnull(FSurcharge2update,0)) into #tmpzzz6 from #tmpbeda7 where fc in (2,3)
group by ticketnumber, tktfsurcharge

update #tmpalltktcpn
set FSurcharge2update = '0'
from #tmpalltktcpn a INNER JOIN #tmpbeda8 b
on b.ticketnumber = a.ticketnumber 
INNER JOIN #tmpzzz6 c
ON c.ticketnumber = a.ticketnumber AND
a.fc in (1,4,5,6,7,8) AND c.jumlah = c.tktfsurcharge

--
drop table #tmpbeda9
select a.ticketnumber, a.curr, a.tktfsurcharge, a.fc, a.farebasis, a.routeawal, a.routeakhir, a.FSurcharge2update
into #tmpbeda9 from #tmpAllTktCpn a INNER JOIN #tmp10 b
on b.ticketnumber = a.ticketnumber

drop table #tmpzzz7
select ticketnumber, tktfsurcharge, jumlah = sum(isnull(FSurcharge2update,0)) into #tmpzzz7 from #tmpbeda9 where fc in (2,7)
group by ticketnumber, tktfsurcharge

update #tmpalltktcpn
set FSurcharge2update = '0'
from #tmpalltktcpn a INNER JOIN #tmpbeda8 b
on b.ticketnumber = a.ticketnumber 
INNER JOIN #tmpzzz7 c
ON c.ticketnumber = a.ticketnumber AND
a.fc in (1,3,4,5,6,8) AND c.jumlah = c.tktfsurcharge


==========================================================================
2.

alter table #tmp10 add selisih money

update #tmp10
set selisih = tktfsurcharge - fsurcharge

drop table #tmpminFC
select b.ticketnumber,selisih, minFC = min(b.fc) 
into #tmpminfc
from #tmp10 a, #tmpalltktcpn b
where b.ticketnumber = a.ticketnumber AND
isnull(b.fsurcharge2update,0) > 0
group by b.ticketnumber,selisih

update #tmpalltktcpn
set fsurcharge2update = fsurcharge2update + a.selisih
from #tmpminfc a, #tmpalltktcpn b
where b.ticketnumber = a.ticketnumber AND
b.fc = a.minfc

==========================================================================
3.

alter table #tmp10 add selisih money

update #tmp10
set selisih = tktfsurcharge - fsurcharge

drop table #tmpminFC
select b.ticketnumber,selisih, minFC = min(b.fc) 
into #tmpminfc
from #tmp10 a, #tmpalltktcpn b
where b.ticketnumber = a.ticketnumber 
group by b.ticketnumber,selisih

update #tmpalltktcpn
set fsurcharge2update = fsurcharge2update + a.selisih
from #tmpminfc a, #tmpalltktcpn b
where b.ticketnumber = a.ticketnumber AND
b.fc = a.minfc


*/
drop table #tmpZ
select * into #tmpZ from #tmpAllTktCpn where FSurcharge2update < 0
order by TktFSurcharge 

select * from #tmpZ -- KALO EXCH GPP 

/*
update #tmpAllTktCpn
set FSurcharge2update = '19.80'
from #tmpAllTktCpn a, #tmpZ b
where b.TicketNumber = a.TicketNumber AND a.TktFSurcharge = '19.80' AND a.FC = 1

update #tmpAllTktCpn
set FSurcharge2update = '0'
from #tmpAllTktCpn a, #tmpZ b
where b.TicketNumber = a.TicketNumber AND a.TktFSurcharge = '19.80' AND a.FC = 2

update #tmpalltktcpn
set FSurcharge2update = 0.20
where ticketnumber = 9902134416030 AND fc = 1

update #tmpalltktcpn
set FSurcharge2update = 0
where ticketnumber = 9902134416030 AND fc = 2

select * from #tmpalltktcpn where fsurcharge < -10000 AND curr <> 'IDR'

select * from #tmpalltktcpn where ticketnumber = 9902134416030


*/
--------------------------------------------

begin tran
update		#tmpAllTktCpn 
set			fSurcharge2update = 0
where		fSurcharge2update IS NULL

commit tran
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
begin tran
update		dmtktcpn
set			fSurcharge=b.fSurcharge2update
from		dmtktcpn a 
			INNER JOIN #tmpAllTktCpn b
ON			b.ticketasal=a.ticketnumber AND
			b.fcasal=a.fc
			INNER JOIN dmtkt c with(nolock)
ON			c.StKey = a.StKey AND 
			c.TicketNumber = a.TicketNumber AND
			c.TicketNumber = b.ticketasal 

commit tran


/*
-- KALO UDA UPDATE LANGSUNG CEK FSURCHARGENYA LAGI, ADA YANG 0 / NULL SEMUA ATAU TIDAK.
 select distinct fSurcharge from dmtktcpn where InsertDate > '14 Apr 2015'

where InsertDate > '14 Apr 2015'
AND FSurcharge =0

*/

select		COUNT(*) 
from		#tmptkt 

select		COUNT(*) 
from		#tmpconj 




