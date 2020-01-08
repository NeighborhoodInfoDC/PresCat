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
%DCData_lib( RealProp )

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

/**********************
proc sql noprint;
  create table property_addr2_b as
  select coalesce( addr.ssl, parcel.ssl ) as ssl, addr.nlihc_id, addr.ownername, addr.premiseadd, 
    parcel.in_last_ownerpt
  from property_addr2 as addr left join RealProp.Parcel_base_who_owns as parcel
  on addr.ssl = parcel.ssl
  where not( missing( nlihc_id ) )
  order by nlihc_id, ssl;
quit;


** Parse out individual addresses from parcel address ranges **;

%Rcasd_address_parse( data=property_addr2_b, out=property_addr_parsed, addr=premiseadd, keepin=, id=nlihc_id ssl ownername )

proc print data=property_addr_parsed;
run;

** Run geocoder to verify addresses against MAR **;

%DC_mar_geocode( data=property_addr_parsed, staddr=Address, out=property_addr_parsed_geo )

%Dup_check(
  data=property_addr2,
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
**********************************/

** Add missing parcels to Catalog **;

proc sql noprint;
  create table New_parcel_list as
        select coalesce( addr.ssl, parcel.ssl ) as ssl, addr.nlihc_id, parcel.*
        from property_addr2 as addr 
        left join 
        ( select coalesce( a.ssl, b.ssl, c.ssl ) as ssl, a.in_last_ownerpt, 
            a.ui_proptype as Parcel_type, 
            a.saledate as Parcel_owner_date,
            a.ownerpt_extractdat_last as Parcel_info_source_date,
            b.ownername_full as Parcel_owner_name, 
            b.ownercat as Parcel_owner_type, 
            c.x_coord as Parcel_x, 
            c.y_coord as Parcel_y
          from RealProp.Parcel_base as a
          left join
          RealProp.Parcel_base_who_owns as b
          on a.ssl = b.ssl
          left join
          RealProp.Parcel_geo as c
          on b.ssl = c.ssl
        ) as parcel
        on addr.ssl = parcel.ssl
        where not( missing( nlihc_id ) );
    quit;


proc sort data=New_parcel_list out=New_parcel_list_nodup nodupkey;
  by nlihc_id ssl;
run;

data Parcel;

  length Nlihc_id $ 16 ssl $ 17;

  merge 
    New_parcel_list_nodup 
      (keep=nlihc_id ssl in_last_ownerpt parcel_:)
    PresCat.Parcel;
  by nlihc_id ssl;

  format Nlihc_id ;
  informat Nlihc_id ;

run;

proc compare base=PresCat.Parcel compare=Parcel listall maxprint=(40,32000);
  id nlihc_id ssl;
run;



***********************************************************************;
***********************************************************************;
***********************************************************************;

proc sql noprint;
  create table Full_addr_list as
    select coalesce( A.Address_id, Mar.Address_id ) as Address_id, A.*,
        Mar.fulladdress, Mar.status, Mar.active_res_occupancy_count as Bldg_units_mar,
        Mar.latitude as Bldg_lat, Mar.longitude as Bldg_lon, Mar.x as Bldg_x, Mar.y as Bldg_y,
        Mar.zip as Bldg_zip, Mar.anc2012, Mar.cluster_tr2000, 
        put( Cluster_tr2000, $clus00b. ) as Cluster_tr2000_name,
        Mar.geo2010, Mar.psa2012, Mar.ward2012
    from Mar.Address_points_view as Mar
    right join
    ( select coalesce( xref.ssl, prop.ssl ) as ssl, xref.Address_id, prop.*
      from Mar.Address_ssl_xref as xref
      right join 
      Parcel as prop
      /*
      ( select coalesce( addr.ssl, parcel.ssl ) as ssl, addr.nlihc_id, addr.ownername, addr.premiseadd, 
          parcel.*
        from property_addr2 as addr 
        left join 
        ( select coalesce( a.ssl, b.ssl, c.ssl ) as ssl, a.in_last_ownerpt, 
            a.ui_proptype as Parcel_type, 
            a.saledate as Parcel_owner_date,
            a.ownerpt_extractdat_last as Parcel_info_source_date,
            b.ownername_full as Parcel_owner_name, 
            b.ownercat as Parcel_owner_type, 
            c.x_coord as Parcel_x, 
            c.y_coord as Parcel_y
          from RealProp.Parcel_base as a
          left join
          RealProp.Parcel_base_who_owns as b
          on a.ssl = b.ssl
          left join
          RealProp.Parcel_geo as c
          on b.ssl = c.ssl
        ) as parcel
        on addr.ssl = parcel.ssl
        where not( missing( nlihc_id ) )
      ) as prop
      */
    on xref.ssl = prop.ssl ) as A
  on A.Address_id = Mar.Address_id
  order by nlihc_id, A.ssl, A.Address_id;
