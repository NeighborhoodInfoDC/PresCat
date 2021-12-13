/**************************************************************************
 Program:  Update_MFIS_2021_11.sas
 Library:  PresCat
 Project:  Urban-Greater DC
 Author:   W.Oliver
 Created:  12/13/2021
 Version:  SAS 9.4
 Environment:  Local Windows session (desktop)
 GitHub issue:  
 
 Description:  Update Preservation Catalog with latest 
 HUD MFIS update file.

 Modifications:
**************************************************************************/

%include "\\sas1\DCdata\SAS\Inc\StdLocal.sas";

** Define libraries **;
%DCData_lib( PresCat )
%DCData_lib( HUD )


%Update_REAC( Update_file=REAC_2021_11 )


