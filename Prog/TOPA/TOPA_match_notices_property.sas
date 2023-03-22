/**************************************************************************
 Program:  TOPA_match_notices_property.sas
 Library:  PresCat
 Project:  Urban-Greater DC
 Author:   Elizabeth Burton
 Created:  12/13/2022
 Version:  SAS 9.4
 Environment:  Local Windows session (desktop)
 
 Description:  Match TOPA notices to the same properties
 
 Modifications:
**************************************************************************/

%include "\\sas1\DCdata\SAS\Inc\StdLocal.sas";

** Define libraries **;
%DCData_lib( PresCat )
%DCData_lib( DHCD )
%DCData_lib( MAR )
%DCData_lib( RealProp )

%File_info( data=PresCat.TOPA_SSL, printobs=5 )
%File_info( data=PresCat.TOPA_realprop, printobs=5 ) /** some IDs don't have real_prop info**/
%File_info( data=PresCat.TOPA_addresses, printobs=5 )
%File_info( data=PresCat.TOPA_database, printobs=5 ) /** 1699 obs**/

/** sorting by id then address id**/
proc sort data=Topa_addresses_full out=Topa_addresses_full_sort;
  by id address_id;
run;

%File_info( data=Topa_address_ssl_realprop_sort, printobs=5 )

/** create ID (notice) x address_id crosswalk **/
data Topa_id_x_address_1; 
  set Topa_addresses_full_sort;
  by id; 
  if first.id then output; 
  *keep address_id id casd_date offer_sale_date; 
  rename address_id=address_id_ref;
run; 

/** Fill in missing ID numbers to match original TOPA database **/
data Topa_id_x_address; 
  merge 
    Topa_id_x_address_1
    Prescat.Topa_database (keep=id all_street_addresses address_for_mapping);
  by id;
run; 
 
%File_info( data=Topa_id_x_address, printobs=5 ) /** 1699 obs**/

title2 '** Notices with missing address_id_ref **';
proc print data=Topa_id_x_address;
  where missing( address_id_ref );
  id id;
  var address_id_ref all_street_addresses address_for_mapping;
run;
title2;

/*proc export data=Topa_id_x_address*/
/*    outfile="&_dcdata_default_path\PresCat\Prog\AddNew\Topa_id_x_address.csv"*/
/*    dbms=csv*/
/*    replace;*/
/*run;*/

proc sort data=Topa_id_x_address;
  by address_id_ref id;
run;

data Topa_notice_freq; 
  set Topa_id_x_address; 
  by address_id_ref; 
  if first.address_id_ref then fr_offer_sale_date=offer_sale_date;
  retain fr_offer_sale_date;
  days_btwn_notices = offer_sale_date - fr_offer_sale_date;  
  fr_offer_sale_date = offer_sale_date;
  format fr_offer_sale_date MMDDYY10.;
  run;

%File_info( data=Topa_notice_freq, printobs=5 ) /** 1699 obs**/

proc sort data=Topa_notice_freq; 
  by id; 
run; 

proc export data=Topa_notice_freq
    outfile="&_dcdata_default_path\PresCat\Prog\AddNew\Topa_notice_freq.csv"
    dbms=csv
    replace;
run;

  %Finalize_data_set( 
    /** Finalize data set parameters **/
    data=Topa_id_x_address,
    out=Topa_id_x_address,
    outlib=PresCat,
    label="Preservation Catalog, ID (TOPA notice) and unique address_id crosswalk",
    sortby=id,
    /** Metadata parameters **/
    revisions=%str(New data set.),
    /** File info parameters **/
    printobs=10 
  )


