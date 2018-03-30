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
  left join Mar.Address_points_2016_01 as b
  on a.bldg_address_id = b.address_id
  order by nlihc_id, bldg_addre;
quit;

proc summary data=Bldg_units_mar;
  by nlihc_id;
  var Bldg_units_mar;
  output out=Proj_units_mar (drop=_type_ _freq_) sum=Proj_units_mar;
run;

proc compare base=PresCat.Project compare=Proj_units_mar 
    listall maxprint=(400,32000)
    method=absolute criterion=5 out=Comp_results;
id nlihc_id;
  var proj_units_tot;
  with proj_units_mar;
run;

proc import datafile= "D:\DCData\Libraries\PresCat\MAR_addresses.csv" 
out=property_addr2
dbms=csv;
run; 
options dkricond=nowarning dkrocond=nowarning ;
%Rcasd_address_parse( data= property_addr2, out=property_addr_parsed, addr=premiseadd, debug=N, id=ssl )

%DC_mar_geocode( data=property_addr_parsed, staddr=Address, out=proprety_addr_parsed_geo )
