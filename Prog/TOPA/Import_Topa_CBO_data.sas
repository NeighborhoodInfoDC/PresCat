/**************************************************************************
 Program:  Import_Topa_CBO_data.sas
 Library:  Prescat
 Project:  Urban-Greater DC
 Author:   P. Tatian
 Created:  07/18/23
 Version:  SAS 9.4
 Environment:  Local Windows session (desktop)
 GitHub issue:  388
 
 Description:  Import TOPA data from CBOs.

 Modifications:
**************************************************************************/

%include "\\sas1\DCdata\SAS\Inc\StdLocal.sas";

** Define libraries **;
%DCData_lib( Prescat )

%let revisions = Add data cleaning steps.;

%let categorical_vars = 
    cbo_lihtc_plus 
    r_Existing_LIHTC r_New_LIHTC TA_assign_rights
    outcome_homeowner outcome_nonprofit_owner
    outcome_rent_assign_rc_cont outcome_assign_rc_nopet
    outcome_assign_LIHTC outcome_assign_section8
    outcome_assign_profit_share
    outcome_assign_noafford outcome_rehab outcome_buyouts
    outcome_100pct_afford outcome_affordability
    outcome_pres_funding_fail outcome_dev_agree    
;

%let info_vars = cbo_dhcd_received_ta_reg cbo_complete r_TA_provider r_TA_staff r_TA_lawyer r_TA_dev_partner;


/** Macro Read_data - Start Definition **/

%macro Read_data( file_suffix= );

  %local file_base;
  %let file_base = Topa_CBO_sheet 4.28.23_with_var_names;

  ** Download and read TOPA dataset into SAS dataset**;
  %let dsname="&_dcdata_r_path\PresCat\Raw\TOPA\&file_base._&file_suffix..csv";
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

  proc import out=Topa_CBO_sheet_&file_suffix
      datafile=fixed
      dbms=csv replace;
    datarow=3;
    getnames=yes;
    guessingrows=max;
  run;

  filename fixed clear;

  data Topa_CBO_sheet_&file_suffix;

    set Topa_CBO_sheet_&file_suffix;
    where not( missing( id ) );

    id_num = input( id, 12.0 );
    
    drop id;
    rename id_num=id;
    
    %if %lowcase( &file_suffix ) = without_sales or %lowcase( &file_suffix ) = add_these_topas %then %do;
    
      length cbo_unit_count_char $ 7;
    
      cbo_unit_count_char = left( put( cbo_unit_count, 7.0 ) );
      
      drop cbo_unit_count;
      rename cbo_unit_count_char=cbo_unit_count;
      
    %end;
        
    %if %lowcase( &file_suffix ) = add_these_topas %then %do;
    
      drop u_sale_date u_notice_date u_address_id_ref;
      
    %end;
        
    u_date_dhcd_received_ta_reg = left( compbl( compress( propcase( u_date_dhcd_received_ta_reg ), '.' ) ) );
    
    length cbo_dhcd_received_ta_reg $ 3;
    
    if missing( u_date_dhcd_received_ta_reg ) then cbo_dhcd_received_ta_reg = 'No';
    else if lowcase( u_date_dhcd_received_ta_reg ) = 'no info' then cbo_dhcd_received_ta_reg = 'No';
    else cbo_dhcd_received_ta_reg = 'Yes';
   
    format _all_ ;
    informat _all_ ;
    
    drop VAR: drop: ;
    
    rename u_date_dhcd_received_ta_reg=cbo_date_dhcd_received_ta_reg;

  run;
  
  proc sort data=Topa_CBO_sheet_&file_suffix;
    by id;
  run;
  
  %File_info( data=Topa_CBO_sheet_&file_suffix, printobs=5 )

%mend Read_data;

/** End Macro Definition **/


%Read_data( file_suffix=with_sales )

%Read_data( file_suffix=without_sales )

%Read_data( file_suffix=sales_2021_2022 )

%Read_data( file_suffix=add_these_topas )


** Combine data sets **;

