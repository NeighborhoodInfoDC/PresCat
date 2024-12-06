/**************************************************************************
 Program:  Update_REAC_yyyy_mm.sas
 Library:  PresCat
 Project:  Urban-Greater DC
 Author:   
 Created:  
 Version:  SAS 9.4
 Environment:  Local Windows session (desktop)
 GitHub issue:  
 
 Description:  Update Preservation Catalog with latest HUD REAC scores.
 
 These messages can be ignored in the LOG:
   WARNING: The MASTER data set contains more than one observation for a BY group.
   WARNING: The data set ... contains a duplicate observation at observation number 2.

 Modifications:
**************************************************************************/

%include "\\sas1\DCdata\SAS\Inc\StdLocal.sas";

** Define libraries **;
%DCData_lib( PresCat )
%DCData_lib( HUD )


%Update_REAC( Update_file=REAC_yyyy_mm )


