/**************************************************************************
 Program:  TOPA_match_notices_property.sas
 Library:  PresCat
 Project:  Urban-Greater DC
 Author:   Elizabeth Burton
 Created:  4/27/2023
 Version:  SAS 9.4
 Environment:  Local Windows session (desktop)
 
 Description:  Create basic descriptive tables for TOPA evaluation
 
 Modifications:
**************************************************************************/

%include "\\sas1\DCdata\SAS\Inc\StdLocal.sas";

** Define libraries **;
%DCData_lib( PresCat )
%DCData_lib( Realprop )

%File_info( data=PresCat.TOPA_addresses, printobs=5 ) 
%File_info( data=PresCat.TOPA_realprop, printobs=5 ) 
%File_info( data=PresCat.TOPA_notices_sales, printobs=5 ) 
%File_info( data=PresCat.TOPA_database, printobs=5 ) 

** Combine data and final edits before creating tables **;
** N = 1455 notices **;
data TOPA_table_data; 
  
  merge 
    PresCat.TOPA_notices_sales (in=in1)
    PresCat.TOPA_CBO_sheet (keep=id cbo_dhcd_received_ta_reg ta_assign_rights u_has_cbo_outcome outcome_:)
    PresCat.topa_subsidies (keep=id before_: after_:); 
  by id;

  if in1 and '01Jan2006'd <= u_notice_date <= '31dec2020'd;  /** Limit notice data to 2006-2020 **/
  
  ** Analysis variables **;
  
  all_notices=1;  
  
  if lowcase( cbo_dhcd_received_ta_reg ) = 'yes' then d_cbo_dhcd_received_ta_reg = 1;
  else if lowcase( cbo_dhcd_received_ta_reg ) = 'no' then d_cbo_dhcd_received_ta_reg = 0;
  
  if lowcase( ta_assign_rights ) = 'yes' then d_ta_assign_rights = 1;
  else if lowcase( ta_assign_rights ) = 'no' then d_ta_assign_rights = 0;
  
  if after_lec_aff_units > 0 or lowcase( outcome_homeowner ) in ( 'le coop', 'condo' ) then d_purch_condo_coop = 1;
  else d_purch_condo_coop = 0;
  
  label
    all_notices = "Every notice (including duplicates)"
    d_cbo_dhcd_received_ta_reg = "Tenant association registered"
    d_ta_assign_rights = "Tenants assigned rights"
    d_purch_condo_coop = "Tenant homeownership: LE Coop or Condo"
  ;
  
run;

%File_info( data=TOPA_table_data)

** Create formats for tables **;

proc format;
  value year_built (notsorted)
    1 -< 1910 = 'Before 1910'
    1910 -< 1920 = '1910 to 1919'
    1920 -< 1930 = '1920 to 1929'
    1930 -< 1940 = '1930 to 1939'
    1940 -< 1950 = '1940 to 1949'
    1950 -< 1960 = '1950 to 1959'
    1960 -< 1970 = '1960 to 1969'
    1970 -< 1980 = '1970 to 1979'
    1980 -< 1990 = '1980 to 1989'
    1990 -< 2000 = '1990 to 2000'
    2000 - high  = '2000 or later'
    . = 'Unknown';
  value dyesnounk (notsorted)
    1 = 'Yes'
    0 = 'No'
    . = 'Unknown';
run;


*************************************************************************
** Export Ward 6 projects **;
ods tagsets.excelxp   /** Open the excelxp destination **/
  file="&_dcdata_default_path\PresCat\Prog\TOPA\TOPA_Ward6_2012-14.xls"  /** This is where the output will go **/
  style=Normal    /** This is the ODS style that will be used in the workbook **/
  options( sheet_interval='proc' )   /** This creates a new worksheet for every proc print in the output **/
;

ods listing close;  /** Close the regular listing destination **/

