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

%File_info( data=PresCat.TOPA_SSL, printobs=5 )
%File_info( data=PresCat.TOPA_realprop, printobs=5 ) /** some IDs don't have real_prop info**/
%File_info( data=PresCat.TOPA_addresses, printobs=5 )
%File_info( data=PresCat.TOPA_database, printobs=5 ) 

/*create flags (u_dedup_notice & u_notice_with_sale )*/
/*create u_days_between_notices & u_days_from_dedup_notice_to_sale*/
/*sales data listed in the data analysis plan 5.a*/

/** Creating an ID for each property **/
/** sorting by id then address id**/
proc sort data=Prescat.Topa_addresses out=Topa_addresses_sort;
  by id address_id;
run;

/** create ID (notice) x address_id crosswalk **/
data Topa_id_x_address_1; 
  set Topa_addresses_sort;
  by id; 
  if first.id then output; 
  rename address_id=u_address_id_ref;
run; 

%File_info( data=Topa_id_x_address_1, printobs=5 ) /** 1738 obs**/


/** Fill in missing ID numbers to match original TOPA database **/
data Topa_id_x_address; 
  merge 
    Topa_id_x_address_1
    Prescat.Topa_database (keep=id all_street_addresses address_for_mapping);
  by id;
run; 
 
%File_info( data=Topa_id_x_address, printobs=5 ) /** 1740 obs**/

title2 '** Notices with missing u_address_id_ref **';
proc print data=Topa_id_x_address;
  where missing( u_address_id_ref );
  id id;
  var u_address_id_ref all_street_addresses address_for_mapping;
run;
title2;

/*proc export data=Topa_id_x_address*/
/*    outfile="&_dcdata_default_path\PresCat\Prog\AddNew\Topa_id_x_address.csv"*/
/*    dbms=csv*/
/*    replace;*/
/*run;*/

/*Add vars from real_prop, combine with TOPA_id_x_address created above, clean up variables, and limit sale/notice data to 2006-2020*/
data Sales_by_property;
  merge
    Prescat.Topa_realprop Topa_id_x_address;
  by id;
  if missing( ssl ) then delete;
run;

proc sort data=Sales_by_property out=Sales_by_property_nodup nodupkey;
  by u_address_id_ref descending saledate;
run;

%File_info( data=Sales_by_property_nodup, printobs=5 ) /** 4958 obs**/

data TOPA_by_property;
  merge Prescat.Topa_database Topa_id_x_address;
  by id;
run; 

proc sort data=TOPA_by_property;
  by u_address_id_ref descending u_offer_sale_date id;
run;

%File_info( data=TOPA_by_property, printobs=5 ) /** 1740 obs**/

data Combo;
  set 
    TOPA_by_property 
    (keep=u_address_id_ref id u_offer_sale_date
     rename=(u_offer_sale_date=ref_date)
     in=is_notice)
    Sales_by_property_nodup
	  (keep=u_address_id_ref saledate saleprice ownername_full ui_proptype
	   rename=(saledate=ref_date));
	by u_address_id_ref descending ref_date;

	length desc $ 40;

	if is_notice then desc = "NOTICE OF SALE";
	else desc = "SALE";

    /**Limit sale and notice data to 2006-2020 and do not use obs with missing address or date **/
    where ref_date between '01Jan2006'd and '31dec2020'd 
	  and not( missing( u_address_id_ref ) or missing( ref_date ) );

run;

%File_info( data=Combo, printobs=5 ) /** 4050 obs**/

/*Create flags (u_dedup_notice & u_notice_with_sale)*/
proc sort data=Combo;
  by u_address_id_ref descending ref_date;
run; /* I don't know if this is neccessary but I know it always says to sort before using first operator*/

/* dedup_notice is just the most recent notice of sale for a property; */

data Topa_notice_flag; 
  set Combo;  
  by u_address_id_ref descending ref_date;
  descsale=desc; 
  retain descsale; 
  if first.u_address_id_ref and desc="NOTICE OF SALE" then u_dedup_notice=1;
  else if descsale="SALE" then u_dedup_notice=1;
  else u_dedup_notice=0; 
run; 

/** Temporary Proc Print for checking results **/
proc print data=Topa_notice_flag;
  where u_address_id_ref=5142;
  by u_address_id_ref;
  id ref_date;
  var desc id u_dedup_notice descsale;
run;
   
data Topa_notice_flag_2; 
  set Topa_notice_flag;  
  by u_address_id_ref descending ref_date;
  retain temp2;
  if first.u_address_id_ref and not(saleprice) then do; temp2=0; end; /** not(saleprice) to show no sale on property**/
  if ID and not(temp2) then do; temp2=1; u_notice_with_sale=0;end;else u_notice_with_sale=1; 
  drop temp1 temp2;
run; 

%File_info( data=Topa_notice_flag_2, printobs=100) /** 4050 obs ID 5559**/


/*Create u_days_between_notices & u_days_from_dedup_notice_to_sale*/
proc sort data=Topa_id_x_address;
  by u_address_id_ref id;
run;

data Topa_notice_freq; 
  set Topa_id_x_address; 
  by u_address_id_ref; 
  if first.u_address_id_ref then u_fr_offer_sale_date=u_offer_sale_date;
  retain u_fr_offer_sale_date;
  u_days_between_notices = u_offer_sale_date - u_fr_offer_sale_date;  
  u_fr_offer_sale_date = u_offer_sale_date;
  format u_fr_offer_sale_date MMDDYY10.;
  run;

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


