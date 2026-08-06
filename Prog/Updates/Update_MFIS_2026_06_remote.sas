/**************************************************************************
 Program:  Update_MFIS_2026_06_remote.sas
 Library:  PresCat
 Project:  Urban-Greater DC
 Author:   P. Tatian
 Created:  07/09/2026
 Version:  SAS 9.4
 Environment:  Remote session (SAS1)
 GitHub issue:  
 
 Description:  Update Preservation Catalog with latest 
 HUD MFIS update file.

 Modifications:
**************************************************************************/

%include "F:\DCDATA\SAS\Inc\StdRemote.sas";

** Define libraries **;
%DCData_lib( PresCat )
%DCData_lib( HUD )


%Update_MFIS( Update_file=MFIS_2026_06 )


