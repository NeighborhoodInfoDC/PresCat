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

%let SOURCE_DATE = '10jan2020'd;
%let UPDATE_DTM = %sysfunc( datetime() );

** Read in LEC database **;

filename fimport "&_dcdata_r_path\PresCat\Raw\Coops\LEC_Database_10Jan20_LEC_or_Affordable.csv" lrecl=5000;

data Coop_db;

  retain ID 0;

  infile fimport dsd missover firstobs=2;

  input
    Cooperative : $120. 
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
  ;
  
  if missing( Cooperative ) then delete;
  
  ID + 1;
  
  length Address_ref $ 80;
  
  select ( ID );
    when (  8 ) Address_ref = "1440 Tuckerman St NW";
    when ( 16 ) Address_ref = "1413 Half St SW";
    when ( 54 ) Address_ref = "24 Bates St NW";
    when ( 61 ) Address_ref = "1436 W St NW";
    when ( 86 ) Address_ref = "1701 EUCLID ST NW";
    when ( 93 ) Address_ref = "3715 2nd St SE";
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
  /*
  select ( Id );
    when ( 39 ) ssl = "3153    2071";
    when ( 62 ) ssl = "2594    2086";
    otherwise ** DO NOTHING **;
  end;
  */
 
run;

%File_info( data=Coop_db_geo, freqvars=ward2012 _score_ M_EXACTMATCH )

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

%Dup_check(
  data=Coop_ssl_by_owner,
  by=id ssl,
  id=ownername
)

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
      addr.fulladdress, addr.ssl, addr.active_res_occupancy_count
    from (  
      select coop.id, xref.address_id, coalesce( coop.ssl, xref.ssl ) as ssl 
      from Coop_ssl_by_owner as coop 
      full join
      Mar.Address_ssl_xref as xref
      on xref.ssl = coop.ssl
      where not( missing( id ) or missing( address_id ) ) ) as coopaddr
    left join
    Mar.Address_points_view as addr
    on coopaddr.address_id = addr.address_id ) as coopfulla
  left join
  RealProp.Parcel_base as parcel
  on coopfulla.ssl = parcel.ssl
  order by id, address_id;
  
  create table Coop_units as
  select coop.id, sum( coop.active_res_occupancy_count ) as active_res_occupancy_count
  from Coop_addresses as coop
  group by id;
  
quit;

title2 "--- Coop_addresses ---";

%Dup_check(
  data=Coop_addresses,
  by=id address_id,
  id=fulladdress ssl
)

proc print data=Coop_addresses;
  by id;
  id id address_id;
  var fulladdress ssl in_last_ownerpt ownername;
run;

title2 "--- Coop_units ---";

proc print data=Coop_units;
  id id;
  var active_res_occupancy_count;
  sum active_res_occupancy_count;
run;

title2;


** Check for matches with Preservation Catalog **;

proc sql noprint;

  create table Coop_catalog as
  select coop.id, coalesce( coop.ssl, prescat.ssl ) as ssl, prescat.nlihc_id
  from Coop_ssl_by_owner as coop
  left join
  Prescat.Parcel as prescat
  on coop.ssl = prescat.ssl
  where not( missing( nlihc_id ) )
  order by id, nlihc_id;
  
  create table Coop_catalog_subsidies as
  select distinct coop.id, coalesce( coop.nlihc_id, subsidy.nlihc_id ) as nlihc_id, 
    subsidy.subsidy_id, subsidy.subsidy_active, subsidy.program, subsidy.units_assist,
    subsidy.poa_start, subsidy.poa_end
  from Coop_catalog as coop
  right join
  Prescat.Subsidy as subsidy
  on coop.nlihc_id = subsidy.nlihc_id
  where not( missing( id ) )
  order by id, nlihc_id, subsidy_id;
  
quit;

proc sort data=Coop_catalog nodupkey;
  by id nlihc_id;
run;

title2 "--- Coop_catalog ---";

%Dup_check(
  data=Coop_catalog,
  by=id,
  id=nlihc_id ssl
)

proc print data=Coop_catalog n;
  id id;
  var nlihc_id;
run;

title2 "--- Coop_catalog_subsidies ---";

proc print data=Coop_catalog_subsidies;
  by id nlihc_id;
  id id nlihc_id subsidy_id;
run;

title2;


** Export projects to add to Catalog **;

