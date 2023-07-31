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

*************************************************************************
** Export SSL/address data for IDs **;
/*ods tagsets.excelxp   /** Open the excelxp destination **/*/
/*  file="&_dcdata_default_path\PresCat\Prog\TOPA\TOPA_IDs_316_753_754.xls"  /** This is where the output will go **/*/
/*  style=Normal    /** This is the ODS style that will be used in the workbook **/*/
/*  options( sheet_interval='proc' )   /** This creates a new worksheet for every proc print in the output **/*/
/*;*/
/**/
/*ods listing close;  /** Close the regular listing destination **/*/
/**/
/*ods tagsets.excelxp options(sheet_name="By addresses");*/
/*proc print label data=PresCat.Topa_addresses;*/
/*  by id;*/
/*  id id;*/
/*  var address_id FULLADDRESS ACTIVE_RES_OCCUPANCY_COUNT;*/
/*  where id in ( 316 753 754 );*/
/*run;*/
/**/
/*ods tagsets.excelxp options(sheet_name="By real property");*/
/*proc print label data=PresCat.TOPA_realprop;*/
/*  by id;*/
/*  id id;*/
/*  var ssl saledate saleprice ownername_full;*/
/*  where id in ( 316 753 754 );*/
/*run;*/
/**/
/*ods tagsets.excelxp close;  /** Close the excelxp destination **/*/
/*ods listing;   /** Reopen the listing destination **/*/
*************************************************************************

** Final edits before creating tables **;
data TOPA_table_data; 
  set PresCat.TOPA_notices_sales; 
  where u_notice_date between '01Jan2006'd and '31dec2020'd;  /** Limit notice data to 2006-2020 **/
  all_notices=1; label all_notices = "Every notice (including duplicates)"; 
run;

%File_info( data=TOPA_table_data)

** Comparing # of units from MAR addresses to CNHED TOPA database **;
data TOPA_unit_check; 
  merge 
	PresCat.TOPA_database
	TOPA_table_data; 
  by id; 
run;

proc sort data=TOPA_unit_check;
  by Ward2022 id;
run;

/*title2 'PresCat.TOPA_addresses';*/
/*proc print data=PresCat.TOPA_addresses;*/
/*  var id FULLADDRESS ACTIVE_RES_OCCUPANCY_COUNT address_id; */
/*  where id in ( 316 336 753 754 862 1260 );*/
/*run;*/
/**/
/*title2 'TOPA_unit_check';*/
/*proc print data=TOPA_unit_check;*/
/*  var id Units u_final_units Ward2022; */
/*  where id in ( 316 336 753 754 862 1260 );*/
/*run;*/
/**/
/*title2 'PresCat.Topa_realprop';*/
/*proc print data=PresCat.Topa_realprop;*/
/*  by id;*/
/*  id id;*/
/*  var ssl saledate saleprice ownername_full;*/
/*  where id in ( 316 336 753 754 862 1260 );*/
/*run;*/
/*title2;*/

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

%fdate()

ods listing close;
ods rtf file="&_dcdata_default_path\Prescat\Prog\Topa\TOPA_desc_tables.rtf" style=Styles.Rtf_lato_9pt;

footnote1 height=9pt "Prepared by Urban-Greater DC (greaterdc.urban.org), &fdate..";
footnote2 height=9pt j=r '{Page}\~{\field{\*\fldinst{\pard\b\i0\chcbpat8\qc\f1\fs19\cf1{PAGE }\cf0\chcbpat0}}}';

** 1a. Table All Notices by Ward and Year **;
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
  title2 " ";
  title3 "1a. TOPA Notices of Sale (With Duplicates) by Ward and Year, 2006-2020";
run;


** 1b. Table All Notices by Neighborhood Cluster and Year **;
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
  title2 " ";
  title3 "1b. TOPA Notices of Sale (With Duplicates) by Neighborhood Cluster and Year, 2006-2020";
run;

** 2a. Table Deduplicated by Ward and Year **;
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
  title2 " ";
  title3 "2a. TOPA Notices of Sale (Deduplicated) by Ward and Year, 2006-2020";
run;

** 2b. Table Deduplicated by Neighborhood Cluster and Year **;
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
  title2 " ";
  title3 "2b. TOPA Notices of Sale (Deduplicated) by Neighborhood Cluster and Year, 2006-2020";
run;

** 3a. Table Residential Units by Ward and Year**;
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
  title2 " ";
  title3 "3a. Residential Units in Properties with TOPA Notices of Sale (Deduplicated) by Ward and Year, 2006-2020";
run;

** 3b. Table Residential Units by Neighborhood Cluster and Year**;
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
  title2 " ";
  title3 "3b. Residential Units in Properties with TOPA Notices of Sale (Deduplicated) by Neighborhood Cluster and Year, 2006-2020";
run;

** 4a. Table Deduplicated notices resulting in a property sale (count) by Ward and Year**;
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
  title2 " ";
  title3 "4a. Properties with TOPA Notices that Sold by Ward and Year, 2006-2020";
run;

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
  title3 "4b. Properties with TOPA Notices that Sold by Neighborhood Cluster and Year, 2006-2020";
run;

** 5a. Table Deduplicated notices resulting in a property sale (percentage) by Ward and Year**;

proc tabulate data=TOPA_table_data format=percent10.0 noseps missing;
  where u_dedup_notice=1;
  class ward2022 u_notice_date;   
  var u_notice_with_sale ;  
  table 
    /** Rows **/
    all="DC"    
    ward2022=" "  
    ,
    /** Columns **/
    u_notice_with_sale=" " * mean=" " *
    (
    all="Total"    
    u_notice_date=" "  
    ) 
  ;
  format u_notice_date year.;  
  title2 " ";
  title3 "5a. Percentage of Properties with TOPA Notices that Sold by Ward and Year, 2006-2020";
run;

** 5b. Table Deduplicated notices resulting in a property sale (percentage) by Neighborhood Cluster and Year**;

proc tabulate data=TOPA_table_data format=percent10.0 noseps missing;
  where u_dedup_notice=1;
  class cluster2017 u_notice_date;   
  var u_notice_with_sale ;  
  table 
    /** Rows **/
    all="DC"    
    cluster2017=" "  
    ,
    /** Columns **/
    u_notice_with_sale=" " * mean=" " *
    (
    all="Total"    
    u_notice_date=" "  
    ) 
  ;
  format u_notice_date year. ;  
  title2 " ";
  title3 "5b. Percentage of Properties with TOPA Notices that Sold by Neighborhood Cluster and Year, 2006-2020";
run;

** 6a. Table Residential Units that sold by Ward and Year**;
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
  title2 " ";
  title3 "6a. Residential Units in Properties with TOPA Notices that Sold by Ward and Year, 2006-2020";
run;

** 6b. Table Residential Units that sold by Ward and Year by Neighborhood Cluster and Year**;
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
  title2 " ";
  title3 "6b. Residential Units in Properties with TOPA Notices that Sold by Neighborhood Cluster and Year, 2006-2020";
run;

title2;
footnote1;

ods rtf close;
ods listing;



