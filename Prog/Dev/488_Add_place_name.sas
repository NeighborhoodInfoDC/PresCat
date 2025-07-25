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
  by address_id place_name_id;
run;

data Place_name;

  set Points_of_interest (keep=address_id place_name place_name_id);
  by address_id;

  retain Place_name_list Place_name_id_list;
  
  length Place_name_list $ 1000 Place_name_id_list $ 200;
  
  if first.address_id then do;
    Place_name_list = "";
    Place_name_id_list = "";
  end;
  
  Place_name_list = catx( '; ', Place_name_list, Place_name );
  Place_name_id_list = catx( '; ', Place_name_id_list, Place_name_id );
  
  if last.address_id then output;
  
  keep Address_id Place_name_list Place_name_id_list;
  
  label
    Place_name_list = "List of MAR point of interest names (aliases)"
    Place_name_id_list = "List of MAR point of interest IDs";
    
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
  revisions=%str(Add Place_name_list, Place_name_id_list.)
)


** Project_geocode **;

%Create_project_geocode( data=Building_geocode, revisions=%str(Add Place_name_list, Place_name_id_list.) )

