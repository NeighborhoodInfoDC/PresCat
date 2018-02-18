/**************************************************************************
 Program:  Add_new_projects_test.sas
 Library:  PresCat
 Project:  NeighborhoodInfo DC
 Author:   P. Tatian
 Created:  02/17/18
 Version:  SAS 9.2
 Environment:  Local Windows session (desktop)
 
 Description:  Add new projects to Preservation Catalog. 

 TEST PROGRAM

 Modifications:
**************************************************************************/

%include "L:\SAS\Inc\StdLocal.sas";

** Define libraries **;
%DCData_lib( PresCat )
%DCData_lib( MAR )
%DCData_lib( RealProp )


%Add_new_projects(
  input_file_pre = Buildings_for_geocoding_2017-05-25,
  streetalt_file = 
)


run;
