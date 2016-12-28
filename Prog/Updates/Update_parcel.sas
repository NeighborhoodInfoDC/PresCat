/**************************************************************************
 Program:  Update_parcel.sas
 Library:  PresCat
 Project:  NeighborhoodInfo DC
 Author:   P. Tatian
 Created:  10/09/13
 Version:  SAS 9.1
 Environment:  Local Windows session (desktop)
 
 Description:  Update Parcel data set for DC Preservation Catalog

 Modifications:
**************************************************************************/

%include "L:\SAS\Inc\StdLocal.sas";

** Define libraries **;
%DCData_lib( PresCat )
%DCData_lib( MAR, local=n )
%DCData_lib( RealProp, local=n )


data Building_geocode;

  set 
    PresCat.Building_geocode;
  by Nlihc_id;

run;

proc sql noprint;
  create table Parcel_a as
  select 
    coalesce( Bldg.Bldg_address_id, Xref.address_id ) as address_id, 
    Bldg.nlihc_id,
    Xref.ssl 
    from Building_geocode (where=(not(missing(Bldg_address_id)))) as Bldg 
      left join Mar.Address_ssl_xref as xref
  on Bldg.Bldg_address_id = Xref.address_id
  order by Bldg.nlihc_id, Xref.ssl;
quit;

data Parcel_a2;

  set 
    Parcel_a 
    Building_geocode
      (keep=nlihc_id ssl Bldg_address_id
       rename=(Bldg_address_id=Address_id));
  by nlihc_id;
  
  if missing( ssl ) then delete;
  
  length ssl_clean $ 17;
  
  ssl_clean = left( scan( ssl, 1, '-' ) );
  
  label
    ssl_clean = "Property identification number (square/suffix/lot)"
    ssl = "Original property identification number";
  
  rename ssl_clean=Ssl ssl=Ssl_orig;
  
run;

** Remove duplicate project/ssl combinations **;

proc sort data=Parcel_a2 nodupkey;
  by nlihc_id ssl;

** Merge with Parcel_base, Parcel_geo, and Parcel_who_owns **;

proc sort data=Parcel_a2;
  by ssl;
  
data Parcel (label="Preservation Catalog, Real property parcels");

  length Nlihc_id $ 16 Ssl $ 17;
  
  merge
    Parcel_a2 
      (in=in_Parcel)
    RealProp.Parcel_base 
      (keep=ssl ui_proptype saledate in_last_ownerpt ownerpt_extractdat_last
       in=in_Parcel_base)
    RealProp.Parcel_geo 
      (keep=ssl x_coord y_coord)
    RealProp.Parcel_base_who_owns
      (keep=ssl Ownername_full Ownercat);
  by ssl;
  
  if in_Parcel;
  
  if x_coord = 0 then x_coord = .u;
  if y_coord = 0 then y_coord = .u;
  
  if not in_Parcel_base then do;
    %warn_put( msg="SSL not found in Parcel_base; will not be saved. " nlihc_id= ssl= ssl_orig= )
    delete;
  end;
  
  informat _all_ ;

  label
    address_id = "Parcel MAR address ID"
    NLIHC_ID = "Preservation Catalog project ID";

  rename 
    ui_proptype=Parcel_type ownername_full=Parcel_owner_name saledate=Parcel_owner_date 
    ownerpt_extractdat_last=Parcel_Info_Source_Date
    address_id=Parcel_address_id
    x_coord=Parcel_x y_coord=Parcel_y Ownercat=Parcel_owner_type;
  
run;


** Finalize data set **;

%Finalize_dataset(
  data=Parcel,
  out=Parcel,
  outlib=PresCat,
  label="Preservation Catalog, Real property parcels",
  sortby=nlihc_id ssl,
  revisions=%str(Update with latest PresCat.Building_geocode, RealProp.Parcel_base, and Mar.Address_ssl_xref.),
  archive=y,
  freqvars=parcel_type parcel_owner_type 
)

