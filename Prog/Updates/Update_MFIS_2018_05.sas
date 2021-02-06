/**************************************************************************
 Program:  Update_MFIS_yyyy_mm.sas
 Library:  PresCat
 Project:  NeighborhoodInfo DC
 Author:   W. Oliver
 Created:  07/06/18
 Version:  SAS 9.2
 Environment:  Local Windows session (desktop)
 
 Description:  Update Preservation Catalog with latest 
 HUD MFIS update file.

 Modifications:
**************************************************************************/

%include "\\sas1\DCdata\SAS\Inc\StdLocal.sas";

** Define libraries **;
%DCData_lib( PresCat )
%DCData_lib( HUD )


%Update_MFIS( Update_file=MFIS_2018_05 )


