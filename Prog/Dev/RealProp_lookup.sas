/**************************************************************************
 Program:  RealProp_lookup.sas
 Library:  PresCat
 Project:  NeighborhoodInfo DC
 Author:   P. Tatian
 Created:  01/29/15
 Version:  SAS 9.2
 Environment:  Local Windows session (desktop)
 
 Description:  Look up property info in RealProp.Parcel_base.

 Modifications:
**************************************************************************/

%include "L:\SAS\Inc\StdLocal.sas";

** Define libraries **;
%DCData_lib( PresCat )
%DCData_lib( Realprop )

data _null_;
  set RealProp.Parcel_base (where=(compbl(ssl) in: ( "PAR 0229", "PAR 0299", "5914" )));
  file print;
  put / '--------------------';
  **put (_all_) (= /);
  put (ssl square suffix lot premiseadd ownername usecode) (= /);
run;

