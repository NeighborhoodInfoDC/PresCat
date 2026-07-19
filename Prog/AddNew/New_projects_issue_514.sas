/**************************************************************************
 Program:  New_projects_issue_nnn.sas
 Library:  PresCat
 Project:  Urban-Greater DC
 Author:   P. Tatian
 Created:  07/10/2026
 Version:  SAS 9.4
 Environment:  Remote session (SAS1)
 
 Description:  Add new projects to Preservation Catalog. 
 

 Modifications:
**************************************************************************/

%include "F:\DCDATA\SAS\Inc\StdRemote.sas";

** Define libraries **;
%DCData_lib( PresCat )
%DCData_lib( MAR, local=n )
%DCData_lib( RealProp, local=n )
%DCData_lib( ROD, local=n )
%DCData_lib( DHCD, local=n )


%Add_new_projects(
  input_file_pre = New_projects_issue_514,
  address_data_edits = 
    if bldg_address_id = 65280 then delete;
)


run;
