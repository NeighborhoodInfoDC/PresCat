/**************************************************************************
 Program:  Update_Sec8mf_yyyy_mm.sas
 Library:  PresCat
 Project:  NeighborhoodInfo DC
 Author:   W. Oliver
 Created:  07/06/18
 Version:  SAS 9.2
 Environment:  Local Windows session (desktop)
 
 Description:  Update Preservation Catalog with latest HUD Sec 8 MF
 update file.

 Modifications:
**************************************************************************/

%include "L:\SAS\Inc\StdLocal.sas";

** Define libraries **;
%DCData_lib( PresCat )
%DCData_lib( HUD )


%Update_Sec8mf( Update_file=Sec8mf_2018_06 )

