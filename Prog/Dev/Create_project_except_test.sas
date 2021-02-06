/**************************************************************************
 Program:  Create_project_except_test.sas
 Library:  PresCat
 Project:  NeighborhoodInfo DC
 Author:   P. Tatian
 Created:  07/19/15
 Version:  SAS 9.2
 Environment:  Local Windows session (desktop)
 
 Description:  Create testing version of Project_except.

 Modifications:
**************************************************************************/

%include "\\sas1\DCdata\SAS\Inc\StdLocal.sas";

** Define libraries **;
%DCData_lib( PresCat )

data Project_except_recs;

  length Nlihc_id $ 8 Except_init $ 8 Hud_Own_Name Hud_Mgr_Name $ 80;
  
  ** Exception for updated var **;
  nlihc_id = "NL000047";
  Hud_Own_Name = "NEW OWNER!";
  Hud_Own_Effect_dt = .;
  Hud_mgr_name = "";
  Except_date = date();
  Except_init = 'PAT';
  output;
  
  ** Exception for nonupdated var **;
  nlihc_id = "NL000001";
  Hud_Own_Name = "";
  Hud_Own_Effect_dt = '01jan2015'd;
  Hud_mgr_name = "";
  Except_date = date();
  Except_init = 'PAT';
  output;
  
  ** Exception same as updated var **;
  nlihc_id = "NL000102";
  Hud_Own_Name = "Fpw, LP";
  Hud_Own_Effect_dt = .;
  Hud_mgr_name = "";
  Except_date = date();
  Except_init = 'PAT';
  output;
  
  ** Exception for nonupdated obs **;
  nlihc_id = "NL000035";
  Hud_Own_Name = "";
  Hud_Own_Effect_dt = .;
  Hud_mgr_name = "Who's the manager?";
  Except_date = date();
  Except_init = 'PAT';
  output;
  
run; 

data PresCat.Project_except_test;

  set PresCat.Project_except;
  
run;

proc append base=PresCat.Project_except_test data=Project_except_recs force;
run;

%File_info( data=PresCat.Project_except_test, contents=y, stats= )

run;

