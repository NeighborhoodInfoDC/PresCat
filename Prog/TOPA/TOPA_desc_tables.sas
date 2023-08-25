/**************************************************************************
 Program:  TOPA_match_notices_property.sas
 Library:  PresCat
 Project:  Urban-Greater DC
 Author:   Elizabeth Burton
 Created:  4/27/2023
 Version:  SAS 9.4
 Environment:  Local Windows session (desktop)
 
 Description:  Create basic descriptive tables for TOPA evaluation
 
 Saves these outputs in Prog\TOPA:
   TOPA_desc_tables.rtf - Summary tables in Word format (need to create TOC by opening doc and typing ctrl-A, F9)
   TOPA_afford_list.xls - List of 15+ unit TOPA properties with affordability added or preserved
   TOPA_outcome_summary.xls - Summary crosstabulation of key outcome variables for diagnostics
   
 Saves these outputs in Raw\TOPA:
   TOPA_table_data.csv - Export of all data used for producing summary tables in CSV format
   TOPA_table_data_dictionary.xls - Data dictionary for TOPA_table_data.csv
   
 Modifications:
**************************************************************************/

%include "\\sas1\DCdata\SAS\Inc\StdLocal.sas";

** Define libraries **;
%DCData_lib( PresCat )
%DCData_lib( Realprop )

/*
%File_info( data=PresCat.TOPA_addresses, printobs=5 ) 
%File_info( data=PresCat.TOPA_realprop, printobs=5 ) 
%File_info( data=PresCat.TOPA_notices_sales, printobs=5 ) 
%File_info( data=PresCat.TOPA_database, printobs=5 ) 
*/

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
  value dyesonly
    1 = 'Yes'
    other = ' ';
  value $buyout (notsorted)
    '100.00%' = '100%'
    'Partial/Option' = 'Partial/Option'
    'None' = 'None';
  value day_range
    low -< 0 = '(negative)'
    0 -< 45 = 'Less than 45 days'
    45 -< 90 = '45 to 89 days'
    90 -< 180 = '90 to 179 days'
    180 -< 360 = '180 to 359 days'
    360 -< 420 = '360 to 419 days'
    420 -< 540 = '420 to 539 days'
    540 - high = '540 days or more';  
run;


