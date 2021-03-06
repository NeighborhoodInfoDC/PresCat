/**************************************************************************
 Program:  Update_Sec8mf_2019_05.sas
 Library:  PresCat
 Project:  Urban-Greater DC
 Author:   W. Oliver
 Created:  06/04/2019
 Version:  SAS 9.4
 Environment:  Local Windows session (desktop)
 GitHub issue:  update - #202
 
 Description:  Update Preservation Catalog with latest HUD Sec 8 MF
 update file.

 Modifications:
**************************************************************************/

%include "\\sas1\DCdata\SAS\Inc\StdLocal.sas";

** Define libraries **;
%DCData_lib( PresCat )
%DCData_lib( HUD )


%Update_Sec8mf( Update_file=Sec8mf_2019_05 )

