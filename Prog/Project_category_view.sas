/**************************************************************************
 Program:  Project_category_view.sas
 Library:  PresCat
 Project:  NeighborhoodInfo DC
 Author:   P. Tatian
 Created:  03/31/16
 Version:  SAS 9.2
 Environment:  Local Windows session (desktop)
 
 Description:  Create SAS View with combined Project and
Project_category data sets.

 Modifications:
**************************************************************************/

%include "L:\SAS\Inc\StdLocal.sas";

** Define libraries **;
%DCData_lib( PresCat )

proc sql noprint;
  create view PresCat.Project_category_view (label="Preservation Catalog, Project + Project_Category") as
    select * from 
      PresCat.Project 
        (drop=Category_code Cat_at_risk Cat_lost Cat_more_info Cat_replaced 
              Proj_Name Proj_Name_old Proj_Addre_old) as Project 
      left join 
      PresCat.Project_category 
        (keep=nlihc_id Proj_Name Category_code Cat_at_risk Cat_lost Cat_more_info Cat_replaced) 
          as Category
      on Project.Nlihc_id = Category.Nlihc_id
     order by Project.Nlihc_id;
  quit;

run;

%File_info( data=PresCat.Project_category_view )

