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

/*
%File_info( data=PresCat.TOPA_addresses, printobs=5 ) 
%File_info( data=PresCat.TOPA_realprop, printobs=5 ) 
%File_info( data=PresCat.TOPA_notices_sales, printobs=5 ) 
%File_info( data=PresCat.TOPA_database, printobs=5 ) 
*/

** Combine data and final edits before creating tables **;
** N = 1455 notices **;
data TOPA_table_data;
  
  merge 
    PresCat.TOPA_notices_sales (in=in1)
    PresCat.TOPA_CBO_sheet (keep=id cbo_dhcd_received_ta_reg ta_assign_rights u_has_cbo_outcome outcome_:)
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
  
  if lowcase( outcome_homeowner ) in ( 'le coop' ) then d_le_coop = 1;
  else d_le_coop = 0;
  
  if after_lec_aff_units > 0 or lowcase( outcome_homeowner ) in ( 'le coop', 'condo' ) then d_purch_condo_coop = 1;
  else d_purch_condo_coop = 0;
  
  if d_purch_condo_coop = 0 and u_proptype = '11' then d_other_condo = 1;
  else d_other_condo = 0;
  
  if after_LIHTC_aff_units > 0 or lowcase( outcome_assign_LIHTC ) in ( 'yes' ) or 
     after_fed_aff_units > 0 or not( lowcase( outcome_assign_section8 ) in ( 'yes', '' ) ) or
     outcome_rent_assign_rc_cont =: 'y' or outcome_assign_rc_nopet =: 'y' or
     d_le_coop then d_affordable = 1;
  else d_affordable = 0;
  
  if lowcase( outcome_100pct_afford ) in: ( 'y', 'a' ) then d_100pct_afford = 1;
  else d_100pct_afford = 0;
  
  if lowcase( outcome_rehab ) = 'yes' then d_rehab = 1;
  else d_rehab = 0;
    
  label
    all_notices = "Every notice (including duplicates)"
    d_cbo_dhcd_received_ta_reg = "Tenant association registered"
    d_ta_assign_rights = "Tenants assigned rights"
    d_le_coop = "Limited equity coop" 
    d_purch_condo_coop = "Tenant homeownership: LE Coop or Condo"
    d_other_condo = "Other condos (not tenant homeownership)"
    d_affordable = "Affordability added or preserved"
    d_100pct_afford = "100% affordable"
    d_rehab = "Renovations or repairs for residents in development agreement"
  ;
  
run;

%File_info( data=TOPA_table_data, printobs=0 )


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
ods rtf file="&_dcdata_default_path\Prescat\Prog\Topa\TOPA_desc_tables.rtf" style=Styles.Rtf_lato_9pt nokeepn notrkeep notoc_data startpage=off;

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
  title=%str( Condo Properties Without Tenant Purchase, 2006-2020 ),
  where=u_dedup_notice=1 and u_notice_with_sale=1 and d_other_condo=1,
  notes=Deduplicated notices with sales and condo properties without tenant purchase.
  )

%Count_table(
  table_num=13,
  title=%str( Properties With Affordability Added or Preserved, 2006-2020 ),
  where=u_dedup_notice=1 and u_notice_with_sale=1 and d_affordable=1,
  notes=Deduplicated notices with sales and affordability (LIHTC, Section 8 or other project-based, rent control, LE coop) added or preserved.
  )

%Count_table(
  table_num=14,
  title=%str( 15+ Unit Properties, 2006-2020 ),
  where=u_dedup_notice=1 and u_notice_with_sale=1 and u_final_units >= 15,
  notes=Deduplicated notices for properties with 15+ units with sales.
  )

%Count_table(
  table_num=15,
  title=%str( 15+ Unit Properties With Affordability Added or Preserved, 2006-2020 ),
  where=u_dedup_notice=1 and u_notice_with_sale=1 and d_affordable=1 and u_final_units >= 15,
  notes=%str( Deduplicated notices for properties with 15+ units with sales and affordability (LIHTC, Section 8 or other project-based, rent control, LE coop) added or preserved. )
  )

%Count_table(
  table_num=16,
  analysis_var=d_affordable,
  analysis_stat=mean,
  table_fmt=percent12.1,
  title=%str( 15+ Unit Properties With Affordability Added or Preserved, 2006-2020 ),
  title_prefix=Percentage of,
  where=u_dedup_notice=1 and u_notice_with_sale=1 and u_final_units >= 15,
  notes=Deduplicated notices for properties with 15+ units with sales.
  )

