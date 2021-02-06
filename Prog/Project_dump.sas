/**************************************************************************
 Program:  Project_dump.sas
 Library:  PresCat
 Project:  NeighborhoodInfo DC
 Author:   P. Tatian
 Created:  09/09/13
 Version:  SAS 9.1
 Environment:  Windows
 
 Description:  Dump all data on selected projects.

 Modifications:
**************************************************************************/

%include "\\sas1\DCdata\SAS\Inc\StdLocal.sas";

** Define libraries **;
%DCData_lib( PresCat, local=n )
%DCData_lib( HUD )

%let Sel_Nlihc_id = 'NL000137', 'NL000303', 'NL000098', 'NL000999', 'NL000234';
%let Sel_Nlihc_id = 'NL000262';

proc print data=PresCat.DC_Info;
  where nlihc_id in ( &Sel_Nlihc_id );
  id nlihc_id;
  var category Proj_Name Proj_Addre ID_: ;
  title2 'data=PresCat.DC_Info';
run;

proc print data=PresCat.Project;
  where nlihc_id in ( &Sel_Nlihc_id );
  id nlihc_id;
  title2 'data=PresCat.Project';
run;

proc print data=PresCat.Subsidy_mfa;
  where nlihc_id in ( &Sel_Nlihc_id );
  id nlihc_id;
  title2 'data=PresCat.Subsidy_mfa';
run;

proc print data=PresCat.Subsidy;
  where nlihc_id in ( &Sel_Nlihc_id );
  id nlihc_id;
  title2 'data=PresCat.Subsidy';
run;

proc print data=PresCat.Parcel;
  where ssl in ( "5299    0038" );
  id nlihc_id;
  title2 'data=PresCat.Parcel';
run;

title2 'data=HUD.sec8mf_2014_11_dc';
 
data _null_;
  set HUD.sec8mf_2014_11_dc;
  where property_id = 800219652;
  file print;
  put / '--------------------';
  put (_all_) (= /);
run;

title2;

/*
proc sort data=PresCat.DC_Info out=DC_Info;
  by nlihc_id;

proc sort data=PresCat.Subsidy_mfa out=Subsidy_mfa;
  by nlihc_id;

proc compare base=DC_Info compare=Subsidy_mfa maxprint=(40,32000) allvars listequalvar;
  where nlihc_id in ( &Sel_Nlihc_id );
  id nlihc_id;
run;

/*
data _null_;
  
  set PresCat.DC_Info;
  where nlihc_id in ( &Sel_Nlihc_id );
  
  file print;
  put / '--------------------';
  put (_all_) (= /);
run;

/*
proc sql print;
  select nlihc_id from PresCat.DC_Info
  order by nlihc_id desc
;

run;

