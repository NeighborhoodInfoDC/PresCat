/**************************************************************************
 Program:  Old_MFA_projects.sas
 Library:  PresCat
 Project:  NeighborhoodInfo DC
 Author:   P. Tatian
 Created:  12/30/14
 Version:  SAS 9.2
 Environment:  Local Windows session (desktop)
 
 Description:  Get data on two older MFA projects that are no longer
in HUD's database.

 Modifications:
**************************************************************************/

%include "L:\SAS\Inc\StdLocal.sas";

** Define libraries **;
%DCData_lib( PresCat )
%DCData_lib( HUD )

data _null_;
  set Hud.Sec8mf_2007_12_dc;
  where property_id in ( 800003695, 800003708 );
  file print;
  put / '--------------------';
  put (_all_) (= /);
run;

