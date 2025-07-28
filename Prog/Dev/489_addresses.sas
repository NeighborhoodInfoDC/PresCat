/**************************************************************************
 Program:  489_addresses.sas
 Library:  PresCat
 Project:  Urban-Greater DC
 Author:   P. Tatian
 Created:  07/28/25
 Version:  SAS 9.4
 Environment:  Local Windows session (desktop)
 GitHub issue:  489
 
 Description:  Check on list of additional addresses for section 8
properties (NL000261 and NL000280). 

 Modifications:
**************************************************************************/

%include "\\sas1\DCdata\SAS\Inc\StdLocal.sas";

** Define libraries **;
%DCData_lib( PresCat )
%DCData_lib( MAR )

/*
data Place_name_list;

  set MAR.Points_of_interest (keep=address_id place_name place_name_id);
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
*/

data Addresses;

  infile datalines dsd stopover;
  
  length nlihc_id $ 16 bldg_addre $ 80;

  input nlihc_id bldg_addre;

datalines;
NL000261,2230 Savannah Terrace SE
NL000261,2234 Savannah Terrace SE
NL000261,2235 Savannah Terrace SE
NL000261,2239 Savannah Terrace SE
NL000261,2244 Savannah Terrace SE
NL000261,2245 Savannah Terrace SE
NL000261,2249 Savannah Terrace SE
NL000261,3225 23rd Street SE
NL000261,3245 23rd Street SE
NL000261,3249 23rd Street SE
NL000261,3253 23rd Street SE
NL000261,3255 23rd Street SE
NL000280,2400 Elvans Road SE
NL000280,2402 Elvans Road SE
NL000280,2404 Elvans Road SE
NL000280,2406 Elvans Road SE
NL000280,2408 Elvans Road SE
NL000280,2410 Elvans Road SE
NL000280,2412 Elvans Road SE
NL000280,2412 Elvans Road SE
NL000280,2414 Elvans Road SE
NL000280,2416 Elvans Road SE
NL000280,2418 Elvans Road SE
NL000280,2420 Elvans Road SE
NL000280,2422 Elvans Road SE
NL000280,2424 Elvans Road SE
;


run;

** Geocode addresses **;

%DC_mar_geocode(
  geo_match=Y,
  data=Addresses,
  out=Addresses_geo,
  staddr=bldg_addre,
  zip=,
  id=,
  ds_label=,
  listunmatched=Y
)

proc print data=Addresses_geo;
  var M_EXACTMATCH bldg_addre bldg_addre_std address_id _score_;
run;

proc sort data=Addresses_geo;
  by nlihc_id address_id;
run;


** Check against Building_geocode **;

proc sort data=PresCat.Building_geocode out=Building_geocode_sort;
  by nlihc_id bldg_address_id;
run;

data Check;

  merge 
    Building_geocode_sort 
      (in=in1 
       where=(nlihc_id in ('NL000261', 'NL000280')))
    Addresses_geo 
      (in=in2 
       drop=bldg_addre
       rename=(address_id=bldg_address_id bldg_addre_std=bldg_addre)
       where=(M_EXACTMATCH));
  by nlihc_id bldg_address_id;
  
  in_building_geocode = in1;
  in_addresses_geo = in2;
    
run;

proc print data=Check;
  var nlihc_id bldg_address_id bldg_addre ssl in_:;
  sum in_: ;
run;


proc sql noprint;
  create table Place_name as
  select distinct 
    coalesce( Addr.bldg_address_id, POI.address_id ) as bldg_address_id, Addr.Nlihc_id, POI.Place_name, POI.Place_name_id 
    from Check as Addr left join Mar.Points_of_interest as POI
  on Addr.bldg_address_id = POI.address_id
  where not( missing( POI.Place_name ) )
  order by Addr.Nlihc_id, Addr.bldg_address_id;
quit;


proc print data=Place_name;
  var nlihc_id bldg_address_id Place_name:;
run;



data Place_name_list_address;

  set Place_name (keep=nlihc_id bldg_address_id place_name);
  by nlihc_id bldg_address_id;

  retain Place_name_list;
  
  length Place_name_list $ 1000;
  
  if first.bldg_address_id then do;
    Place_name_list = "";
  end;
  
  Place_name_list = catx( '; ', Place_name_list, propcase( Place_name ) );
  
  if last.bldg_address_id then output;
  
  drop place_name;
  
  label
    Place_name_list = "List of MAR point of interest names (aliases)";
    
run;

proc print data=Place_name_list_address;
  var nlihc_id bldg_address_id Place_name:;
run;


proc sort data=Place_name out=Place_name_by_project nodupkey;
  by nlihc_id place_name;
run;

data Place_name_list_project;

  set Place_name_by_project (keep=nlihc_id bldg_address_id place_name);
  by nlihc_id;

  retain Place_name_list;
  
  length Place_name_list $ 1000;
  
  if first.nlihc_id then do;
    Place_name_list = "";
  end;
  
  Place_name_list = catx( '; ', Place_name_list, propcase( Place_name ) );
  
  if last.nlihc_id then output;
  
  drop place_name;
  
  label
    Place_name_list = "List of MAR point of interest names (aliases)";
    
run;

proc print data=Place_name_list_project;
  var nlihc_id Place_name:;
run;

