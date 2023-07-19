/**************************************************************************
 Program:  Import_Topa_CBO_data.sas
 Library:  Prescat
 Project:  Urban-Greater DC
 Author:   P. Tatian
 Created:  07/18/23
 Version:  SAS 9.4
 Environment:  Local Windows session (desktop)
 GitHub issue:  388
 
 Description:  Import TOPA data from CBOs.

 Modifications:
**************************************************************************/

%include "\\sas1\DCdata\SAS\Inc\StdLocal.sas";

** Define libraries **;
%DCData_lib( Prescat )

filename fimport "\\sas1\DCData\Libraries\PresCat\Raw\TOPA\Topa_CBO_sheet 4.28.23_with_var_names_with_sales.csv" lrecl=10000;

proc import out=Topa_CBO_sheet
    datafile=fimport
    dbms=csv replace;
  datarow=3;
  getnames=yes;
  guessingrows=max;
run;

filename fimport clear;

data Topa_CBO_sheet;

  set Topa_CBO_sheet;
  where not( missing( id ) );
  
  format _all_ ;
  informat _all_ ;
  
  drop VAR: drop: ;

run;

%File_info( data=Topa_CBO_sheet )