data 
  Coop_export_main (keep=Proj_Name Bldg_City Bldg_ST Bldg_Zip Bldg_Addre)
  Coop_export_subsidy
    (keep=MARID Units_tot Units_Assist Current_Affordability_Start
          Affordability_End rent_to_fmr_description
          Subsidy_Info_Source_ID Subsidy_Info_Source
          Subsidy_Info_Source_Date Program Compliance_End_Date
          Previous_Affordability_end Agency Date_Affordability_Ended)
  Coop_db_geo_catalog
    (rename=(Current_affordability_start=Poa_start)); 
  
  merge
    Coop_db_geo
    Coop_catalog (in=in_cat)
    Coop_units;
  by id;
  
  ** Main project list **;
  
  length Proj_Name $ 120 Bldg_City Bldg_ST $ 40 Bldg_Zip $ 5 Bldg_Addre $ 80;
  
  retain Bldg_city 'Washington' Bldg_st 'DC' Bldg_Zip '';
  
  i = index( cooperative, '(' );
  
  if i > 0 then Proj_name = substr( cooperative, 1, i - 1 );
  else Proj_name = cooperative;
  
  Bldg_addre = Address_ref;
  
  ** Project subsidy data **;

  length
    Subsidy_active 3
    Units_tot Units_Assist Current_Affordability_Start 8
    Affordability_End Subsidy_Info_Source_ID $ 1
    Subsidy_Info_Source $ 40 Subsidy_Info_Source_Date 8 
    Program $ 32 Portfolio $ 16 
    Rent_to_fmr_description $ 40
    Compliance_End_Date Previous_Affordability_end Agency Date_Affordability_Ended $ 1;
 
   retain 
     Affordability_End Subsidy_Info_Source_ID ' '
     Subsidy_Info_Source 'VCU-CNHED/LECOOP'
     Subsidy_Info_Source_Date &SOURCE_DATE 
     Program 'LECOOP'
     Portfolio 'LECOOP'
     Compliance_End_Date Previous_Affordability_end Agency Date_Affordability_Ended ' '
     Subsidy_id 999
     Subsidy_active 1
     Update_dtm &UPDATE_DTM;
     
   MARID = ADDRESS_ID;
   
   Units_tot = active_res_occupancy_count;
   Units_assist = input( scan( Units, 1 ), 16. );
   
   if not( Units_assist > 0 ) then Units_assist = Units_tot;

   if not( Units_tot > 0 ) then Units_tot = Units_assist;

   if Units_tot ~= Units_assist then do;
     %warn_put( msg="Unit counts do not match: " id= units_tot= units_assist= )
   end;
   
   if index( year_coop_formed, '/' ) then 
     Current_affordability_start = input( year_coop_formed, mmddyy10. ); 
   else
     Current_affordability_start = mdy( 1, 1, input( year_coop_formed, 4. ) );
   
   if input( AMI_0_30, 10. ) > 0 then
     Rent_to_fmr_description = trim( left( put( input( AMI_0_30, 10. ), 5. ) ) ) || '@0-30/';
     
   if input( AMI_31_50, 10. ) > 0 then
     Rent_to_fmr_description = trim( Rent_to_fmr_description ) || trim( left( put( input( AMI_31_50, 10. ), 5. ) ) ) || '@31-50/';
     
   if input( AMI_51_60, 10. ) > 0 then
     Rent_to_fmr_description = trim( Rent_to_fmr_description ) || trim( left( put( input( AMI_51_60, 10. ), 5. ) ) ) || '@51-60/';
     
   if input( AMI_61_80, 10. ) > 0 then
     Rent_to_fmr_description = trim( Rent_to_fmr_description ) || trim( left( put( input( AMI_61_80, 10. ), 5. ) ) ) || '@61-80/';
     
   if Rent_to_fmr_description ~= '' then 
     Rent_to_fmr_description = trim( left( substr( Rent_to_fmr_description, 1, length( Rent_to_fmr_description ) - 1 ) ) ) || ' AMI';
     
   format Subsidy_Info_Source_Date Current_Affordability_Start mmddyy10.;
   
   if not in_cat then do;
     output Coop_export_main;
     output Coop_export_subsidy;
   end;
   else do;
     output Coop_db_geo_catalog;
   end;

run;

filename fexport "&_dcdata_r_path\PresCat\Raw\AddNew\084_Review_LECoop_db_main.csv" lrecl=1000;

proc export data=Coop_export_main
    outfile=fexport
    dbms=csv replace;

run;

filename fexport clear;

filename fexport "&_dcdata_r_path\PresCat\Raw\AddNew\084_Review_LECoop_db_subsidy.csv" lrecl=1000;

proc export data=Coop_export_subsidy
    outfile=fexport
    dbms=csv replace;

run;

filename fexport clear;


** Update existing LEC's in Catalog **;

proc sort data=Coop_db_geo_catalog;
  by nlihc_id;
run;

proc print data=Coop_db_geo_catalog;
  where not missing( Rent_to_fmr_description );
  id nlihc_id subsidy_id;
  var units_assist Rent_to_fmr_description;
run;

** Subsidy **;

data Subsidy_update;

  set 
    PresCat.Subsidy
    Coop_db_geo_catalog 
      (keep=Nlihc_id Subsidy_id Subsidy_active Poa_start Program Portfolio Units_assist 
            Rent_to_fmr_description Subsidy_Info_Source Subsidy_Info_Source_Date Update_dtm);
  by Nlihc_id Subsidy_id;
  
  retain _hold_subsidy_id;
  
  if first.Nlihc_id then do;
    _hold_subsidy_id = 1;
  end;
  else do;
    _hold_subsidy_id + 1;
  end;
  
  Subsidy_id = _hold_subsidy_id;
  
  drop _hold_subsidy_id;

run;

%File_info( data=Subsidy_update, printobs=0, freqvars=program portfolio Subsidy_info_source )

proc print data=subsidy_update;
  where datepart( update_dtm ) = today();
  id nlihc_id subsidy_id;
run;

proc compare base=PresCat.Subsidy compare=Subsidy_update listall maxprint=(40,32000);
  id Nlihc_id Subsidy_id;
run;


/**********************
** Project **;

data Project_update;

  merge 
    PresCat.Project
    Coop_db_geo_catalog 
      (keep=Nlihc_id cooperative management 
       in=isLEC);
  by Nlihc_id;
  
  
