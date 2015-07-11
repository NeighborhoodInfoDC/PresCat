/**************************************************************************
 Program:  Brookland_manor.sas
 Library:  PresCat
 Project:  NeighborhoodInfo DC
 Author:   P. Tatian
 Created:  10/02/14
 Version:  SAS 9.2
 Environment:  Local Windows session (desktop)
 
 Description:  Get information on Brookland Manor (Brentwood
 Village).

 Modifications:
**************************************************************************/

%include "L:\SAS\Inc\StdLocal.sas";

** Define libraries **;
%DCData_lib( PresCat, local=n )
%DCData_lib( RealProp, local=n )
%DCData_lib( Mar, local=n )

title2 'PresCat.Project';

data _null_;
  set PresCat.Project (where=(nlihc_id='NL000046'));
  file print;
  put / '--------------------';
  put (_all_) (= /);
run;

title2 'PresCat.Subsidy';

data _null_;
  set PresCat.Subsidy (where=(nlihc_id='NL000046'));
  file print;
  put / '--------------------';
  put (_all_) (= /);
run;

title2 'PresCat.Parcel';

proc print data=PresCat.Parcel (where=(nlihc_id='NL000046'));
  id nlihc_id;
  var ssl in_last_ownerpt Parcel_owner_date Parcel_owner_name Parcel_type;
run;

title2 'PresCat.Building_geocode';

proc print data=PresCat.Building_geocode (where=(nlihc_id='NL000046'));
  id nlihc_id;
  var Bldg_address_id Bldg_addre Ssl;
run;

title2 'RealProp.Parcel_base';

proc print data=RealProp.Parcel_base;
  where ownername =: 'BRENTWOOD ASSOC';
  id ssl;
  var premiseadd ownername ownname2 in_last_ownerpt ui_proptype;
run;

title2 'RealProp.Parcel_units';

proc print data=RealProp.Parcel_units;
  where ssl in (
    "3953    0001",
    "3953    0002",
    "3953    0003",
    "3954    0001",
    "3954    0002",
    "3954    0003",
    "3954    0004",
    "3954    0005",
    "4024    0001",
    "4024    0002",
    "4024    0003",
    "4024    0004",
    "4025    0001",
    "4025    0002",
    "4025    0003",
    "4025    0004",
    "4025    0005",
    "4025    0006",
    "4025    0007" );
  id ssl;
  var units_: ;
  sum units_: ;
run;


