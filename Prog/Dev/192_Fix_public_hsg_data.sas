/**************************************************************************
 Program:  192_Fix_public_hsg_data.sas
 Library:  PresCat
 Project:  Urban-Greater DC
 Author:   P. Tatian
 Created:  09/20/19
 Version:  SAS 9.4
 Environment:  Local Windows session (desktop)
 GitHub issue:  192
 
 Description:  Correct Catalog address and parcel data for public housing.

 Modifications:
**************************************************************************/

%include "L:\SAS\Inc\StdLocal.sas";

** Define libraries **;
%DCData_lib( PresCat )

** Read in parcel corrections **;

filename fimport "D:\DCData\Libraries\PresCat\Prog\Dev\Public_hsg_parcels_notincat_corr.csv" lrecl=1000;

proc import out=Notincat_corr
    datafile=fimport
    dbms=csv replace;
  datarow=2;
  getnames=yes;
  guessingrows=max;
run;

filename fimport clear;

proc sort data=Notincat_corr;
  by ssl;
run;

%File_info( data=Notincat_corr, printobs=0, stats=, freqvars=nlihc_id )

filename fimport "D:\DCData\Libraries\PresCat\Prog\Dev\Public_hsg_parcels_notincat_oth_corr.csv" lrecl=1000;

proc import out=Notincat_oth_corr
    datafile=fimport
    dbms=csv replace;
  datarow=2;
  getnames=yes;
  guessingrows=max;
run;

filename fimport clear;

%File_info( data=Notincat_oth_corr, printobs=0, stats=, freqvars=nlihc_id )

** Create updated parcel data set **;

data Parcel_additions;

  set
    Notincat_corr
    Notincat_oth_corr;
  
  where nlihc_id =: "NL";

  informat _all_ ;
  format _all_ ;
  
  keep ssl nlihc_id;
  
run;

proc sort data=Parcel_additions;
  by nlihc_id ssl;
run;

data Parcel_a;

  set
    PresCat.Parcel
    Parcel_additions;
  by nlihc_id ssl;

run;

%File_info( data=Parcel_a )
