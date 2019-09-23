/**************************************************************************
 Program:  192_Fix_public_hsg_data.sas
 Library:  PresCat
 Project:  Urban-Greater DC
 Author:   P. Tatian
 Created:  09/20/19
 Version:  SAS 9.4
 Environment:  Local Windows session (desktop)
 GitHub issue:  192
 
 Description:  Correct Catalog address and parcel data for public housing.

 Modifications:
**************************************************************************/

%include "L:\SAS\Inc\StdLocal.sas";

** Define libraries **;
%DCData_lib( PresCat )
%DCData_lib( RealProp )
%DCData_lib( MAR )

%let revisions = Update public housing records (GitHub issue #192).;


** Update project name for NL000387 to "CAPITOL QUARTER I & II (public housing)" **;

data Project_category;

  set Prescat.Project_category;
  
  if nlihc_id = 'NL000387' then proj_name = "Capitol Quarter I & II (public housing)";
  
run;

%Finalize_data_set( 
  /** Finalize data set parameters **/
  data=Project_category,
  out=Project_category,
  outlib=PresCat,
  label="Preservation Catalog, Project category",
  sortby=nlihc_id,
  archive=Y,
  /** Metadata parameters **/
  revisions=%str(&revisions),
  /** File info parameters **/
  contents=Y,
  printobs=0,
  freqvars=,
  stats=
)

%Data_to_format(
  FmtLib=work,
  FmtName=$nlihcid_to_projname,
  Data=Project_category,
  Value=nlihc_id,
  Label=proj_name,
  OtherLabel=,
  Print=N,
  Contents=N
)


** Read in parcel corrections **;

filename fimport "D:\DCData\Libraries\PresCat\Raw\Dev\Public_hsg_parcels_notincat_corr.csv" lrecl=1000;

proc import out=Notincat_corr
    datafile=fimport
    dbms=csv replace;
  datarow=2;
  getnames=yes;
  guessingrows=max;
run;

filename fimport clear;

proc sort data=Notincat_corr;
  by ssl;
run;

%File_info( data=Notincat_corr, printobs=0, stats=, freqvars=nlihc_id )

filename fimport "D:\DCData\Libraries\PresCat\Raw\Dev\Public_hsg_parcels_notincat_oth_corr.csv" lrecl=1000;

proc import out=Notincat_oth_corr
    datafile=fimport
    dbms=csv replace;
  datarow=2;
  getnames=yes;
  guessingrows=max;
run;

filename fimport clear;

%File_info( data=Notincat_oth_corr, printobs=0, stats=, freqvars=nlihc_id )

** Create updated parcel data set **;

data Parcel_add;

  set
    Notincat_corr
    Notincat_oth_corr;
  by ssl;
  
  where nlihc_id =: "NL";

  informat _all_ ;
  format _all_ ;
  
  keep ssl nlihc_id;
  
run;

%Dup_check(
  data=Parcel_add,
  by=ssl,
  id=nlihc_id
)

proc summary data=Mar.Address_ssl_xref nway;
  class ssl;
  var address_id;
  output out=ssl_addressid (drop=_type_ _freq_) min=;
run;

data Parcel_add_wchar;

  merge
    Parcel_add 
      (in=in_Parcel)
    RealProp.Parcel_base 
      (keep=ssl ui_proptype saledate in_last_ownerpt ownerpt_extractdat_last
       in=in_Parcel_base)
    RealProp.Parcel_geo 
      (keep=ssl x_coord y_coord)
    RealProp.Parcel_base_who_owns
      (keep=ssl Ownername_full Ownercat)
    ssl_addressid
      (keep=ssl address_id);
  by ssl;
  
  if in_Parcel;
  
  ** Remove duplicate SSL record **;
  if nlihc_id = 'NL000174' and address_id = 156176 then delete; 
  
  if x_coord = 0 then x_coord = .u;
  if y_coord = 0 then y_coord = .u;
  
  if not in_Parcel_base then do;
    %warn_put( msg="SSL not found in Parcel_base; will not be saved. " nlihc_id= ssl= )
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

title2 '--Parcel_add_wchar--';
%Dup_check(
  data=Parcel_add_wchar,
  by=nlihc_id ssl,
  id=in_last_ownerpt Parcel_x parcel_owner_name parcel_address_id parcel_type
)
title2;
    
proc sort data=Parcel_add_wchar;
  by nlihc_id ssl;
run;

data Parcel Parcel_del;

  set
    PresCat.Parcel
    Parcel_add_wchar;
  by nlihc_id ssl;

  ** Remove non-public housing parcels: 
  ** output to separate data set to use for deleting corresponding addresses;
  
  if nlihc_id = 'NL000387' and upcase( Parcel_owner_name ) ~= 'DISTRICT OF COLUMBIA HOUSING AUTHORITY' 
    then output Parcel_del;
  else if nlihc_id = 'NL000121' and compbl( ssl ) = '5422 0017' then output Parcel_del;
  else if nlihc_id = 'NL000353' and compbl( ssl ) = '5058 0008' then output Parcel_del;
  else output Parcel;
  
run;

%Finalize_data_set( 
  /** Finalize data set parameters **/
  data=Parcel,
  out=Parcel,
  outlib=PresCat,
  label="Preservation Catalog, Real property parcels",
  sortby=nlihc_id ssl,
  archive=Y,
  /** Metadata parameters **/
  restrictions=None,
  revisions=%str(&revisions),
  /** File info parameters **/
  printobs=0,
  freqvars=Parcel_type Parcel_owner_type
)

** Check for duplicate obs **;

title2 '--Parcel--';
%Dup_check(
  data=Parcel,
  by=nlihc_id ssl,
  id=parcel_owner_name parcel_address_id parcel_type
)
title2;

proc compare base=PresCat.Parcel compare=Parcel maxprint=(40,32000) listvar;
  id nlihc_id ssl;
run;

** Verify parcels for selected projects **;

proc print data=Parcel;
  where nlihc_id in ( 'NL000387', 'NL000121', 'NL000353' );
  by nlihc_id;
  id nlihc_id ssl;
  var parcel_owner_type Parcel_owner_name;
run;


** Create updated address data sets **;

** Addresses to add **;

proc sql noprint;
  create table Address_add as
  select Parcel.ssl, Parcel.nlihc_id, Mar.* 
  from Parcel_add_wchar as Parcel 
  left join ( 
    select xref.ssl, xref.address_id, pt.address_id, 
      pt.fulladdress as bldg_addre, 
      pt.x as Bldg_x, 
      pt.y as Bldg_y,
      pt.zip as Bldg_zip,
      pt.anc2012, pt.cluster_tr2000, pt.geo2010, pt.psa2012, pt.ward2012
    from Mar.Address_ssl_xref as xref left join Mar.Address_points_view as pt
    on xref.address_id = pt.address_id
  ) as Mar
  on mar.ssl = Parcel.ssl
  where not missing( address_id )
  order by Nlihc_id, bldg_addre;
quit;

proc sort data=Address_add nodupkey;
  by Nlihc_id bldg_addre;
run;

%File_info( data=Address_add, printobs=100 )

/*
title2 '--
%Dup_check(
  data=Address_add,
  by=nlihc_id ssl,
  id=address_id bldg_addre
)
*/

title2 '--Address_add--';
%Dup_check(
  data=Address_add,
  by=nlihc_id address_id,
  id=bldg_addre
)
title2;


** Addresses to remove **;

proc sql noprint;
  create table Address_del as
  select coalesce( Mar.ssl, Parcel.ssl ) as ssl, Parcel.nlihc_id, Mar.address_id
  from Parcel_del as Parcel 
  left join
  Mar.Address_ssl_xref as Mar
  on mar.ssl = Parcel.ssl
  where not missing( address_id )
  order by Nlihc_id, address_id;
quit;

%File_info( data=Address_del, contents=n, stats=, printobs=100 )

%Data_to_format(
  FmtLib=work,
  FmtName=$Address_del,
  Desc=,
  Data=Address_del,
  Value=trim( nlihc_id ) || left( put( address_id, z10. ) ),
  Label='X',
  OtherLabel=' ',
  Print=N,
  Contents=N
  )

** Correct duplicate address IDs **;

data 
  Building_geocode_a 
  Building_geocode_b 
    (drop=bldg_address_id bldg_x bldg_y bldg_lat bldg_lon anc: psa: geo: cluster: ward:);

  set Prescat.Building_geocode;
  
  if ( nlihc_id = 'NL001038' and bldg_address_id = 277581 ) or
     ( nlihc_id = 'NL001044' and bldg_address_id = 253199 ) then 
    output Building_geocode_b;
  else 
    output Building_geocode_a;

run;

%DC_mar_geocode(
  data=Building_geocode_b,
  out=Building_geocode_b_geo,
  staddr=bldg_addre,
  zip=bldg_zip,
  id=nlihc_id,
  keep_geo=address_id latitude longitude anc2012 cluster_tr2000 geo2010 psa2012 ward2012,
  listunmatched=Y
)

proc sort data=Building_geocode_b_geo;
  by nlihc_id bldg_addre;
run;

data Building_geocode;

  set
    Building_geocode_a
    Building_geocode_b_geo
      (drop=m_: _: bldg_addre_std
       rename=(address_id=bldg_address_id x=Bldg_x y=Bldg_y latitude=Bldg_lat longitude=Bldg_lon))
    Address_add (rename=(address_id=bldg_address_id));
  by nlihc_id bldg_addre;
    
  if put( trim( nlihc_id ) || left( put( bldg_address_id, z10. ) ), $Address_del. ) = 'X' then delete;
  
  if cluster_tr2000_name = '' then cluster_tr2000_name = left( put( cluster_tr2000, clus00b. ) );
  
  proj_name = left( put( nlihc_id, $nlihcid_to_projname. ) );
  
run;

%Finalize_data_set( 
  /** Finalize data set parameters **/
  data=Building_geocode,
  out=Building_geocode,
  outlib=PresCat,
  label="Preservation Catalog, Building-level geocoding info",
  sortby=nlihc_id bldg_addre,
  archive=Y,
  /** Metadata parameters **/
  restrictions=None,
  revisions=%str(&revisions),
  /** File info parameters **/
  printobs=0,
  freqvars=Ward2012
)

** Check for duplicate obs **;

title2 '--Building_geocode--';
%Dup_check(
  data=Building_geocode,
  by=nlihc_id bldg_address_id,
  id=bldg_addre
)
title2;

proc compare base=PresCat.Building_geocode compare=Building_geocode maxprint=(40,32000) listvar method=relative;
  id nlihc_id bldg_addre;
run;

title2 '-- Verify addresses for selected projects --';

proc print data=Building_geocode;
  where nlihc_id in ( 'NL000387', 'NL000121', 'NL000353' );
  by nlihc_id;
  id nlihc_id;
  var bldg_addre bldg_address_id;
run;

title2;


** Create updated Project_geocode data set **;

%Create_project_geocode( data=Building_geocode, revisions=%str(&revisions), compare=n )

proc compare base=PresCat.Project_geocode compare=Project_geocode maxprint=(400,32000) listvar listall method=relative;
  id nlihc_id;
run;


******* NEXT STEPS ********;



** Update Subsidy data set with APSH IDs **;

** Update Project data set **;


