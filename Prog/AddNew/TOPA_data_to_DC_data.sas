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

%let revisions = Reformat and update TOPA data sets.;

** Download and read TOPA dataset into SAS dataset**;
%let dsname="&_dcdata_r_path\PresCat\Raw\TOPA\TOPA_DOPA_5+_with_var_names.csv";
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

data TOPA_database;
    set TOPA_database1;
	format _all_;
	informat _all_;
	format Date_Contract TA_PS_Contract_Date mmddyy10.;
      label
        %include "&_dcdata_r_path\PresCat\Raw\TOPA\TOPA_DOPA_5+_variable_labels.txt";
      ;
      
    ** If addresses are missing, use Address_for_mapping entered in CNHED database **;
    if lowcase( All_street_addresses ) in ( "lo", "" ) then All_street_addresses = Address_for_mapping;
    
    ** Fill in address for Holmead Place Apartments (Holmstead Place is a typo) **;
    if lowcase( All_street_addresses ) in: ( "holmead place", "holmstead place" ) then
      All_street_addresses = "3435 Holmead Pl NW";
    
    ** Create proper date variables from text input **;
    u_CASD_date = input(CASD_Report_week_ending_date, anydtdte12.);
    format u_CASD_date MMDDYY10.;
    u_offer_sale_date = input(Offer_of_Sale_date, anydtdte12.);
    format u_offer_sale_date MMDDYY10.;
    label
      u_CASD_date = "CASD report week ending date (Urban created var)"
      u_offer_sale_date = "Notice offer of sale date (Urban created var)";
run;

**show missing dates in data**;
proc print data=TOPA_database; 
	where u_CASD_date <= 0 OR u_offer_sale_date <= 0;
	var ID SSL u_CASD_date u_offer_sale_date; 
run; 

**parse out individual addresses from TOPA dataset**;
%Rcasd_address_parse(
	data=TOPA_database,
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
	staddr=Address,
	out=TOPA_geocoded, 
	geo_match=yes, 
	keep_geo= SSL Address_id Ward2012 Anc2012 cluster2017 Geo2020 GeoBg2020 GeoBlk2020 Psa2012 VoterPre2012 Ward2022
)

** Manually fix addresses that are not successfully geocoded (problem with geocoder) **;

data TOPA_geocoded;

  set TOPA_geocoded;
  
  if Address_std = "5115 QUEEN'S STROLL PLACE SE" then Address_id = 155975;
  
run;

%File_info( data=TOPA_geocoded, printobs=5 )

** MAR.address_ssl_xref to identify other parcels to match to address **;
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
      left join Mar.Address_ssl_xref as xref    /** Left join = only keep obs that are in TOPA_geocoded **/
  on TOPA_geocoded.ADDRESS_ID = Xref.address_id   /** This is the condition you are matching on **/
  where not( missing( xref.ssl ) )
  order by TOPA_geocoded.ID, Xref.ssl;    /** Optional: sorts the output data set **/
quit;

%File_info( data=TOPA_SSL, printobs=5 )

%File_info( data=RealProp.Sales_master, printobs=5 )

** match property sales records in realprop.sales_master to TOPA addresses **;
proc sql noprint;
  create table TOPA_realprop as   /** Name of output data set to be created **/
  select unique 
    coalesce( TOPA_SSL.SSL, RealProp.SSL ) as SSL, /** Matching variables **/
	/** obs where sale date is after the later of CASD data and offer of sale data **/
	saledate - u_offer_sale_date as u_days_notice_to_sale label="Number of days from offer of sale to actual sale (Urban created var)",
	TOPA_SSL.ID, /** Other vars you want to keep from the two data sets, separated by commas **/
	TOPA_SSL.u_CASD_date, TOPA_SSL.u_offer_sale_date,
	TOPA_SSL.Anc2012, TOPA_SSL.cluster2017, TOPA_SSL.Geo2020, 
	TOPA_SSL.GeoBg2020, TOPA_SSL.GeoBlk2020, TOPA_SSL.Psa2012,
	TOPA_SSL.VoterPre2012, TOPA_SSL.Ward2022, TOPA_SSL.Ward2012,
    RealProp.SSL, RealProp.SALEPRICE, RealProp.saleprice_prev, RealProp.SALEDATE, RealProp.saledate_prev, RealProp.Ownername_full, RealProp.ownername_full_prev, RealProp.ui_proptype,
	RealProp.address1, RealProp.address2, RealProp.address3, RealProp.address1_prev, RealProp.address2_prev, RealProp.address3_prev, RealProp.premiseadd, RealProp.hstd_code  
    from TOPA_SSL (where=(not(missing(SSL)))) as TOPA_SSL
      left join RealProp.Sales_master as realprop    /** Left join = only keep obs that are in TOPA_geocoded **/
  on TOPA_SSL.SSL = realprop.SSL   /** This is the condition you are matching on **/
  where SALEDATE > max(u_CASD_date, u_offer_sale_date) /** obs where sale date is after the later of CASD data and offer of sale data **/
  order by TOPA_SSL.ID, realprop.SALEDATE;    /** Optional: sorts the output data set **/
quit;

/******** NEED TO DEBUG THIS ***********
%Parcel_base_who_owns(
  RegExpFile=&_dcdata_r_path\RealProp\Prog\Updates\Owner type codes reg expr.txt,
  Diagnostic_file=&_dcdata_default_path\PresCat\Prog\AddNew\TOPA_who_owns_diagnostic.xls,
  inlib=work,
  data=TOPA_realprop_a,
  outlib=work,
  finalize=N,
  Revisions=NULL  
  )
********************************************/

%File_info( data=TOPA_realprop, printobs=5 )

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
    order by id, address_id;

quit;

** Export 2007 TOPA/real property data **;
ods tagsets.excelxp   /** Open the excelxp destination **/
  file="&_dcdata_default_path\PresCat\Prog\AddNew\TOPA_data_to_DC_data_2007.xls"  /** This is where the output will go **/
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
  file="&_dcdata_default_path\PresCat\Prog\AddNew\TOPA_data_days_notice_propsales.xls"  /** This is where the output will go **/
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
    printobs=10 
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
    freqvars=Notice_listed_address
  )

  %Finalize_data_set( 
    /** Finalize data set parameters **/
    data=Topa_ssl,
    out=Topa_ssl,
    outlib=PresCat,
    label="Preservation Catalog, real property parcels for TOPA database properties",
    sortby=ID,
    /** Metadata parameters **/
    revisions=%str(&revisions),
    /** File info parameters **/
    printobs=10 
  )