** Combine data and final edits before creating tables **;
** N = 1455 notices **;
data TOPA_table_data;
  
  merge 
    PresCat.TOPA_notices_sales 
      (in=in1 
       keep=id u_dedup_notice u_notice_with_sale fulladdress ward2022 cluster2017 u_actual_saledate u_address_id_ref
            u_days_from_dedup_notice_to_sale u_final_units u_notice_date u_sale_date u_ownercat u_ownername u_proptype
            u_year_built_original u_recent_reno x y)
    PresCat.TOPA_CBO_sheet (keep=id cbo_dhcd_received_ta_reg ta_assign_rights r_ta_provider u_has_cbo_outcome outcome_:)
    PresCat.topa_subsidies (keep=id before_: after_:)
    PresCat.topa_database (keep=id All_street_addresses Property_name); 
  by id;

  if in1 and '01Jan2006'd <= u_notice_date <= '31dec2020'd;  /** Limit notice data to 2006-2020 **/
  
  ** Analysis variables **;
  
  all_notices=1;  
  
  if lowcase( cbo_dhcd_received_ta_reg ) = 'yes' then d_cbo_dhcd_received_ta_reg = 1;
  else if lowcase( cbo_dhcd_received_ta_reg ) = 'no' then d_cbo_dhcd_received_ta_reg = 0;
  
  if lowcase( ta_assign_rights ) = 'yes' then d_ta_assign_rights = 1;
  else if lowcase( ta_assign_rights ) = 'no' then d_ta_assign_rights = 0;
  
  ** NOTE: Only use CBO designated LEC's **;
  if lowcase( outcome_homeowner ) in ( 'le coop' ) then d_le_coop = 1;
  else d_le_coop = 0;
  
  if lowcase( outcome_homeowner ) in ( 'le coop', 'condo' ) then d_purch_condo_coop = 1;
  else d_purch_condo_coop = 0;
  
  if d_purch_condo_coop = 0 and u_proptype = '11' then d_other_condo = 1;
  else d_other_condo = 0;
  
  if after_LIHTC_aff_units > 0 or lowcase( outcome_assign_LIHTC ) in ( 'yes' ) then d_lihtc = 1;
  else d_lihtc = 0;
  
  if after_fed_aff_units > 0 or lowcase( outcome_assign_section8 ) in: ( 'yes', 'added', 'lrsp added' ) then d_fed_aff = 1;
  else d_fed_aff = 0;
  
  if lowcase( outcome_rent_assign_rc_cont ) =: 'y' or lowcase( outcome_assign_rc_nopet ) in: ( 'y', 'added' ) then d_rent_control = 1;
  else d_rent_control = 0;
  
  if d_lihtc=1 or d_fed_aff=1 or d_rent_control=1 or d_le_coop=1 then d_affordable = 1;
  else d_affordable = 0;
  
  if lowcase( outcome_100pct_afford ) in: ( 'y', 'a' ) then d_100pct_afford = 1;
  else d_100pct_afford = 0;
  
  if lowcase( outcome_rehab ) = 'yes' then d_rehab = 1;
  else d_rehab = 0;
  
  if not( lowcase( r_ta_provider ) in ( '', 'none' ) ) then d_cbo_involved = 1;
  else d_cbo_involved = 0;
    
  label
    all_notices = "Notices"
    d_cbo_dhcd_received_ta_reg = "Tenant association registered"
    d_ta_assign_rights = "Tenants assigned rights"
    d_le_coop = "Limited equity coop" 
    d_purch_condo_coop = "Tenant homeownership: LE Coop or Condo"
    d_other_condo = "Other condos (not tenant homeownership)"
    d_lihtc = "LIHTC added or preserved"
    d_fed_aff = "Section 8 or other federal project-based added or preserved"
    d_rent_control = "Rent control preserved"
    d_affordable = "Affordability added or preserved"
    d_100pct_afford = "100% affordable"
    d_rehab = "Renovations or repairs for residents in development agreement"
    d_cbo_involved = "Properties with CBO involvement"
  ;
  
  format
    d_cbo_dhcd_received_ta_reg d_ta_assign_rights d_cbo_involved d_rehab
    d_affordable d_100pct_afford d_purch_condo_coop d_le_coop d_lihtc d_fed_aff d_rent_control d_other_condo dyesno.;

  ** CLEANING manual edits to take out notice dates or saledates (and relevant vars) from Farah **; 

  if id in (
	  106, 134, 224, 381, 410, 489, 349
	) then do;
  u_notice_date =.;
  u_days_from_dedup_notice_to_sale=.;
  end;

  if id in (
	  766, 850
	) then do;
  u_sale_date =.;
  u_days_from_dedup_notice_to_sale=.;
  u_actual_saledate=.;
  end;

run;

%File_info( data=TOPA_table_data, printobs=0 )

** Outcome diagnostic summary **;

proc summary data=TOPA_table_data nway;
  where u_dedup_notice=1 and u_notice_with_sale=1;
  class 
    cbo_dhcd_received_ta_reg d_cbo_involved d_affordable d_100pct_afford d_purch_condo_coop d_le_coop d_lihtc d_fed_aff d_rent_control d_other_condo;
  var all_notices u_final_units;
  output out=TOPA_outcome_summary (drop=_type_ _freq_) sum=;
run;

ods tagsets.excelxp file="&_dcdata_default_path\Prescat\Prog\Topa\TOPA_outcome_summary.xls" style=Normal options(sheet_interval='Bygroup' );
ods listing close;

ods tagsets.excelxp options( absolute_column_width="16");
ods tagsets.excelxp options( sheet_name="Outcome summary" );

proc print data=TOPA_outcome_summary label noobs;
  sum all_notices u_final_units;
  label u_final_units = "Units";
run;

ods tagsets.excelxp close;
ods listing;


** Export list of projects/units affordability was added/preserved for appendix **;

proc sort data=TOPA_table_data;
  by ward2022 u_notice_date fulladdress;
run;

ods tagsets.excelxp file="&_dcdata_default_path\Prescat\Prog\Topa\TOPA_afford_list.xls" style=Normal options(sheet_interval='Bygroup' );
ods listing close;

