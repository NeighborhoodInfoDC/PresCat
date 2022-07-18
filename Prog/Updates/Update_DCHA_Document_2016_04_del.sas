/**************************************************************************
 Program:  Update_DCHA_Document_2016_04_del.sas
 Library:  PresCat
 Project:  NeighborhoodInfo DC
 Author:   P. Tatian
 Created:  10/07/16
 Version:  SAS 9.2
 Environment:  Local Windows session (desktop)
 
 Description:  Delete duplicate projects NL000375 and NL001019 from
 all Catalog data sets.

 Modifications:
**************************************************************************/

%include "\\sas1\DCdata\SAS\Inc\StdLocal.sas";

** Define libraries **;
%DCData_lib( PresCat )


%Delete_catalog_projects( Project_list="NL000375" "NL001019" )

run;