%Count_table(
  table_num=17,
  title=%str( Properties With 100% Affordability, 2006-2020 ),
  where=u_dedup_notice=1 and u_notice_with_sale=1 and d_100pct_afford=1,
  notes=Deduplicated notices with sales and 100% affordability (marked by CBOs).
  )

%Count_table(
  table_num=18,
  title=%str( Properties With Renovations or Repairs for Residents in Development Agreement, 2006-2020 ),
  where=u_dedup_notice=1 and u_notice_with_sale=1 and d_rehab=1,
  notes=Deduplicated notices with sales and renovations or repairs for residents in development agreement.
  )

%Count_table(
  table_num=19,
  row_var=outcome_buyouts,
  row_var_label="\i With buyouts",
  row_var_fmt=$buyout.,
  title=%str( Properties With Buyouts, 2006-2020 ),
  where=u_dedup_notice=1 and u_notice_with_sale=1 and not( missing( outcome_buyouts ) ),
  notes=Deduplicated notices with sales and renovations or repairs for residents in development agreement indicated by CBOs. (Unmarked notices omitted.)
  )

** Count notices excluded because of TOPA tolling **;
proc sql noprint;
  select sum( all_notices ) into :topa_tolling_notices from TOPA_table_data
  where u_dedup_notice=1 and u_notice_with_sale=1 and u_actual_saledate=1 and ( '01mar2020'd <= u_sale_date < '01may2023'd ) and u_final_units >= 15;
quit;

%Count_table(
  table_num=20,
  row_var=u_days_from_dedup_notice_to_sale,
  row_var_label="\i Days from notice to sale",
  row_var_fmt=day_range.,
  title=%str( Properties With 15+ Units With Tenant Association Registered by Days from Notice to Sale, 2006-2020* ),
  where=u_dedup_notice=1 and u_notice_with_sale=1 and d_cbo_dhcd_received_ta_reg=1 and u_actual_saledate=1 and not( '01mar2020'd <= u_sale_date < '01may2023'd ) and u_final_units >= 15,
  notes=%str( Deduplicated notices for properties with 15+ units that sold, with tenant association registered. ),
  notes2=%str( *Includes only notices with an actual sale date reported. Exludes %left(&topa_tolling_notices) notices with sales between March 2020 and April 2023 which were affected by TOPA tolling. )
)

%Count_table(
  table_num=21,
  row_var=u_days_from_dedup_notice_to_sale,
  row_var_label="\i Days from notice to sale",
  row_var_fmt=day_range.,
  title=%str( Properties With 15+ Units Without Tenant Association Registered by Days from Notice to Sale, 2006-2020* ),
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
  table_num=22,
  row_var=u_days_from_dedup_notice_to_sale,
  row_var_label="\i Days from notice to sale",
  row_var_fmt=day_range.,
  title=%str( Properties With Tenant Association Registered by Days from Notice to Sale, 2006-2020* ),
  where=u_dedup_notice=1 and u_notice_with_sale=1 and d_cbo_dhcd_received_ta_reg=1 and u_actual_saledate=1 and not( '01mar2020'd <= u_sale_date < '01may2023'd ),
  notes=%str( Deduplicated notices for all properties that sold, with tenant association registered. ),
  notes2=%str( *Includes only notices with an actual sale date reported. Exludes %left(&topa_tolling_notices) notices with sales between March 2020 and April 2023 that were affected by TOPA tolling. )
)

%Count_table(
  table_num=23,
  row_var=u_days_from_dedup_notice_to_sale,
  row_var_label="\i Days from notice to sale",
  row_var_fmt=day_range.,
  title=%str( Properties Without Tenant Association Registered by Days from Notice to Sale, 2006-2020* ),
  where=u_dedup_notice=1 and u_notice_with_sale=1 and d_cbo_dhcd_received_ta_reg=0 and u_actual_saledate=1 and not( '01mar2020'd <= u_sale_date < '01may2023'd ),
  notes=%str( Deduplicated notices for all properties that sold, with tenant association registered. ),
  notes2=%str( *Includes only notices with an actual sale date reported. Exludes %left(&topa_tolling_notices) notices with sales between March 2020 and April 2023 which were affected by TOPA tolling. )
)


title2;
footnote1;

ods rtf close;
ods listing;



