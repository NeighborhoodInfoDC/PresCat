/**************************************************************************
 Program:  Create_parcel.sas
 Library:  PresCat
 Project:  NeighborhoodInfo DC
 Author:   P. Tatian
 Created:  06/03/17
 Version:  SAS 9.2
 Environment:  Local Windows session (desktop)
 
 Description:  Autocall macro to create updated Parcel data set from
 PresCat.Building_geocode, Mar.Address_ssl_xref,  RealProp.Parcel_base, 
 RealProp.Parcel_geo, and RealProp.Parcel_base_who_owns. 
 
 MAR and RealProp libraries must be declared before calling this macro.

 Modifications:
**************************************************************************/

/** Macro Create_parcel - Start Definition **/

%macro Create_parcel( 
  data=PresCat.Building_geocode, 
  out=Parcel, 
  revisions=, 
  compare=Y,
  finalize=Y, 
  archive=Y 
  );

  proc sql noprint;
    create table _Create_parcel_a as
    select 
      coalesce( Bldg.Bldg_address_id, Xref.address_id ) as address_id, 
      Bldg.nlihc_id,
      Xref.ssl 
      from &data (where=(not(missing(Bldg_address_id)))) as Bldg 
        left join Mar.Address_ssl_xref as xref
    on Bldg.Bldg_address_id = Xref.address_id
    order by Bldg.nlihc_id, Xref.ssl;
  quit;

  data _Create_parcel_b;

    set 
      _Create_parcel_a 
      &data
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

  proc sort data=_Create_parcel_b nodupkey;
    by nlihc_id ssl;

  ** Merge with Parcel_base, Parcel_geo, and Parcel_who_owns **;

  proc sort data=_Create_parcel_b;
    by ssl;
    
  data &out;

    length Nlihc_id $ 16 Ssl $ 17;
    
    merge
      _Create_parcel_b 
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
    
  %if %mparam_is_yes( &compare ) %then %do;
  
    proc sort data=&out;
      by nlihc_id ssl;
    run;
   
    proc compare base=PresCat.Parcel compare=&out listall maxprint=(40,32000);
      id nlihc_id ssl;
    run;
  
  %end;
    
  %if %mparam_is_yes( &finalize ) %then %do;
  
    ** Finalize data set **;

    %Finalize_data_set(
      data=&out,
      out=Parcel,
      outlib=PresCat,
      label="Preservation Catalog, Real property parcels",
      sortby=nlihc_id ssl,
      revisions=%str(&revisions),
      archive=&archive,
      freqvars=parcel_type parcel_owner_type 
    )
    
  %end;
  
  ** Cleanup temporary data sets **;
  
  proc datasets library=work nolist;
    delete _create_parcel_: /memtype=data;
  quit;

%mend Create_parcel;

/** End Macro Definition **/

