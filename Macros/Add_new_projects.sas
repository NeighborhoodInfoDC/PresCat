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
  input_path=&_dcdata_r_path\PresCat\Raw\AddNew  /** Location of input files **/
  );
  
  ** Update PresCat.Building_geocode, PresCat.Project_geocode, PresCat.Parcel **;
  
  %Add_new_projects_geocode( 
    input_file_pre=&input_file_pre,
    input_path=&input_path
  )
/**************  TEMPORARILY COMMENT OUT CODE FOR TESTING
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
**********************/
%mend Add_new_projects;

/** End Macro Definition **/

