/**************************************************************************
 Program:  Update_MFIS_2015_09.sas
 Library:  PresCat
 Project:  NeighborhoodInfo DC
 Author:   P. Tatian
 Created:  11/3/15
 Version:  SAS 9.2
 Environment:  Local Windows session (desktop)
 
 Description:  Update Preservation Catalog with latest 
 HUD MFIS update file.

 Modifications:
**************************************************************************/

%include "L:\SAS\Inc\StdLocal.sas";

** Define libraries **;
%DCData_lib( PresCat, local=n )
%DCData_lib( HUD, local=n )


%Update_MFIS( Update_file=MFIS_2015_09, Finalize=Y )


