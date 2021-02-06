/**************************************************************************
 Program:  Update_MFIS_2020_05.sas
 Library:  PresCat
 Project:  Urban-Greater DC
 Author:   W.Oliver
 Created:  6/5/2020
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


%Update_MFIS( Update_file=MFIS_2020_05 )


