/**************************************************************************
 Program:  Match_TOPA_db_to_RCASD.sas
 Library:  Prescat
 Project:  Urban-Greater DC
 Author:   P. Tatian
 Created:  03/25/23
 Version:  SAS 9.4
 Environment:  Local Windows session (desktop)
 GitHub issue: 350
 
 Description:  Match TOPA_database with Urban-Greater DC RCASD data
 for checking. 

 Modifications:
**************************************************************************/

%include "\\sas1\DCdata\SAS\Inc\StdLocal.sas";

** Define libraries **;
%DCData_lib( Prescat )
%DCData_lib( DHCD )

%let year = 2020;

proc sql noprint;
  create table Match_TOPA_db_to_RCASD as
  select 
    coalesce( topa.address_id, rcasd.address_id ) as address_id,
    topa.u_offer_sale_date, topa.id, 
    rcasd.notice_date, rcasd.notice_type, rcasd.nidc_rcasd_id,
	case
	  when missing( topa.id ) then 0
	  else 1
	end as in_topa_db,
	case
	  when missing( rcasd.nidc_rcasd_id ) then 0
	  else 1
	end as in_rcasd
  from Dhcd.Rcasd_&year as rcasd
  full outer join 
  (
    select 
      coalesce( topa.id, addr.id ) as id,
      topa.u_offer_sale_date,
      addr.address_id, addr.notice_listed_address
    from 
      Prescat.Topa_database as topa
      left join
      Prescat.Topa_addresses as addr
      on topa.id = addr.id
      where year( u_offer_sale_date ) = &year and notice_listed_address = 1
  ) as topa
  on topa.address_id = rcasd.address_id and abs( u_offer_sale_date - notice_date ) <= 3
  where notice_type in ( '210', '228', '229' )
  order by nidc_rcasd_id, u_offer_sale_date, notice_date;
quit;


proc summary data=Match_TOPA_db_to_RCASD nway;
  where in_rcasd;
  class nidc_rcasd_id;
  id notice_type;
  var in_topa_db;
  output out=not_in_topa_db (drop=_type_ _freq_ where=(in_topa_db=0)) max=;
run;

title2 "Notices in RCASD but not in TOPA_database (&year)";
proc print data=not_in_topa_db;
  id nidc_rcasd_id;
run;

proc summary data=Match_TOPA_db_to_RCASD nway;
  where in_topa_db;
  class id;
  var in_rcasd;
  output out=not_in_rcasd (drop=_type_ _freq_ where=(in_rcasd=0)) max=;
run;

title2 "Notices in TOPA_database but not in RCASD (&year)";
proc print data=not_in_rcasd;
  id id;
run;

title2;