options nobyline;

ods tagsets.excelxp options( absolute_column_width="16,16,32,32,16,16,16,16,16");

proc print data=TOPA_table_data label noobs;
  where u_dedup_notice=1 and u_notice_with_sale=1 and d_affordable=1;
  by ward2022;
  var u_notice_date u_sale_date fulladdress property_name u_final_units d_lihtc d_fed_aff d_rent_control d_le_coop;
  format d_lihtc d_fed_aff d_rent_control d_le_coop dyesonly.;
  label
    u_notice_date = "Notice date"
    u_sale_date = "Sale date (may be approximate)"
    fulladdress = "Reference address (property may include other addresses)"
    u_final_units = "Total units";
run;

ods tagsets.excelxp close;
ods listing;

options byline;


/** Macro Count_table - Start Definition **/

%macro Count_table( 
  table_num=, title=, title_prefix=, where=, row_var=ward2022, col_var=u_notice_date, row_var_fmt=, col_var_fmt=year.,
  row_var_label=' ', col_var_label=' ', notes=, notes2=,
  analysis_var=all_notices, table_fmt=comma12.0, analysis_stat=sum
  );
  
  %local full_table_title;

  ods rtf startpage=now;
  
  %let full_table_title = Table &table_num.a. %left(%trim(&title_prefix)) %left(&title);
  
  title3 "&full_table_title";
  
  ods rtf text = "^S={outputwidth=100% just=l} {\tc\f3\fs0\cf8 &full_table_title}"; 

  proc tabulate data=TOPA_table_data format=&table_fmt noseps missing;
    where &where;
    class &row_var / preloadfmt order=data;   
    class &col_var;   
    var &analysis_var;
    table 
      /** Rows **/
      all="Total"
      &row_var=&row_var_label  
      ,
      /** Columns **/
      &analysis_var=" " * &analysis_stat=" " * 
      (
      all="Total"    
      &col_var=&col_var_label
      ) 
    ;
    %if %length( &col_var_fmt ) > 0 %then %do;
      format &col_var &col_var_fmt;  
    %end;
    %if %length( &row_var_fmt ) > 0 %then %do;
      format &row_var &row_var_fmt;  
    %end;
  run;

  proc odstext;
    p "Notes: %left(&notes)";
    p "%left(&notes2)";
  run;


  ods rtf startpage=now;
  
  %let full_table_title = Table &table_num.b. %left(&title_prefix) Residential Units in %left(&title);
  
  title3 "&full_table_title";
  
  ods rtf text = "^S={outputwidth=100% just=l} {\tc\f3\fs0\cf8 &full_table_title}"; 

  proc tabulate data=TOPA_table_data format=&table_fmt noseps missing;
    where &where;
    class &row_var / preloadfmt order=data;   
    class &col_var;   
    var &analysis_var / weight=u_final_units;
    table 
      /** Rows **/
      all="Total"
      &row_var=&row_var_label  
      ,
      /** Columns **/
      &analysis_var=" " * &analysis_stat=" " * 
      (
      all="Total"    
      &col_var=&col_var_label
      ) 
    ;
    %if %length( &col_var_fmt ) > 0 %then %do;
      format &col_var &col_var_fmt;  
    %end;
    %if %length( &row_var_fmt ) > 0 %then %do;
      format &row_var &row_var_fmt;  
    %end;
  run;

  proc odstext;
    p "Notes: %left(&notes)";
    p "%left(&notes2)";
  run;

%mend Count_table;

/** End Macro Definition **/


** Printing Descriptive Tables **;
options nodate nonumber;
options orientation=landscape;
options missing='-';
ods escapechar = '^';

%fdate()

ods listing close;
ods rtf file="&_dcdata_default_path\Prescat\Prog\Topa\TOPA_desc_tables.rtf" style=Styles.Rtf_lato_9pt nokeepn /* notrkeep */ notoc_data startpage=off;
** removing notrkeep for my sas version **;

footnote1 height=9pt "Prepared by Urban-Greater DC (greaterdc.urban.org), &fdate..";
footnote2 height=9pt j=r '{Page}\~{\field{\*\fldinst{\pard\b\i0\chcbpat8\qc\f1\fs19\cf1{PAGE }\cf0\chcbpat0}}}';

