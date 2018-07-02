/**************************************************************************
 Program:  Add_new_projects_yyyymmdd.sas
 Library:  PresCat
 Project:  NeighborhoodInfo DC
 Author:   
 Created:  
 Version:  SAS 9.4
 Environment:  Local Windows session (desktop)
 
 Description:  Add new projects to Preservation Catalog. 

 

 Modifications:
**************************************************************************/

%include "L:\SAS\Inc\StdLocal.sas";

** Define libraries **;
%DCData_lib( PresCat )
%DCData_lib( MAR, local=n )
%DCData_lib( RealProp, local=n )
%DCData_lib( ROD, local=n )
%DCData_lib( DHCD, local=n )


%Add_new_projects(
  input_file_pre = ,
  streetalt_file = 
)


run;
