/**************************************************************************
 Program:  Update_MFIS_2018_09.sas
 Library:  PresCat
 Project:  NeighborhoodInfo DC
 Author:   Will Oliver
 Created:  11/7/18
 Version:  SAS 9.2
 Environment:  Local Windows session (desktop)
 
 Description:  Update Preservation Catalog with latest 
 HUD MFIS update file.

 Modifications:
**************************************************************************/

%include "L:\SAS\Inc\StdLocal.sas";

** Define libraries **;
%DCData_lib( PresCat )
%DCData_lib( HUD )


%Update_REAC( Update_file=REAC_2018_09 )


