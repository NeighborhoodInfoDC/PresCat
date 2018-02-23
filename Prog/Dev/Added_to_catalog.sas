/**************************************************************************
 Program:  Added_to_catalog.sas
 Library:  PresCat
 Project:  NeighborhoodInfo DC
 Author:   P. Tatian
 Created:  02/22/18
 Version:  SAS 9.2
 Environment:  Local Windows session (desktop)
 
 Description:  Add new var Added_to_catalog to PresCat.Project.

 Modifications:
**************************************************************************/

%include "L:\SAS\Inc\StdLocal.sas";

** Define libraries **;
%DCData_lib( PresCat )

data Project;

  set PresCat.Project;
  
  if datepart( update_dtm ) = '18feb2018'd then Added_to_catalog = '18feb2018'd;
  else Added_to_catalog = '03sep2015'd;
  
  format Added_to_catalog mmddyy10.;
  
  label Added_to_catalog = "Date project was added to Catalog";

run;

%Finalize_data_set( 
  /** Finalize data set parameters **/
  data=Project,
  out=Project,
  outlib=PresCat,
  label="Preservation Catalog, Projects",
  sortby=nlihc_id,
  archive=Y,
  archive_name=,
  /** Metadata parameters **/
  creator_process=&_program,
  restrictions=None,
  revisions=%str(Add Added_to_catalog var.),
  /** File info parameters **/
  contents=Y,
  printobs=10,
  printchar=N,
  printvars=,
  freqvars=Added_to_catalog,
  stats=n sum mean stddev min max
)

