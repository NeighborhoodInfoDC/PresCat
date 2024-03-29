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

%macro Print_id( id=, u_address_id_ref=, ssl=  );

  ods html body="&_dcdata_default_path\PresCat\Prog\TOPA\Topa_CBO_data_checks_&id..html" (title="ID=&id") style=Analysis;

  title4 "TOPA ID = &ID";

  title6 'Topa_database';
  proc print data=Prescat.Topa_database;
    where id in ( &id );
    id id;
    var u_casd_date u_offer_sale_date date_final_closing final_purchaser units all_street_addresses;
  run;

  title6 'Topa_addresses';
  proc print data=Prescat.Topa_addresses;
    where id in ( &id );
    id id;
    var address_id active_res_occupancy_count fulladdress notice_listed_address;
    sum active_res_occupancy_count;
  run;

  title6 'Topa_ssl';
  proc print data=Prescat.Topa_ssl;
    where id in ( &id );
    id id;
    var ssl;
  run;

  title6 'Topa_realprop';
  proc print data=Prescat.Topa_realprop;
    where id in ( &id );
    id id;
    var ssl saledate saleprice ownername_full ui_proptype premiseadd ownerpt_extractdat_first;
  run;
  
  proc sql noprint;
  select u_address_id_ref into :u_address_id_ref from Prescat.Topa_notices_sales
  where id = &id;
  quit;

/*  
  title6 'Topa_notices_sales';
  proc print data=Prescat.Topa_notices_sales;
    where id in ( &id );
    id id;
    var u_address_id_ref u_notice_date u_dedup_notice u_notice_with_sale u_sale_date;
  run;
*/  
  %if %length( &u_address_id_ref ) > 0 %then %do;
    title6 "Topa_notices_sales (all for u_address_id_ref = &u_address_id_ref)";
    proc print data=Prescat.Topa_notices_sales;
      where u_address_id_ref = &u_address_id_ref;
      id id;
      var u_address_id_ref u_notice_date u_dedup_notice u_notice_with_sale u_sale_date;
    run;
  %end;

  %if %length( &ssl ) > 0 %then %do;
    title6 'Realprop.Sales_master';
    proc print data=Realprop.Sales_master;
      where ssl in ( &ssl );
      by ssl;
      var saledate saleprice ownername_full ui_proptype premiseadd ownerpt_extractdat_first ownerpt_extractdat_last;
    run;
  %end;
  
  title6;
  
  ods html close;

%mend Print_id;

/** End Macro Definition **/

/*
title2 '-- TOPA notices without an SSL --';

data A;

  merge 
    Prescat.Topa_database (keep=id all_street_addresses u_casd_date u_offer_sale_date in=indb)
    Prescat.Topa_ssl (keep=id in=inssl);
  by id;
  
  if indb and not inssl;
  
run;

proc print data=A;
  id id;
run;

proc print data=Realprop.Parcel_base;
  where lowcase( premiseadd ) contains "705 4th";
  id ssl;
  var premiseadd;
run;

proc print data=Prescat.Topa_notices_sales;
  where id = 347;
  id id;
  var u_address_id_ref;
run;


title2 '7444 Georgia Avenue NW';
%Print_id( id=62, u_address_id_ref=253505 );

title6 'Topa_addresses';
proc print data=Prescat.Topa_addresses;
  where address_id in ( 253505 );
  id id;
  var address_id active_res_occupancy_count fulladdress notice_listed_address;
  sum active_res_occupancy_count;
run;

title2;

title2 'Bass Circle Apts';
title3 'Topa_addresses';
proc print data=Prescat.Topa_addresses;
  where address_id in ( 149678 );
  id id;
  var address_id active_res_occupancy_count fulladdress notice_listed_address;
  sum active_res_occupancy_count;
run;

proc print data=Prescat.Topa_ssl;
  where ssl =: '5345';
    id id;
    var ssl;
  run;
*/  



ods listing close;

title2 '--Notices to delete?--';
%Print_id( id=15 )
%Print_id( id=857 )

%Print_id( id=68 )
%Print_id( id=73 )
%Print_id( id=605 )

%Print_id( id=151 )

%Print_id( id=184 )

%Print_id( id=207 )
%Print_id( id=270 )
%Print_id( id=276 )
%Print_id( id=284 )
%Print_id( id=312 )
%Print_id( id=339 )
%Print_id( id=572 )
%Print_id( id=605 )
%Print_id( id=686 )
%Print_id( id=750 )
%Print_id( id=773 )
%Print_id( id=882 )
%Print_id( id=884 )
%Print_id( id=901 )
%Print_id( id=954 )
%Print_id( id=1017 )
%Print_id( id=1079 )
%Print_id( id=1104 )
%Print_id( id=1108 )
%Print_id( id=1157 )
%Print_id( id=1251 )
%Print_id( id=1306 )
%Print_id( id=1370 )
%Print_id( id=1386 )
%Print_id( id=1421 )
%Print_id( id=10004 )


ENDSAS;

title2 '--Properties with incorrect sale?--';
%Print_id( id=750 )


title2;


title2 '--Properties missing an earlier TOPA notice--';

title3 '930, 940, 960 Randolph Street NW';
%Print_id( id=986, u_address_id_ref=225073, ssl=%str('2905    0037', '2905    0038', '2905    0039', '2905    0812') )

title3 '1111 Massachusetts Avenue NW';
%Print_id( id=416, u_address_id_ref = 239117 )
%Print_id( id=990, ssl=%str('0315    0026', '0315    0822') )


title2 '--Properties without sales--';

title3 '1900 Minnesota Avenue SE';
%Print_id( id=370, ssl=%str('5593    0005') )

title3 '2270 & 2276 Savannah Street, etc.';
%Print_id( id=258, ssl=%str('5894    0003', '5740    0322') )

title3 '4000 Kansas Avenue NW';
%Print_id( id=232, ssl='2908    0066' )

title3 '460 L Street NW';
%Print_id( id=316, ssl = %str( '0515    3224', '0515    3225', '0515    3226', '0515    0158' ) )

title3 '76 M Street NW';
%Print_id( id=894, ssl = '0620    0893' )

title3 '2333 Skyland Place SE';
%Print_id( id=1380 )

title3 'Wingate';
%Print_id( id=623 )

title3 '86 Webster Street NW';
%Print_id( id=10006 )

title3 '6931 1/2 Georgia Avenue';
%Print_id( id=480 )

title3 '705 4th Street NW';
%Print_id( id=347 )

title3 '1302 12th Street NW';
%Print_id( id=41 )


title2 '--Geocoding issues--';

title3 '1710 Alabama Avenue SE etc.';
%Print_id( id=318 )

title3 '4837 3rd Street NE (invalid address)';
%Print_id( id=25 )

title3 '4040 A 8TH STREET NW';
%Print_id( id=10002 );

title3 '4212 EAST CAPITOL STREET NE';
%Print_id( id=930, u_address_id_ref=305753 );
%Print_id( id=931, u_address_id_ref=305753 );
%Print_id( id=10004, u_address_id_ref=305753 );
%Print_id( id=10005, u_address_id_ref=305753 );

title3 '1215 49th Street NE';
%Print_id( id=15 )
%Print_id( id=857 )


title2

ods listing;
