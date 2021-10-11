/**************************************************************************
 Program:  Add_new_projects_20180219.sas
 Library:  PresCat
 Project:  NeighborhoodInfo DC
 Author:   P Tatian
 Created:  02/19/2018
 Version:  SAS 9.4
 Environment:  Local Windows session (desktop)
 
 Description:  Add new projects to Preservation Catalog. 

 LIHTC 2013 update

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
  input_file_pre = Update_Lihtc_2013,
  streetalt_file = 
)


run;
