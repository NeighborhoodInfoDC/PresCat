/**************************************************************************
 Program:  Project_export.sas
 Library:  PresCat
 Project:  NeighborhoodInfo DC
 Author:   P. Tatian
 Created:  01/29/15
 Version:  SAS 9.2
 Environment:  Local Windows session (desktop)
 
 Description:  Export Project database to XLS file.

 Modifications:
**************************************************************************/

%include "L:\SAS\Inc\StdLocal.sas";

** Define libraries **;
%DCData_lib( PresCat, local=n )

ods tagsets.excelxp file="L:\Libraries\PresCat\Prog\Dev\Project_export.xls" style=Minimal options(sheet_interval='None' );

proc print data=PresCat.Project;
  id nlihc_id;
run;

ods tagsets.excelxp close;

