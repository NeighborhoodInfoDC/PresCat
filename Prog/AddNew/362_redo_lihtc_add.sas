/**************************************************************************
 Program:  362_redo_lihtc_add.sas
 Library:  Prescat
 Project:  Urban-Greater DC
 Author:   P. Tatian
 Created:  04/27/23
 Version:  SAS 9.4
 Environment:  Local Windows session (desktop)
 GitHub issue:  362
 
 Description:  Had a problem adding a few LIHTC projects to the
 Catalog in issue #300. Will redo these and debug code.

   * North Capitol Commons
   * 770 C Street Apartments

 Modifications:
**************************************************************************/

%include "\\sas1\DCdata\SAS\Inc\StdLocal.sas";

** Define libraries **;
%DCData_lib( Prescat )
%DCData_lib( MAR, local=n )
%DCData_lib( RealProp, local=n )
%DCData_lib( ROD, local=n )
%DCData_lib( DHCD, local=n )


%Add_new_projects(
  input_file_pre = New_projects_issue_362,
  address_data_edits =
  ,
  parcel_data_edits =
)


run;
