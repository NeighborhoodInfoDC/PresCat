/**************************************************************************
 Program:  DC_data_to_TOPA_data.sas
 Library:  PresCat
 Project:  Urban-Greater DC
 Author:   Elizabeth Burton
 Created:  9/29/2022
 Version:  SAS 9.4
 Environment:  Local Windows session (desktop)
 
 Description:  Match TOPA database from CNHED to DCData data sets to add characteristics. 
 
 Modifications:
**************************************************************************/

%include "\\sas1\DCdata\SAS\Inc\StdLocal.sas";

** Define libraries **;
%DCData_lib( PresCat )
%DCData_lib( DHCD )
%DCData_lib( MAR )
%DCData_lib( RealProp )

%let revisions = Remove nonexact address matches from data.;

** Download and read TOPA dataset into SAS dataset**;
%let dsname="&_dcdata_r_path\PresCat\Raw\TOPA\TOPA-DOPA 5+_with_var_names_3_20_23_urban_update.csv";
filename fixed temp;
/** Remove carriage return and line feed characters within quoted strings **/
/*'0D'x is the hexadecimal representation of CR and
/*'0A'x is the hexadecimal representation of LF.*/
/* Replace carriage return and linefeed characters inside */
/* double quotes with a specified character.  */
/* CR/LFs not in double quotes will not be replaced. */
%let repA=' || '; /* replacement character LF */
%let repD=' || '; /* replacement character CR */
 data _null_;
 /* RECFM=N reads the file in binary format. The file consists */
 /* of a stream of bytes with no record boundaries. SHAREBUFFERS */
 /* specifies that the FILE statement and the INFILE statement */
 /* share the same buffer. */
 infile &dsname recfm=n sharebuffers;
 file fixed recfm=n;
 /* OPEN is a flag variable used to determine if the CR/LF is within */
 /* double quotes or not. Retain this value. */
 retain open 0;
 input a $char1.;
 /* If the character is a double quote, set OPEN to its opposite value. */
 if a = '"' then open = ^(open);
 /* If the CR or LF is after an open double quote, replace the byte with */
 /* the appropriate value. */
 if open then do;
 if a = '0D'x then put &repD;
 else if a = '0A'x then put &repA;
 else put a $char1.;
 end;
 else put a $char1.;
run;

proc import datafile=fixed
            dbms=csv
            out=TOPA_database1
            replace;
		
     getnames=yes;  /** Variable names are in row 1 **/
     datarow=3;  /** Skip first 2 rows which have variable names and labels **/
	 guessingrows=max;
run;

proc print data=TOPA_database1 (obs=5); 
run; 

data Topa_database2;
    set TOPA_database1;
	format _all_;
	informat _all_;
	format Date_Contract TA_PS_Contract_Date mmddyy10.;
      label
        %include "&_dcdata_r_path\PresCat\Raw\TOPA\TOPA_DOPA_5+_variable_labels.txt";
      ;
      
    ** Delete invalid notices **;
    if id in ( 
      95, 137, 207, 270, 276, 312, 339, 572, 750, 773, 839, 884, 901, 954, 1017, 1104, 1108, 1157,
      1113, 1121, 1251, 1298, 1306, 1370, 1385, 10004, 10005
    ) then u_delete_notice = 1;
    else u_delete_notice = 0;
    
    ** Change temporary CR-LF replacement text in Address (improves address parsing) **;
    All_street_addresses = left( compbl( tranwrd( All_street_addresses, '||', '; ' ) ) );
    
    ** If addresses are missing, use Address_for_mapping entered in CNHED database **;
    if lowcase( All_street_addresses ) in ( "lo", "", "4a03" ) then All_street_addresses = Address_for_mapping;
    
    ** Fill in address for Holmead Place Apartments (Holmstead Place is a typo) **;
    if lowcase( All_street_addresses ) in: ( "holmead place", "holmstead place" ) then
      All_street_addresses = "3435 Holmead Pl NW";
      
    ** Address corrections **;
    
    select ( id );
    
      when ( 68, 73, 605 ) All_street_addresses = "4505-4511 B St SE; 4608-4614 Benning Rd SE; 4600-4606 Benning Rd SE; 4605-4611 Bass Pl SE";
      
      when ( 15 ) All_street_addresses = "1215 49th Street NE; 1225 49TH STREET NE";
      
      when ( 1107 ) All_street_addresses = "2420 & 2426 15th Place SE"; /** Combined with 1108 **/
      
      otherwise /** DO NOTHING **/
    
    end;
    
    ** Create proper date variables from text input **;
    u_CASD_date = input(CASD_Report_week_ending_date, anydtdte12.);
    format u_CASD_date MMDDYY10.;
    u_offer_sale_date = input(Offer_of_Sale_date, anydtdte12.);
    format u_offer_sale_date MMDDYY10.;
    format u_delete_notice dyesno.;
    label
      u_delete_notice = "Notice flagged for deletion (Urban created var)"
      u_CASD_date = "CASD report week ending date (Urban created var)"
      u_offer_sale_date = "Notice offer of sale date (Urban created var)";
