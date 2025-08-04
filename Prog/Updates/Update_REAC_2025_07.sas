/**************************************************************************
 Program:  Update_REAC_2025_07.sas
 Library:  PresCat
 Project:  Urban-Greater DC
 Author:   Rodrigo G
 Created:  8/3/2025
 Version:  SAS 9.4
 Environment:  Local Windows session (desktop)
 GitHub issue:  #485
 
 Description:  Update Preservation Catalog with latest HUD REAC scores.
 
 These messages can be ignored in the LOG:
   WARNING: The MASTER data set contains more than one observation for a BY group.
   WARNING: The data set ... contains a duplicate observation at observation number 2.

 Modifications:
**************************************************************************/

%include "F:\DCdata\SAS\Inc\StdRemote.sas";

** Define libraries **;
%DCData_lib( PresCat )
%DCData_lib( HUD )


%Update_REAC( Update_file=REAC_2025_07, Finalize=N )


