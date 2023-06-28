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

  ods html body="&_dcdata_default_path\PresCat\Prog\TOPA\Topa_CBO_data_checks_&id..html" style=Analysis;

  title4 "TOPA ID = &ID";

  %if %length( &u_address_id_ref ) > 0 %then %do;
    title6 'Topa_notices_sales';
    proc print data=Prescat.Topa_notices_sales;
      where u_address_id_ref = &u_address_id_ref;
      id id;
      var u_address_id_ref u_notice_date u_dedup_notice u_notice_with_sale u_sale_date;
    run;
  %end;

  title6 'Topa_database';
  proc print data=Prescat.Topa_database;
    where id in ( &id );
    id id;
    var u_casd_date u_offer_sale_date date_final_closing final_purchaser all_street_addresses;
  run;

  title6 'Topa_addresses';
  proc print data=Prescat.Topa_addresses;
    where id in ( &id );
    id id;
    var address_id fulladdress notice_listed_address;
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
    var ssl saledate saleprice ownername_full ui_proptype;
  run;
  
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

