/**************************************************************************
 Program:  Update_MFIS_2021_04.sas
 Library:  PresCat
 Project:  Urban-Greater DC
 Author:   P. Tatian
 Created:  6/2/201
 Version:  SAS 9.4
 Environment:  Local Windows session (desktop)
 GitHub issue:  266
 
 Description:  Update Preservation Catalog with latest 
 HUD MFIS update file.

 Modifications:
**************************************************************************/

%include "\\sas1\DCdata\SAS\Inc\StdLocal.sas";

** Define libraries **;
%DCData_lib( PresCat )
%DCData_lib( HUD )


%Update_MFIS( Update_file=MFIS_2021_04 )


