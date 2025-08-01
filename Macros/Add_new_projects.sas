/**************************************************************************
 Program:  Add_new_projects.sas
 Library:  PresCat
 Project:  NeighborhoodInfo DC
 Author:   P. Tatian
 Created:  02/17/18
 Version:  SAS 9.2
 Environment:  Local Windows session (desktop)
 
 Description:  Autocall macro to add new projects to Preservation
 Catalog. 

 Main macro
 
 Process updates the following data sets:
   PresCat.Buiding_geocode
   PresCat.Project_geocode
   PresCat.Parcel
   PresCat.Subsidy
   PresCat.Project
   PresCat.Project_category
   PresCat.Real_property

 Modifications:
**************************************************************************/

%macro Add_new_projects( 
  input_file_pre=, /** First part of input file names **/
  input_path=&_dcdata_r_path\PresCat\Raw\AddNew,  /** Location of input files **/
  use_zipcode=N,  /** Use ZIP code when geocoding (set =N when invoking macro if input data does not have ZIP codes) **/
  match_score_min=71,  /** Minimum score for match **/
  matching_project_list=, /** Destination XLS file for list of projects matching existing Catalog or another new project **/
  geocode_edits=,  /** Geocoding manual edits **/
  address_data_edits=, /** Address data manual edits **/
  parcel_data_edits= /** Parcel data manual edits **/
  );
  
  %global _macro_fatal_error;
  %let _macro_fatal_error = 0;
  
  ** Update PresCat.Building_geocode, PresCat.Project_geocode, PresCat.Parcel **;
  
  %Add_new_projects_geocode( 
    input_file_pre=&input_file_pre,
    input_path=&input_path,
    use_zipcode=&use_zipcode,
    match_score_min=&match_score_min,
    matching_project_list=&matching_project_list, 
    geocode_edits=&geocode_edits,
    address_data_edits=&address_data_edits,
    parcel_data_edits=&parcel_data_edits
  )
  
  %if &_macro_fatal_error %then %do;
    %err_mput( macro=Add_new_projects, msg=Macro exiting with error. )
    %goto exit_macro;
  %end;
  
  ** Update PresCat.Subsidy **;
  
  %Add_new_projects_subsidy( 
    input_file_pre=&input_file_pre,
    input_path=&input_path
  )
  
  ** Update PresCat.Project, PresCat.Project_category **;
  
  %Add_new_projects_project( )  
  
  ** Update PresCat.Real_property **;
  
  %Update_real_property( Parcel=Parcel, revisions=%str(Add new projects from &input_file_pre._*.csv.) )
  
  title2 'Real_property: New records';

  proc print data=Real_property n;
    where put( nlihc_id, $New_nlihc_id. ) ~= "";
    id nlihc_id;
  run;
  
  title2;

  %exit_macro: 
  
%mend Add_new_projects;

/** End Macro Definition **/

