/**************************************************************************
 Program:  084_Review_LECoop_db.sas
 Library:  PresCat
 Project:  Urban-Greater DC
 Author:   P. Tatian
 Created:  10/12/19
 Version:  SAS 9.4
 Environment:  Local Windows session (desktop)
 GitHub issue:  84
 
 Description:  Review the new limited equity cooperative database
 created by CNHED and VCU for the LEC study.  

 Modifications:
**************************************************************************/

%include "L:\SAS\Inc\StdLocal.sas";

** Define libraries **;
%DCData_lib( PresCat )
%DCData_lib( MAR )
%DCData_lib( RealProp )


** Read in LEC database **;

filename fimport "&_dcdata_r_path\PresCat\Raw\Coops\Confirmed Data COPY Coop Database_with ID_LEC or affordable.csv" lrecl=5000;

data Coop_db;

  infile fimport dsd missover firstobs=2;

  input
    ID
    Cooperative : $40. 
    Address : $80.
    Address2 : $80.
    Coop_db_SSL : $16.
    Census_tract : $16.
    GeoID : $16.
    Ward : $8.
    Neighborhood : $40.
    Year_coop_formed : $40.
    Year_Constructed : $40.
    Units : $40.
    Land_area : comma16.
    TA_Provider : $80.
    Management : $80.
    Contact_Management : $40.
    On_DHCD_Asset_Management_List : $40.
    Affordability_Covenant : $40.
    Other_Notes : $40.
    Loan1 : $40.
    Type_of_Development1 : $40.
    Loan2 : $40.
    Type_of_Development2 : $40.
    Use_Code : $40.
    Loan3 : $40.
    Type_of_Development3 : $40.
    Carrying_charges : $40.
    AMI_0_30 : $40.
    AMI_31_50 : $40.
    AMI_51_60 : $40.
    AMI_61_80 : $40.
    Initials_Confirmed : $40.
    Story : $250.
    Coop_Contacts : $40.
    Coop_Clinic_2017 : $40.
    Other_Notes : $250.
    Overall_Status : $80.
  ;
  
  if missing( ID ) then delete;
  
  length Address_ref $ 80;
  
  select ( ID );
    when ( 15 ) Address_ref = "3218 Wisconsin Ave NW";
    when ( 30 ) Address_ref = "24 Bates St NW";
    when ( 38 ) Address_ref = "1436 W St NW";
    when ( 70 ) Address_ref = "1701 EUCLID ST NW";
    when ( 91 ) Address_ref = "1413 Half St SW";
    when ( 94 ) Address_ref = "1440 Tuckerman St NW";
    when ( 95 ) Address_ref = "3715 2nd St SE";
    otherwise Address_ref = Address;
  end;
  
  i = index( upcase( Address_ref ), "WASHINGTON" );
  j = index( upcase( Address_ref ), "(MAILING" );
  
  if i > 0 and j > 0 then i = min( i, j );
  else if j > 0 then i = j;
  
  if i > 0 then do;
    put id= address_ref=;
    address_ref = substr( Address_ref, 1, i - 1 );
    put address_ref= /;
  end;
  
  label address_ref = "Reference street address";
  
  drop i j;

run;

filename fimport clear;

run;

** Geocode addresses **;

%DC_mar_geocode(
  geo_match=Y,
  data=Coop_db,
  out=Coop_db_geo_a,
  staddr=Address_ref,
  zip=,
  id=ID Cooperative,
  ds_label=,
  listunmatched=Y,
  match_score_min=65,
  streetalt_file=&_dcdata_default_path\PresCat\Prog\Dev\084_StreetAlt_LECoop.txt
)

data Coop_db_geo;

  set Coop_db_geo_a;
  
  ** Revise selected SSLs **;
  
  select ( Id );
    when ( 39 ) ssl = "3153    2071";
    when ( 62 ) ssl = "2594    2086";
    otherwise /** DO NOTHING **/;
  end;
 
run;

%File_info( data=Coop_db_geo, freqvars=overall_status ward2012 _score_ M_EXACTMATCH )

proc print data=Coop_db_geo;
  id id;
  var address_ref address_ref_std;
run;


** Check data **;

title2 "--- Nonmatching SSLs ---";

proc print data=Coop_db_geo;
  where compbl( coop_db_ssl ) ~= compbl( ssl );
  id id;
  var cooperative address coop_db_ssl ssl;
run;

title2;
  

** Find related parcels by using property owner names **;

proc sql noprint;

  /*
  create table Coop_ownerlist as 
  select Coop.Id, coalesce( Coop.SSL, Parcel.SSL ) as SSL, Parcel.Ownername, Parcel.In_last_ownerpt
  from Coop_db_geo as Coop
  left join
  Realprop.Parcel_base as Parcel
  on Coop.SSL = Parcel.SSL
  order by id;
  */

  create table Coop_ssl_by_owner as
  select coalesce( Parcel.Ownername, Owners.Ownername ) as Ownername, Owners.ID, 
    Parcel.ssl, Parcel.In_last_ownerpt, Parcel.ui_proptype
  from RealProp.Parcel_base as Parcel 
  left join (
    select Coop.Id, coalesce( Coop.SSL, Parcel.SSL ) as SSL, Parcel.Ownername
    from Coop_db_geo as Coop
    left join
    Realprop.Parcel_base as Parcel
    on Coop.SSL = Parcel.SSL ) as Owners
  on Parcel.Ownername = Owners.Ownername
  where not( missing( Owners.id ) )
  order by id, ssl;
 
quit;

/*
proc print data=Coop_ownerlist n;
  id id;
  var ssl ownername in_last_ownerpt;
run;
*/

title2 "--- Coop_ssl_by_owner ---";

proc print data=Coop_ssl_by_owner;
  by id;
  id id ssl;
  var In_last_ownerpt Ownername ui_proptype;
run;

title2;


** Find related addresses **;

proc sql noprint;
  create table Coop_addresses as
  select coopfulla.*, parcel.ssl, parcel.in_last_ownerpt, parcel.ownername
  from (
    select distinct coopaddr.id, coalesce( coopaddr.address_id, addr.address_id ) as address_id, 
      addr.fulladdress, addr.ssl
    from (  
      select coop.id, xref.address_id, coalesce( coop.ssl, xref.ssl ) as ssl 
      from Coop_ssl_by_owner as coop 
      full join
      Mar.Address_ssl_xref as xref
      on xref.ssl = coop.ssl
      where not( missing( id ) or missing( address_id ) )
      group by id, address_id ) as coopaddr
    left join
    Mar.Address_points_view as addr
    on coopaddr.address_id = addr.address_id ) as coopfulla
  left join
  RealProp.Parcel_base as parcel
  on coopfulla.ssl = parcel.ssl
  order by id, address_id;
  
quit;

title2 "--- Coop_addresses ---";

proc print data=Coop_addresses;
  by id;
  id id address_id;
  var fulladdress ssl in_last_ownerpt ownername;
run;

title2;

