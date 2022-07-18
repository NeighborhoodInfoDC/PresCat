/**************************************************************************
 Program:  Update_Sec8mf_2018_01.sas
 Library:  PresCat
 Project:  NeighborhoodInfo DC
 Author:   Noah Strayer
 Created:  2/6/18
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


%Update_Sec8mf( Update_file=Sec8mf_2018_01 )