data Topa_CBO_sheet;

  length 
    cbo_complete $ 40 
    r_ta_provider r_ta_lawyer outcome_100pct_afford $ 80 
    outcome_nonprofit_owner $ 200
    add_notes data_notes $ 600;

  set 
    Topa_CBO_sheet_with_sales (in=in1)
    Topa_CBO_sheet_without_sales (in=in2)
    Topa_CBO_sheet_sales_2021_2022 (in=in3)
    Topa_CBO_sheet_add_these_topas;
  by id;
  
  length Source_sheet $ 24;
  
  if in1 then Source_sheet = "WITH SALES";
  else if in2 then Source_sheet = "WITHOUT SALES";
  else if in3 then Source_sheet = "SALES IN 2021 AND 2022";
  else Source_sheet = "ADD THESE TOPAS";
  
  ** CLEANING: Switch outcomes to different notice **;
  
  select ( id );
  
    when ( 1555 ) delete;
    when ( 1445 ) id = 1555;
  
    when ( 931 ) delete;
    when ( 10005 ) id = 931;
    
    when ( 733 ) delete;
    when ( 1137 ) id = 733;
    
    otherwise /** DO NOTHING **/;
    
  end;

  ** CLEANING: Manually  add CBO outcomes from Farah 8/15/23**;

  if id = 753 then do; 
  outcome_affordability = 'Not Affordable Before Sale';
  TA_assign_rights = 'Yes';
  end; 

  if id = 73 then do;
  TA_assign_rights = 'Yes';
  outcome_100pct_afford = 'Yes';
  outcome_rehab = 'Yes'; 
  end; 

  if id = 62 then do;
  cbo_dhcd_received_ta_reg = 'Yes';
  TA_assign_rights = 'Yes';
  outcome_rent_assign_rc_cont = 'Yes';
  outcome_100pct_afford = 'Yes';
  outcome_rehab = 'Yes'; 
  end; 

  select ( id );
    when ( 862 ) outcome_affordability = 'Not Affordable Before Sale';
	when ( 1320 ) outcome_assign_noafford = 'No';
    when ( 348, 1137, 416, 417, 418, 419, 420, 2009) cbo_dhcd_received_ta_reg = 'Yes';
	when ( 349 ) cbo_dhcd_received_ta_reg = 'No';
	when ( 945, 761, 820, 1011, 1297, 700) TA_assign_rights = 'Yes';

  otherwise /** DO NOTHING **/;
  end; 
  
  ** Reformat categorical responses & create outcome flag **;
  
  u_has_cbo_outcome = 0;
  
  array a{*} &categorical_vars;
  
  do i = 1 to dim(a);
  
    a{i} = left( trim( compbl( propcase( a{i} ) ) ) );

    select ( a{i});
      when ( 'Y', 'Yes' )
        a{i} = 'Yes';
      when ( 'N', 'No', 'N.' )
        a{i} = 'No';
      otherwise /** Do nothing **/;
    end;
    
    if not( missing( a{i} ) ) then u_has_cbo_outcome = 1;

  end;
  
  if cbo_unit_count in ( '.', '#N/A' ) then cbo_unit_count = '';
  else if substr( cbo_unit_count, 1, 1 ) = '$' then cbo_unit_count = left( put( input( substr( cbo_unit_count, 2 ), 8. ), 5.0 ) );

  label
    u_has_cbo_outcome = 'Has one or more CBO outcome coded'
    id = "CNHED database unique notice ID"
    u_address_id_ref = "Unique property ID (DC MAR address ID) (Urban created var)"
    cbo_complete = "Complete"
    u_notice_date = "Notice offer of sale date (Urban created var)"
    All_street_addresses = "All street addresses"
    Property_name = "Property name"
    cbo_unit_count = "Unit count, includes entries modified by CBOs"
    cbo_date_dhcd_received_ta_reg = "Date DHCD received LOI (Urban created var, modified by CBOs)"
    cbo_dhcd_received_ta_reg = "DHCD received LOI"
    u_sale_date = "Property sale date (Urban created var)"
    u_ownername = "Name(s) of property buyer(s) (Urban created var)"
    r_notes = "Notes from CNHED datababase"
    r_TA_provider = "CBO Technical assistance provider"
    r_TA_staff = "Who filled this in now? (Was - who has info)"
    r_TA_lawyer = "Tenant association lawyer"
    r_Existing_LIHTC = "Existing LIHTC Financing (before Offer)? (Y/N)"
    r_New_LIHTC = "New LIHTC Financing (per development ag)? (Y/N)"
    cbo_lihtc_plus = "LIHTC + (existing tenants at rent control levels or better)"
    TA_assign_rights = "Did the TA assign its rights? (Y/N)"
    r_TA_dev_partner = "TA Development partner/ consultant"
    outcome_homeowner = "Outcome: Homeownership"
    outcome_nonprofit_owner = "Non-profit owner/ affordable outcome (no assignment)"
    outcome_rent_assign_rc_cont = "Outcome: Rental Assignment w/ Rent Control Continued (Y/N)"
    outcome_assign_rc_nopet = "Assignment: Rent control - No petitions in DA"
    outcome_assign_LIHTC = "Outcome: Rental Assignment w/ LIHTC (Y/N)"
    outcome_assign_section8 = "Outcome: Rental Assignment w/ Project-Based Section 8 Continued (Y/N)"
    outcome_assign_profit_share = "Outcome: Rental Assignment w/ Profit-Sharing (Y/N)"
    outcome_assign_noafford = "Outcome: Rental Assignment w/ No Affordability Guarantee (Y/N)"
    outcome_rehab = "Outcome: Renovations / Repairs for residents in development ag (ownership or rental) (Y/N)"
    outcome_buyouts = "Outcome: Buyouts"
    outcome_100pct_afford = "100% affordable (Y/N)"
    outcome_affordability = "What happened to affordability"
    outcome_pres_funding_fail = "Preservation Funding Fail? (Y/N)"
    outcome_dev_agree = "Development agreement? (Y/N)"
    add_notes = "Additional notes"
    data_notes = "Data Notes";

  format u_sale_date u_notice_date mmddyy10. u_has_cbo_outcome dyesno.;
  
  drop i;
   
