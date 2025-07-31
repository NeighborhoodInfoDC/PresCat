/**************************************************************************
 Program:  Test_add_new_projects.sas
 Library:  PresCat
 Project:  Urban-Greater DC
 Author:   P. Tatian
 Created:  07/31/25
 Version:  SAS 9.4
 Environment:  Local Windows session (desktop)
 GitHub issue:  
 
 Description:  Code for testing %Add_new_projects_geocode() macro. 

 THIS CODE SHOULD NOT BE RUN AS FINALIZED CODE. 

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
  input_file_pre = Test_add_new_projects,
   use_zipcode = N
)


run;
