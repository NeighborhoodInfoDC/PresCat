/**************************************************************************
 Program:  Update_REAC_2020_06.sas
 Library:  PresCat
 Project:  Urban-Greater DC
 Author:   W.Oliver
 Created:  7/10/2020
 Version:  SAS 9.4
 Environment:  Local Windows session (desktop)
 GitHub issue:  
 
 Description:  Update Preservation Catalog with latest 
 HUD MFIS update file.

 Modifications:
**************************************************************************/

%include "L:\SAS\Inc\StdLocal.sas";

** Define libraries **;
%DCData_lib( PresCat )
%DCData_lib( HUD )


%Update_REAC( Update_file=REAC_2020_06 )


