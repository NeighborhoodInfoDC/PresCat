/**************************************************************************
 Program:  416_Add_202207_pipeline_subsidies.sas
 Library:  Prescat
 Project:  Urban-Greater DC
 Author:   P. Tatian
 Created:  08/27/23
 Version:  SAS 9.4
 Environment:  Local Windows session (desktop)
 GitHub issue:  416
 
 Description:  Add new subsidies in Prescat.Dc_pipeline_2022_07 to
 Prescat.Subsidy for existing Catalog projects identified in issue #303.

 Modifications:
**************************************************************************/

%include "\\sas1\DCdata\SAS\Inc\StdLocal.sas";

** Define libraries **;
%DCData_lib( Prescat )

%let revisions = Update subsidies with data from Prescat.Dc_pipeline_2022_07.;

%let UPDATE_DTM = %sysfunc( datetime() );

** Read new subsidy data **;

filename fimport "\\sas1\DCData\Libraries\PresCat\Raw\416_pipeline_subsidies.csv" lrecl=2000;

proc import out=Pipeline_subsidies
    datafile=fimport
    dbms=csv replace;
  datarow=2;
  getnames=yes;
  guessingrows=max;
run;

filename fimport clear;

proc sort data=Pipeline_subsidies; 
  by nlihc_id Current_Affordability_Start Program;
  format _all_ ;
  informat _all_ ;
run;

%File_info( data=Pipeline_subsidies )

run;

** Update Prescat.Subsidy **;

data Subsidy;

  retain subsidy_id_ret;

  set 
    Prescat.subsidy
    Pipeline_subsidies 
      (keep=nlihc_id units_assist Current_Affordability_Start Subsidy_Info_Source     
            Subsidy_Info_Source_Date program agency
       rename=(Current_Affordability_Start=poa_start)
       in=in_pipeline); 
  by nlihc_id;
  
  if not in_pipeline then subsidy_id_ret = subsidy_id;
  
  if in_pipeline then do;
    subsidy_id = subsidy_id_ret + 1;
    subsidy_id_ret = subsidy_id;
    Portfolio = put( Program, $progtoportfolio. );
    poa_start_orig = poa_start;
    subsidy_active = 1;
    update_dtm = &UPDATE_DTM;
  end;
  
  drop subsidy_id_ret;
  
run;

%File_info( data=Subsidy, printobs=0 )

proc print data=Subsidy;
  where nlihc_id in ( 'NL000027', 'NL000029', 'NL000197', 'NL000234', 'NL000305', 'NL000397', 'NL001031' );
  by nlihc_id;
  id nlihc_id subsidy_id;
  var units_assist poa_start poa_start_orig program portfolio subsidy_active update_dtm;
  format program portfolio;
run;

proc compare base=Prescat.Subsidy compare=Subsidy maxprint=(40,32000);
  id nlihc_id subsidy_id;
run;

%Finalize_data_set( 
  /** Finalize data set parameters **/
  data=Subsidy,
  out=Subsidy,
  outlib=Prescat,
  label="Preservation Catalog, Project subsidies",
  sortby=nlihc_id subsidy_id,
  /** Metadata parameters **/
  revisions=%str(&revisions),
  /** File info parameters **/
  printobs=0,
  freqvars=
)


** Update Prescat.Project **;

%Create_project_subsidy_update( data=Subsidy, out=Project_subsidy_update, project_file=Prescat.Project )

data Project;

  update PresCat.Project Project_subsidy_update;
  by nlihc_id;
  
run;

proc compare base=Prescat.Project compare=Project listall maxprint=(40,32000);
  id nlihc_id;
run;

%Finalize_data_set( 
  /** Finalize data set parameters **/
  data=Project,
  out=Project,
  outlib=Prescat,
  label="Preservation Catalog, Projects",
  sortby=nlihc_id,
  /** Metadata parameters **/
  revisions=%str(&revisions),
  /** File info parameters **/
  printobs=0,
  freqvars=
)

