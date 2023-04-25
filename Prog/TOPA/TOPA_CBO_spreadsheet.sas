/**************************************************************************
 Program:  TOPA_CBO_TA_spreadsheet.sas
 Library:  PresCat
 Project:  Urban-Greater DC
 Author:   Elizabeth Burton
 Created:  3/30/2023
 Version:  SAS 9.4
 Environment:  Local Windows session (desktop)
 
 Description:  Create CBO spreadsheet for TA information
 
 Modifications:
**************************************************************************/

%include "\\sas1\DCdata\SAS\Inc\StdLocal.sas";

** Define libraries **;
%DCData_lib( PresCat )

%File_info( data=PresCat.TOPA_database, printobs=5 ) 
%File_info( data=PresCat.TOPA_notices_sales, printobs=5 ) 

/** Fill in missing columns from original TOPA database to notices sale database created**/
data Topa_CBO_sheet; 
  merge 
    PresCat.TOPA_notices_sales (keep=id u_address_id_ref u_dedup_notice u_notice_date u_ownername u_sale_date u_notice_with_sale in=time_period)
    Prescat.Topa_database (keep=id All_street_addresses Property_name Notes Technical_assistance_provider u_date_dhcd_received_ta_reg Tech_Assist_Staff Tenant_Assn_Lawyer Did_a_TA_claim_TOPA_rights TA_Development_Partner Existing_LIHTC_Financing New_LIHTC_Financing);
  by id;
  if time_period;
  outcome_homeowner=""; label outcome_homeowner = "Outcome: Homeownership";
  outcome_rentcontrol=""; label outcome_rentcontrol ="Outcome: Rental Assignment w/ Rent Control Continued (Y/N)";
  outcome_LIHTC=""; label outcome_LIHTC ="Outcome: Rental Assignment w/ LIHTC (Y/N)";
  outcome_section8=""; label outcome_section8 ="Outcome: Rental Assignment w/ Project-Based Section 8 Continued (Y/N)";
  outcome_profit=""; label outcome_profit ="Outcome: Rental Assignment w/ Profit-Sharing (Y/N)";
  outcome_rehab=""; label outcome_rehab ="Outcome: Rental Assignment w/ Rehab (Y/N)";
  outcome_no_afford=""; label outcome_no_afford = "Outcome: Rental Assignment w/ No Affordability Guarantee (Y/N)";
  outcome_buyouts=""; label outcome_buyouts = "Outcome: Buyouts"; 
  dev_agree=""; label dev_agree = "Development agreement? (Y/N)";
  add_notes=""; label add_notes = "Additional notes"; 
run; 

proc sort data=Topa_CBO_sheet out=Topa_CBO_sheet_sorted;
  by u_address_id_ref u_notice_date;
run;

%File_info( data=Topa_CBO_sheet_sorted, printobs=20 ) 

data Topa_CBO_sheet_retain; 
  set Topa_CBO_sheet_sorted;
  by u_address_id_ref u_notice_date;
  format r_notes $char500.;
  format r_TA_provider $char.;
  format r_TA_staff $char.;
  format r_TA_lawyer $char.;
  format r_TA_claim_rights $char.;
  format r_TA_dev_partner $char.;
  if u_dedup_notice=0 then do;
  r_notes=Notes; r_TA_provider=Technical_assistance_provider; r_TA_staff=Tech_Assist_Staff; r_TA_lawyer=Tenant_Assn_Lawyer; r_TA_claim_rights=Did_a_TA_claim_TOPA_rights;
r_TA_dev_partner=TA_Development_Partner; r_Existing_LIHTC=Existing_LIHTC_Financing; r_New_LIHTC=New_LIHTC_Financing;
end;
  retain r_notes r_TA_provider r_TA_staff r_TA_lawyer r_TA_claim_rights r_TA_dev_partner r_Existing_LIHTC r_New_LIHTC; 
  label r_notes ='Notes';
  label r_TA_provider='CBO Technical assistance provider';
  label r_TA_staff='Technical assistance staff';
  label r_TA_lawyer='Technical assistance lawyer';
  label r_TA_claim_rights='Did the TA assign its rights?';
  label r_TA_dev_partner='TA Development Partner or consultant';
  label r_Existing_LIHTC='Existing LIHTC Financing? (Y/N)';
  label r_New_LIHTC='New LIHTC Financing? (Y/N)';

