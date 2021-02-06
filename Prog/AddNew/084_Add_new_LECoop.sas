/**************************************************************************
 Program:  084_Add_new_LECoop.sas
 Library:  PresCat
 Project:  Urban-Greater DC
 Author:   P. Tatian
 Created:  01/25/20
 Version:  SAS 9.4
 Environment:  Local Windows session (desktop)
 GitHub issue:  84
 
 Description:  Add new limited equity cooperative projects to PresCat
 from database created by CNHED and VCU for the LEC study.  

 Input data for new projects created by Prog\Dev\084_Review_LECoop_db.sas.

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
  input_file_pre = 084_Review_LECoop_db
)


run;
