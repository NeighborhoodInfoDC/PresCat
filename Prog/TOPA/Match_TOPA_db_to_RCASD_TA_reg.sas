/**************************************************************************
 Program:  TOPA_TA_registration.sas
 Library:  Prescat
 Project:  Urban-Greater DC
 Author:   P. Tatian
 Created:  03/25/23
 Version:  SAS 9.4
 Environment:  Local Windows session (desktop)
 GitHub issue: 352
 
 Description:  Match TOPA_database with Urban-Greater DC RCASD data
 for filling in tenant association (TA) registration info.
 Use RCASD data for 2015-2020, TOPA_database entered data for 2006-2014.
 
 This code was used to test the matching and produce the 
 Match_TOPA_db_to_RCASD_TA_reg_not_found.xls workbook to share with 
 CNHED. Final code adding u_date_dhcd_received_ta_reg to TOPA_database
 is in Prog\TOPA\TOPA_data_to_DC_data.sas.

 Modifications:
**************************************************************************/

%include "\\sas1\DCdata\SAS\Inc\StdLocal.sas";

** Define libraries **;
%DCData_lib( Prescat )
%DCData_lib( DHCD )

** Combine RCASD data sets **;

data Rcasd_all_TA_reg;

  set
    Dhcd.Rcasd_2015
    Dhcd.Rcasd_2016
    Dhcd.Rcasd_2017
    Dhcd.Rcasd_2018
    Dhcd.Rcasd_2019
    Dhcd.Rcasd_2020
  ;
  
  where not( missing( address_id ) or missing( notice_date ) ) and
    notice_type in ( '207' );
    
run;

proc sql noprint;
  create table Match_TOPA_db_to_RCASD_TA as
  select 
    coalesce( topa.address_id, rcasd.address_id ) as address_id,
    topa.u_offer_sale_date, topa.id, topa.date_dhcd_received_ta_reg,
    topa.all_street_addresses, topa.u_casd_date,
    rcasd.notice_date, rcasd.notice_type, rcasd.nidc_rcasd_id,
    rcasd.orig_address
  from Rcasd_all_TA_reg as rcasd
  left join 
  (
    select 
      coalesce( topa.id, addr.id ) as id,
      topa.u_offer_sale_date, topa.date_dhcd_received_ta_reg,
      topa.all_street_addresses, topa.u_casd_date,
      addr.address_id, addr.notice_listed_address
    from 
      Prescat.Topa_database as topa
      left join
      Prescat.Topa_addresses as addr
      on topa.id = addr.id
      where notice_listed_address = 1 and 
        not( missing( u_offer_sale_date ) or missing( address_id ) )
  ) as topa
  on topa.address_id = rcasd.address_id and 0 <= notice_date - u_offer_sale_date <= 365
  order by id, notice_date;
quit;

data Match_TOPA_db_to_RCASD_TA_unq;

  merge 
    Prescat.Topa_database (keep=id u_offer_sale_date date_dhcd_received_ta_reg u_casd_date all_street_addresses)
    Match_TOPA_db_to_RCASD_TA (where=(not( missing( id ) or missing( nidc_rcasd_id ))));
  by id;
  
  if first.id;
  
  if 2006 <= year( u_offer_sale_date ) <= 2014 then do;
    u_date_dhcd_received_ta_reg = input( scan( date_dhcd_received_ta_reg, 1, ',; ' ), anydtdte20. );
    if not( missing( date_dhcd_received_ta_reg ) ) and missing( u_date_dhcd_received_ta_reg ) then do;
      %warn_put( msg="Could not read TA reg date: " date_dhcd_received_ta_reg= )
    end;
  end;
  else if 2015 <= year( u_offer_sale_date ) <= 2020 then do;
    u_date_dhcd_received_ta_reg = notice_date;
  end;
  
  format u_date_dhcd_received_ta_reg mmddyy10.;
  
run;

proc print data=Match_TOPA_db_to_RCASD_TA_unq (obs=80);
  where 2006 <= year( u_offer_sale_date ) <= 2014;
  id id;
  var u_date_dhcd_received_ta_reg nidc_rcasd_id u_offer_sale_date date_dhcd_received_ta_reg notice_date notice_type;
run;

proc print data=Match_TOPA_db_to_RCASD_TA_unq (obs=80);
  where 2015 <= year( u_offer_sale_date ) <= 2020;
  id id;
  var u_date_dhcd_received_ta_reg nidc_rcasd_id u_offer_sale_date date_dhcd_received_ta_reg notice_date notice_type;
run;


ods listing close;
ods tagsets.excelxp file="&_dcdata_default_path\PresCat\Prog\TOPA\Match_TOPA_db_to_RCASD_TA_reg_not_found.xls" style=Normal options(sheet_interval='None' );

title2 'TA registrations in TOPA database but not found in Urban RCASD notices';
proc print data=Match_TOPA_db_to_RCASD_TA_unq label;
  where 2015 <= year( u_offer_sale_date ) <= 2020 and missing( u_date_dhcd_received_ta_reg ) and date_dhcd_received_ta_reg not in ( "", "N/A" );
  id id;
  var u_offer_sale_date date_dhcd_received_ta_reg all_street_addresses;
run;
title2;

ods tagsets.excelxp close;
ods listing;


proc print data=Dhcd.Rcasd_2015;
  where notice_date = '09mar2015'd;
  id nidc_rcasd_id; 
  var source_file notice_date notice_type address;
run;

proc print data=Prescat.Topa_database;
  where id = 875;
  id id;
  var u_casd_date u_offer_sale_date date_dhcd_received_ta_reg all_street_addresses;
run;

proc format;
  value $missyn 
    ' ' = 'Missing'
    other = 'Not missing';
  value missyn
    . = 'Missing'
    other = 'Not missing';
run;

proc freq data=Match_TOPA_db_to_RCASD_TA_unq;
  where 2015 <= year( u_offer_sale_date ) <= 2020;
  tables date_dhcd_received_ta_reg * notice_date / missing;
  format date_dhcd_received_ta_reg $missyn. notice_date missyn.;
run;

** Do a visual check on address matching across TOPA and RCASD databases **;

data Match_TOPA_db_to_RCASD_TA_unq_ck;

  retain id nidc_rcasd_id orig_address all_street_addresses;

  set Match_TOPA_db_to_RCASD_TA_unq;
  
  keep id nidc_rcasd_id orig_address all_street_addresses;
  
run;
  
filename fexport "&_dcdata_default_path\PresCat\Prog\TOPA\Match_TOPA_db_to_RCASD_TA_unq_ck.csv" lrecl=10000;

proc export data=Match_TOPA_db_to_RCASD_TA_unq_ck
    outfile=fexport
    dbms=csv replace;

run;

filename fexport clear;



/****
proc print data=Match_TOPA_db_to_RCASD_TA;
  where missing( id );
  id nidc_rcasd_id;
  var notice_date notice_type orig_address;
run;