run;
ENDSAS;
title2 '** Check for duplicate values of ID **';
%Dup_check(
  data=Topa_database2,
  by=ID,
  id=
)

title2 '**show missing dates in data**';
proc print data=Topa_database2; 
	where u_CASD_date <= 0 OR u_offer_sale_date <= 0;
	var ID SSL u_CASD_date u_offer_sale_date; 
run; 

title2;

**parse out individual addresses from TOPA dataset**;
data Topa_database_w_del;
  set Topa_database2;
  where not( u_delete_notice );
run;

%Rcasd_address_parse(
	data=Topa_database_w_del,
	out=TOPA_addresses_notices,
	id=ID,
	addr=All_street_addresses,
	keepin=u_CASD_date u_offer_sale_date,
	keepout=u_CASD_date u_offer_sale_date
)

%File_info( data=TOPA_addresses_notices, printobs=40 )

** adding SSLs and GEO ids to the address list**;
%DC_mar_geocode(
	data=TOPA_addresses_notices,
	id=id,
	staddr=Address,
	out=TOPA_geocoded_a, 
	geo_match=yes, 
	keep_geo=Address_id /*SSL Address_id Ward2012 Anc2012 cluster2017 Geo2020 GeoBg2020 GeoBlk2020 Psa2012 VoterPre2012 Ward2022*/
)

** Filter out non-exact matches.
** Manually fix addresses that are not successfully geocoded (problem with geocoder) **;

data TOPA_geocoded_b;

  set TOPA_geocoded_a;
  
  if Address_std = "5115 QUEEN'S STROLL PLACE SE" then Address_id = 155975;
  else if ID in ( 930, 931, 10004, 10005 ) then address_id = 305753; /** 4212 EAST CAPITOL STREET NE **/
  else if ID = 1700 then address_id = 219981; /** 2852 CONNECTICUT AVENUE NW **/
  else if ID = 480 then /** DO NOTHING **/; /** 6931, 6933, 6935, 6937 1/2 Georgia Avenue **/
  else if ID = 83 then address_id = 234680;  /** 3536 CENTER STREET NW **/
  else if ID = 404 then address_id = 245619;  /** 5810 BLAIR ROAD NW **/
  else if ID = 10001 then address_id = 255207;  /** 4526 13TH STREET NW **/
  else if ID = 10002 then address_id = 289376; /** 4040 A 8TH STREET NW **/
  else if not m_exactmatch then delete;
  
run;

** Add geography variables to final geocoded data **;

proc sql noprint;
  create table TOPA_geocoded as 
  select
    TOPA_geocoded_b.*, 
	MAR.SSL, MAR.Address_id, MAR.Ward2012, MAR.Anc2012, MAR.cluster2017, MAR.Geo2020, MAR.GeoBg2020, 
    MAR.GeoBlk2020, MAR.Psa2012, MAR.VoterPre2012, MAR.Ward2022
	from
	  TOPA_geocoded_b left join Mar.Address_points_view as MAR
  on TOPA_geocoded_b.Address_id = MAR.Address_id
  order by ID, Address_id;
quit;

%File_info( data=TOPA_geocoded, printobs=5 )

** checking if manual adding above worked **;
proc print data=TOPA_geocoded;
  where id in (10004, 10005);
run;

** proc print for manual adds **; 
proc print data=Realprop.Parcel_base;
  where lowcase( premiseadd ) contains "1350 fairmont";
  id ssl;
  var premiseadd;
run;

proc print data=Prescat.Topa_notices_sales; 
  where id in (1159, 1543);
run; 

** Manually add SSL to IDs (in order) 894, 347&376, 387, 403&1075, 824&1383&1387&1579, 894, 1159&1543, 1466**;
data Address_ssl_xref_new_obs;
  length ssl $ 17;
  infile datalines dlm=",";
  input address_id ssl;
