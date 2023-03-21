/**************************************************************************
 Program:  New_projects_issue_300.sas
 Library:  PresCat
 Project:  Urban-Greater DC
 Author:   Donovan Harvey
 Created:  11/2/2022
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
  input_file_pre = New_projects_issue_300_rev
)


run;
