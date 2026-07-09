/**************************************************************************
 Program:  Update_REAC_2026_07_remote.sas
 Library:  PresCat
 Project:  Urban-Greater DC
 Author:   P. Tatian
 Created:  07/09/2026
 Version:  SAS 9.4
 Environment:  Remote session (SAS1)
 GitHub issue:  
 
 Description:  Update Preservation Catalog with latest HUD REAC scores.
 
 These messages can be ignored in the LOG:
   WARNING: The MASTER data set contains more than one observation for a BY group.
   WARNING: The data set ... contains a duplicate observation at observation number 2.

 Modifications:
**************************************************************************/

%include "F:\DCDATA\SAS\Inc\StdRemote.sas";

** Define libraries **;
%DCData_lib( PresCat )
%DCData_lib( HUD )


%Update_REAC( Update_file=REAC_2026_07 )


