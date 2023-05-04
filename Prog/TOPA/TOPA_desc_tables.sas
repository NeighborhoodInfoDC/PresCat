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

%File_info( data=PresCat.TOPA_addresses, printobs=5 )
%File_info( data=PresCat.TOPA_notices_sales, printobs=5 ) 

** Sum residential units by address_id **;
proc sort data=PresCat.TOPA_addresses; 
  by id; 
run; 

proc summary data=PresCat.TOPA_addresses
 noprint;
 var ACTIVE_RES_OCCUPANCY_COUNT;
 class id;
 output out=TOPA_sum_units (drop=_:)
	sum=sum_units;
run;

** Merge summed dataset above with TOPA_notices_sales **;
data TOPA_data_merge;
  merge TOPA_sum_units PresCat.TOPA_notices_sales;
  by id;
run;

data TOPA_table_data; 
  set TOPA_data_merge; 
  where u_notice_date between '01Jan2006'd and '31dec2020'd;  /** Limit notice data to 2006-2020 **/
  all_notices=1; label all_notices = "Every notice (including duplicates)";
run;

%File_info( data=TOPA_table_data)

** Printing Descriptive Tables **;
options nodate nonumber;
options orientation=landscape;

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
  class ward2022 u_notice_date;   
  var sum_units;  
  table 
    /** Rows **/
    all="DC"    
    ward2022=" "  
    ,
    /** Columns **/
    sum_units=" " * sum=" " * 
    (
    all="Total"    
    u_notice_date=" "  
    ) 
  ;
  format u_notice_date year.;  
  title2 " ";
  title3 "3a. Residential Units in Properties with TOPA Notices of Sale by Ward and Year, 2006-2020";
run;

** 3b. Table Residential Units by Neighborhood Cluster and Year**;
proc tabulate data=TOPA_table_data format=comma12.0 noseps missing;
  class cluster2017 u_notice_date;   
  var sum_units;  
  table 
    /** Rows **/
    all="DC"    
    cluster2017=" "  
    ,
    /** Columns **/
    sum_units=" " * sum=" " * 
    (
    all="Total"    
    u_notice_date=" "  
    ) 
  ;
  format u_notice_date year.;  
  title2 " ";
  title3 "3b. Residential Units in Properties with TOPA Notices of Sale by Neighborhood Cluster and Year, 2006-2020";
run;

title2;
footnote1;

ods rtf close;
ods listing;
