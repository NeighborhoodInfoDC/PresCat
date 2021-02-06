/**************************************************************************
 Program:  Project_check.sas
 Library:  PresCat
 Project:  NeighborhoodInfo DC
 Author:   P. Tatian
 Created:  09/27/14
 Version:  SAS 9.2
 Environment:  Local Windows session (desktop)
 
 Description:  Check projects with missing parcel info.

 Modifications:
**************************************************************************/

%include "\\sas1\DCdata\SAS\Inc\StdLocal.sas";

** Define libraries **;
%DCData_lib( PresCat, local=n )
%DCData_lib( RealProp, local=n )

%let PROJECT_CHECK = 'NL000046';

title2 "PresCat.Project";

data _null_;
  set PresCat.Project;
  where nlihc_id = &PROJECT_CHECK;
  file print;
  put / '--------------------';
  put (_all_) (= /);
run;

title2 'PresCat.Subsidy_mfa';

data _null_;
  set PresCat.Subsidy_mfa;
  where nlihc_id = &PROJECT_CHECK;
  file print;
  put / '--------------------';
  put (_all_) (= /);
run;

title2 "PresCat.Subsidy";

proc print data=PresCat.Subsidy;
  where nlihc_id = &PROJECT_CHECK;
  id Nlihc_id;
run;

title2 "PresCat.Parcel";

proc print data=PresCat.Parcel;
  where nlihc_id = &PROJECT_CHECK;
  id Nlihc_id;
run;

/*
title2 "RealProp.Parcel_base";

data _null_;
  set RealProp.Parcel_base;
  where ssl = '0216    0027';
  file print;
  put / '--------------------';
  put (_all_) (= /);
run;



run;