datalines;
237132 , 0620    0893
242832 , 0529    0037
242832 , 0529    0848
59651 , 4510    0058
49215 , 5894    0003
49215 , 5894    0004
253521 , 2956    0041
237132 , 0620    0893
284000 , 2861    0078
240916 , 0282    0031
;
run;

data Address_ssl_xref;
  set Mar.Address_ssl_xref Address_ssl_xref_new_obs;
run;


** Address_ssl_xref to identify other parcels to match to address **;
proc sql noprint;
  create table TOPA_SSL as   /** Name of output data set to be created **/
  select
    coalesce( TOPA_geocoded.ADDRESS_ID, Xref.address_id ) as address_id label="DC MAR address ID",    /** Matching variables **/
    TOPA_geocoded.ID, /** Other vars you want to keep from the two data sets, separated by commas **/
	TOPA_geocoded.u_CASD_date, TOPA_geocoded.u_offer_sale_date,
	TOPA_geocoded.Anc2012, TOPA_geocoded.cluster2017, TOPA_geocoded.Geo2020, 
	TOPA_geocoded.GeoBg2020, TOPA_geocoded.GeoBlk2020, TOPA_geocoded.Psa2012,
	TOPA_geocoded.VoterPre2012, TOPA_geocoded.Ward2022, TOPA_geocoded.Ward2012,
    Xref.ssl
    from TOPA_geocoded (where=(not(missing(ADDRESS_ID)))) as TOPA_geocoded
      left join Address_ssl_xref as xref    /** Left join = only keep obs that are in TOPA_geocoded **/
  on TOPA_geocoded.ADDRESS_ID = Xref.address_id   /** This is the condition you are matching on **/
  where not( missing( xref.ssl ) )
  order by TOPA_geocoded.ID, Xref.ssl;    /** Optional: sorts the output data set **/
quit;

** Remove duplicate SSLs **;
proc sort data=TOPA_SSL nodupkey;
  by id ssl;
run;

%File_info( data=TOPA_SSL, printobs=5 )

** checking if manual adding above worked **;
proc print data=TOPA_SSL;
  where id in (347,376,387,403,824,894,1075,1159,1382,1387,1466,1543,1579);
run;

%File_info( data=RealProp.Sales_master, printobs=5 )

** match property sales records in realprop.sales_master to TOPA addresses **;
proc sql noprint;
  create table TOPA_realprop_a as   /** Name of output data set to be created **/
  select unique 
    coalesce( TOPA_SSL.SSL, RealProp.SSL ) as SSL label="Property identification number (square/suffix/lot)", /** Matching variables **/
	saledate - u_offer_sale_date as u_days_notice_to_sale label="Number of days from offer of sale to actual sale (Urban created var)",
	TOPA_SSL.ID, /** Other vars you want to keep from the two data sets, separated by commas **/
	TOPA_SSL.u_CASD_date, TOPA_SSL.u_offer_sale_date,
	TOPA_SSL.Anc2012, TOPA_SSL.cluster2017, TOPA_SSL.Geo2020, 
	TOPA_SSL.GeoBg2020, TOPA_SSL.GeoBlk2020, TOPA_SSL.Psa2012,
	TOPA_SSL.VoterPre2012, TOPA_SSL.Ward2022, TOPA_SSL.Ward2012,
    RealProp.SSL, RealProp.SALEPRICE, RealProp.saleprice_prev, RealProp.SALEDATE, RealProp.saledate_prev, RealProp.Ownername_full, RealProp.ownername_full_prev, RealProp.ui_proptype,
	RealProp.address1, RealProp.address2, RealProp.address3, RealProp.address1_prev, RealProp.address2_prev, RealProp.address3_prev, RealProp.premiseadd, RealProp.hstd_code,
    RealProp.mix1txtype, Realprop.mix2txtype ,RealProp.ownerpt_extractdat_first, RealProp.ownerpt_extractdat_last
    from TOPA_SSL (where=(not(missing(SSL)))) as TOPA_SSL
      left join RealProp.Sales_master as realprop    /** Left join = only keep obs that are in TOPA_geocoded **/
  on TOPA_SSL.SSL = realprop.SSL   /** This is the condition you are matching on **/
  /** CLEANING: Remove irrelevant sales **/
  where not( 
    ( realprop.id = 882 and realprop.saledate = '30mar2020'd ) or 
    ( realprop.id = 184 and year( realprop.saledate ) = 2010 )
  )
  order by TOPA_SSL.ID, realprop.SALEDATE;    /** Optional: sorts the output data set **/
