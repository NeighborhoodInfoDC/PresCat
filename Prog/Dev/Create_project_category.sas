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

%include "\\sas1\DCdata\SAS\Inc\StdLocal.sas";

** Define libraries **;
%DCData_lib( PresCat, local=n )

data PresCat.Project_category (label="Preservation Catalog, project category");

  length
    Nlihc_id      $  8
    Proj_Name     $ 80
    Category_Code $  1;
    
  set PresCat.Project;
  
  format Category_code $Categrn.;
  
  keep Nlihc_id Proj_name Category_code Cat_At_Risk Cat_Lost Cat_More_Info Cat_Replaced;

run;

%File_info( data=PresCat.Project_category )

