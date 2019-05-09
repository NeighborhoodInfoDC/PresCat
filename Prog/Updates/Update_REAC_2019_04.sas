/**************************************************************************
 Program:  Update_MFIS_2019_04.sas
 Library:  PresCat
 Project:  Urban-Greater DC
 Author:   W. Oliver
 Created:  05/09/2019
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


%Update_REAC( Update_file=REAC_2019_04 )


