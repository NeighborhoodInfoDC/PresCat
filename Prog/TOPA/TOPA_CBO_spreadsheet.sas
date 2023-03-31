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
    PresCat.TOPA_notices_sales (keep=id u_address_id_ref u_dedup_notice u_notice_date u_ownername u_sale_date  in=time_period)
    Prescat.Topa_database (keep=id All_street_addresses Property_name Notes Technical_assistance_provider u_date_dhcd_received_ta_reg Tech_Assist_Staff Tenant_Assn_Lawyer Did_a_TA_claim_TOPA_rights TA_Development_Partner Date_TA_assignment_of_rights Developer_assignment_of_rights);
  by id;
  if time_period;
  TA_negotiate=""; label TA_negotiate = "Did TA negotiate outside of TOPA process?";
  ass_aff_developer=""; label ass_aff_developer ="Is Assignee an Affordable Housing developer?";
  dev_agree=""; label dev_agree = "Development agreement? (Y/N)";
  buyouts=""; label buyouts = "Number of buy outs"; 
  assign_terms=""; label assign_terms = "Description of assignment terms";
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
  format r_date_TA_ass_rigts $char.;
  format r_dev_ass_right $char.;
  if u_dedup_notice=0 then do;
  r_notes=Notes; r_TA_provider=Technical_assistance_provider; r_TA_staff=Tech_Assist_Staff; r_TA_lawyer=Tenant_Assn_Lawyer; r_TA_claim_rights=Did_a_TA_claim_TOPA_rights;
r_TA_dev_partner=TA_Development_Partner; r_date_TA_ass_rigts=Date_TA_assignment_of_rights; r_dev_ass_right=Developer_assignment_of_rights;
end;
  retain r_notes r_TA_provider r_TA_staff r_TA_lawyer r_TA_claim_rights r_TA_dev_partner r_date_TA_ass_rigts r_dev_ass_right; 
  label r_notes ='Notes';
  label r_TA_provider='CBO Technical assistance provider';
  label r_TA_staff='Technical assistance staff';
  label r_TA_lawyer='Technical assistance lawyer';
  label r_TA_claim_rights='Did TA provider claim TOPA rights?';
  label r_TA_dev_partner='TA Development Partner';
  label r_date_TA_ass_rigts='Approx. Date of TA assignment of rights';
  label r_dev_ass_right='Developer receiving assignment of rights';

/*  if u_dedup_notice=1 then do;*/
  if u_dedup_notice=1 and not( missing( Notes ) ) then r_notes=Notes;
  else if u_dedup_notice=1 not( missing( Technical_assistance_provider ) ) then r_TA_provider=Technical_assistance_provider;
  else if u_dedup_notice=1 not( missing( Tech_Assist_Staff ) ) then r_TA_staff=Tech_Assist_Staff;
  else if u_dedup_notice=1 not( missing( Tenant_Assn_Lawyer ) ) then r_TA_lawyer=Tenant_Assn_Lawyer;
  else if u_dedup_notice=1 not( missing( Did_a_TA_claim_TOPA_rights ) ) then r_TA_claim_rights=Did_a_TA_claim_TOPA_rights;
  else if u_dedup_notice=1 not( missing( TA_Development_Partner ) ) then r_TA_dev_partner=TA_Development_Partner;
  else if u_dedup_notice=1 not( missing( Date_TA_assignment_of_rights ) ) then r_date_TA_ass_rigts=Date_TA_assignment_of_rights;
  else if u_dedup_notice=1 not( missing( Developer_assignment_of_rights ) ) then r_dev_ass_right=Developer_assignment_of_rights;

	output;
	r_notes=""; r_TA_provider=.; r_TA_staff=""; r_TA_lawyer="";
	r_TA_claim_rights=""; r_TA_dev_partner=""; r_date_TA_ass_rigts=""; r_dev_ass_right="";
	end;
  run; 
%File_info( data=Topa_CBO_sheet_retain, printobs=20 ) 


** Export for CBO spreadsheet **;
ods tagsets.excelxp   /** Open the excelxp destination **/
  file="&_dcdata_default_path\PresCat\Prog\TOPA\Topa_CBO_sheet_retain.xls"  /** This is where the output will go **/
  style=Normal    /** This is the ODS style that will be used in the workbook **/
;

ods listing close;  /** Close the regular listing destination **/
proc print label data=Topa_CBO_sheet_retain;
  where u_dedup_notice=1;
  id id; 
  var u_address_id_ref u_notice_date All_street_addresses Property_name u_date_dhcd_received_ta_reg u_sale_date u_ownername r_notes r_TA_provider
r_TA_staff r_TA_lawyer r_TA_claim_rights r_TA_dev_partner TA_negotiate r_date_TA_ass_rigts r_dev_ass_right ass_aff_developer dev_agree buyouts assign_terms add_notes;
run;

ods tagsets.excelxp close;  /** Close the excelxp destination **/
ods listing;   /** Reopen the listing destination **/