quit;


** Add information on owner type (buyer) **;
%Parcel_base_who_owns(
  RegExpFile=&_dcdata_r_path\RealProp\Prog\Updates\Owner type codes reg expr.txt,
  Diagnostic_file=&_dcdata_default_path\PresCat\Prog\TOPA\TOPA_who_owns_diagnostic.xls,
  inlib=work,
  data=TOPA_realprop_a,
  outlib=work,
  out=TOPA_realprop,
  finalize=N,
  ownername_full_provided=Y 
  )

** Create full list of addresses by rematching SSL file to SSL-address crosswalk **;

proc sql noprint;

  /** Get all addresses associated with SSLs in data **/
  create table _ssl_addr as
  select unique
    coalesce( TOPA_SSL.ssl, xref.ssl ) as ssl, TOPA_SSL.id, xref.address_id
	from TOPA_SSL left join Mar.Address_ssl_xref as xref
	on TOPA_SSL.ssl = xref.ssl
    order by id, address_id;

  /** Concatenate addresses from SSLs and notices **/ 
  create table _full_address_list as
    select address_id, id, 1 as Notice_listed_address from Topa_geocoded
    where not( missing( address_id ) )
    union
    select address_id, id, 0 as Notice_listed_address from _ssl_addr
    where not( missing( address_id ) );
  
  /** Group by address_id and id, combining notice flag **/
  create table _full_address_list_grp as
    select address_id, id, 
      max( Notice_listed_address ) as Notice_listed_address 
        label="Address was listed on TOPA notice"
        format=dyesno.
    from _full_address_list
    group by address_id, id;

  /** Add geographic vars to addresses **/
  create table TOPA_addresses as
    select unique coalesce( _full_address_list_grp.address_id, mar.address_id ) as address_id 
        label = "DC MAR address ID",
      _full_address_list_grp.id, _full_address_list_grp.Notice_listed_address,
  	mar.fulladdress, mar.Anc2012, mar.cluster2017, mar.Geo2020, 
  	mar.GeoBg2020, mar.GeoBlk2020, mar.Psa2012,
  	mar.VoterPre2012, mar.Ward2022, mar.Ward2012, mar.x, mar.y, mar.zip,
  	mar.active_res_occupancy_count, mar.active_res_unit_count
    from _full_address_list_grp left join 
    Mar.Address_points_view as mar
    on _full_address_list_grp.address_id = mar.address_id
    /** CLEANING: Remove irrelevant/incorrect addresses **/
    where not( 
      _full_address_list_grp.id = 1079 and _full_address_list_grp.address_id = 316359
    )
    order by id, address_id;

quit;

 

*************************************************************************
** Add revised TA registration date to Topa_database **;

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

** Match TA registrations from RCASD data that are within one year after notice date **;

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
      Topa_database_w_del as topa
      left join
      Topa_addresses as addr
      on topa.id = addr.id
      where notice_listed_address = 1 and 
        not( missing( u_offer_sale_date ) or missing( address_id ) )
  ) as topa
  on topa.address_id = rcasd.address_id and 0 <= notice_date - u_offer_sale_date <= 365
  order by id, notice_date;
quit;

data Match_TOPA_db_to_RCASD_TA_unq;

  merge 
    Topa_database_w_del (keep=id u_offer_sale_date date_dhcd_received_ta_reg u_casd_date all_street_addresses)
    Match_TOPA_db_to_RCASD_TA (where=(not( missing( id ) or missing( nidc_rcasd_id ))));
  by id;
  
  if first.id;
  
  ** For 2015-2020, use Urban RCASD data to fill in TA registration date **;
  
  if 2015 <= year( u_offer_sale_date ) <= 2020 then u_date_dhcd_received_ta_reg = notice_date;
  
  ** If Urban TA registration date is missing (i.e., not 2015-2020 or CNHED had date we do not have)
  ** then use CNHED database date;

  if missing( u_date_dhcd_received_ta_reg ) then do; 
  
    u_date_dhcd_received_ta_reg = input( scan( date_dhcd_received_ta_reg, 1, ',; ' ), anydtdte20. );
    if not( missing( date_dhcd_received_ta_reg ) ) and missing( u_date_dhcd_received_ta_reg ) then do;
      %warn_put( msg="Could not read TA reg date: " date_dhcd_received_ta_reg= )
    end;
  end;
  
  format u_date_dhcd_received_ta_reg mmddyy10.;
  
  label u_date_dhcd_received_ta_reg = "Date DHCD received TA registration (Urban created var)";
  
