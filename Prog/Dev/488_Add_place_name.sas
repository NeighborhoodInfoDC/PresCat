/**************************************************************************
 Program:  488_Add_place_name.sas
 Library:  PresCat
 Project:  Urban-Greater DC
 Author:   P. Tatian
 Created:  07/14/25
 Version:  SAS 9.4
 Environment:  Local Windows session (desktop)
 GitHub issue:  488
 
 Description:  Add Place_name from Mar.Points_of_interest to 
 PresCat data files.

 Modifications:
**************************************************************************/

%include "\\sas1\DCdata\SAS\Inc\StdLocal.sas";

** Define libraries **;
%DCData_lib( PresCat )
%DCData_lib( Mar )


** Reduce Place_name to one per address_id **;

proc sort data=Mar.Points_of_interest out=Points_of_interest;
  where not( missing( Place_name ) );
  by address_id descending created_date descending last_edited_date;
run;

data Place_name;

  set Points_of_interest (keep=address_id place_name place_name_id);
  by address_id;
  
  if first.address_id;
  
run;


** Building_geocode **;

proc sort data=PresCat.Building_geocode out=Building_geocode_sort;
  by bldg_address_id;
run;

data Building_geocode;

  merge 
    Building_geocode_sort (in=in1)
    Place_name (rename=(address_id=bldg_address_id));
  by bldg_address_id;
  
  if in1;

run;

%Finalize_data_set( 
  data=Building_geocode,
  out=Building_geocode,
  outlib=PresCat,
  label="Preservation Catalog, Building-level geocoding info",
  sortby=nlihc_id bldg_addre,
  revisions=%str(Add Place_name, Place_name_id.)
)


** Project_geocode **;

%Create_project_geocode( data=Building_geocode, revisions=%str(Add Place_name, Place_name_id.) )

