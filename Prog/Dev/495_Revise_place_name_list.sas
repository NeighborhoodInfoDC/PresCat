/**************************************************************************
 Program:  495_Revise_place_name_list.sas
 Library:  PresCat
 Project:  Urban-Greater DC
 Author:   P. Tatian
 Created:  07/30/25
 Version:  SAS 9.4
 Environment:  Local Windows session (desktop)
 GitHub issue:  495
 
 Description:  Revise Place_name_list from Mar.Points_of_interest in 
 PresCat data files.
 
 Review geographies. psa2019 and VoterPre2012 are missing from 
 Building_geocode and Project_geocode.
 

 Modifications:
**************************************************************************/

%include "\\sas1\DCdata\SAS\Inc\StdLocal.sas";

** Define libraries **;
%DCData_lib( PresCat )
%DCData_lib( Mar )


%Create_place_name_list( by=bldg_address_id )

proc sort data=PresCat.Building_geocode out=Building_geocode_sort;
  by bldg_address_id;
run;

data Building_geocode;

  merge 
    Building_geocode_sort (in=in1 drop=Place_name_list Place_name_id_list ID)
    Place_name_list_bldg_address_id
    Mar.Address_points_view (keep=address_id psa2019 voterpre2012 rename=(address_id=bldg_address_id));
  by bldg_address_id;
  
  if in1 and not( missing( bldg_address_id ) );
  
run;

%Finalize_data_set( 
  data=Building_geocode,
  out=Building_geocode,
  outlib=PresCat,
  label="Preservation Catalog, Building-level geocoding info",
  sortby=nlihc_id bldg_addre,
  revisions=%str(Update Place_name_list. Drop Place_name_id_list. Add psa2019 and voterpre2012.)
)


** Project_geocode **;

%Create_project_geocode( data=Building_geocode, revisions=%str(Update Place_name_list. Drop Place_name_id_list. Add psa2019 and voterpre2012.) )