run;

title2 "TOPA TA REGISTRATIONS 2006-2014";
proc print data=Match_TOPA_db_to_RCASD_TA_unq (obs=40);
  where 2006 <= year( u_offer_sale_date ) <= 2014;
  id id;
  var u_date_dhcd_received_ta_reg nidc_rcasd_id u_offer_sale_date date_dhcd_received_ta_reg notice_date notice_type;
run;

title2 "TOPA TA REGISTRATIONS 2015-2020";
proc print data=Match_TOPA_db_to_RCASD_TA_unq (obs=40);
  where 2015 <= year( u_offer_sale_date ) <= 2020;
  id id;
  var u_date_dhcd_received_ta_reg nidc_rcasd_id u_offer_sale_date date_dhcd_received_ta_reg notice_date notice_type;
run;

title2;

** Add u_date_dhcd_received_ta_reg to main Topa_database **;

data Topa_database;

  merge Topa_database2 Match_TOPA_db_to_RCASD_TA_unq (keep=id u_date_dhcd_received_ta_reg);
  by id;
  
run;

*************************************************************************
** Adding year built (originally and after recent reno) to TOPA_SSL database **;

proc sort data=TOPA_SSL out=ssl_sorted;
  by ssl;
run;

data Topa_ssl_parcel; 
  merge
   Realprop.cama_parcel (keep=ssl AYB EYB)
   ssl_sorted;
  by ssl; 
  if missing( id ) then delete;
run; 

%File_info( data=Topa_ssl_parcel, printobs=5 ) /** 4635 obs**/

*************************************************************************
** Export 2007 TOPA/real property data **;
ods tagsets.excelxp   /** Open the excelxp destination **/
  file="&_dcdata_default_path\PresCat\Prog\TOPA\TOPA_data_to_DC_data_2007.xls"  /** This is where the output will go **/
  style=Normal    /** This is the ODS style that will be used in the workbook **/
  options( sheet_interval='bygroup' )   /** This creates a new worksheet for every BY group in the output **/
;

ods listing close;  /** Close the regular listing destination **/

proc print data=TOPA_realprop;  /** Create the output for the workbook **/
  where year( u_CASD_date ) = 2007;  /** Only use 2007 data **/
  var ID SSL u_CASD_date u_offer_sale_date SALEPRICE saleprice_prev	SALEDATE saledate_prev 
	Ownername_full ownername_full_prev ui_proptype ADDRESS1 ADDRESS2 address3
	address1_prev address2_prev address3_prev; /** drop geographies **/
  by ID; /** BY groups (worksheets) will be for each TOPA ID **/
run;

ods tagsets.excelxp close;  /** Close the excelxp destination **/
ods listing;   /** Reopen the listing destination **/

/** days format for saledate **/
proc format;
  value days_range (notsorted)
    . = 'Missing notice date'
    .n = 'No sale recorded'
     0 - 30 = 'Sale within 30 days'
    31 - 60 = '31 - 60 days'
    61 - 90 = '61 - 90'
    91 - 120 = '91 - 120'
    121 - 180 = '121 - 180'
    181 - 240 = '181 - 240'
     241 - 300 = '241 - 300'
     301 - 330 = '301 - 330'
     331 - 365 = '331 - 365'
     366 - high = 'More than 365 days';
run;

/** summarize by notice id first**/
proc summary data=Topa_realprop;
  by ID;
  id ward2022;
  var u_offer_sale_date u_days_notice_to_sale;
  output out=Topa_realprop_by_id min=;
run;

/** add back notices dropped in real prop match **/

proc sort data=Topa_database;
  by id;
run;

proc sort data=Topa_geocoded out=Topa_geocoded_by_id nodupkey;
  by id;
run;

data Topa_realprop_by_id_full;

  merge
    TOPA_database (keep=id u_offer_sale_date)
    Topa_geocoded_by_id (keep=id ward2022)
    Topa_realprop_by_id (in=in_realprop drop=u_offer_sale_date ward2022);
 by id;
 
 if not in_realprop then u_days_notice_to_sale = .n;

