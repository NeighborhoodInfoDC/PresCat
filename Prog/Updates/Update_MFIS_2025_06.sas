/**************************************************************************
 Program:  Update_MFIS_yyyy_mm.sas
 Library:  PresCat
 Project:  Urban-Greater DC
 Author:   Rodrigo G
 Created:  8/3/2025
 Version:  SAS 9.4
 Environment:  Local Windows session (desktop)
 GitHub issue:  #485
 
 Description:  Update Preservation Catalog with latest 
 HUD MFIS update file.

 Modifications:
**************************************************************************/

%include "F:\DCdata\SAS\Inc\StdRemote.sas";

** Define libraries **;
%DCData_lib( PresCat )
%DCData_lib( HUD )


%Update_MFIS( Update_file=MFIS_2025_06, Finalize=N )


