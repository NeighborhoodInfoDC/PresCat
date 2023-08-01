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

%File_info( data=Topa_id_x_address_1, printobs=5 ) /** 1749 obs**/

/** Fill in missing ID numbers to match original TOPA database **/
data Topa_id_x_address; 
  merge 
    Topa_id_x_address_1
    Prescat.Topa_database (keep=id all_street_addresses address_for_mapping units u_delete_notice);
  by id;
  if u_delete_notice then delete;
run; 
 
%File_info( data=Topa_id_x_address, printobs=5 ) /** 1750 obs**/

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

proc print data=Sales_by_property; /* can't find 894 ID */ 
  where id=894;
run;

data Sales_by_property_dates;
  set Sales_by_property; 
  format all_saledate MMDDYY10.;
  format actual_saledate DYESNO.;
  if not(missing(SALEDATE)) then do; 
	all_saledate=SALEDATE;
	actual_saledate=1;
		end; 
  else if (missing(SALEDATE)) then do; 
	all_saledate=ownerpt_extractdat_first;
	actual_saledate=0;
		end;
  label all_saledate='Property sale date or if sale date missing, extract date of Ownerpt update where sale first appeared';
  label actual_saledate='Property sale date used';
  if '01Jan2006'd <= all_saledate <= '31mar2023'd;
run;
%File_info( data=Sales_by_property_dates, printobs=5 ) 

proc print data=Sales_by_property_dates;
  where id in ( 232, 316, 894, 986, 990, 10004, 10005 );
  by id;
  var id ownerpt_extractdat_first SALEDATE all_saledate actual_saledate All_street_addresses u_address_id_ref;
run;

proc sort data=Sales_by_property_dates out=Sales_by_property_nodup nodupkey;
  by u_address_id_ref descending all_saledate;
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

%File_info( data=TOPA_by_property, printobs=5 ) /** 1750 obs**/

/*Adding years built variables to datasets below*/
proc summary data=PresCat.TOPA_SSL;
  by id;
  var eyb ayb;
  output out=TOPA_years_built (drop=_type_ _freq_) min=u_recent_reno u_year_built_original;
run;

%File_info( data=TOPA_years_built, printobs=20 ) 

data TOPA_years; 
  merge TOPA_by_property TOPA_years_built; 
  by id; 
  label u_year_built_original = 'Earliest year main portion originally built (Urban created var)';
  label u_recent_reno = 'Calculated or apparent year an improvement was built (Urban created var)'; 
run;  

%File_info( data=TOPA_years, printobs=5 ) 

proc sort data=TOPA_years out=TOPA_by_property_dates;
  by u_address_id_ref descending u_offer_sale_date id;
run;

data Combo;
  set 
    TOPA_by_property_dates 
    (keep=u_address_id_ref id u_offer_sale_date u_final_units u_year_built_original u_recent_reno FULLADDRESS Anc2012 Geo2020 GeoBg2020 GeoBlk2020 Psa2012 VoterPre2012 Ward2012 Ward2022 cluster2017
     rename=(u_offer_sale_date=u_ref_date)
     in=is_notice)
    Sales_by_property_nodup
	  (keep=u_address_id_ref saledate ownerpt_extractdat_first all_saledate actual_saledate saleprice ownername_full Ownercat ui_proptype ADDRESS1 ADDRESS2 address3
	   rename=(all_saledate=u_ref_date));
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
  format u_orig_saledate MMDDYY10.;
  format u_ownerpt_extractdat_first MMDDYY10.;
  format u_actual_saledate DYESNO.;
  format u_ownercat $OWNCAT.;

  if first.u_address_id_ref then do; 
	  prev_desc=""; u_notice_date=""; u_ownername=""; u_saleprice=.; u_proptype=.; u_address1="";
	  u_address2=""; u_address3=""; u_sale_date=.; u_orig_saledate=.; u_ownerpt_extractdat_first=.; u_actual_saledate=""; u_ownercat="";

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
  label u_sale_date='Property sale date or if sale date missing, extract date of Ownerpt update where sale first appeared (Urban created var)';
  
  if desc="NOTICE OF SALE" then u_notice_date=u_ref_date;
  retain u_notice_date;
  label u_notice_date='Notice offer of sale date (Urban created var)';
  
  if desc="SALE" and u_address_id_ref=u_address_id_ref then do; 
	u_ownername=Ownername_full; u_saleprice=SALEPRICE; u_proptype=ui_proptype; u_address1=ADDRESS1;
	u_address2=ADDRESS2; u_address3=address3; u_orig_saledate=saledate; u_ownerpt_extractdat_first=ownerpt_extractdat_first; 
	u_actual_saledate=actual_saledate; u_ownercat=Ownercat;

	end; 
  retain u_ownername u_saleprice u_proptype u_address1 u_address2 u_address3 u_orig_saledate u_ownerpt_extractdat_first u_actual_saledate u_ownercat; 
  label u_ownername ='Name(s) of property buyer(s) (Urban created var)';
  label u_saleprice='Property sale price ($) (Urban created var)';
  label u_proptype='Property type at sale (Urban created var)';
  label u_address1='Buyer tax billing address part 1 (Urban created var)';
  label u_address2='Buyer tax billing address part 2 (Urban created var)';
  label u_address3='Buyer tax billing address part 3 (City, State, ZIP) (Urban created var)';
  label u_orig_saledate='Property sale date from real_prop (Urban created var)'; 
  label u_ownerpt_extractdat_first='Extract date of Ownerpt update where sale first appeared (Urban created var)'; 
  label u_actual_saledate= 'ID used Property sale date from real_prop (Urban created var)';   
  label u_ownercat='Property owner type (Urban created var';

  /** Write observation if a notice of sale and reset retained sales data for next observation **/
  if desc="NOTICE OF SALE" then do;
	output;
	u_ownername=""; u_saleprice=.; u_proptype=.; u_address1="";
	u_address2=""; u_address3=""; u_sale_date=.; u_orig_saledate=.; u_ownerpt_extractdat_first=.; u_actual_saledate=""; u_ownercat="";
	end;
  
  label
    u_address_id_ref = "Unique property ID (DC MAR address ID) (Urban created var)"
    FULLADDRESS = "Street address for unique property ID (Urban created var)";
  
  drop desc;
  drop Ownername_full SALEPRICE ui_proptype u_ref_date ADDRESS1 ADDRESS2 address3 prev_desc saledate ownerpt_extractdat_first actual_saledate Ownercat;
run; 

/** Proc Print for checking results **/
proc print data=Topa_notice_flag (firstobs=79 obs=94);
  /**where u_address_id_ref=5142;**/
  by u_address_id_ref;
  var id u_final_units u_notice_date u_sale_date u_dedup_notice u_notice_with_sale u_days_: u_saleprice u_ownername u_proptype;
run;

%File_info( data=Topa_notice_flag, printobs=5 ) 

/** Finalize Topa_notices_sales (1498 obs) **/

  %Finalize_data_set( 
    /** Finalize data set parameters **/
    data=Topa_notice_flag,
    out=Topa_notices_sales,
    outlib=PresCat,
    label="TOPA notices from CNHED combined with real prop and address data to create new variables for TOPA eval, 2006-2020",
    sortby=ID,
    /** Metadata parameters **/
    revisions=%str(Data cleaning. ),
    /** File info parameters **/
    printobs=10,
    freqvars=u_dedup_notice u_notice_with_sale u_proptype ward2022 cluster2017
  )