run;


** Export Topa_realprop_by_id notices of sales filed**;
ods tagsets.excelxp   /** Open the excelxp destination **/
  file="&_dcdata_default_path\PresCat\Prog\TOPA\TOPA_data_days_notice_propsales.xls"  /** This is where the output will go **/
  style=Normal    /** This is the ODS style that will be used in the workbook **/
  options( sheet_interval='proc' )   /** This creates a new worksheet for every BY group in the output **/
;

ods listing close;  /** Close the regular listing destination **/

ods tagsets.excelxp options(sheet_name="By year");
proc tabulate data=Topa_realprop_by_id_full noseps missing format=comma8.0;
  class u_offer_sale_date;
  class u_days_notice_to_sale /order=data preloadfmt;
  table 
    /** Rows **/
    n='Notices of sale filed'
    n=' ' * u_days_notice_to_sale='Days between notice and property sale' 
    ,
    /** Columns **/
    all='All Years' u_offer_sale_date='By Notice Year'
  ;
  format u_offer_sale_date year4. u_days_notice_to_sale days_range.; 
run;

ods tagsets.excelxp options(sheet_name="By ward");
proc tabulate data=Topa_realprop_by_id_full noseps missing format=comma8.0;
  class Ward2022;
  class u_days_notice_to_sale /order=data preloadfmt;
  table 
    /** Rows **/
    n='Notices of sale filed'
    n=' ' * u_days_notice_to_sale='Days between notice and property sale' 
    ,
    /** Columns **/
    all='All Wards' Ward2022='By Ward (2022)'
  ;
  format Ward2022 $CHAR3. u_days_notice_to_sale days_range.; 
run;

ods tagsets.excelxp close;  /** Close the excelxp destination **/
ods listing;   /** Reopen the listing destination **/

** Finalize permanent data sets **;

  %Finalize_data_set( 
    /** Finalize data set parameters **/
    data=TOPA_database,
    out=TOPA_database,
    outlib=PresCat,
    label="Preservation Catalog, CNHED DC TOPA notice of sale database, 5+ unit buildings only",
    sortby=ID,
    /** Metadata parameters **/
    revisions=%str(&revisions),
    /** File info parameters **/
    printobs=10,
    freqvars=technical_assistance_provider
  )

  %Finalize_data_set( 
    /** Finalize data set parameters **/
    data=Topa_realprop,
    out=Topa_realprop,
    outlib=PresCat,
    label="Preservation Catalog, Real property sales for TOPA database properties",
    sortby=ID SALEDATE,
    /** Metadata parameters **/
    revisions=%str(&revisions),
    /** File info parameters **/
    printobs=10,
    freqvars=ownercat 
  )

  %Finalize_data_set( 
    /** Finalize data set parameters **/
    data=TOPA_addresses,
    out=TOPA_addresses,
    outlib=PresCat,
    label="Preservation Catalog, full set of addresses for TOPA database properties",
    sortby=ID address_id,
    /** Metadata parameters **/
    revisions=%str(&revisions),
    /** File info parameters **/
    printobs=10,
    freqvars=Notice_listed_address ward2022
  )

  %Finalize_data_set( 
    /** Finalize data set parameters **/
    data=Topa_ssl_parcel,
    out=Topa_ssl,
    outlib=PresCat,
    label="Preservation Catalog, real property parcels for TOPA database properties",
    sortby=ID,
    /** Metadata parameters **/
    revisions=%str(&revisions),
    /** File info parameters **/
    printobs=10 
  )


**** Diagnostics ****;

title2 '** Notices without any address in TOPA_addresses **';

proc sql;

  select 
    coalesce( TOPA_database.ID, TOPA_addresses.ID ) as ID,
    TOPA_database.all_street_addresses,
    TOPA_addresses.address_id
  from TOPA_database left join TOPA_addresses
  on TOPA_database.ID = TOPA_addresses.ID
  where missing( TOPA_addresses.address_id )
  order by id;
  
quit;


title2 '** Notices without any parcel in TOPA_ssl **';

proc sql;

  select 
    coalesce( TOPA_database.ID, TOPA_ssl.ID ) as ID,
    TOPA_database.all_street_addresses,
    TOPA_ssl.ssl
  from TOPA_database left join TOPA_ssl
  on TOPA_database.ID = TOPA_ssl.ID
  where missing( TOPA_ssl.ssl )
  order by id;
  
quit;

title2;

run;
