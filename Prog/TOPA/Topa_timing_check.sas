/**************************************************************************
 Program:  Topa_timing_check.sas
 Library:  Prescat
 Project:  Urban-Greater DC
 Author:   P. Tatian
 Created:  07/22/23
 Version:  SAS 9.4
 Environment:  Local Windows session (desktop)
 GitHub issue:  389
 
 Description:  Dates of sale, purchase, TA registration/ LOI: Urban
 run analysis of 
 a. the number of days between notice and sale
 (ranges) with and without a tenant association being formed and 
 b. By number of days between tenant association formation and sale
 (ranges).

 Offer date and TA/LOI date should not vary by more than 45 days.
 TA/LOI should never before an offer or sale 
 Building should never close less than 45 days after an offer of sale
 (there is at least one case in the database that was an illegal sale
 that did close too soon)
 Sale should not be more than 14 months after the offer of sale [may
 be some exceptions]

 Modifications:
**************************************************************************/

%include "\\sas1\DCdata\SAS\Inc\StdLocal.sas";

** Define libraries **;
%DCData_lib( Prescat )

data Topa_timing_check;

  merge 
    Prescat.Topa_notices_sales 
    Prescat.Topa_database (keep=id u_date_dhcd_received_ta_reg u_delete_notice)
    Prescat.Topa_cbo_sheet (keep=id cbo_dhcd_received_ta_reg);
  by id;
  
  if u_dedup_notice and u_notice_with_sale;
  
  if u_delete_notice then delete;
    
  total = 1;
  
  if not( missing( u_date_dhcd_received_ta_reg ) ) then cbo_dhcd_received_ta_reg = 'Yes';
  
  u_days_from_TA_to_sale = u_sale_date - u_date_dhcd_received_ta_reg;
  u_days_from_notice_to_TA = u_date_dhcd_received_ta_reg - u_notice_date;
  
  label 
    u_days_from_TA_to_sale = "Number of days from TA registration to sale"
    u_days_from_notice_to_TA = "Number of days from notice to TA registration"
  ;

run;

proc format;
  value day_range
    low -< 0 = '(negative)'
    0 -< 45 = 'Less than 45 days'
    45 -< 90 = '45 to 89 days'
    90 -< 180 = '90 to 179 days'
    180 -< 360 = '180 to 359 days'
    360 -< 420 = '360 to 419 days'
    420 -< 540 = '420 to 539 days'
    540 - high = '540 days or more';
  value $received_reg (notsorted)
    ' ', 'No' = 'No'
    'Yes' = 'Yes';
  value received_reg
    . = 'No'
    0 - high = 'Yes';
  value bldg_size
    0 - 15 = 'Smaller Buildings (15 units or fewer)'
    16 - high = 'Larger Buildings (16 units or more)';
run;


** Check on exclusions, building sizes **;

proc freq data=Topa_timing_check;
  where '01mar2020'd <= u_sale_date < '01may2023'd;
  tables u_actual_saledate u_sale_date / missing;
  format u_sale_date yyq. ;
run;

proc univariate data=Topa_timing_check plot;
  where u_actual_saledate and not( '01mar2020'd <= u_sale_date < '01may2023'd );
  var u_final_units;
run;

options missing=' ';

%fdate()

ods listing close;

ods tagsets.excelxp 
  file="&_dcdata_default_path\PresCat\Prog\TOPA\Topa_timing_check.xls" 
  style=Normal 
  options(sheet_interval='Proc' embedded_titles='Yes' embedded_footnotes='Yes');

ods tagsets.excelxp options( sheet_name="Table 1" absolute_column_width="30,16,16,16,16");

footnote1 "Prepared by Urban-Greater DC (greaterdc.urban.org), &fdate..";

title2 'Table 1. Number of days between notice and sale with and without a tenant association being formed';

footnote3 'Notes: Includes only notices with an actual sale date reported. Exludes 220 notices with sales between March 2020 and April 2023 which were affected by TOPA tolling.';

