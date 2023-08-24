/**************************************************************************
 Program:  New_projects_issue_303.sas
 Library:  PresCat
 Project:  Urban-Greater DC
 Author:   Elizabeth Burton
 Created:  8/21/2023
 Version:  SAS 9.4
 Environment:  Local Windows session (desktop)
 
 Description:  Add new projects to Preservation Catalog. 
 

 Modifications:
**************************************************************************/

%include "\\sas1\DCdata\SAS\Inc\StdLocal.sas";

** Define libraries **;
%DCData_lib( PresCat )
%DCData_lib( MAR, local=n )
%DCData_lib( RealProp, local=n )
%DCData_lib( ROD, local=n )
%DCData_lib( DHCD, local=n )


%Add_new_projects(
  input_file_pre = New_projects_issue_303,
  use_zipcode = N,
  match_score_min = 65,
  geocode_edits =
    if id = 151 then M_EXACTMATCH = 1;
  ,
  matching_project_list=C:\DCData\Libraries\PresCat\Prog\AddNew\New_projects_issue_303_matching_project_list.xls
)


run;
