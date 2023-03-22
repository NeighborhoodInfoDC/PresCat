/**************************************************************************
 Program:  346_Fix_Portner_Flats.sas
 Library:  Prescat
 Project:  Urban-Greater DC
 Author:   P. Tatian
 Created:  03/21/23
 Version:  SAS 9.4
 Environment:  Local Windows session (desktop)
 GitHub issue:  346
 
 Description:  Fix addresses, parcels. and related data for Portner
 Flats (NL000243).
 
 Only include address_id = 298461 and SSL = '0204    0851'.
 
 SSL = '0204    0208' is former Portner Place and does not seem to be
 part of tax credit development. 

 Modifications:
**************************************************************************/

%include "\\sas1\DCdata\SAS\Inc\StdLocal.sas";

** Define libraries **;
%DCData_lib( Prescat )
%DCData_lib( Mar )
%DCData_lib( Realprop )
%DCData_lib( Rod )
%DCData_lib( DHCD )

%let revisions = Fix addresses and parcels for Portner Flats (NL000243).;


title2 "Current addresses for Portner Flats";

proc print data=Prescat.Building_geocode;
  where nlihc_id = 'NL000243';
  id nlihc_id;
  var bldg_address_id bldg_addre bldg_units_mar ssl;
run;

title2 "Current parcels for Portner Flats";

proc print data=Prescat.Parcel;
  where nlihc_id = 'NL000243';
  id nlihc_id;
  var ssl in_last_ownerpt parcel_owner_name parcel_type;
run;

title2;


** Create replacement parcel and address data **;

data NL000234_parcel;

  length Nlihc_id $ 16;
  
  retain Nlihc_id 'NL000243' parcel_address_id 298461;
  
  merge 
    Realprop.Parcel_base
    Realprop.Parcel_base_who_owns (keep=ssl ownername_full ownercat);
  by ssl;
  where SSL = '0204    0851';
  
  
  keep 
    SSL Nlihc_id parcel_address_id 
    in_last_ownerpt ownerpt_extractdat_last saledate
    ownername_full ownercat ui_proptype
    x_coord y_coord;

  rename
    ownerpt_extractdat_last = Parcel_info_source_date
    saledate = Parcel_owner_date
    ownername_full = Parcel_owner_name
    ownercat = Parcel_owner_type
    ui_proptype = Parcel_type
    x_coord = parcel_x
    y_coord = parcel_y
  ;

run;

data NL000243_building_geocode;

  length Nlihc_id $ 16 Proj_name $ 80;
  
  retain Nlihc_id 'NL000243' Proj_name 'Portner Flats (Portner Place)';
  
  set Mar.Address_points_view;
  where address_id = 298461;
  
  ** Cluster names **;
  
  length Cluster_tr2000_name $ 120;
	    
  Cluster_tr2000_name = left( put( Cluster_tr2000, $clus00b. ) );
  
  keep
    Nlihc_id Proj_name address_id fulladdress active_res_occupancy_count 
    zip anc2012 cluster2017 cluster_tr2000 Cluster_tr2000_name latitude longitude 
    x y geo2010 geo2020 geobg2020 geoblk2020 psa2012 ssl ward2012 ward2022;

  rename
    address_id = bldg_address_id
    fulladdress = bldg_addre
    latitude = bldg_lat
    longitude = bldg_lon
    active_res_occupancy_count = bldg_units_mar
    x = bldg_x
    y = bldg_y
    zip = bldg_zip
  ;
  
run;


** Create new Building_geocode data set;

data Building_geocode;

  length Cluster_tr2000_name $ 120;

  set
    Prescat.Building_geocode (where=(nlihc_id ~= 'NL000243'))
    NL000243_building_geocode;
  by nlihc_id bldg_addre;
  
  format Bldg_image_url ;

run;

%Finalize_data_set( 
  /** Finalize data set parameters **/
  data=Building_geocode,
  out=Building_geocode,
  outlib=PresCat,
  label="Preservation Catalog, Building-level geocoding info",
  sortby=Nlihc_id Bldg_addre,
  archive=N,
  /** Metadata parameters **/
  revisions=%str(&revisions),
  /** File info parameters **/
  printobs=0
)

title2 "New addresses for Portner Flats";

proc print data=Building_geocode;
  where nlihc_id = 'NL000243';
  id nlihc_id;
  var bldg_address_id bldg_addre bldg_units_mar ssl;
run;

title2;

** Create new Project_geocode data set;

%Create_project_geocode(
  data=Building_geocode, 
  revisions=%str(&revisions),
  compare=N,
  archive=N
)


** Create new Parcel data set;

data Parcel;

  set
    Prescat.Parcel (where=(nlihc_id ~= 'NL000243'))
    NL000234_parcel;
  by nlihc_id ssl;
  
  informat _all_ ;
  
run;

%Finalize_data_set( 
  /** Finalize data set parameters **/
  data=Parcel,
  out=Parcel,
  outlib=PresCat,
  label="Preservation Catalog, Real property parcels",
  sortby=nlihc_id ssl,
  archive=N,
  /** Metadata parameters **/
  revisions=%str(&revisions),
  /** File info parameters **/
  printobs=0
)

title2 "New parcels for Portner Flats";

proc print data=Parcel;
  where nlihc_id = 'NL000243';
  id nlihc_id;
  var ssl in_last_ownerpt parcel_owner_name parcel_type;
run;

title2;

** Create new Realprop data set;

%Update_real_property( Parcel=Parcel, revisions=%str(&revisions) )

title2 'New real property records for Portner Flats';

proc print data=Real_property n;
  where nlihc_id = 'NL000243';
  id nlihc_id;
run;

title2;

