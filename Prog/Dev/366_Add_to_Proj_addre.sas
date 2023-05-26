/**************************************************************************
 Program:  366_Add_to_Proj_addre.sas
 Library:  Prescat
 Project:  Urban-Greater DC
 Author:   P. Tatian
 Created:  05/04/23
 Version:  SAS 9.4
 Environment:  Local Windows session (desktop)
 GitHub issue:  366
 
 Description:  Expand the Proj_addre field to include more addresses,
 and list addresses in descending order by numbers of housing units.

 Update Prescat.Project with the new field. 

 Modifications:
**************************************************************************/

%include "\\sas1\DCdata\SAS\Inc\StdLocal.sas";

** Define libraries **;
%DCData_lib( Prescat )
%DCData_lib( Realprop )

%Create_project_geocode( data=Prescat.Building_geocode, compare=N, finalize=N )

ods html body="&_dcdata_default_path\prescat\prog\dev\366_add_to_proj_addre.html" style=Minimal;
ods listing close;

proc print data=Project_geocode;
  id nlihc_id;
  var proj_addre;
run;

ods html close;
ods listing;

data Project;

  merge Prescat.Project Project_geocode;
  by nlihc_id;
  
  label Proj_addre = "Project addresses";
  
run;

%let revisions = Revise Proj_addre variable.;

%Finalize_data_set(
  data=Project_geocode,
  out=Project_geocode,
  outlib=PresCat,
  label="Preservation Catalog, Project-level geocoding info",
  sortby=nlihc_id,
  revisions=%str(&revisions),
  printobs=0
)

%Finalize_data_set( 
  /** Finalize data set parameters **/
  data=Project,
  out=Project,
  outlib=PresCat,
  label="Preservation Catalog, Projects",
  sortby=Nlihc_id,
  archive=N,
  /** Metadata parameters **/
  revisions=%str(&revisions),
  /** File info parameters **/
  printobs=0
)

proc compare base=Prescat.Project compare=Project listall maxprint=(40,32000) criterion=0.01 method=absolute;
  id nlihc_id;
run;

