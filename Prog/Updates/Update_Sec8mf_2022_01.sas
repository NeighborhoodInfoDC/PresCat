/**************************************************************************
 Program:  Update_Sec8mf_yyyy_mm.sas
 Library:  PresCat
 Project:  Urban-Greater DC
 Author:   
 Created:  
 Version:  SAS 9.4
 Environment:  Local Windows session (desktop)
 GitHub issue:  
 
 Description:  Update Preservation Catalog with latest HUD Sec 8 MF
 update file.

 Modifications:
**************************************************************************/

%include "\\sas1\DCdata\SAS\Inc\StdLocal.sas";

** Define libraries **;
%DCData_lib( PresCat )
%DCData_lib( HUD )

options nominoperator;
%Update_Sec8mf( Update_file=Sec8mf_2022_01 )

