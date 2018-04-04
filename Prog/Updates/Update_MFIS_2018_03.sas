/**************************************************************************
 Program:  Update_MFIS_2018_03.sas
 Library:  PresCat
 Project:  NeighborhoodInfo DC
 Author:   Noah Strayer
 Created:  4/4/2018
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


%Update_MFIS( Update_file=MFIS_2018_03 )