** Table of contents **;

proc odstext;
  p "Table of Contents" /style=[font_weight=bold];
run;

ods rtf text = "^S={outputwidth=100% just=l}{\field{\*\fldinst {\\TOC \\f \\h}}}"; 

** Table specifications **;

%Count_table(
  table_num=1,
  title=%str( TOPA Notices of Sale (With Duplicates) by Ward and Year, 2006-2020 ),
  where=1,
  notes=%str( All notices, with and without sales. )
  )

%Count_table(
  table_num=2,
  title=%str( TOPA Notices of Sale (With Duplicates) by Neighborhood Cluster and Year, 2006-2020 ),
  row_var=cluster2017,
  where=1,
  notes=%str( All notices, with and without sales. )
  )

%Count_table(
  table_num=3,
  title=%str( TOPA Notices of Sale (Deduplicated) by Ward and Year, 2006-2020 ),
  where=u_dedup_notice=1,
  notes=%str( Deduplicated notices, with and without sales. )
  )

%Count_table(
  table_num=4,
  row_var=cluster2017,
  title=%str( TOPA Notices of Sale (Deduplicated) by Neighborhood Cluster and Year, 2006-2020 ),
  where=u_dedup_notice=1,
  notes=%str( Deduplicated notices, with and without sales. )
  )

%Count_table(
  table_num=5,
  title=%str( Properties With TOPA Notices That Sold by Ward and Year, 2006-2020 ),
  where=u_dedup_notice=1 and u_notice_with_sale=1,
  notes=%str( Deduplicated notices with sales. )
  )

%Count_table(
  table_num=6,
  row_var=cluster2017,
  title=%str( Properties With TOPA Notices That Sold by Neighborhood Cluster and Year, 2006-2020 ),
  where=u_dedup_notice=1 and u_notice_with_sale=1,
  notes=%str( Deduplicated notices with sales. )
  )


ods rtf startpage=now;

title3 "Table 7a. Percentage of Properties With TOPA Notices That Sold by Ward and Year, 2006-2020";

ods rtf text = "^S={outputwidth=100% just=l} {\tc\f3\fs0\cf8 Table 7a. Percentage of Properties With TOPA Notices That Sold by Ward and Year, 2006-2020}"; 

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


ods rtf startpage=now;

title3 "Table 7b. Percentage of Properties With TOPA Notices That Sold by Neighborhood Cluster and Year, 2006-2020";

ods rtf text = "^S={outputwidth=100% just=l} {\tc\f3\fs0\cf8 Table 7b. Percentage of Properties With TOPA Notices That Sold by Neighborhood Cluster and Year, 2006-2020}"; 

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


%Count_table(
  table_num=8,
  title=%str( Properties With Tenant Association Registered by Ward and Year, 2006-2020 ),
  where=u_dedup_notice=1 and u_notice_with_sale=1 and d_cbo_dhcd_received_ta_reg=1,
  notes=Deduplicated notices with sales and a tenant association registration.
  )

%Count_table(
  table_num=9,
  row_var=u_year_built_original,
  row_var_label="\i By year built",
  row_var_fmt=year_built.,
  title=%str( Properties With Tenant Association Registered by Year Built and Year, 2006-2020 ),
  where=u_dedup_notice=1 and u_notice_with_sale=1 and d_cbo_dhcd_received_ta_reg=1,
  notes=Deduplicated notices with sales and a tenant association registration.
  )

%Count_table(
  table_num=10,
  title=%str( Properties Where Tenants Assigned Rights by Ward and Year, 2006-2020 ),
  where=u_dedup_notice=1 and u_notice_with_sale=1 and d_ta_assign_rights=1,
  notes=Deduplicated notices with sales where tenants assigned rights.
  )

%Count_table(
  table_num=11,
  title=%str( Properties Where Tenants Purchased Coop/Condo by Ward and Year, 2006-2020 ),
  where=u_dedup_notice=1 and u_notice_with_sale=1 and d_purch_condo_coop=1,
  notes=Deduplicated notices with sales where tenants purchased coop/condo.
  )