run;

proc sort data=Topa_CBO_sheet;
  by id;
run;

proc print data=Topa_CBO_sheet;
  where id =62;
  id id;
run;

%File_info( data=Topa_CBO_sheet, printobs=0, freqvars=Source_sheet )

%Dup_check(
  data=Topa_CBO_sheet,
  by=id,
  id=u_notice_date source_sheet,
  out=_dup_check,
  listdups=Y,
  count=dup_check_count,
  quiet=N,
  debug=N
)

proc print data=Topa_CBO_sheet;
  where missing( u_notice_date );
  id id;
  var source_sheet all_street_addresses property_name;
run;

ods tagsets.excelxp file="&_dcdata_default_path\PresCat\Prog\TOPA\Topa_CBO_frequencies.xls" style=Normal options(sheet_interval='Table' );

proc freq data=Topa_CBO_sheet;
  tables u_has_cbo_outcome &categorical_vars &info_vars;
run;

ods tagsets.excelxp close;


** Examine notes for selected obs **;

ods listing close;
**ods html body="&_dcdata_default_path\PresCat\Prog\TOPA\Topa_CBO_notes.html" (title="Topa_CBO_notes") style=BarrettsBlue;
ods tagsets.excelxp file="&_dcdata_default_path\PresCat\Prog\TOPA\Topa_CBO_notes.xls" style=Normal options(sheet_interval='Proc' );

ods tagsets.excelxp options( sheet_name="Remove" );

title2 '-- Notices to remove --';
proc print data=Topa_CBO_sheet;
  where lowcase( cbo_complete ) contains 'remove' or lowcase( cbo_complete ) contains 'delete' or lowcase( cbo_complete ) contains 'duplicate';
  id id;
  var source_sheet u_notice_date cbo_complete add_notes data_notes;
run;

ods tagsets.excelxp options( sheet_name="outcome_rent_assign_rc_cont" );

title2 '-- outcome_rent_assign_rc_cont --';
proc print data=Topa_CBO_sheet;
  where lowcase( outcome_rent_assign_rc_cont ) contains 'of sorts';
  id id;
  var source_sheet u_notice_date outcome_rent_assign_rc_cont add_notes data_notes;
run;

ods tagsets.excelxp options( sheet_name="LRSP in notes" );

title2 '-- LRSP in notes --';
proc print data=Topa_CBO_sheet;
  where lowcase( add_notes ) contains 'lrsp' or lowcase( data_notes) contains 'lrsp' or
  lowcase( add_notes ) contains 'rent sup' or lowcase( data_notes) contains 'rent sup';
  id id;
  var source_sheet u_notice_date outcome_assign_section8 add_notes data_notes;
run;

title2;

**ods html close;
ods tagsets.excelxp close;
ods listing;


ods listing close;
ods tagsets.excelxp file="&_dcdata_default_path\PresCat\Prog\TOPA\Topa_CBO_nondedup_outcomes.xls" style=Normal options(sheet_interval='Proc' );

title2 '-- Non-dedup notices with CBO outcomes --';

data outcome_nodedup;

  merge
    Topa_CBO_sheet (keep=id source_sheet u_notice_date u_has_cbo_outcome &categorical_vars)
    Prescat.Topa_notices_sales (keep=id u_dedup_notice u_notice_with_sale);
  by id;
  
  if u_has_cbo_outcome and not u_dedup_notice;
    
run;

proc print data=outcome_nodedup;
  id id;
  var source_sheet u_notice_date u_notice_with_sale &categorical_vars;
run;

ods tagsets.excelxp close;
ods listing;


** Finalize data **;

%Finalize_data_set( 
  /** Finalize data set parameters **/
  data=Topa_CBO_sheet,
  out=Topa_CBO_sheet,
  outlib=Prescat,
  label="TOPA CBO review workbook with outcomes, created 4/28/2023",
  sortby=id,
  /** Metadata parameters **/
  revisions=%str(&revisions),
  /** File info parameters **/
  printobs=5,
  freqvars=source_sheet
)


** Compare unit counts from original CNHED data **;

proc compare base=Prescat.Topa_database compare=Topa_CBO_sheet (where=(cbo_unit_count~='')) maxprint=(1000,32000);
  id id;
  var units;
  with cbo_unit_count;
run;

