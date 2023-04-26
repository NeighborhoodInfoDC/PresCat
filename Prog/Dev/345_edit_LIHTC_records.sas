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
 - Add new tax credit record for Cedar Heights to Finsbury Square Apts (NL000106). [This change was determined to be unneccesary]
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

  /** Set lengths of character variables **/

  length subsidy_info_source $ 40 nlihc_id $ 16 rent_to_fmr_description $ 40 subsidy_info_source_ID $ 40 
program $ 32 /*** FILL IN REST BASED ON VAR LENGTHS IN PRESCAT.SUBSIDY ****/;

  /** Data that is the same for both projects **/

  subsidy_info_source_date = '8apr2022'd;

  subsidy_info_source = "HUD/Low Income Housing Tax Credits";
    /** New tax credit row for Portner Flats (NL000243) **/

  nlihc_id = "NL000243";

  subsidy_id = 3;  /** Fill in number for new subsidy row **/

  /*units_tot = 96;*/

  units_Assist = 96;

  POA_start = '1jan2018'd;

  POA_end = '1jan2048'd;

  rent_to_fmr_description = "60% AMI";

  subsidy_info_source_ID = "DCB20180002";

  program = "LIHTC/4PCT";

  compl_end = '1jan2033'd;

  output;  /** Saves the row to the output data set **/

run;

proc print data=Subsidy_new_obs;
	format POA_start POA_end compl_end subsidy_info_source_date MMDDYY8.;
run;

data Subsidy;

  set Prescat.Subsidy Subsidy_new_obs;  /** Listing two data sets here. Rows will be read from both into the new data set **/ 
  by nlihc_id subsidy_id;  /** Keeps the order of the rows sorted by these two vars **/

  /** Remove tax credit row for Augusta Louisa, which was added from 2020 HUD update **/
  if Nlihc_id = "NL000337" and Portfolio = "LIHTC" and year( subsidy_info_source_date ) = 2020 then delete;
  
run;

/** Replace Prescat.Subsidy with new version **/

%Finalize_data_set( 
  /** Finalize data set parameters **/
  data=Subsidy,
  out=Subsidy,
  outlib=Prescat,
  label="Preservation Catalog, Project subsidies",
  sortby=nlihc_id subsidy_id,
  /** Metadata parameters **/
  revisions=%str(Fix new LIHTC subsidies for NL000106, NL000243, and NL000337.),
  /** File info parameters **/
  printobs=0
)

/** Update subsidy vars in Prescat.Project **/

%Create_project_subsidy_update( data=Subsidy ) 

data Project;
  	merge Prescat.project Project_Subsidy_update;
	by nlihc_id;
run;

%Finalize_data_set( 
  /** Finalize data set parameters **/
  data=Project,
  out=Project,
  outlib=PresCat,
  label="Preservation Catalog, Projects",
  sortby=Nlihc_id,
  archive=N,
  /** Metadata parameters **/
  revisions=%str(Fix new LIHTC subsidies for NL000106, NL000243, and NL000337.),
  /** File info parameters **/
  printobs=0
)
  
title2 '***** CHECKS *****';

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


proc compare base=PresCat.Project compare=Project listall maxprint=(40,32000);
  id nlihc_id;
run;

title2;