ods tagsets.excelxp options(sheet_name="2012");
proc print label data=TOPA_table_data n;
  id id;
  var FULLADDRESS u_final_units u_notice_date u_dedup_notice u_notice_with_sale ;
  sum u_final_units;
  where u_dedup_notice=1 and (Ward2022="6") and (u_notice_date between '01Jan2012'd and '31dec2012'd);
run;

ods tagsets.excelxp options(sheet_name="2013");
proc print label data=TOPA_table_data n;
  id id;
  var FULLADDRESS u_final_units u_notice_date u_dedup_notice u_notice_with_sale ;
  sum u_final_units;
  where u_dedup_notice=1 and (Ward2022="6") and (u_notice_date between '01Jan2013'd and '31dec2013'd);
run;

ods tagsets.excelxp options(sheet_name="2014");
proc print label data=TOPA_table_data n;
  id id;
  var FULLADDRESS u_final_units u_notice_date u_dedup_notice u_notice_with_sale ;
  sum u_final_units;
  where u_dedup_notice=1 and (Ward2022="6") and (u_notice_date between '01Jan2014'd and '31dec2014'd);
run;

ods tagsets.excelxp close;  /** Close the excelxp destination **/
ods listing;   /** Reopen the listing destination **/
*************************************************************************

** Printing Descriptive Tables **;
options nodate nonumber;
options orientation=landscape;
options missing='-';
ods escapechar = '^';

%fdate()

ods listing close;
ods rtf file="&_dcdata_default_path\Prescat\Prog\Topa\TOPA_desc_tables.rtf" style=Styles.Rtf_lato_9pt nokeepn notrkeep;

footnote1 height=9pt "Prepared by Urban-Greater DC (greaterdc.urban.org), &fdate..";
footnote2 height=9pt j=r '{Page}\~{\field{\*\fldinst{\pard\b\i0\chcbpat8\qc\f1\fs19\cf1{PAGE }\cf0\chcbpat0}}}';

title3 "Table 1a. TOPA Notices of Sale (With Duplicates) by Ward and Year, 2006-2020";

proc tabulate data=TOPA_table_data /** insert name of input data set here **/ format=comma12.0 noseps missing;
  class ward2022 u_notice_date;   /** These variables define the table rows and columns **/
  var all_notices;  /** This variable is used for the content of the table **/
  table 
    /** Rows **/
    all="DC"    /** ALL is a keyword that creates a total. Using this here creates the total row for all wards. **/
    ward2022=" "  /** Create separate rows by ward **/
    ,
    /** Columns **/
    all_notices=" " * sum=" " * 
    (
    all="Total"    /** Create the total column for all years **/
    u_notice_date=" "  /** Create separate columns by notice year **/
    ) 
  ;
  format u_notice_date year.;  /** The year. format displays the year part of a date variable. Applying the format 
                     here forces the columns to be summarized by year, rather than individual dates. **/
run;

proc odstext;
  p "Notes: All notices, with and without sales.";
run;


title3 "Table 1b. TOPA Notices of Sale (With Duplicates) by Neighborhood Cluster and Year, 2006-2020";

proc tabulate data=TOPA_table_data format=comma12.0 noseps missing;
  class cluster2017 u_notice_date;   
  var all_notices;  
  table 
    /** Rows **/
    all="DC"    
    cluster2017=" "  
    ,
    /** Columns **/
    all_notices=" " * sum=" " * 
    (
    all="Total"    
    u_notice_date=" "  
    ) 
  ;
  format u_notice_date year.;  
run;

proc odstext;
  p "Notes: All notices, with and without sales.";
run;


title3 "2a. TOPA Notices of Sale (Deduplicated) by Ward and Year, 2006-2020";

proc tabulate data=TOPA_table_data format=comma12.0 noseps missing;
  class ward2022 u_notice_date;   
  var u_dedup_notice;  
  table 
    /** Rows **/
    all="DC"    
    ward2022=" "  
    ,
    /** Columns **/
    u_dedup_notice=" " * sum=" " * 
    (
    all="Total"    
    u_notice_date=" "  
    ) 
  ;
  format u_notice_date year.;  
run;

proc odstext;
  p "Notes: Deduplicated notices, with and without sales.";
