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

** Read in parcel corrections **;

filename fimport "D:\DCData\Libraries\PresCat\Prog\Dev\Public_hsg_parcels_notincat_corr.csv" lrecl=1000;

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

filename fimport "D:\DCData\Libraries\PresCat\Prog\Dev\Public_hsg_parcels_notincat_oth_corr.csv" lrecl=1000;

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
  label="Preservation Catalog, ",
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

proc compare base=PresCat.Parcel compare=Parcel maxprint=(40,32000);
  id nlihc_id ssl;
run;

** Verify parcels for CAPITOL QUARTER are all owned by DCHA **;

proc print data=Parcel;
  where nlihc_id = 'NL000387';
  id nlihc_id ssl;
  var parcel_owner_type Parcel_owner_name;
run;


