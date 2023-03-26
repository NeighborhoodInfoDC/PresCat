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

** Combine RCASD data sets **;

data Rcasd_all;

  set
    Dhcd.Rcasd_2015
    Dhcd.Rcasd_2016
    Dhcd.Rcasd_2017
    Dhcd.Rcasd_2018
    Dhcd.Rcasd_2019
    Dhcd.Rcasd_2020
  ;
  
  where not( missing( address_id ) or missing( notice_date ) );
    
run;

** Match with TOPA database **;

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
  from Rcasd_all as rcasd
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
      where notice_listed_address = 1 and 
        not( missing( u_offer_sale_date ) or missing( address_id ) )
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

title2 "Notices in RCASD but not in TOPA_database";
proc print data=not_in_topa_db n;
  id nidc_rcasd_id;
run;

proc summary data=Match_TOPA_db_to_RCASD nway;
  where in_topa_db;
  class id;
  var in_rcasd;
  output out=not_in_rcasd (drop=_type_ _freq_ where=(in_rcasd=0)) max=;
run;

title2 "Notices in TOPA_database but not in RCASD";
proc print data=not_in_rcasd n;
  id id;
run;

title2;


** Create CSV data to add to TOPA_database input file **;

data add_notices;

  merge
    not_in_topa_db (in=in1)
    Rcasd_all (where=(addr_num=1));
  by nidc_rcasd_id;
  
  if in1;
  
run;

proc print data=add_notices;
  id nidc_rcasd_id;
  var source_file notice_date;
run;

data add_notices_export;

  length 
    ID 8
    Verified_By $ 40
    CASD_Report_week_ending_date 8
    Offer_of_Sale_date 8
    All_street_addresses $ 1000
    SSL $ 40
    Cluster $ 40
    Ward $ 40
    ANC $ 40
    ANC_SMD $ 40
    Census_Tract $ 40
    Zone $ 40
    Zip_Code $ 40
    Property_name $ 40
    Address_for_mapping $ 120
    Notes $ 1000
    Subsidy $ 40
    Sale_related_to_notice $ 40
    Offer_Price $ 40
    Offer_price_per_unit $ 40
  ;

  set add_notices;
  
    ID = _n_ + 10000;
    Verified_By = "Urban";
    
    if source_file = "week of october 21 - 25 2019.csv" then CASD_Report_week_ending_date = '25oct2019'd;
    else if source_file = "weekly report march 9 - 13.csv" then CASD_Report_week_ending_date = '13mar2020'd;
    else CASD_Report_week_ending_date = input( scan( source_file, 1, '.' ), anydtdte40. );
    
    Offer_of_Sale_date = notice_date;
    All_street_addresses = orig_address;
    Cluster = cluster2017;
    ANC = anc2012;
    Zip_Code = put( m_zip, z5. );
    Address_for_mapping = address;
    
    if sale_price > 0 then Offer_Price = left( put( sale_price, dollar24.2 ) );

  format CASD_Report_week_ending_date Offer_of_Sale_date mmddyy10.;

  keep 
    ID Verified_By CASD_Report_week_ending_date
    Offer_of_Sale_date All_street_addresses SSL Cluster Ward ANC
    ANC_SMD Census_Tract Zone Zip_Code Property_name
    Address_for_mapping Notes Subsidy Sale_related_to_notice
    Offer_Price Offer_price_per_unit;
    
 run;
 

filename fexport "&_dcdata_default_path\PresCat\Raw\TOPA\Add_2015_2020_notices_export.csv" lrecl=5000;

proc export data=Add_notices_export
    outfile=fexport
    dbms=csv replace;

run;

filename fexport clear;

