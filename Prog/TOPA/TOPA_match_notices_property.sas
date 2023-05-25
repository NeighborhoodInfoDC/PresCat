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
%DCData_lib( Realprop )

%File_info( data=PresCat.TOPA_SSL, printobs=5 )
%File_info( data=PresCat.TOPA_realprop, printobs=5 ) /** some IDs don't have real_prop info**/
%File_info( data=PresCat.TOPA_addresses, printobs=5 )
%File_info( data=PresCat.TOPA_database, printobs=5 ) 

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

data Sales_by_property_dates;
  set Sales_by_property; 
  where saledate between '01Jan2006'd and '31may2022'd; /** Limit sale data to 2006-2020 **/
run;

proc sort data=Sales_by_property_dates out=Sales_by_property_nodup nodupkey;
  by u_address_id_ref descending saledate;
run;

%File_info( data=Sales_by_property_nodup, printobs=5 ) /** 4958 obs**/

data TOPA_by_property;
  merge Prescat.Topa_database Topa_id_x_address;
  by id;
run; 

data TOPA_by_property_dates; 
  set TOPA_by_property; 
  where u_offer_sale_date between '01Jan2006'd and '31dec2020'd;  /** Limit notice data to 2006-2020 **/
run;

proc sort data=TOPA_by_property_dates;
  by u_address_id_ref descending u_offer_sale_date id;
run;

%File_info( data=TOPA_by_property, printobs=5 ) /** 1740 obs**/

/*Adding years built variables to datasets below*/
data TOPA_SSL_prop; 
  merge PresCat.TOPA_SSL Topa_id_x_address; 
  by id; 
run; 

data TOPA_years_clean; 
  set TOPA_SSL_prop; 
  where EYB between 1 and 2023; /*removing zeros and future years*/
  where AYB between 1 and 2023; 
run; 

proc sort data=TOPA_years_clean; 
  by id EYB descending AYB; 
run; 

data TOPA_years_built;  
  set TOPA_years_clean; 
  	if first.id then do; 
	  u_year_built_original=AYB; u_recent_reno=EYB;   
	end; 
  retain u_year_built_original; 
  retain u_recent_reno; 
run; 

%File_info( data=TOPA_years_built, printobs=20 ) 


data Combo;
  set 
    TOPA_by_property_dates 
    (keep=u_address_id_ref id u_offer_sale_date FULLADDRESS Anc2012 Geo2020 GeoBg2020 GeoBlk2020 Psa2012 VoterPre2012 Ward2012 Ward2022 cluster2017
     rename=(u_offer_sale_date=u_ref_date)
     in=is_notice)
    Sales_by_property_nodup
	  (keep=u_address_id_ref saledate saleprice ownername_full ui_proptype ADDRESS1 ADDRESS2 address3
	   rename=(saledate=u_ref_date));
	by u_address_id_ref descending u_ref_date;
	length desc $ 40;

	if is_notice then desc = "NOTICE OF SALE";
	else desc = "SALE";

    /**do not use obs with missing address or date **/
    where not( missing( u_address_id_ref ) or missing( u_ref_date ) );

run;

%File_info( data=Combo, printobs=5 ) /** 4050 obs**/

