/**************************************************************************
 Program:  488_Add_place_name.sas
 Library:  PresCat
 Project:  Urban-Greater DC
 Author:   P. Tatian
 Created:  07/14/25
 Version:  SAS 9.4
 Environment:  Local Windows session (desktop)
 GitHub issue:  495
 
 Description:  Revise Place_name_list from Mar.Points_of_interest in 
 PresCat data files.
 
 review geographies. psa2019 and VoterPre2012 are missing from Building_geocode and Project_geocode.
 

 Modifications:
**************************************************************************/

%include "\\sas1\DCdata\SAS\Inc\StdLocal.sas";

** Define libraries **;
%DCData_lib( PresCat )
%DCData_lib( Mar )


** Reduce Place_name to one per address_id **;

proc sql noprint;
  create table Place_name as
  select distinct Nlihc_id, Place_name from
  (
    select 
      coalesce( Addr.bldg_address_id, POI.address_id ) as bldg_address_id, Addr.Nlihc_id, POI.Place_name, POI.Place_name_id 
      from PresCat.Building_geocode as Addr left join Mar.Points_of_interest as POI
    on Addr.bldg_address_id = POI.address_id
    where not( missing( POI.Place_name ) )
  )
  order by Nlihc_id, Place_name;
quit;

proc print data=Place_name (obs=40);
  by nlihc_id;
  id nlihc_id;
run;

data Place_name_list;

  set Place_name;
  by nlihc_id;

  retain Place_name_list;
  
  length Place_name_list $ 1000;
  
  if first.nlihc_id then do;
    Place_name_list = "";
  end;
  
  Place_name_list = catx( '; ', Place_name_list, propcase( Place_name ) );
  
  if last.nlihc_id then output;
  
  drop Place_name;
  
  label
    Place_name_list = "List of MAR point of interest names (aliases)";
    
run;

proc print data=Place_name_list (obs=40);
run;

ENDSAS;


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

