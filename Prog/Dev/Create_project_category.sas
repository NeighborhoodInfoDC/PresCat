/**************************************************************************
 Program:  Create_project_category.sas
 Library:  PresCat
 Project:  NeighborhoodInfo DC
 Author:   P. Tatian
 Created:  07/04/15
 Version:  SAS 9.2
 Environment:  Local Windows session (desktop)
 
 Description:  Create initial Category data set for Preservation
Catalog.

 Modifications:
**************************************************************************/

%include "L:\SAS\Inc\StdLocal.sas";

** Define libraries **;
%DCData_lib( PresCat, local=n )

data PresCat.Project_category (label="Preservation Catalog, project category");

  set PresCat.Project;
  
  keep Nlihc_id Category_code Cat_At_Risk Cat_Lost Cat_More_Info Cat_Replaced;

run;

%File_info( data=PresCat.Project_category )

