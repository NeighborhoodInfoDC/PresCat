/**************************************************************************
 Program:  Update_Sec8mf_2014_11.sas
 Library:  PresCat
 Project:  NeighborhoodInfo DC
 Author:   P. Tatian
 Created:  7/18/15
 Version:  SAS 9.2
 Environment:  Local Windows session (desktop)
 
 Description:  Update Preservation Catalog with latest HUD Sec 8 MF
 update file.

 Modifications:
**************************************************************************/

/*%include "L:\SAS\Inc\StdLocal.sas";*/
%include "C:\DCData\SAS\Inc\StdLocal.sas";

** Define libraries **;
%DCData_lib( PresCat, local=n )
%DCData_lib( HUD, local=n )


%Update_Sec8mf( Update_file=Sec8mf_2014_11, Finalize=N, Subsidy_except=Subsidy_except_test, Project_except=Project_except_test, Quiet=Y )

