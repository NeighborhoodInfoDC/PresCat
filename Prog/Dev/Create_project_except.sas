/**************************************************************************
 Program:  Create_project_except.sas
 Library:  PresCat
 Project:  NeighborhoodInfo DC
 Author:   P. Tatian
 Created:  01/09/15
 Version:  SAS 9.2
 Environment:  Local Windows session (desktop)
 
 Description:  Create initial subsidy exception data set (blank).

 Modifications:
**************************************************************************/

%include "L:\SAS\Inc\StdLocal.sas";

** Define libraries **;
%DCData_lib( PresCat, local=n )

data PresCat.Project_except (label="Preservation Catalog, project exception file");

  set PresCat.Project 
    (obs=0
     keep=Nlihc_id Status Subsidized Cat_At_Risk
          Cat_Expiring Cat_Failing_Insp Cat_More_Info Cat_Lost
          Cat_Replaced Proj_Name Proj_Addre Proj_City Proj_ST Proj_Zip
          Proj_Units_Tot Proj_Units_Assist_Min Proj_Units_Assist_Max
          Hud_Own_Effect_dt Hud_Own_Name Hud_Own_Type Hud_Mgr_Name
          Hud_Mgr_Type);

  length Except_date 8 Except_init $ 8;
  
  label 
    Except_date = "Date exception added"
    Except_init = "Initials of person entering exception";
  
  format Except_date mmddyy10.;
  
run;

%File_info( data=PresCat.Project_except, stats= )

