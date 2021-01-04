/**************************************************************************
 Program:  242_Add_new_IZ.sas
 Library:  PresCat
 Project:  Urban-Greater DC
 Author:   M Cohen
 Created:  01/3/21
 Version:  SAS 9.4
 Environment:  Local Windows session (desktop)
 GitHub issue:  242
 
 Description:  Add new iz projects to PresCat.  

 Input data for new projects created by Prog\Dev\242_Review_IZ_db.sas.

 Modifications:
**************************************************************************/

%include "\\sas1\DCDATA\SAS\Inc\StdLocal.sas";

** Define libraries **;
%DCData_lib( PresCat )
%DCData_lib( MAR, local=n )
%DCData_lib( RealProp, local=n )
%DCData_lib( ROD, local=n )
%DCData_lib( DHCD, local=n )


%Add_new_projects(
  input_file_pre = 242_Review_IZ_db
)


run;
