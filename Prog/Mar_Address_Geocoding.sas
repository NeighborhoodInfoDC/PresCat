/**************************************************************************
 Program:  MAR_Address_Geocoding.sas
 Library:  PresCat
 Project:  NeighborhoodInfo DC
 Author:   NStrayer
 Created:  03/13/18
 Version:  SAS 9.2
 Environment:  Local Windows session (desktop)
 
 Description:  Add missing building and parcels for current projects based on MAR unit county

 Modifications:
**************************************************************************/

%include "L:\SAS\Inc\StdLocal.sas";

** Define libraries **;
%DCData_lib( DHCD )
%DCData_lib( PresCat ) 
%DCData_lib( MAR ) 


proc sql noprint;

  create table Bldg_units_mar as
  select coalesce( a.bldg_address_id, b.address_id ) as bldg_address_id, 
    a.nlihc_id, b.active_res_occupancy_count as Bldg_units_mar
  from PresCat.Building_geocode as a 
  left join Mar.Address_points_view as b
  on a.bldg_address_id = b.address_id
  order by nlihc_id, bldg_addre;
quit;

proc summary data=Bldg_units_mar;
  by nlihc_id;
  var Bldg_units_mar;
  output out=Proj_units_mar (drop=_type_ _freq_) sum=Proj_units_mar;
run;

proc compare 
    base=PresCat.Project (keep=nlihc_id proj_units_tot) 
    compare=Proj_units_mar (keep=nlihc_id proj_units_mar) 
    nosummary nodate listall maxprint=(400,32000)
    method=absolute criterion=5 out=Comp_results;
id nlihc_id;
  var proj_units_tot;
  with proj_units_mar;
run;

** Read in parcel list **;

proc import datafile= "L:\Libraries\PresCat\Raw\MAR_addresses_rev_20190819.csv" 
out=property_addr2
dbms=csv replace;
guessingrows=max;
run; 

data property_addr2_b;

  set property_addr2 (where=(not(missing(nlihc_id))));

run;

** Parse out individual addresses from parcel address ranges **;

%Rcasd_address_parse( data=property_addr2_b, out=property_addr_parsed, addr=premiseadd, keepin=, id=nlihc_id ssl ownername )

proc print data=property_addr_parsed;
run;

** Run geocoder to verify addresses against MAR **;

%DC_mar_geocode( data=property_addr_parsed, staddr=Address, out=property_addr_parsed_geo )

proc sort data=property_addr2_b out=property_addr2_nodup nodupkey;
  by ssl;
run;

proc sql noprint;
  create table Full_addr_list as
    select coalesce( A.Address_id, Mar.Address_id ) as Address_id, 
        A.premiseadd, A.ownername, A.ssl, A.nlihc_id, Mar.fulladdress
    from Mar.Address_points_view as Mar
    right join
    ( select coalesce( xref.ssl, prop.ssl ) as ssl, xref.Address_id, prop.premiseadd, prop.ownername, prop.nlihc_id
      from Mar.Address_ssl_xref as xref
      right join 
      property_addr2_nodup as prop
    on xref.ssl = prop.ssl ) as A
  on A.Address_id = Mar.Address_id
  order by A.ownername, A.premiseadd, A.ssl, A.Address_id;
quit;
