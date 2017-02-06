/**************************************************************************
 Program:  Restore_project_geocode.sas
 Library:  PresCat
 Project:  NeighborhoodInfo DC
 Author:   P. Tatian
 Created:  01/03/17
 Version:  SAS 9.2
 Environment:  Local Windows session (desktop)
 
 GitHub issue: #85
 
 Description:  Restore Project_geocode file from Building_geocode.

 Modifications:
**************************************************************************/

%include "L:\SAS\Inc\StdLocal.sas";

** Define libraries **;
%DCData_lib( PresCat )

data Project_geocode;

  set PresCat.Building_geocode;
  by Nlihc_id;
  
  

run;
