/**************************************************************************
 Program:  Create_update_history.sas
 Library:  PresCat
 Project:  NeighborhoodInfo DC
 Author:   P. Tatian
 Created:  12/23/14
 Version:  SAS 9.2
 Environment:  Local Windows session (desktop)
 
 Description:  Create initial Update_history file for Preservation
 Catalog (empty file).

 Modifications:
  01/08/15 PAT Changed Update_date to Update_dtm (datetime).
  07/04/15 PAT Removed Nlihc_ID.
**************************************************************************/

%include "L:\SAS\Inc\StdLocal.sas";

** Define libraries **;
%DCData_lib( PresCat, local=n )

data PresCat.Update_history (label="Preservation Catalog, Update history");

  length
    Update_Dtm 8
    Info_Source $ 40
    Info_Source_Date 8;
   
  delete;
  
  label
    Info_Source = "Source for update"
    Info_Source_Date = "Date of update source"
    Update_Dtm = "Datetime update ran";
  
  format Info_Source $infosrc. Info_Source_Date mmddyy10. Update_Dtm datetime16.;
  
run;

%File_info( data=PresCat.Update_history, printobs=0, stats= )

