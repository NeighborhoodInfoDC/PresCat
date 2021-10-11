/**************************************************************************
 Program:  Update_Sec8mf_2018_04.sas
 Library:  PresCat
 Project:  NeighborhoodInfo DC
 Author:   Wilton Oliver
 Created:  05/02/2018
 Version:  SAS 9.2
 Environment:  Local Windows session (desktop)
 
 Description:  Update Preservation Catalog with latest HUD Sec 8 MF
 update file.

 Modifications:
**************************************************************************/

%include "\\sas1\DCdata\SAS\Inc\StdLocal.sas";

** Define libraries **;
%DCData_lib( PresCat )
%DCData_lib( HUD )


%Update_Sec8mf( Update_file=Sec8mf_2018_04 )

