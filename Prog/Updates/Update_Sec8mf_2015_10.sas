/**************************************************************************
 Program:  Update_Sec8mf_2015_10.sas
 Library:  PresCat
 Project:  NeighborhoodInfo DC
 Author:   P. Tatian
 Created:  11/3/15
 Version:  SAS 9.2
 Environment:  Local Windows session (desktop)
 
 Description:  Update Preservation Catalog with latest HUD Sec 8 MF
 update file.

 Modifications:
**************************************************************************/

%include "L:\SAS\Inc\StdLocal.sas";

** Define libraries **;
%DCData_lib( PresCat, local=n )
%DCData_lib( HUD, local=n )


%Update_Sec8mf( Update_file=Sec8mf_2015_10, Finalize=Y )

