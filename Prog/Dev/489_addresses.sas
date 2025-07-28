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
%DCData_lib( Realprop )
%DCData_lib( ROD )
%DCData_lib( DHCD )

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
  keep_geo=
    Address_id Latitude Longitude ANC2023 Anc2012 
    Cluster_tr2000 Geo2010 Geo2020 GeoBg2020
    GeoBlk2020 Psa2012 Ward2012 Ward2022 cluster2017 ssl,
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
       keep=nlihc_id bldg_address_id ssl
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
  create table Check_units as
    select Check.*, Mar.address_id, Mar.active_res_occupancy_count as bldg_units_mar
    from Check left join Mar.Address_points_view as Mar
    on Check.bldg_address_id = Mar.Address_id
    where not Check.in_building_geocode
    order by nlihc_id, bldg_addre;
  quit;
run;

data Building_geocode;

  set
    PresCat.Building_geocode
    Check_units
      (drop=m_: _: address_id
       rename=(x=Bldg_x y=Bldg_y latitude=Bldg_lat longitude=Bldg_lon);
  by nlihc_id bldg_addre;
  
  if missing( Proj_name ) then do;
    if nlihc_id = "NL000280" then Proj_name = "Forest Ridge & The Vistas (Formerly Stanton-Wellington Apts)";
    else if nlihc_id = "NL000261" then Proj_name = "Woodberry Village (Savannah Ridge)";
  end;
  
  ** Cluster names **;
  
  if missing( Cluster_tr2000_name ) then Cluster_tr2000_name = put( Cluster_tr2000, $clus00b. );
    
  drop in_: ;
    
run;

%Dup_check(
  data=Building_geocode,
  by=nlihc_id bldg_addre,
  id=bldg_address_id,
  out=_dup_check,
  listdups=Y,
  count=dup_check_count,
  quiet=N,
  debug=N
)

proc compare base=PresCat.Building_geocode compare=Building_geocode listall maxprint=(40,32000);
  id nlihc_id bldg_addre;
run;

%Finalize_data_set( 
  data=Building_geocode,
  out=Building_geocode,
  outlib=PresCat,
  label="Preservation Catalog, Building-level geocoding info",
  sortby=nlihc_id bldg_addre,
  revisions=%str(Add missing addresses for NL000261 and NL000280.)
)


** Project_geocode **;

%Create_project_geocode( data=Building_geocode, revisions=%str(Add missing addresses for NL000261 and NL000280.) )


** Update parcel list **;

proc sql noprint;
  create table Check_ssl as
    select ssl_list.nlihc_id, coalesce( ssl_list.ssl, pb.ssl ) as ssl, 
      pb.in_last_ownerpt, pb.ownername_full as parcel_owner_name, 
      pb.ownerpt_extractdat_last as parcel_info_source_date, pb.ownercat as parcel_owner_type,
      pb.saledate as parcel_owner_date, pb.ui_proptype as parcel_type, 
      pb.x_coord as parcel_x, pb.y_coord as parcel_y
    from 
    (
      select distinct check.nlihc_id, check.ssl from Check  
    ) as ssl_list 
    left join Realprop.Parcel_base_who_owns as pb
    on ssl_list.ssl = pb.ssl
    order by nlihc_id, ssl_list.ssl;
  quit;
run;

proc print data=Check_ssl;
  var nlihc_id ssl parcel_owner_name;
run;

** Update parcels for NL000261 and NL000280 **;

data Parcel;

  merge
    Prescat.Parcel
    Check_ssl;
  by nlihc_id ssl;
  
run;

proc compare base=PresCat.Parcel compare=Parcel listall maxprint=(40,32000);
  id nlihc_id ssl;
run;

%Finalize_data_set( 
  data=Parcel,
  out=Parcel,
  outlib=PresCat,
  label="Preservation Catalog, Real property parcels",
  sortby=nlihc_id ssl,
  revisions=%str(Add missing parcels for NL000261 and NL000280.)
)


%Update_real_property( Parcel=Parcel, revisions=%str(Add missing parcels for NL000261 and NL000280.) )