/*  if u_dedup_notice=1 then do;*/
  if u_dedup_notice=1 then do; 
	if not( missing( Notes ) ) then r_notes=Notes;
	if not( missing( Technical_assistance_provider ) ) then r_TA_provider=Technical_assistance_provider;
	if not( missing( Tech_Assist_Staff ) ) then r_TA_staff=Tech_Assist_Staff;
	if not( missing( Tenant_Assn_Lawyer ) ) then r_TA_lawyer=Tenant_Assn_Lawyer;
	if not( missing( Did_a_TA_claim_TOPA_rights ) ) then r_TA_claim_rights=Did_a_TA_claim_TOPA_rights;
	if not( missing( TA_Development_Partner ) ) then r_TA_dev_partner=TA_Development_Partner;
	if not( missing( Existing_LIHTC_Financing ) ) then r_Existing_LIHTC=Existing_LIHTC_Financing;
	if not( missing( New_LIHTC_Financing ) ) then r_New_LIHTC=New_LIHTC_Financing;
	output;
	r_notes=""; r_TA_provider=.; r_TA_staff=""; r_TA_lawyer="";
	r_TA_claim_rights=""; r_TA_dev_partner=""; r_Existing_LIHTC=""; r_New_LIHTC="";
	end;
  run; 
%File_info( data=Topa_CBO_sheet_retain, printobs=20 ) 

options missing=' ';

** Export for CBO spreadsheet **;
ods tagsets.excelxp   /** Open the excelxp destination **/
  file="&_dcdata_default_path\PresCat\Prog\TOPA\Topa_CBO_sheet_newsales.xls"  /** This is where the output will go **/
  style=Normal    /** This is the ODS style that will be used in the workbook **/
  options(sheet_interval='Proc' )
;
ods listing close;  /** Close the regular listing destination **/

ods tagsets.excelxp options( sheet_name="With Sales" );

proc print label data=Topa_CBO_sheet_retain;
  where u_dedup_notice=1 and u_notice_with_sale=1 and u_sale_date < '01jan2021'd;
  id id; 
  var u_address_id_ref u_notice_date All_street_addresses Property_name u_date_dhcd_received_ta_reg u_sale_date 
u_ownername r_notes r_TA_provider r_TA_staff r_TA_lawyer r_Existing_LIHTC r_New_LIHTC r_TA_claim_rights r_TA_dev_partner outcome_homeowner 
outcome_rentcontrol outcome_LIHTC outcome_section8 outcome_profit outcome_rehab outcome_no_afford outcome_buyouts dev_agree add_notes;
run;

ods tagsets.excelxp options( sheet_name="Without Sales" );

proc print label data=Topa_CBO_sheet_retain;
  where u_dedup_notice=1 and u_notice_with_sale=0;
  id id; 
  var u_address_id_ref u_notice_date All_street_addresses Property_name u_date_dhcd_received_ta_reg u_sale_date 
u_ownername r_notes r_TA_provider r_TA_staff r_TA_lawyer r_TA_claim_rights r_TA_dev_partner outcome_homeowner 
outcome_rentcontrol outcome_LIHTC outcome_section8 outcome_profit outcome_rehab outcome_no_afford outcome_buyouts dev_agree r_Existing_LIHTC r_New_LIHTC add_notes;
run;

ods tagsets.excelxp options( sheet_name="Sales in 2021 and 2022" );

proc print label data=Topa_CBO_sheet_retain;
  where u_dedup_notice=1 and u_notice_with_sale=1 and u_sale_date > '31dec2020'd;
  id id; 
  var u_address_id_ref u_notice_date All_street_addresses Property_name u_date_dhcd_received_ta_reg u_sale_date 
u_ownername r_notes r_TA_provider r_TA_staff r_TA_lawyer r_TA_claim_rights r_TA_dev_partner outcome_homeowner 
outcome_rentcontrol outcome_LIHTC outcome_section8 outcome_profit outcome_rehab outcome_no_afford outcome_buyouts dev_agree r_Existing_LIHTC r_New_LIHTC add_notes;
run;

ods tagsets.excelxp close;  /** Close the excelxp destination **/
ods listing;   /** Reopen the listing destination **/


