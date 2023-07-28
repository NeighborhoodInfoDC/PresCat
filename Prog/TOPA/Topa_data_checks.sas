/**************************************************************************
 Program:  Topa_data_checks.sas
 Library:  PresCat
 Project:  Urban-Greater DC
 Author:   P. Tatian
 Created:  06/24/23
 Version:  SAS 9.4
 Environment:  Local Windows session (desktop)
 GitHub issue:  392
 
 Description:  Output TOPA data for checking. 

 Modifications:
**************************************************************************/

%include "\\sas1\DCdata\SAS\Inc\StdLocal.sas";

** Define libraries **;
%DCData_lib( PresCat )
%DCData_lib( DHCD )
%DCData_lib( MAR )
%DCData_lib( RealProp )


/** Macro Print_id - Start Definition **/

%macro Print_id( id=, ssl=  );

  %local u_address_id_ref;

  ods html body="&_dcdata_default_path\PresCat\Prog\TOPA\Data checks\Topa_data_checks_&id..html" (title="ID=&id") style=Analysis;

  title2 "TOPA ID = &ID";

  proc sql noprint;
  select u_address_id_ref into :u_address_id_ref from Prescat.Topa_notices_sales
  where id = &id;
  quit;

  title4 "Topa_notices_sales + Topa_cbo_sheet (u_address_id_ref=&u_address_id_ref)";
  proc print data=Topa_sales_cbo;
    where u_address_id_ref = &u_address_id_ref;
    id id;
    var 
      u_notice_date u_dedup_notice u_notice_with_sale u_sale_date
      cbo_dhcd_received_ta_reg
      r_Existing_LIHTC r_New_LIHTC TA_assign_rights
      outcome_homeowner outcome_nonprofit_owner
      outcome_rent_assign_rc_cont 
      outcome_assign_section8
      outcome_assign_profit_share
      outcome_rehab outcome_buyouts
      outcome_100pct_afford outcome_affordability
      outcome_pres_funding_fail 
      add_notes data_notes
    ;
  run;
  
  title4 "Unit count comparisons";
  proc print data=Topa_sales_cbo label;
    where u_address_id_ref = &u_address_id_ref;
    id id;
    var units cbo_unit_count u_sum_units;
    label 
      units = 'Units from notice (CNHED db)'
    ;
  run;

  title4 'Topa_database';
  proc print data=Prescat.Topa_database;
    where id in ( &id );
    id id;
    var u_delete_notice u_casd_date u_offer_sale_date date_final_closing final_purchaser units u_final_units all_street_addresses property_name;
  run;

  title4 'Topa_addresses';
  proc print data=Prescat.Topa_addresses;
    where id in ( &id );
    id id;
    var address_id active_res_occupancy_count fulladdress notice_listed_address;
    sum active_res_occupancy_count;
  run;
  
  title4 'Topa_ssl';
  proc print data=Prescat.Topa_ssl;
    where id in ( &id );
    id id;
    var ssl;
  run;

  title4 'Topa_realprop';
  proc print data=Prescat.Topa_realprop;
    where id in ( &id );
    id id;
    var ssl saledate saleprice ownername_full ui_proptype premiseadd ownerpt_extractdat_first;
  run;
  
  %if %length( &ssl ) > 0 %then %do;
    title4 'Realprop.Sales_master';
    proc print data=Realprop.Sales_master;
      where ssl in ( &ssl );
      by ssl;
      var saledate saleprice ownername_full ui_proptype premiseadd ownerpt_extractdat_first ownerpt_extractdat_last;
    run;
  %end;
  
  title4;
  
  ods html close;

%mend Print_id;

/** End Macro Definition **/


/** Macro Print_all - Start Definition **/

%macro Print_all(  );

  %local id_list;

  proc sql noprint;
  select id into :id_list separated by ' ' from Prescat.Topa_database;
  quit;
  
  %put id_list=&id_list;
  
  %local i v;

  %let i = 1;
  %let v = %scan( &id_list, &i, %str( ) );

  %do %until ( &v = );

    %Print_id( id=&v )

    %let i = %eval( &i + 1 );
    %let v = %scan( &id_list, &i, %str( ) );

  %end;

%mend Print_all;

/** End Macro Definition **/


** Merge sales and CBO outcome data **;

data Topa_sales_cbo;

  merge 
    Prescat.Topa_notices_sales
    Prescat.Topa_cbo_sheet (drop=u_address_id_ref u_notice_date u_sale_date u_ownername)
    Prescat.Topa_database (keep=id units);
  by id;

run;

** List of multiple notices per address **;

%Dup_check(
  data=Topa_sales_cbo,
  by=u_address_id_ref,
  id=id
)


** Create all output **;

ods listing close;

%Print_all( )

ods listing;