proc tabulate data=Topa_timing_check format=comma12.0 noseps missing;
  where u_actual_saledate and not( '01mar2020'd <= u_sale_date < '01may2023'd );
  class u_days_from_dedup_notice_to_sale cbo_dhcd_received_ta_reg u_final_units;
  var total;
  table 
    /** Page **/
    all='All Buildings'
    u_final_units=' ',
    /** Rows **/
    all='Total'
    u_days_from_dedup_notice_to_sale='Days from notice to sale',
    /** Columns **/
    total=' ' * ( sum='Total notices' colpctsum='Percent' * f=comma12.1 ) 
    total=' ' * cbo_dhcd_received_ta_reg='Tenant association formed' * ( sum='Notices' colpctsum='Percent' * f=comma12.1 )
    / condense rts=60;
  format u_final_units bldg_size. cbo_dhcd_received_ta_reg $received_reg. u_days_from_dedup_notice_to_sale day_range.;
run;


ods tagsets.excelxp options( sheet_name="Table 2"  /*absolute_column_width="30,1,16,16,16"*/);

title2 'Table 2. Number of days between notice and tenant association registration';

footnote3 'Notes: Includes only notices where date of tenant association registration is known.';

proc tabulate data=Topa_timing_check format=comma12.0 noseps missing;
  where not( missing( u_days_from_notice_to_TA ) );
  class u_days_from_notice_to_TA;
  var total;
  table 
    /** Rows **/
    all='Total' 
    u_days_from_notice_to_TA='Days from notice to TA registration'
    ,
    /** Columns **/
    total=' ' * ( sum='Notices' colpctsum='Percent' * f=comma12.1 )
    / condense rts=60;
  format u_days_from_notice_to_TA day_range.;
run;


ods tagsets.excelxp options( sheet_name="List 1" absolute_column_width="12,16,16,16,16,12,24,24");

title2 'List 1. Notices with TA registration before notice date';

footnote3 'Notes: Includes only notices where date of tenant association registration is known.';

proc print data=Topa_timing_check label n;
  where not( missing( u_days_from_notice_to_TA ) ) and u_days_from_notice_to_TA < 0;
  id id;
  var u_days_from_notice_to_TA u_notice_date u_date_dhcd_received_ta_reg u_sale_date u_actual_saledate fulladdress u_ownername;
  label 
    u_sale_date = 'Property sale date' 
    u_actual_saledate = 'Property sale is actual date';
run;


ods tagsets.excelxp options( sheet_name="List 2" );

title2 'List 2. Notices with TA registration more than 45 days after notice date';

footnote3 'Notes: Includes only notices where date of tenant association registration is known.';

proc print data=Topa_timing_check label n;
  where u_days_from_notice_to_TA > 45;
  id id;
  var u_days_from_notice_to_TA u_notice_date u_date_dhcd_received_ta_reg u_sale_date u_actual_saledate fulladdress u_ownername;
  label 
    u_sale_date = 'Property sale date' 
    u_actual_saledate = 'Property sale is actual date';
run;


ods tagsets.excelxp options( sheet_name="List 3" );

title2 'List 3. Notices with notice and sale < 45 days apart';

footnote3 'Notes: Includes only notices with an actual sale date reported. Exludes 220 notices with sales between March 2020 and April 2023 which were affected by TOPA tolling.';

proc print data=Topa_timing_check label n;
  where 0 <= u_days_from_dedup_notice_to_sale < 45 and ( u_actual_saledate and '01mar2020'd <= u_sale_date < '01may2023'd );
  id id;
  var u_days_from_dedup_notice_to_sale u_notice_date u_date_dhcd_received_ta_reg u_sale_date u_actual_saledate fulladdress u_ownername;
  label 
    u_sale_date = 'Property sale date' 
    u_actual_saledate = 'Property sale is actual date';
run;


ods tagsets.excelxp options( sheet_name="List 4" );

title2 'List 4. Notices with notice and sale >= 420 days (14 months) apart';

proc print data=Topa_timing_check label n;
  where u_days_from_dedup_notice_to_sale >= 420 and ( u_actual_saledate and not( '01mar2020'd <= u_sale_date < '01may2023'd ) );
  id id;
  var u_days_from_dedup_notice_to_sale u_notice_date u_date_dhcd_received_ta_reg u_sale_date u_actual_saledate fulladdress u_ownername;
  label 
    u_sale_date = 'Property sale date' 
    u_actual_saledate = 'Property sale is actual date';
run;


ods tagsets.excelxp close;
ods listing;
