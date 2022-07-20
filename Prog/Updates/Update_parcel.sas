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

%include "\\sas1\DCdata\SAS\Inc\StdLocal.sas";

** Define libraries **;
%DCData_lib( PresCat )
%DCData_lib( MAR, local=n )
%DCData_lib( RealProp, local=n )

%let revisions = %str(Update with latest real property data.);

proc sort data=PresCat.Parcel out=Parcel_sorted;
  by ssl;
run;

data Parcel (label="Preservation Catalog, Real property parcels");

  length Nlihc_id $ 16 Ssl $ 17;
  
  merge
    Parcel_sorted
      (in=in_Parcel)
    RealProp.Parcel_base 
      (keep=ssl ui_proptype saledate in_last_ownerpt ownerpt_extractdat_last
       rename=(ui_proptype=Parcel_type saledate=Parcel_owner_date ownerpt_extractdat_last=Parcel_Info_Source_Date)
       in=in_Parcel_base)
    RealProp.Parcel_geo 
      (keep=ssl x_coord y_coord
       rename=(x_coord=Parcel_x y_coord=Parcel_y))
    RealProp.Parcel_base_who_owns
      (keep=ssl Ownername_full Ownercat
       rename=(ownername_full=Parcel_owner_name Ownercat=Parcel_owner_type));
  by ssl;
  
  if in_Parcel;
  
  if Parcel_x = 0 then Parcel_x = .u;
  if Parcel_y = 0 then Parcel_y = .u;
  
  if not in_Parcel_base then do;
    %warn_put( msg="SSL not found in Parcel_base; will not be saved. " nlihc_id= ssl= ssl_orig= )
    delete;
  end;

  informat _all_ ;

run;


** Finalize data set **;

%Finalize_data_set(
  data=Parcel,
  out=Parcel,
  outlib=PresCat,
  label="Preservation Catalog, Real property parcels",
  sortby=nlihc_id ssl,
  revisions=&revisions,
  archive=n,
  freqvars=parcel_type parcel_owner_type 
)

