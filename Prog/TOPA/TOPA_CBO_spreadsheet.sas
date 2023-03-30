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
    PresCat.TOPA_notices_sales (keep=id u_address_id_ref u_dedup_notice u_notice_date u_ownername u_sale_date in=time_period)
    Prescat.Topa_database (keep=id All_street_addresses Property_name Date_DHCD_received_TA_reg Notes Technical_assistance_provider Tech_Assist_Staff Tenant_Assn_Lawyer Did_a_TA_claim_TOPA_rights TA_Development_Partner Date_TA_assignment_of_rights Developer_assignment_of_rights);
  by id;
  if time_period;
  TA_negotiate=""; label TA_negotiate = "Did TA negotiate outside of TOPA process?";
  ass_aff_developer=""; label ass_aff_developer ="Is Assignee an Affordable Housing developer?";
  dev_agree=""; label dev_agree = "Development agreement? (Y/N)";
  buyouts=""; label buyouts = "Number of buy outs"; 
  assign_terms=""; label assign_terms = "Description of assignment terms";
  add_notes=""; label add_notes = "Additional notes"; 
run; 

%File_info( data=Topa_CBO_sheet, printobs=5 ) 


** Export for CBO spreadsheet **;
ods tagsets.excelxp   /** Open the excelxp destination **/
  file="&_dcdata_default_path\PresCat\Prog\TOPA\TOPA_CBO_TA.xls"  /** This is where the output will go **/
  style=Normal    /** This is the ODS style that will be used in the workbook **/
;

ods listing close;  /** Close the regular listing destination **/
proc print label data=Topa_CBO_sheet;
  where u_dedup_notice=1;
  var u_address_id_ref id u_notice_date All_street_addresses Property_name Date_DHCD_received_TA_reg u_sale_date u_ownername Notes 
Technical_assistance_provider Tech_Assist_Staff Tenant_Assn_Lawyer Did_a_TA_claim_TOPA_rights TA_Development_Partner TA_negotiate 
Date_TA_assignment_of_rights Developer_assignment_of_rights ass_aff_developer dev_agree buyouts assign_terms add_notes;
run;

ods tagsets.excelxp close;  /** Close the excelxp destination **/
ods listing;   /** Reopen the listing destination **/


