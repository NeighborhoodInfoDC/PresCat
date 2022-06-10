/**************************************************************************
 Program:  Update_REAC_yyyy_mm.sas
 Library:  PresCat
 Project:  Urban-Greater DC
 Author:   Donovan Harvey
 Created:  6/10/2022
 Version:  SAS 9.4
 Environment:  Local Windows session (desktop)
 GitHub issue:  #278
 
 Description:  Update Preservation Catalog with latest HUD REAC scores.

 Modifications:
**************************************************************************/

%include "\\sas1\DCdata\SAS\Inc\StdLocal.sas";

** Define libraries **;
%DCData_lib( PresCat )
%DCData_lib( HUD )


%Update_REAC( Update_file=REAC_2022_05 )


