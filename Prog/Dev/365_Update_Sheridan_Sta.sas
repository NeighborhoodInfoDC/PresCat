/**************************************************************************
 Program:  365_Update_Sheridan_Sta.sas
 Library:  Prescat
 Project:  Urban-Greater DC
 Author:   P. Tatian
 Created:  05/03/23
 Version:  SAS 9.4
 Environment:  Local Windows session (desktop)
 GitHub issue:  365
 
 Description:  Update LIHTC info for Sheridan Station (NL001047).

 Modifications:
**************************************************************************/

%include "\\sas1\DCdata\SAS\Inc\StdLocal.sas";

** Define libraries **;
%DCData_lib( Prescat )
%DCData_lib( HUD )

proc print data=Prescat.Subsidy;
  where nlihc_id in ( 'NL001047' );  /** Limit output to rows with these project IDs **/
  var nlihc_id subsidy_id subsidy_active program units_assist Subsidy_info_source_id Subsidy_info_source subsidy_info_source_date; /** Limit output to these variables **/
run;

proc print data=Prescat.Project_category_view;
  where nlihc_id in ( 'NL001047' );  /** Limit output to rows with these project IDs **/
  id nlihc_id;
  var proj_name proj_units_tot proj_units_mar added_to_catalog proj_addre category_code;
run;

proc print data=Hud.Lihtc_2020_dc;
  where hud_id in ( 'DCB20142003' );
  id hud_id;
  var NONPROG LI_units project proj_add;
run;


proc print data=Prescat.Subsidy;
  where missing( subsidy_active ); 
  var nlihc_id subsidy_id subsidy_active program units_assist Subsidy_info_source_id Subsidy_info_source subsidy_info_source_date;
run;


data Subsidy_new_obs;

  /** Set lengths of character variables **/

  length subsidy_active 3 subsidy_info_source $ 40 nlihc_id $ 16 rent_to_fmr_description $ 40 subsidy_info_source_ID $ 40 
         program $ 32;

  /** Data that is the same for both projects **/

  subsidy_info_source_date = '8apr2022'd;

  subsidy_info_source = "HUD/Low Income Housing Tax Credits";
  
  /** New tax credit row for Sheridan Station (NL001047) **/

  nlihc_id = "NL001047";

  subsidy_id = 3;

  units_Assist = 133;

  POA_start = '1jan2014'd;

  POA_end = '1jan2044'd;

  rent_to_fmr_description = "60% AMI";

  subsidy_info_source_ID = "DCB20142003";

  program = "LIHTC/4PCT";

  compl_end = '1jan2029'd;
  
  Subsidy_active = 1;
  
  Update_Dtm = datetime();

  output;  /** Saves the row to the output data set **/

run;

proc print data=Subsidy_new_obs;
	format POA_start POA_end compl_end subsidy_info_source_date MMDDYY8.;
run;

data Subsidy;

  set Prescat.Subsidy Subsidy_new_obs;  /** Listing two data sets here. Rows will be read from both into the new data set **/ 
  by nlihc_id subsidy_id;  /** Keeps the order of the rows sorted by these two vars **/

  /** Set initial tax credit row for Sheridan Station (NL001047) to inactive **/
  if Nlihc_id = "NL001047" and Subsidy_id = 1 then do;
    Subsidy_active = 0;
    Update_Dtm = datetime();
  end;
  
  /** Set tax credit row for Portner Flats (NL000243) to active **/
  if Nlihc_id = "NL000243" and Subsidy_id = 3 then do;
    Subsidy_active = 1;
    Update_Dtm = datetime();
  end;
  
run;

proc sort data=Subsidy;
  by nlihc_id subsidy_id;
run;

title2 '***** CHECKS: SUBSIDY *****';

proc compare base=PresCat.Subsidy compare=Subsidy listall maxprint=(40,32000);
  id nlihc_id subsidy_id;
run;

%Dup_check(
  data=Subsidy,
  by=nlihc_id subsidy_id,
  id=program,
  out=_dup_check,
  listdups=Y,
  count=dup_check_count,
  quiet=N,
  debug=N
)

proc print data=Subsidy;
  where nlihc_id in ( 'NL001047', 'NL000243' ); 
  by nlihc_id;
  id nlihc_id subsidy_id;
  var subsidy_active program portfolio units: subsidy_info: update_dtm;
  format program portfolio ;
run;

title2;

/** Replace Prescat.Subsidy with new version **/

%Finalize_data_set( 
  /** Finalize data set parameters **/
  data=Subsidy,
  out=Subsidy,
  outlib=Prescat,
  label="Preservation Catalog, Project subsidies",
  sortby=nlihc_id subsidy_id,
  /** Metadata parameters **/
  revisions=%str(Fix new LIHTC subsidies for NL001047, NL000243.),
  /** File info parameters **/
  printobs=0
)

/** Update subsidy vars in Prescat.Project **/

%Create_project_subsidy_update( data=Subsidy ) 

data Project;
  	merge Prescat.project Project_Subsidy_update;
	by nlihc_id;
run;

title2 '***** CHECKS: PROJECT *****';

proc compare base=PresCat.Project compare=Project listall maxprint=(40,32000);
  id nlihc_id;
run;

title2;

%Finalize_data_set( 
  /** Finalize data set parameters **/
  data=Project,
  out=Project,
  outlib=PresCat,
  label="Preservation Catalog, Projects",
  sortby=Nlihc_id,
  archive=N,
  /** Metadata parameters **/
  revisions=%str(Fix new LIHTC subsidies for NL001047, NL000243.),
  /** File info parameters **/
  printobs=0
)

run;
