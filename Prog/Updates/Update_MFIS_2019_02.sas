/**************************************************************************
 Program:  Update_MFIS_2019_02.sas
 Library:  PresCat
 Project:  Urban-Greater DC
 Author:   P Tatian
 Created:  3/7/2019
 Version:  SAS 9.4
 Environment:  Local Windows session (desktop)
 GitHub issue:  188
 
 Description:  Update Preservation Catalog with latest 
 HUD MFIS update file.

 Modifications:
**************************************************************************/

%include "\\sas1\DCdata\SAS\Inc\StdLocal.sas";

** Define libraries **;
%DCData_lib( PresCat )
%DCData_lib( HUD )


%Update_MFIS( Update_file=MFIS_2019_02 )


