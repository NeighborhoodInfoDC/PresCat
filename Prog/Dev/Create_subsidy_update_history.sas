/**************************************************************************
 Program:  Create_subsidy_update_history.sas
 Library:  PresCat
 Project:  NeighborhoodInfo DC
 Author:   P. Tatian
 Created:  07/11/15
 Version:  SAS 9.2
 Environment:  Local Windows session (desktop)
 
 Description:  Create initial Subsidy_update_history file for 
 Preservation Catalog (empty file).

 Modifications:
**************************************************************************/

/*%include "L:\SAS\Inc\StdLocal.sas";*/
%include "C:\DCData\SAS\Inc\StdLocal.sas";

** Define libraries **;
%DCData_lib( PresCat, local=n )

data PresCat.Subsidy_update_history (label="Preservation Catalog, Subsidy update history");

  length
    Nlihc_id $ 8
    Subsidy_id 8
    Subsidy_Info_Source $ 40
    Subsidy_Info_Source_Date 8
    Update_Dtm 8
    Subsidy_Info_Source_ID $ 40
    Compl_end_BASE
    Compl_end_COMPARE
    Compl_end_EXCEPT 8
    POA_end_BASE
    POA_end_COMPARE
    POA_end_EXCEPT 8
    POA_start_BASE
    POA_start_COMPARE
    POA_start_EXCEPT 8
    Program_BASE
    Program_COMPARE
    Program_EXCEPT $ 32
    Subsidy_Active_BASE
    Subsidy_Active_COMPARE
    Subsidy_Active_EXCEPT 3
    Units_Assist_BASE
    Units_Assist_COMPARE
    Units_Assist_EXCEPT 8
    rent_to_FMR_description_BASE
    rent_to_FMR_description_COMPARE
    rent_to_FMR_description_EXCEPT $ 40;
   
  delete;
  
  label
    Subsidy_Info_Source = "Source for update"
    Subsidy_Info_Source_Date = "Date of update source"
    Update_Dtm = "Datetime update ran"
  ;
  
  format Subsidy_Info_Source $infosrc. Subsidy_Info_Source_Date mmddyy10. Update_Dtm datetime16.;
  
run;

%File_info( data=PresCat.Subsidy_update_history, printobs=0, stats= )

