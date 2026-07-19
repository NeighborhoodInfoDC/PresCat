/**************************************************************************
 Program:  515_Delete_projects.sas
 Library:  PresCat
 Project:  Urban-Greater DC
 Author:   P. Tatian
 Created:  07/19/26
 Version:  SAS 9.4
 Environment:  Remote session (SAS1)
 GitHub issue:  515
 
 Description:  Remove projects added by mistake. 

 Modifications:
**************************************************************************/

%include "F:\DCDATA\SAS\Inc\StdRemote.sas";

** Define libraries **;
%DCData_lib( PresCat )

%Delete_catalog_projects( Project_list="NL001344" "NL001345" "NL001346" )

run;
