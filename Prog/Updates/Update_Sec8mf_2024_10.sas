/**************************************************************************
 Program:  Update_Sec8mf_2024_10.sas
 Library:  PresCat
 Project:  Urban-Greater DC
 Author:   Rodrigo Garcia
 Created:  12/5/2024
 Version:  SAS 9.4
 Environment:  Local Windows session (desktop)
 GitHub issue: ISSUE #472
 
 Description:  Update Preservation Catalog with latest HUD Sec 8 MF
 update file.

 Modifications:
**************************************************************************/

%include "\\sas1\DCdata\SAS\Inc\StdLocal.sas";

** Define libraries **;
%DCData_lib( PresCat )
%DCData_lib( HUD )

options nominoperator;
%Update_Sec8mf( Update_file=Sec8mf_2024_10 )

