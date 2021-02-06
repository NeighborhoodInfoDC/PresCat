/**************************************************************************
 Program:  Strategy_units_built.sas
 Library:  PresCat
 Project:  NeighborhoodInfo DC
 Author:   P. Tatian
 Created:  11/25/14
 Version:  SAS 9.2
 Environment:  Local Windows session (desktop)
 
 Description:  Units built per year for preservation strategy working
group paper.

 Modifications:
**************************************************************************/

%include "\\sas1\DCdata\SAS\Inc\StdLocal.sas";

** Define libraries **;
%DCData_lib( PresCat )
%DCData_lib( OCC )
%DCData_lib( RealProp, local=n )
%DCData_lib( DHCD, local=n ) 

data A;

  merge 
    OCC.YearNewResDev_parcel
      (where=(ui_proptype=:'1')
       in=in1)
    RealProp.Parcel_rental_units
      (rename=(ui_proptype=ui_proptype_units))
    Dhcd.Units_regression
      (keep=ssl units_full);
  by ssl;

  if in1;
    
  if ui_proptype in ( '10', '11' ) then units_total = 1;
  else units_total = units_active;

  if missing( units_total ) then units_total = units_full;
  
run;

proc tabulate data=A format=comma10.0 noseps missing;
  where 2012 >= YearBuiltMax >= 1990;
  class ui_proptype YearBuiltMax;
  var units_total;
  table 
    /** Pages **/
    Nmiss='Missing unit counts' N='Parcels' sum='Units',
    /** Rows **/
    YearBuiltMax='Year built',
    /** Columns **/
    units_total=' ' * (all='Total' ui_proptype=' ')
  /rts=45
  ;
run;

proc format;
  value yearrng
    1990-2001 = '1990 to 2001'
    2002-2012 = '2002 to 2012';
    
proc summary data=A nway;
  where 2012 >= YearBuiltMax >= 1990;
  class YearBuiltMax;
  var units_total;
  output out=A_annual sum=;
run;

proc tabulate data=A_annual format=comma10.0 noseps missing;
  class YearBuiltMax;
  var units_total;
  table 
    /** Pages **/
    mean='Average units per year',
    /** Rows **/
    YearBuiltMax='Year built',
    /** Columns **/
    units_total='Total'
  /rts=45
  ;
  format YearBuiltMax yearrng.;
run;

    