%Count_table(
  table_num=12,
  title=%str( Condo Properties Without Tenant Purchase by Ward and Year, 2006-2020 ),
  where=u_dedup_notice=1 and u_notice_with_sale=1 and d_other_condo=1,
  notes=Deduplicated notices with sales and condo properties without tenant purchase.
  )

%Count_table(
  table_num=13,
  title=%str( Properties With Affordability Added or Preserved by Ward and Year, 2006-2020 ),
  where=u_dedup_notice=1 and u_notice_with_sale=1 and d_affordable=1,
  notes=Deduplicated notices with sales and affordability (LIHTC, Section 8 or other project-based, rent control, LE coop) added or preserved.
  )

%Count_table(
  table_num=14,
  title=%str( 15+ Unit Properties by Ward and Year, 2006-2020 ),
  where=u_dedup_notice=1 and u_notice_with_sale=1 and u_final_units >= 15,
  notes=Deduplicated notices for properties with 15+ units with sales.
  )

%Count_table(
  table_num=15,
  title=%str( 15+ Unit Properties With Affordability Added or Preserved by Ward and Year, 2006-2020 ),
  where=u_dedup_notice=1 and u_notice_with_sale=1 and d_affordable=1 and u_final_units >= 15,
  notes=%str( Deduplicated notices for properties with 15+ units with sales and affordability (LIHTC, Section 8 or other project-based, rent control, LE coop) added or preserved. )
  )

%Count_table(
  table_num=16,
  analysis_var=d_affordable,
  analysis_stat=mean,
  table_fmt=percent12.1,
  title=%str( 15+ Unit Properties With Affordability Added or Preserved by Ward and Year, 2006-2020 ),
  title_prefix=Percentage of,
  where=u_dedup_notice=1 and u_notice_with_sale=1 and u_final_units >= 15,
  notes=Deduplicated notices for properties with 15+ units with sales.
  )

%Count_table(
  table_num=17,
  title=%str( Properties With 100% Affordability by Ward and Year, 2006-2020 ),
  where=u_dedup_notice=1 and u_notice_with_sale=1 and d_100pct_afford=1,
  notes=Deduplicated notices with sales and 100% affordability (marked by CBOs).
  )

%Count_table(
  table_num=18,
  title=%str( Properties With Renovations or Repairs for Residents in Development Agreement by Ward and Year, 2006-2020 ),
  where=u_dedup_notice=1 and u_notice_with_sale=1 and d_rehab=1,
  notes=Deduplicated notices with sales and renovations or repairs for residents in development agreement.
  )

%Count_table(
  table_num=19,
  row_var=outcome_buyouts,
  row_var_label="\i With buyouts",
  row_var_fmt=$buyout.,
  title=%str( Properties With Buyouts by Ward and Year, 2006-2020 ),
  where=u_dedup_notice=1 and u_notice_with_sale=1 and not( missing( outcome_buyouts ) ),
  notes=Deduplicated notices with sales and renovations or repairs for residents in development agreement indicated by CBOs. (Unmarked notices omitted.)
  )

%Count_table(
  table_num=20,
  title=%str( Properties With CBO Involvement by Ward and Year, 2006-2020 ),
  where=u_dedup_notice=1 and u_notice_with_sale=1 and d_cbo_involved=1,
  notes=Deduplicated notices with sales and CBO involvement.
  )

** Count notices excluded because of TOPA tolling **;
proc sql noprint;
  select sum( all_notices ) into :topa_tolling_notices from TOPA_table_data
  where u_dedup_notice=1 and u_notice_with_sale=1 and u_actual_saledate=1 and ( '01mar2020'd <= u_sale_date < '01may2023'd ) and u_final_units >= 15;
quit;

%Count_table(
  table_num=21,
  row_var=u_days_from_dedup_notice_to_sale,
  row_var_label="\i Days from notice to sale",
  row_var_fmt=day_range.,
  title=%str( Properties With 15+ Units With Tenant Association Registered by Days from Notice to Sale by Ward and Year, 2006-2020* ),
  where=u_dedup_notice=1 and u_notice_with_sale=1 and d_cbo_dhcd_received_ta_reg=1 and u_actual_saledate=1 and not( '01mar2020'd <= u_sale_date < '01may2023'd ) and u_final_units >= 15,
  notes=%str( Deduplicated notices for properties with 15+ units that sold, with tenant association registered. ),
  notes2=%str( *Includes only notices with an actual sale date reported. Exludes %left(&topa_tolling_notices) notices with sales between March 2020 and April 2023 which were affected by TOPA tolling. )
)

