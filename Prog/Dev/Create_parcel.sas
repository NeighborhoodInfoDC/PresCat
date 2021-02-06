/**************************************************************************
 Program:  Create_parcel.sas
 Library:  PresCat
 Project:  NeighborhoodInfo DC
 Author:   P. Tatian
 Created:  08/20/13
 Version:  SAS 9.1
 Environment:  Local Windows session (desktop)
 
 Description:  Create Parcel table for DC Preservation Catalog

 Modifications:
  09/27/14 PAT Updated for SAS1.
               Replaced mar.mardba_ssl_xref_mar_new with 
               Mar.Address_ssl_xref.
  10/16/14 PAT Added updated parcels for Brookland Manor (NL000046).
  12/19/14 PAT Added variable labels.
               Truncated parcel IDs with '-' character.
  12/24/14 PAT Added Parcel_Info_Source_Date field.
**************************************************************************/

%include "\\sas1\DCdata\SAS\Inc\StdLocal.sas";

** Define libraries **;
%DCData_lib( PresCat, local=n )
%DCData_lib( MAR, local=n )
%DCData_lib( RealProp, local=n )

/*%file_info( data=mar.mardba_ssl_xref_mar_new )*/

data Parcels_NL000046;

  infile datalines missover dsd dlm='09'x;

  length Nlihc_id $ 8 ssl $ 17;
  
  retain Nlihc_id "NL000046";

  input ssl;
  
  datalines;
3953    0001
3953    0002
3953    0003
3954    0001
3954    0002
3954    0003
3954    0004
3954    0005
4024    0001
4024    0002
4024    0003
4024    0004
4025    0001
4025    0002
4025    0003
4025    0004
4025    0005
4025    0006
4025    0007
;

run;

/*
proc print data=Parcels_NL000046;
run;
*/

proc sql noprint; 
  create table Parcels_address_NL000046 as
  select
    coalesce( Par.ssl, Xref.ssl ) as ssl,
    Par.Nlihc_id,
    Xref.address_id
  from Parcels_NL000046 as Par 
    left join Mar.Address_ssl_xref as xref
  on Par.ssl = Xref.ssl;
  
  create table Address_NL000046 as
  select Nlihc_id, address_id as Bldg_address_id, count(ssl) as Parcel_count 
  from Parcels_address_NL000046 
  group by Nlihc_id, Bldg_address_id;
quit;

/*
proc print;
run;
*/

data Building_geocode;

  set 
    PresCat.Building_geocode 
    /*
    Address_NL000046
      (where=(Bldg_address_id not in ( 149306, 149307, 150405 ))) */;
  by Nlihc_id;

run;

%Dup_check(
  data=Building_geocode (where=(not(missing(Bldg_address_id)))),
  by=Bldg_address_id,
  id=nlihc_id proj_name Bldg_addre,
  out=_dup_check,
  listdups=Y,
  count=dup_check_count,
  quiet=N,
  debug=N
)

proc sql noprint;
  create table Parcel_a as
  select 
    coalesce( Bldg.Bldg_address_id, Xref.address_id ) as address_id, 
    Bldg.nlihc_id, /*Bldg.ssl as Bldg_ssl,*/
    Xref.ssl 
    from Building_geocode (where=(not(missing(Bldg_address_id)))) as Bldg 
      left join Mar.Address_ssl_xref as xref
  on Bldg.Bldg_address_id = Xref.address_id
  order by Bldg.nlihc_id, Xref.ssl;

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

proc sort data=Parcel_a2 nodupkey;
  by nlihc_id ssl;

/**%File_info( data=Parcel_a2, printobs=100 )**/

proc sort data=Parcel_a2;
  by ssl;
  
data PresCat.Parcel (label="Preservation Catalog, real property parcels");

  length Nlihc_id $ 8 Ssl $ 17;
  
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
  
  if not in_Parcel_base then do;
    %warn_put( msg="SSL not found in Parcel_base; will not be saved. " nlihc_id= ssl= ssl_orig= )
    delete;
  end;

  label
    address_id = "Parcel MAR address ID"
    NLIHC_ID = "Preservation Catalog project ID";

  rename 
    ui_proptype=Parcel_type ownername_full=Parcel_owner_name saledate=Parcel_owner_date 
    ownerpt_extractdat_last=Parcel_Info_Source_Date
    address_id=Parcel_address_id
    x_coord=Parcel_x y_coord=Parcel_y Ownercat=Parcel_owner_type;
  
run;

proc sort data=PresCat.Parcel;
  by nlihc_id ssl;
run;

%File_info( data=PresCat.Parcel, freqvars=Parcel_owner_type Parcel_type )

**** CHECKS ****;

proc print data=PresCat.Parcel n;
  where Nlihc_id = "NL000046";
  by Nlihc_id;
  id Parcel_address_id;
run;

title2 '---Comparison with previous parcel data set---';

proc sort data=PresCat.Parcel_09_28_14 out=Parcel_09_28_14;
  by nlihc_id ssl;
  
proc compare base=Parcel_09_28_14 compare=PresCat.Parcel maxprint=(40,32000);
  id nlihc_id ssl;
run;

title2;
