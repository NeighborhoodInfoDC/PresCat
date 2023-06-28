/**************************************************************************
 Program:  Topa_CBO_data_checks.sas
 Library:  PresCat
 Project:  Urban-Greater DC
 Author:   P. Tatian
 Created:  06/24/23
 Version:  SAS 9.4
 Environment:  Local Windows session (desktop)
 GitHub issue:  375
 
 Description:  Check data based on feedback from CBOs.

 Modifications:
**************************************************************************/

%include "\\sas1\DCdata\SAS\Inc\StdLocal.sas";

** Define libraries **;
%DCData_lib( PresCat )
%DCData_lib( DHCD )
%DCData_lib( MAR )
%DCData_lib( RealProp )


/** Macro Print_id - Start Definition **/

%macro Print_id( id= );

  title3 "TOPA ID = &ID";

  title4 'Topa_database';
  proc print data=Prescat.Topa_database;
    where id in ( &id );
    id id;
    var u_casd_date u_offer_sale_date date_final_closing final_purchaser all_street_addresses;
  run;

  title4 'Topa_addresses';
  proc print data=Prescat.Topa_addresses;
    where id in ( &id );
    id id;
    var address_id fulladdress notice_listed_address;
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
    var ssl saledate saleprice ownername_full ui_proptype;
  run;
  
  title4;

%mend Print_id;

/** End Macro Definition **/

title2 '--Properties missing an earlier TOPA notice--';

ods html body="&_dcdata_default_path\PresCat\Prog\TOPA\Topa_CBO_data_checks_986.html" style=Minimal;


** 930, 940, 960 Randolph Street NW **;

proc print data=Prescat.Topa_notices_sales;
  where u_address_id_ref = 225073;
  id id;
  var u_address_id_ref u_notice_date u_dedup_notice u_notice_with_sale u_sale_date;
run;

%Print_id( id=986 )

title4 'Realprop.Sales_master';
proc print data=Realprop.Sales_master;
  where ssl in ( '2905    0037', '2905    0038', '2905    0039', '2905    0812' );
  by ssl;
  var saledate saleprice ownername_full ui_proptype premiseadd ownerpt_extractdat_first ownerpt_extractdat_last;
run;

ods html close;



ENDSAS;

proc print data=Prescat.Topa_notices_sales;
  where u_address_id_ref = 239117;
  id id;
  var u_address_id_ref u_notice_date u_dedup_notice u_notice_with_sale u_sale_date;
run;

%Print_id( id=416 )

%Print_id( id=990 )

title4 'Realprop.Sales_master';
proc print data=Realprop.Sales_master;
  where ssl in ( '0315    0026', '0315    0822' );
  by ssl;
  var saledate saleprice ownername_full ui_proptype premiseadd ownerpt_extractdat_first ownerpt_extractdat_last;
run;



title2 '--Properties without sales--';

%Print_id( id=370 )

title4 'Realprop.Sales_master';
proc print data=Realprop.Sales_master;
  where ssl in ( '5593    0005' );
  by ssl;
  id saledate;
  var saleprice ownername_full ui_proptype premiseadd ownerpt_extractdat_first ownerpt_extractdat_last;
run;


%Print_id( id=258 )

title4 'Realprop.Sales_master';
proc print data=Realprop.Sales_master;
  where ssl in ( '5894    0003', '5740    0322' );
  by ssl;
  id saledate;
  var saleprice ownername_full ui_proptype premiseadd ownerpt_extractdat_first ownerpt_extractdat_last;
run;

%Print_id( id=232 )

title4 'Realprop.Sales_master';
proc print data=Realprop.Sales_master;
  where ssl in ( '2908    0066' );
  by ssl;
  id saledate;
  var saleprice ownername_full ui_proptype premiseadd ownerpt_extractdat_first ownerpt_extractdat_last;
run;


%Print_id( id=316 )

title4 'Realprop.Sales_master';
proc print data=Realprop.Sales_master;
  where ssl in ( '0515    3224', '0515    3225', '0515    3226', '0515    0158' );
  by ssl;
  id saledate;
  var saleprice ownername_full ui_proptype premiseadd ownerpt_extractdat_first ownerpt_extractdat_last;
run;


%Print_id( id=894 )

title4 'Realprop.Parcel_base';
proc print data=Realprop.Parcel_base;
  where ssl = '0620    0893';
  id ssl;
  var premiseadd in_last_ownerpt ownerpt_extractdat_first ownerpt_extractdat_last ownername ownname2;
run;

title4 'Realprop.Sales_master';
proc print data=Realprop.Sales_master;
  where ssl = '0620    0893';
  by ssl;
  id saledate;
  var saleprice ownername_full ui_proptype premiseadd ownerpt_extractdat_first ownerpt_extractdat_last;
run;

title2;



run;
