/**************************************************************************
 Program:  Update_Sec8mf_2026_07_remote.sas
 Library:  PresCat
 Project:  Urban-Greater DC
 Author:   P. Tatian
 Created:  07/09/2026
 Version:  SAS 9.4
 Environment:  Remote session (SAS1)
 GitHub issue:  
 
 Description:  Update Preservation Catalog with latest HUD Sec 8 MF
 update file.

 Modifications:
**************************************************************************/

%include "F:\DCDATA\SAS\Inc\StdRemote.sas";

** Define libraries **;
%DCData_lib( PresCat )
%DCData_lib( HUD )

options nominoperator;
%Update_Sec8mf( Update_file=Sec8mf_2026_07 )

