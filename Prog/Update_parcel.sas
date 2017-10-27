/**************************************************************************
 Program:  Update_parcel.sas
 Library:  PresCat
 Project:  NeighborhoodInfo DC
 Author:   M. Cohen
 Created:  09/01/16
 Version:  SAS 9.1
 Environment:  Local Windows session (desktop)
 
 Description:  Update Parcel table for DC Preservation Catalog

 Modifications:

**************************************************************************/

%include "L:\SAS\Inc\StdLocal.sas";

** Define libraries **;
%DCData_lib( PresCat, local=n )
%DCData_lib( MAR, local=n )
%DCData_lib( RealProp, local=n )

%Create_parcel( 
  data=Building_geocode, 
  out=Parcel, 
  revisions=%str(Add new projects from &input_file_pre._*.csv.),
  compare=Y,
  archive=Y 
)

