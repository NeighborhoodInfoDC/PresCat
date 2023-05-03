/**************************************************************************
 Program:  Update_Sec8mf_2022_10.sas
 Library:  PresCat
 Project:  Urban-Greater DC
 Author:   Donovan Harvey
 Created:  12/05/2022
 Version:  SAS 9.4
 Environment:  Local Windows session (desktop)
 GitHub issue:  #326
 
 Description:  Update Preservation Catalog with latest HUD Sec 8 MF
 update file.

 Modifications:
**************************************************************************/

%include "\\sas1\DCdata\SAS\Inc\StdLocal.sas";

** Define libraries **;
%DCData_lib( PresCat )
%DCData_lib( HUD )

options nominoperator;
%Update_Sec8mf( Update_file=Sec8mf_2022_10 )

