/**************************************************************************
 Program:  Update_Sec8mf_2025_07.sas
 Library:  PresCat
 Project:  Urban-Greater DC
 Author:   Rodrigo G
 Created:  8/3/25
 Version:  SAS 9.4
 Environment:  Local Windows session (desktop)
 GitHub issue:  #485
 
 Description:  Update Preservation Catalog with latest HUD Sec 8 MF
 update file.

 Modifications:
**************************************************************************/

%include "F:\DCdata\SAS\Inc\StdRemote.sas";

** Define libraries **;
%DCData_lib( PresCat )
%DCData_lib( HUD )

options nominoperator;
%Update_Sec8mf( Update_file=Sec8mf_2025_07, Finalize=Y )

