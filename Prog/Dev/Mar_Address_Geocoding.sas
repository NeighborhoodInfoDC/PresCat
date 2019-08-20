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

** Compare MAR unit counts with Catalog project unit counts **;

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

** Read in parcel list: manually created list of associated project parcels **;

proc import datafile= "L:\Libraries\PresCat\Raw\MAR_addresses_rev_20190819.csv" 
out=property_addr2
dbms=csv replace;
guessingrows=max;
run; 

/*
data property_addr2_b;

  set property_addr2 (where=(not(missing(nlihc_id))));

run;
*/

proc sql noprint;
  create table property_addr2_b as
  select coalesce( addr.ssl, parcel.ssl ) as ssl, addr.nlihc_id, addr.ownername, addr.premiseadd, parcel.in_last_ownerpt
  from property_addr2 as addr left join RealProp.Parcel_base as parcel
  on addr.ssl = parcel.ssl
  where not( missing( nlihc_id ) )
  order by nlihc_id, ssl;
quit;


/**********************
** Parse out individual addresses from parcel address ranges **;

%Rcasd_address_parse( data=property_addr2_b, out=property_addr_parsed, addr=premiseadd, keepin=, id=nlihc_id ssl ownername )

proc print data=property_addr_parsed;
run;

** Run geocoder to verify addresses against MAR **;

%DC_mar_geocode( data=property_addr_parsed, staddr=Address, out=property_addr_parsed_geo )
**********************************/

%Dup_check(
  data=property_addr2_b,
  by=ssl,
  id=nlihc_id,
  out=_dup_check,
  listdups=Y,
  count=dup_check_count,
  quiet=N,
  debug=N
)


proc sort data=property_addr2_b out=property_addr2_nodup nodupkey;
  by ssl;
run;

proc sql noprint;
  create table Full_addr_list as
    select coalesce( A.Address_id, Mar.Address_id ) as Address_id, 
        A.premiseadd, A.ownername, A.ssl, A.nlihc_id, A.in_last_ownerpt, 
        Mar.fulladdress, Mar.status, Mar.active_res_occupancy_count as Bldg_units_mar
    from Mar.Address_points_view as Mar
    right join
    ( select coalesce( xref.ssl, prop.ssl ) as ssl, xref.Address_id, 
        prop.premiseadd, prop.ownername, prop.nlihc_id, prop.in_last_ownerpt
      from Mar.Address_ssl_xref as xref
      right join 
      property_addr2_nodup as prop
    on xref.ssl = prop.ssl ) as A
  on A.Address_id = Mar.Address_id
  order by A.ownername, A.premiseadd, A.ssl, A.Address_id;
quit;

proc sort data=Full_addr_list out=Full_addr_list_nodupa nodupkey;
  by nlihc_id address_id;
run;

proc tabulate data=Full_addr_list_nodupa format=comma10.0 noseps missing;
  where in_last_ownerpt;
  class nlihc_id ownername;
  var bldg_units_mar;
  table 
    /** Rows **/
    nlihc_id * (all=' ' ownername=' ' ),
    /** Columns **/
    n sum=' '*bldg_units_mar
    / indent=2
  ;
run;

** Add missing parcels to Catalog **;

**** FIRST ATTEMPT. NEEDS WORK ****;

data Parcel;

  merge 
    property_addr2_b
      (keep=nlihc_id ssl in_last_ownerpt ownername 
       rename=(ownername=parcel_owner_name))
    PresCat.Parcel;
  by nlihc_id ssl;

run;