run;


title3 "Table 2b. TOPA Notices of Sale (Deduplicated) by Neighborhood Cluster and Year, 2006-2020";

proc tabulate data=TOPA_table_data format=comma12.0 noseps missing;
  class cluster2017 u_notice_date;   
  var u_dedup_notice;  
  table 
    /** Rows **/
    all="DC"    
    cluster2017=" "  
    ,
    /** Columns **/
    u_dedup_notice=" " * sum=" " * 
    (
    all="Total"    
    u_notice_date=" "  
    ) 
  ;
  format u_notice_date year.;  
run;

proc odstext;
  p "Notes: Deduplicated notices, with and without sales.";
run;


title3 "Table 2c. Residential Units in Properties With TOPA Notices of Sale (Deduplicated) by Ward and Year, 2006-2020";

proc tabulate data=TOPA_table_data format=comma12.0 noseps missing;
  where u_dedup_notice=1; 
  class ward2022 u_notice_date;   
  var u_final_units;  
  table 
    /** Rows **/
    all="DC"    
    ward2022=" "  
    ,
    /** Columns **/
    u_final_units=" " * sum=" " * 
    (
    all="Total"    
    u_notice_date=" "  
    ) 
  ;
  format u_notice_date year.;  
run;

proc odstext;
  p "Notes: Deduplicated notices, with and without sales.";
run;


title3 "Table 2d. Residential Units in Properties With TOPA Notices of Sale (Deduplicated) by Neighborhood Cluster and Year, 2006-2020";

proc tabulate data=TOPA_table_data format=comma12.0 noseps missing;
  where u_dedup_notice=1; 
  class cluster2017 u_notice_date;   
  var u_final_units ;  
  table 
    /** Rows **/
    all="DC"    
    cluster2017=" "  
    ,
    /** Columns **/
    u_final_units=" " * sum=" " * 
    (
    all="Total"    
    u_notice_date=" "  
    ) 
  ;
  format u_notice_date year.;
run;

proc odstext;
  p "Notes: Deduplicated notices, with and without sales.";
run;


title3 "Table 3. Outcome summary";

proc tabulate data=TOPA_table_data format=comma12.0 noseps missing;
  where u_dedup_notice=1 and u_notice_with_sale=1;
  class d_cbo_dhcd_received_ta_reg d_ta_assign_rights d_purch_condo_coop / preloadfmt order=data;
  var all_notices;
  table 
    /** Rows **/
    all="Total"    
    d_ta_assign_rights * d_purch_condo_coop
    ,
    /** Columns **/
    all_notices=" " * sum=" " * 
    (
      all="Total notices"    
      d_cbo_dhcd_received_ta_reg
    )
  ;
  format d_cbo_dhcd_received_ta_reg d_ta_assign_rights d_purch_condo_coop dyesnounk.;
run;

proc odstext;
  p "Notes: Deduplicated notices with sales.";
run;


title3 "Table 4a. Properties With Tenant Association Registered by Ward and Year, 2006-2020";

proc tabulate data=TOPA_table_data format=comma12.0 noseps missing;
  where u_dedup_notice=1 and u_notice_with_sale=1 and d_cbo_dhcd_received_ta_reg=1;
  class ward2022 u_notice_date;   
  var all_notices;  
  table 
    /** Rows **/
    all="DC"    
    ward2022=" "  
    ,
    /** Columns **/
    all_notices=" " * sum=" " * 
    (
    all="Total"    
    u_notice_date=" "  
    ) 
  ;
  format u_notice_date year.;  
run;

proc odstext;
  p "Notes: Deduplicated notices with sales and a tenant association registration.";
run;


title3 "Table 4b. Residential Units in Properties With Tenant Association Registered by Ward and Year, 2006-2020";