/*Create flags (u_dedup_notice & u_notice_with_sale), u_days_between_notices & u_days_from_dedup_notice_to_sale*/
data Topa_notice_flag; 
  set Combo;  
  by u_address_id_ref descending u_ref_date;
  Length prev_desc $14;
  format u_notice_date MMDDYY10.;
  format u_sale_date MMDDYY10.;
  format u_proptype $UIPRTYP.;
  format u_dedup_notice DYESNO.;
  format u_notice_with_sale DYESNO.;
  format u_ownername $char100.;
  format u_address1 $char100.;
  format u_address2 $char100.;
  format u_address3 $char100.; 
  
  if first.u_address_id_ref then do; 
	  prev_desc=""; u_notice_date=""; u_ownername=""; u_saleprice=.; u_proptype=.; u_address1="";
	  u_address2=""; u_address3=""; u_sale_date=.; 
	end;
  
  if first.u_address_id_ref and desc="NOTICE OF SALE" then u_dedup_notice=1;
  else if desc="NOTICE OF SALE" and prev_desc="SALE" then u_dedup_notice=1;
  else u_dedup_notice=0; 
  label u_dedup_notice='Latest notice issued on a property (before a sale or without a sale) (Urban created var)';
  
  if desc="NOTICE OF SALE" and prev_desc="SALE" then u_notice_with_sale=1;
  else u_notice_with_sale=0; 
  label u_notice_with_sale='Property sale occurred after the notice (Urban created var)'; 
  
  if u_dedup_notice=1 and u_notice_with_sale=1 then u_days_from_dedup_notice_to_sale=u_sale_date-u_ref_date;
  label u_days_from_dedup_notice_to_sale='Number of days from the de-duplicated notice to the property sale (Urban created var)';
  
  if desc="NOTICE OF SALE" then u_days_between_notices=u_notice_date-u_ref_date;
  label u_days_between_notices='Number of days between notices for the same property (Urban created var)';
  
  retain prev_desc;
  prev_desc=desc; 
  
  if desc="SALE" then u_sale_date=u_ref_date; 
  retain u_sale_date; 
  label u_sale_date='Property sale date (Urban created var)';
  
  if desc="NOTICE OF SALE" then u_notice_date=u_ref_date;
  retain u_notice_date;
  label u_notice_date='Notice offer of sale date (Urban created var)';
  
  if desc="SALE" and u_address_id_ref=u_address_id_ref then do; 
	u_ownername=Ownername_full; u_saleprice=SALEPRICE; u_proptype=ui_proptype; u_address1=ADDRESS1;
	u_address2=ADDRESS2; u_address3=address3; 
	end; 
  retain u_ownername u_saleprice u_proptype u_address1 u_address2 u_address3; 
  label u_ownername ='Name(s) of property buyer(s) (Urban created var)';
  label u_saleprice='Property sale price ($) (Urban created var)';
  label u_proptype='Property type at sale (Urban created var)';
  label u_address1='Buyer tax billing address part 1 (Urban created var)';
  label u_address2='Buyer tax billing address part 2 (Urban created var)';
  label u_address3='Buyer tax billing address part 3 (City, State, ZIP) (Urban created var)';

  /** Write observation if a notice of sale and reset retained sales data for next observation **/
  if desc="NOTICE OF SALE" then do;
	output;
	u_ownername=""; u_saleprice=.; u_proptype=.; u_address1="";
	u_address2=""; u_address3=""; u_sale_date=.; 
	end;
  
  label
    u_address_id_ref = "Unique property ID (DC MAR address ID) (Urban created var)"
    FULLADDRESS = "Street address for unique property ID (Urban created var)";
  
  drop desc;
  drop Ownername_full SALEPRICE ui_proptype u_ref_date ADDRESS1 ADDRESS2 address3 prev_desc;
run; 

/** Proc Print for checking results **/
proc print data=Topa_notice_flag (firstobs=79 obs=94);
  /**where u_address_id_ref=5142;**/
  by u_address_id_ref;
  var id u_notice_date u_sale_date u_dedup_notice u_notice_with_sale u_days_: u_saleprice u_ownername u_proptype;
run;

%File_info( data=Topa_notice_flag, printobs=5 ) /** 4050 obs**/


/** Finalize Topa_notices_sales (1498 obs) **/

  %Finalize_data_set( 
    /** Finalize data set parameters **/
    data=Topa_notice_flag,
    out=Topa_notices_sales,
    outlib=PresCat,
    label="TOPA notices from CNHED combined with real prop and address data to create new variables for TOPA eval, 2006-2020",
    sortby=ID,
    /** Metadata parameters **/
    revisions=%str(New data set. now includes 2021-2022 sales data),
    /** File info parameters **/
    printobs=10,
    freqvars=u_dedup_notice u_notice_with_sale u_proptype ward2022 cluster2017
  )

