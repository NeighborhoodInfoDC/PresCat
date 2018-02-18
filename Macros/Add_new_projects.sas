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
   PresCat.

 Modifications:
**************************************************************************/

%macro Add_new_projects( 
  input_file_pre=, /** First part of input file names **/ 
  streetalt_file= /** File containing street name spelling corrections (if omitted, default file is used) **/
  );
  
  ** Update PresCat.Building_geocode, PresCat.Project_geocode **;
  
  %Add_new_projects_geocode( 
    input_file_pre=&input_file_pre,
    streetalt_file=&streetalt_file
  )
  
  ** Create PresCat.Parcel **;
  
  %Create_parcel( 
    data=Building_geocode, 
    out=Parcel, 
    revisions=%str(Add new projects from &input_file_pre._*.csv.),
    compare=Y,
    archive=Y 
  )
  
  ** Update PresCat.Subsidy **;
  
  %Add_new_projects_subsidy( 
    input_file_pre=&input_file_pre
  )
  
  ** Update PresCat.Project, PresCat.Project_category **;
  
  %Add_new_projects_project( )  
  
%mend Add_new_projects;

/** End Macro Definition **/