proc tabulate data=TOPA_table_data format=comma12.0 noseps missing;
  where u_dedup_notice=1 and u_notice_with_sale=1 and d_cbo_dhcd_received_ta_reg=1;
  class ward2022 u_notice_date;   
  var u_final_units;  
  table 
    /** Rows **/
    all="DC"    
    ward2022=" "  
    ,
    /** Columns **/
    u_final_units=" " * sum=" " * 
    (
    all="Total"    
    u_notice_date=" "  
    ) 
  ;
  format u_notice_date year.;  
run;

proc odstext;
  p "Notes: Deduplicated notices with sales and a tenant association registration.";
run;


title3 "Table 4c. Properties With Tenant Association Registered by Year Built and Year, 2006-2020";

proc tabulate data=TOPA_table_data format=comma12.0 noseps missing;
  where u_dedup_notice=1 and u_notice_with_sale=1 and d_cbo_dhcd_received_ta_reg=1;
  class u_year_built_original /preloadfmt order=data;
  class u_notice_date;   
  var all_notices;  
  table 
    /** Rows **/
    all="Total"    
    u_year_built_original="\i By Year Built"  
    ,
    /** Columns **/
    all_notices=" " * sum=" " * 
    (
    all="Total"    
    u_notice_date=" "  
    ) 
    / printmiss
  ;
  format u_notice_date year. u_year_built_original year_built.;  
run;

proc odstext;
  p "Notes: Deduplicated notices with sales and a tenant association registration.";
run;


title3 "Table 4d. Residential Units in Properties With Tenant Association Registered by Year Built and Year, 2006-2020";

proc tabulate data=TOPA_table_data format=comma12.0 noseps missing;
  where u_dedup_notice=1 and u_notice_with_sale=1 and d_cbo_dhcd_received_ta_reg=1;
  class u_year_built_original /preloadfmt order=data;
  class u_notice_date;   
  var u_final_units;  
  table 
    /** Rows **/
    all="Total"    
    u_year_built_original="\i By Year Built"  
    ,
    /** Columns **/
    u_final_units=" " * sum=" " * 
    (
    all="Total"    
    u_notice_date=" "  
    )  
    / printmiss
  ;
  format u_notice_date year. u_year_built_original year_built.;  
run;

proc odstext;
  p "Notes: Deduplicated notices with sales and a tenant association registration.";
run;


title3 "Table 5a. Properties With TOPA Notices That Sold by Ward and Year, 2006-2020";

proc tabulate data=TOPA_table_data format=comma12.0 noseps missing;
  where u_dedup_notice=1;
  class ward2022 u_notice_date;   
  var u_notice_with_sale ;  
  table 
    /** Rows **/
    all="DC"    
    ward2022=" "  
    ,
    /** Columns **/
    u_notice_with_sale=" " * sum=" " * 
    (
    all="Total"    
    u_notice_date=" "  
    ) 
  ;
  format u_notice_date year.;  
run;

proc odstext;
  p "Notes: Deduplicated notices with sales.";
run;


%MACRO SKIP;
** 4b. Table Deduplicated notices resulting in a property sale (count) by Neighborhood Cluster and Year**;
proc tabulate data=TOPA_table_data format=comma12.0 noseps missing;
  where u_dedup_notice=1;
  class cluster2017 u_notice_date;   
  var u_notice_with_sale ;  
  table 
    /** Rows **/
    all="DC"    
    cluster2017=" "  
    ,
    /** Columns **/
    u_notice_with_sale=" " * sum=" " * 
    (
    all="Total"    
    u_notice_date=" "  
    ) 
  ;
  format u_notice_date year.;  
  title2 " ";
  title3 "4b. Properties With TOPA Notices That Sold by Neighborhood Cluster and Year, 2006-2020";
run;
%MEND SKIP;


title3 "Table 6a. Percentage of Properties With TOPA Notices That Sold by Ward and Year, 2006-2020";

proc tabulate data=TOPA_table_data format=comma12.0 noseps missing;
  where u_dedup_notice=1;
  class ward2022 u_notice_date;   
  var all_notices u_notice_with_sale;  
  table 
    /** Rows **/
    all_notices="Total notices" * sum=" "
    u_notice_with_sale=" " * mean=" " * (
      all="DC"    
      ward2022=" "  
    ) * f=percent10.0
    ,
    /** Columns **/
    all="Total"    
    u_notice_date=" "  
  ;
  format u_notice_date year.;  
