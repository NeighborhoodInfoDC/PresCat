/**************************************************************************
 Program:  Change_len_nlihc_id_b.sas
 Library:  PresCat
 Project:  NeighborhoodInfo DC
 Author:   P. Tatian
 Created:  12/28/16
 Version:  SAS 9.2
 Environment:  Local Windows session (desktop)
 
 Description: Change the length of the Preservation Catalog 
 Nlihc_id var from 8 to 16 chars.

 Exception files

 Modifications:
**************************************************************************/

%include "\\sas1\DCdata\SAS\Inc\StdLocal.sas";

** Define libraries **;
%DCData_lib( PresCat )


data PresCat.Project_except (label="Preservation Catalog, Project exception file");

  length Nlihc_id $ 16;

  set PresCat.Project_except;

run;

proc contents data=PresCat.Project_except;
run;

data PresCat.Subsidy_except (label="Preservation Catalog, Project subsidies exception file");

  length Nlihc_id $ 16;

  set PresCat.Subsidy_except;

run;

proc contents data=PresCat.Subsidy_except;
run;

