/**************************************************************************
 Program:  476_Add_ANC2023.sas
 Library:  PresCat
 Project:  Urban-Greater DC
 Author:   P. Tatian
 Created:  07/09/25
 Version:  SAS 9.4
 Environment:  Local Windows session (desktop)
 GitHub issue:  476
 
 Description:  Add new ANC2023 geography to PresCat data sets.

 Modifications:
**************************************************************************/

%include "\\sas1\DCdata\SAS\Inc\StdLocal.sas";

** Define libraries **;
%DCData_lib( PresCat )

data Building_geocode;

 set Prescat.Building_geocode;
 
 %Block20_to_anc23()

run;

%Finalize_data_set( 
  data=Building_geocode,
  out=Building_geocode,
  outlib=PresCat,
  label="Preservation Catalog, Building-level geocoding info",
  sortby=nlihc_id bldg_addre,
  printobs=0,
  freqvars=ANC2023,
  revisions=%str(Add ANC2023.)
)

%Create_project_geocode( data=Building_geocode, revisions=%str(Add ANC2023.) )

** Project **;

data Project;

  merge
    PresCat.Project
    Project_geocode (drop=proj_name);
  by nlihc_id;
  
run;

%Finalize_data_set( 
  data=Project,
  out=Project,
  outlib=PresCat,
  label="Preservation Catalog, Projects",
  sortby=nlihc_id,
  revisions=%str(Add ANC2023.),
  printobs=0,
  stats=
)

proc compare base=PresCat.Project compare=Project listall maxprint=(40,32000);
  id nlihc_id;
run;
