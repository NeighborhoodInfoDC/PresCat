/**************************************************************************
 Program:  345_edit_LIHTC_records.sas
 Library:  Prescat
 Project:  Urban-Greater DC
 Author:   D. Harvey
 Created:  04/11/2023
 Version:  SAS 9.4
 Environment:  Local Windows session (desktop)
 GitHub issue:  345
 
 Description:  
 Changes to Prescat.Subsidy
 - Add new tax credit record for Cedar Heights to Finsbury Square Apts (NL000106).
 - Add new tax credit record to Portner Flats (NL000243).
 - Remove new tax credit record from Augusta Louisa (NL000337).

 Modifications:
**************************************************************************/

%include "\\sas1\DCdata\SAS\Inc\StdLocal.sas";

** Define libraries **;
%DCData_lib( Prescat )
%DCData_lib( Mar )
%DCData_lib( Realprop )
%DCData_lib( Rod )
%DCData_lib( DHCD )

proc print data=Prescat.Subsidy;
  where nlihc_id in ( 'NL000106', 'NL000243' );  /** Limit output to rows with these project IDs **/
  var nlihc_id subsidy_id program Subsidy_info_source subsidy_info_source_date; /** Limit output to these variables **/
run;

data Subsidy_new_obs;

  set Prescat.Subsidy (obs=0);  /** Copy variables from Prescat.Subsidy, without any data **/

  /** Data that is the same for both projects **/

  Subsidy_source_info_date = 4/8/2022;

  Subsidy_source = "HUD/Low Income Housing Tax Credits";
    /** New tax credit row for Portner Flats (NL000243) **/

  nlihc_id = "NL000243";

  subsidy_id = 3;  /** Fill in number for new subsidy row **/

  units_tot = 96;

  units_Assist = 96;

  POA_start = 1/1/2018;

  POA_end = 1/1/2048;

  rent_to_fmr_description = "60% AMI";

  subsidy_info_source_ID = "DCB20180002";

  program = "LIHTC/4PCT";

  compl_end = 1/1/2033;

  output;  /** Saves the row to the output data set **/

run;


  /** New tax credit row for Cedar Heights/Finsbury Square Apts (NL000106)
  Commenting out for Cedar Heights for now, it does not appear in the "new_projects_issue_300_rev.csv" file
  and the row with the corresponding MARID (286820) in the older "New_projects_issue_subsidy.csv" file is blank

  nlihc_id = "NL000106";

  subsidy_id = 3;  /** Fill in number for new subsidy row 

  units_tot = ;

  units_Assist = ;

  current_affordability_start = ;

  affordability_end = ;

  rent_to_fmr_description = ;

  subsidy_info_source_ID = ;

  program = ;

  compliance_end_date = ;

  output;  /** Saves the row to the output data set **/

