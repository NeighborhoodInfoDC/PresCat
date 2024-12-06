/**************************************************************************
 Program:  Update_MFIS_2024_10.sas
 Library:  PresCat
 Project:  Urban-Greater DC
 Author:   Rodrigo Garcia
 Created:  12/5/24
 Version:  SAS 9.4
 Environment:  Local Windows session (desktop)
 GitHub issue:  Issue #472
 
 Description:  Update Preservation Catalog with latest 
 HUD MFIS update file.

 Modifications:
**************************************************************************/

%include "\\sas1\DCdata\SAS\Inc\StdLocal.sas";

** Define libraries **;
%DCData_lib( PresCat )
%DCData_lib( HUD )


%Update_MFIS( Update_file=MFIS_2024_10 )


