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

data Building_geocode_test (obs=20);
  set Prescat.Building_geocode;
  where nlihc_id in ( 'NL000043' );
run;

proc print data=Building_geocode_test n;
  id nlihc_id;
  var bldg_addre;
run;

%Create_project_geocode( data=Building_geocode_test, compare=N, finalize=N )

ods html body="&_dcdata_default_path\prescat\prog\dev\366_add_to_proj_addre.html" style=Minimal;
ods listing close;

proc print data=Project_geocode;
  var proj_addre;
  format proj_addre $400.;
run;

run;

ods html close;
ods listing;