run;

proc odstext;
  p "Notes: Deduplicated notices, with and without sales.";
run;


title3 "Table 6b. Percentage of Properties With TOPA Notices That Sold by Neighborhood Cluster and Year, 2006-2020";

proc tabulate data=TOPA_table_data format=comma12.0 noseps missing;
  where u_dedup_notice=1;
  class cluster2017 u_notice_date;   
  var all_notices u_notice_with_sale;  
  table 
    /** Rows **/
    all_notices="Total notices" * sum=" "
    u_notice_with_sale=" " * mean=" " * (
      all="DC"    
      cluster2017=" "  
    ) * f=percent10.0
    ,
    /** Columns **/
    all="Total"    
    u_notice_date=" "  
  ;
  format u_notice_date year. ;  
run;

proc odstext;
  p "Notes: Deduplicated notices, with and without sales.";
run;


title3 "Table 7a. Residential Units in Properties With TOPA Notices That Sold by Ward and Year, 2006-2020";

proc tabulate data=TOPA_table_data format=comma12.0 noseps missing;
  where u_dedup_notice=1 and u_notice_with_sale=1;
  class ward2022 u_notice_date;   
  var u_final_units;  
  table 
    /** Rows **/
    all="DC"    
    ward2022=" "  
    ,
    /** Columns **/
    u_final_units=" " * sum=" " * 
    (
    all="Total"    
    u_notice_date=" "  
    ) 
  ;
  format u_notice_date year.;  
run;

proc odstext;
  p "Notes: Deduplicated notices with sales.";
run;


title3 "Table 7b. Residential Units in Properties With TOPA Notices That Sold by Neighborhood Cluster and Year, 2006-2020";

proc tabulate data=TOPA_table_data format=comma12.0 noseps missing;
  where u_dedup_notice=1 and u_notice_with_sale=1;
  class cluster2017 u_notice_date;   
  var u_final_units ;  
  table 
    /** Rows **/
    all="DC"    
    cluster2017=" "  
    ,
    /** Columns **/
    u_final_units=" " * sum=" " * 
    (
    all="Total"    
    u_notice_date=" "  
    ) 
  ;
  format u_notice_date year.;  
run;

proc odstext;
  p "Notes: Deduplicated notices with sales.";
run;


title3 "Table 8a. Properties Where Tenants Assigned Rights by Ward and Year, 2006-2020";

proc tabulate data=TOPA_table_data format=comma12.0 noseps missing;
  where u_dedup_notice=1 and u_notice_with_sale=1 and d_ta_assign_rights=1;
  class ward2022 u_notice_date;   
  var all_notices;  
  table 
    /** Rows **/
    all="DC"    
    ward2022=" "  
    ,
    /** Columns **/
    all_notices=" " * sum=" " * 
    (
    all="Total"    
    u_notice_date=" "  
    ) 
  ;
  format u_notice_date year.;  
run;

proc odstext;
  p "Notes: Deduplicated notices with sales where tenants assigned rights.";
run;


title3 "Table 8b. Residential Units in Properties Where Tenants Assigned Rights by Ward and Year, 2006-2020";

proc tabulate data=TOPA_table_data format=comma12.0 noseps missing;
  where u_dedup_notice=1 and u_notice_with_sale=1 and d_ta_assign_rights=1;
  class ward2022 u_notice_date;   
  var u_final_units;  
  table 
    /** Rows **/
    all="DC"    
    ward2022=" "  
    ,
    /** Columns **/
    u_final_units=" " * sum=" " * 
    (
    all="Total"    
    u_notice_date=" "  
    ) 
  ;
  format u_notice_date year.;  
run;

proc odstext;
  p "Notes: Deduplicated notices with sales where tenants assigned rights.";
run;



title2;
footnote1;

ods rtf close;
ods listing;