%Count_table(
  table_num=22,
  row_var=u_days_from_dedup_notice_to_sale,
  row_var_label="\i Days from notice to sale",
  row_var_fmt=day_range.,
  title=%str( Properties With 15+ Units Without Tenant Association Registered by Days from Notice to Sale by Ward and Year, 2006-2020* ),
  where=u_dedup_notice=1 and u_notice_with_sale=1 and d_cbo_dhcd_received_ta_reg=0 and u_actual_saledate=1 and not( '01mar2020'd <= u_sale_date < '01may2023'd ) and u_final_units >= 15,
  notes=%str( Deduplicated notices for properties with 15+ units that sold, with tenant association registered. ),
  notes2=%str( *Includes only notices with an actual sale date reported. Exludes %left(&topa_tolling_notices) notices with sales between March 2020 and April 2023 that were affected by TOPA tolling. )
)


** Count notices excluded because of TOPA tolling **;
proc sql noprint;
  select sum( all_notices ) into :topa_tolling_notices from TOPA_table_data
  where u_dedup_notice=1 and u_notice_with_sale=1 and u_actual_saledate=1 and ( '01mar2020'd <= u_sale_date < '01may2023'd );
quit;

%Count_table(
  table_num=23,
  row_var=u_days_from_dedup_notice_to_sale,
  row_var_label="\i Days from notice to sale",
  row_var_fmt=day_range.,
  title=%str( Properties With Tenant Association Registered by Days from Notice to Sale by Ward and Year, 2006-2020* ),
  where=u_dedup_notice=1 and u_notice_with_sale=1 and d_cbo_dhcd_received_ta_reg=1 and u_actual_saledate=1 and not( '01mar2020'd <= u_sale_date < '01may2023'd ),
  notes=%str( Deduplicated notices for all properties that sold, with tenant association registered. ),
  notes2=%str( *Includes only notices with an actual sale date reported. Exludes %left(&topa_tolling_notices) notices with sales between March 2020 and April 2023 that were affected by TOPA tolling. )
)

%Count_table(
  table_num=24,
  row_var=u_days_from_dedup_notice_to_sale,
  row_var_label="\i Days from notice to sale",
  row_var_fmt=day_range.,
  title=%str( Properties Without Tenant Association Registered by Days from Notice to Sale by Ward and Year, 2006-2020* ),
  where=u_dedup_notice=1 and u_notice_with_sale=1 and d_cbo_dhcd_received_ta_reg=0 and u_actual_saledate=1 and not( '01mar2020'd <= u_sale_date < '01may2023'd ),
  notes=%str( Deduplicated notices for all properties that sold, with tenant association registered. ),
  notes2=%str( *Includes only notices with an actual sale date reported. Exludes %left(&topa_tolling_notices) notices with sales between March 2020 and April 2023 which were affected by TOPA tolling. )
)


%Count_table(
  table_num=25,
  title=%str( Properties With CBO Involvement and Affordability Added or Preserved by Ward and Year, 2006-2020 ),
  where=u_dedup_notice=1 and u_notice_with_sale=1 and d_cbo_involved=1 and d_affordable=1,
  notes=%str( Deduplicated notices with sales, CBO involvement, and affordability (LIHTC, Section 8 or other project-based, rent control, LE coop) added or preserved. )
  )

%Count_table(
  table_num=26,
  title=%str( Properties Where Tenants Assigned Rights and Affordability Added or Preserved by Ward and Year, 2006-2020 ),
  where=u_dedup_notice=1 and u_notice_with_sale=1 and d_ta_assign_rights=1 and d_affordable=1,
  notes=%str( Deduplicated notices with sales, tenants assigned rights, and affordability (LIHTC, Section 8 or other project-based, rent control, LE coop) added or preserved. )
  )

