/**************************************************************************
 Program:  NL000085_parcels.sas
 Library:  PresCat
 Project:  NeighborhoodInfo DC
 Author:   P. Tatian
 Created:  04/21/14
 Version:  SAS 9.2
 Environment:  Local Windows session (desktop)
 
 Description:  List parcels for NL000085 (Glencrest).

 Modifications:
**************************************************************************/

%include "L:\SAS\Inc\StdLocal.sas";

** Define libraries **;
%DCData_lib( PresCat )
%DCData_lib( RealProp, local=n )

proc print data=RealProp.Parcel_base; 
  where compbl( ssl ) in (
    "5318 0027", 
    "5318 0028", 
    "5318 0029", 
    "5318 0030", 
    "5318 0031", 
    "5318 0022", 
    "5318 0023", 
    "5318 0024", 
    "5318 0025", 
    "5318 0026", 
    "5318 0032", 
    "5318 0033", 
    "5318 0034", 
    "5318 0035", 
    "5318 0036", 
    "5318 0037", 
    "5318 0038", 
    "5318 0039", 
    "5318 0040", 
    "5318 0041"
  );
  id ssl;
  var premiseadd ownername ownname2 saledate ui_proptype;

run;