quit;

/*
%Dup_check(
  data=Full_addr_list,
  by=ssl nlihc_id,
  id=Address_id,
  out=_dup_check,
  listdups=Y,
  count=dup_check_count,
  quiet=N,
  debug=N
)
*/

proc sort data=Full_addr_list out=Full_addr_list_nodup nodupkey;
  where not( missing( address_id ) or missing( nlihc_id ) ) and in_last_ownerpt;
  by nlihc_id address_id;
run;

proc tabulate data=Full_addr_list_nodup format=comma10.0 noseps missing;
  where in_last_ownerpt;
  class nlihc_id Parcel_owner_name;
  var bldg_units_mar;
  table 
    /** Rows **/
    nlihc_id * (all=' ' Parcel_owner_name=' ' ),
    /** Columns **/
    n sum=' '*bldg_units_mar
    / indent=2
  ;
run;

** Add missing addresses to Catalog **;

proc sort data=PresCat.Building_geocode out=PresCat_Building_geocode;
  by nlihc_id bldg_address_id;
run;

data Building_geocode;

  merge
    Full_addr_list_nodup 
      (keep=nlihc_id address_id bldg_: anc2012 cluster_tr2000: geo2010 psa2012 ssl ward2012
       rename=(address_id=Bldg_address_id))
    PresCat_Building_geocode;
  by nlihc_id bldg_address_id;

run;

proc compare base=PresCat_Building_geocode compare=Building_geocode listall maxprint=(40,32000);
  id nlihc_id bldg_address_id;
run;

** Compare MAR unit counts with Catalog project unit counts **;

proc sql noprint;
  create table Bldg_units_mar_2 as
  select coalesce( a.bldg_address_id, b.address_id ) as bldg_address_id, 
    a.nlihc_id, /*a.in_last_ownerpt,*/
    b.active_res_occupancy_count as Bldg_units_mar
/*  from Building_geocode as a */
  from 
  ( select Building_geocode.*, Parcel_base.ssl/*, Parcel_base.in_last_ownerpt*/
    from Building_geocode left join RealProp.Parcel_base as Parcel_base
    on Building_geocode.ssl = Parcel_base.ssl
  ) as a
  left join Mar.Address_points_view as b
  on a.bldg_address_id = b.address_id
  /*where in_last_ownerpt*/
  order by nlihc_id, bldg_address_id;
quit;

proc summary data=Bldg_units_mar_2;
  by nlihc_id;
  var Bldg_units_mar;
  output out=Proj_units_mar_2 (drop=_type_ _freq_) sum=Proj_units_mar;
run;

proc compare 
    base=PresCat.Project (keep=nlihc_id proj_units_tot) 
    compare=Proj_units_mar_2 (keep=nlihc_id proj_units_mar) 
    /*nosummary*/ nodate listall maxprint=(400,32000)
    method=absolute criterion=5 out=Comp_results;
id nlihc_id;
  var proj_units_tot;
  with proj_units_mar;
run;