%Count_table(
  table_num=27,
  title=%str( Properties Where DHCD Received TA Registration and Affordability Added or Preserved by Ward and Year, 2006-2020 ),
  where=u_dedup_notice=1 and u_notice_with_sale=1 and d_cbo_dhcd_received_ta_reg=1 and d_affordable=1,
  notes=%str( Deduplicated notices with sales, TA registration, and affordability (LIHTC, Section 8 or other project-based, rent control, LE coop) added or preserved. )
  )

%Count_table(
  table_num=28,
  title=%str( Properties Where Tenants Purchased Coops by Ward and Year, 2006-2020 ),
  where=u_dedup_notice=1 and u_notice_with_sale=1 and d_le_coop=1, 
  notes=%str(Deduplicated notices with sales where tenants purchased coop.)
  )

%Count_table(
  table_num=29,
  title=%str( Properties Where Tenants Assigned their Rights or Purchased Coops by Ward and Year, 2006-2020 ),
  where=u_dedup_notice=1 and u_notice_with_sale=1 and d_le_coop=1 or d_ta_assign_rights=1,
  notes=%str(Deduplicated notices with sales where tenants assigned their rights or purchased coop.)
  )

title2;
footnote1;

ods rtf close;
ods listing;


** Export all table data **;

/** Macro Export - Start Definition **/

%macro Export( data=, out=, desc= );

  %local lib file;
  
  %if %scan( &data, 2, . ) = %then %do;
    %let lib = work;
    %let file = &data;
  %end;
  %else %do;
    %let lib = %scan( &data, 1, . );
    %let file = %scan( &data, 2, . );
  %end;

  %if &out = %then %let out = &file;
  
  %if %length( &desc ) = 0 %then %do;
    proc sql noprint;
      select memlabel into :desc from dictionary.tables
        where upcase(libname)=upcase("&lib") and upcase(memname)=upcase("&file");
      quit;
    run;
  %end;

  filename fexport "&out_folder\&out..csv" lrecl=2000;

  proc export data=&data
      outfile=fexport
      dbms=csv replace;

  run;
  
  filename fexport clear;

  proc contents data=&data out=_cnt_&out (keep=varnum name label label="&desc") noprint;

  proc sort data=_cnt_&out;
    by varnum;
  run;      
  
  %let file_list = &file_list &out;

%mend Export;

/** End Macro Definition **/


/** Macro Dictionary - Start Definition **/

%macro Dictionary( name=Data dictionary );

  %local desc;

  ** Start writing to XML workbook **;
    
  ods listing close;

  ods tagsets.excelxp file="&out_folder\&name..xls" style=Normal 
      options( sheet_interval='Proc' orientation='landscape' );

  ** Write data dictionaries for all files **;

  %local i k;

  %let i = 1;
  %let k = %scan( &file_list, &i, %str( ) );

  %do %until ( &k = );
   
    proc sql noprint;
      select memlabel into :desc from dictionary.tables
        where upcase(libname)="WORK" and upcase(memname)=upcase("_cnt_&k");
      quit;
    run;

    ods tagsets.excelxp 
        options( sheet_name="&k" 
                 embedded_titles='yes' embedded_footnotes='yes' 
                 embed_titles_once='yes' embed_footers_once='yes' );

    proc print data=_cnt_&k label;
      id varnum;
      var name label;
      label 
        varnum = 'Col #'
        name = 'Name'
        label = 'Description';
      title1 bold "Data dictionary for file: &k..csv";
      title2 bold "&desc";
      title3 height=10pt "Prepared by Urban-Greater DC on %left(%qsysfunc(date(),worddate.)).";
      footnote1;
    run;

    %let i = %eval( &i + 1 );
    %let k = %scan( &file_list, &i, %str( ) );

  %end;

  ** Close workbook **;

  ods tagsets.excelxp close;
  ods listing;

  run;
  
%mend Dictionary;

/** End Macro Definition **/


%global file_list out_folder;

options missing=' ';

** DO NOT CHANGE - This initializes the file_list macro variable **;
%let file_list = ;

** Fill in the folder location where the export files should be saved **;
%let out_folder = &_dcdata_default_path\PresCat\Raw\TOPA;

** Export individual data sets **;
%Export( data=TOPA_table_data, desc=%str(Data for final TOPA study tables) )

** Create data dictionary **;
%Dictionary( name=TOPA_table_data_dictionary )


