/**************************************************************************
 Program:  Create_project_update_history.sas
 Library:  PresCat
 Project:  NeighborhoodInfo DC
 Author:   P. Tatian
 Created:  07/18/15
 Version:  SAS 9.2
 Environment:  Local Windows session (desktop)
 
 Description:  Create initial Project_update_history file for 
 Preservation Catalog (empty file).

 Modifications:
**************************************************************************/

/*%include "L:\SAS\Inc\StdLocal.sas";*/
%include "C:\DCData\SAS\Inc\StdLocal.sas";

** Define libraries **;
%DCData_lib( PresCat, local=n )

data PresCat.Project_update_history (label="Preservation Catalog, Project update history");

  length
    Nlihc_id $ 8
    Subsidy_Info_Source $ 40
    Subsidy_Info_Source_Date 8
    Update_Dtm 8
    Hud_Own_Effect_dt_BASE
    Hud_Own_Effect_dt_COMPARE
    Hud_Own_Effect_dt_EXCEPT 8
    Hud_Own_Name_BASE
    Hud_Own_Name_COMPARE
    Hud_Own_Name_EXCEPT $ 80
    Hud_Own_Type_BASE
    Hud_Own_Type_COMPARE
    Hud_Own_Type_EXCEPT $ 2
    Hud_Mgr_Name_BASE
    Hud_Mgr_Name_COMPARE
    Hud_Mgr_Name_EXCEPT $ 80
    Hud_Mgr_Type_BASE
    Hud_Mgr_Type_COMPARE
    Hud_Mgr_Type_EXCEPT $ 2;
   
  delete;
  
  label
    Subsidy_Info_Source = "Source for update"
    Subsidy_Info_Source_Date = "Date of update source"
    Update_Dtm = "Datetime update ran"
  ;
  
  format 
    Subsidy_Info_Source $infosrc. Subsidy_Info_Source_Date mmddyy10. Update_Dtm datetime16. 
    Hud_Own_Type_BASE Hud_Own_Type_COMPARE Hud_Own_Type_EXCEPT
    Hud_Mgr_Type_BASE Hud_Mgr_Type_COMPARE Hud_Mgr_Type_EXCEPT
    $ownmgrtype.;
  
run;

%File_info( data=PresCat.Project_update_history, printobs=0, stats= )

