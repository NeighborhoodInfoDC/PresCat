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

%include "\\sas1\DCDATA\SAS\Inc\StdLocal.sas";

** Define libraries **;
%DCData_lib( PresCat )
%DCData_lib( MAR )
%DCData_lib( RealProp )
%DCData_lib( ROD )
%DCData_lib( DHCD )

%let SOURCE_DATE = '28sep2020'd;
%let UPDATE_DTM = %sysfunc( datetime() );

%let revisions = Update existing projects with IZ_Projects.csv.; 

** Read in LEC database **;

filename fimport "&_dcdata_r_path\DHCD\Raw\IZ\IZ_Projects.csv" lrecl=5000;

data IZ_db;

  retain ID 0;

  infile fimport dsd missover firstobs=2;

  input
    Project : $120. 
    Address : $80.
    Zip : $10.
    Tenure : $40.
    MFI : $40.
    Construction_Status : $20.
    Lottery_Date : $30.
    Application : $30.
   
  ;
  
  ID + 1;
  
  length Address_ref $ 80;
  
  select ( ID );
    when (  37 ) Address_ref = "1016 17th PL NE";
    otherwise Address_ref = Address;
  end;
  
  **Create AMI categories**;

  if index (MFI, "30") > 0 then AMI_0_30 = 1;
  if index (MFI, "50") > 0 then AMI_31_50 = 1;
  if index (MFI, "60") > 0 then AMI_51_60 = 1;
  if index (MFI, "80") > 0 then AMI_61_80 = 1;

  **Create Agency variables**;

  Agency = "DHCD";

  label address_ref = "Reference street address";

  
  %Project_name_clean( Project, Project )

run;

filename fimport clear;

run;

** Geocode addresses **;

%DC_mar_geocode(
  geo_match=Y,
  data=IZ_db,
  out=IZ_db_geo,
  staddr=Address_ref,
  zip=,
  id=ID Project,
  ds_label=,
  listunmatched=Y,
  match_score_min=65,
  streetalt_file=&_dcdata_default_path\PresCat\Prog\Dev\084_StreetAlt_LECoop.txt
)

%File_info( data=IZ_db_geo, freqvars=ward2012 _score_ M_EXACTMATCH )

proc print data=IZ_db_geo;
  id id;
  var address_ref address_ref_std;
run;




** Check for matches with Preservation Catalog **;

proc sql noprint;

  create table IZ_catalog as
  select IZ.id, coalesce( IZ.ssl, prescat.ssl ) as ssl, prescat.nlihc_id
  from IZ_db_geo as IZ
  left join
  Prescat.Parcel as prescat
  on IZ.ssl = prescat.ssl
  where not( missing( nlihc_id ) )
  order by id, nlihc_id;
  
  create table IZ_catalog_subsidies as
  select distinct IZ.id, coalesce( IZ.nlihc_id, subsidy.nlihc_id ) as nlihc_id, 
    subsidy.subsidy_id, subsidy.subsidy_active, subsidy.program, subsidy.units_assist,
    subsidy.poa_start, subsidy.poa_end
  from IZ_catalog as IZ
  right join
  Prescat.Subsidy as subsidy
  on IZ.nlihc_id = subsidy.nlihc_id
  where not( missing( id ) )
  order by id, nlihc_id, subsidy_id;
  
quit;



proc sort data=IZ_catalog nodupkey;
  by id nlihc_id;
run;

title2 "--- IZ_catalog ---";

%Dup_check(
  data=IZ_catalog,
  by=id,
  id=nlihc_id ssl
)

proc print data=IZ_catalog n;
  id id;
  var nlihc_id;
run;

%Data_to_format(
  FmtLib=work,
  FmtName=IZ_catalog,
  Desc=,
  Data=IZ_catalog,
  Value=id,
  Label=nlihc_id,
  OtherLabel=' ',
  Print=Y,
  Contents=N
  )

title2 "--- IZ_catalog_subsidies ---";

proc print data=IZ_catalog_subsidies;
  by id nlihc_id;
  id id nlihc_id subsidy_id;
run;

title2;


** Export projects to add to Catalog **;

data 
  IZ_export_main (keep=Project Bldg_City Bldg_ST Bldg_Zip Bldg_Addre)
  IZ_export_subsidy
    (keep=MARID Units_tot Units_Assist Current_Affordability_Start
          Affordability_End rent_to_fmr_description
          Subsidy_Info_Source_ID Subsidy_Info_Source
          Subsidy_Info_Source_Date Program Compliance_End_Date
          Previous_Affordability_end Agency Date_Affordability_Ended)
  IZ_db_geo_catalog
    (rename=(Current_affordability_start=Poa_start)); 

  length
    Subsidy_active 3
    MARID Units_tot Units_Assist Current_Affordability_Start 8    
    Affordability_End rent_to_fmr_description Subsidy_Info_Source_ID Subsidy_Info_Source $ 40
    Subsidy_Info_Source_Date 8 
    Program $ 32 Portfolio $ 16 
    Compliance_End_Date Previous_Affordability_end Agency Date_Affordability_Ended $ 1;

  retain 
    Affordability_End ' '
    Subsidy_Info_Source_ID ' '
    Subsidy_Info_Source 'DHCD Inclusionary Zoning Database'
    Subsidy_Info_Source_Date &SOURCE_DATE 
    Program 'IZ'
    Portfolio 'IZ'
    Compliance_End_Date Previous_Affordability_end Agency Date_Affordability_Ended ' '
    Subsidy_id 999
    Subsidy_active 1
    Update_dtm &UPDATE_DTM;
     
  merge
    IZ_db_geo
    IZ_catalog (drop=ssl in=in_cat)
    /*IZ_units
    IZ_ssl_by_owner_unique*/;
  by id;
  
  ** Main project list **;
  
  length Bldg_City Bldg_ST $ 40 Bldg_Zip $ 5 Bldg_Addre $ 80;
  
  retain Bldg_city 'Washington' Bldg_st 'DC' Bldg_Zip '';
  
  Bldg_addre = Address_ref;
  
  ** Project subsidy data **;

   MARID = ADDRESS_ID;
   
   Units_tot = active_res_occupancy_count;
   Units_assist = input( scan( Units, 1 ), 16. );
   
   if not( Units_assist > 0 ) then Units_assist = Units_tot;

   if not( Units_tot > 0 ) then Units_tot = Units_assist;

   if Units_tot ~= Units_assist then do;
     %warn_put( msg="Unit counts do not match: " id= units_tot= units_assist= )
   end;
   
     Current_affordability_start = input( Lottery_date, mmddyy10. ); 
   
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
     output IZ_export_main;
     output IZ_export_subsidy;
   end;
   else do;
     output IZ_db_geo_catalog;
   end;

run;

filename fexport "&_dcdata_r_path\PresCat\Raw\AddNew\242_Review_IZ_db_main (source).csv" lrecl=1000;

proc export data=IZ_export_main
    outfile=fexport
    dbms=csv replace;

run;

filename fexport clear;

filename fexport "&_dcdata_r_path\PresCat\Raw\AddNew\242_Review_IZ_db_subsidy.csv" lrecl=1000;

proc export data=IZ_export_subsidy
    outfile=fexport
    dbms=csv replace;

run;

filename fexport clear;




*******BELOW THIS LINE, SHOULD THERE BE ANY IZ UNITS ALREADY IN THE CATALOG?********:

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

%Finalize_data_set( 
  /** Finalize data set parameters **/
  data=Subsidy_update,
  out=Subsidy,
  outlib=PresCat,
  label="Preservation Catalog, Project subsidies",
  sortby=nlihc_id subsidy_id,
  archive=Y,
  /** Metadata parameters **/
  revisions=%str(&revisions),
  /** File info parameters **/
  printobs=0,
  freqvars=program portfolio Subsidy_info_source
)

proc print data=subsidy_update;
  where datepart( update_dtm ) = today();
  id nlihc_id subsidy_id;
run;

proc compare base=PresCat.Subsidy compare=Subsidy_update listall maxprint=(40,32000);
  id Nlihc_id Subsidy_id;
run;


** Project-level subsidy info **;

%Create_project_subsidy_update( data=Subsidy_update, out=Project_subsidy_update )


** Addresses **;

data Coop_addresses_update;

  length Nlihc_id $ 16 Proj_name cluster_tr2000_name $ 80;

  set Coop_addresses;
  
  Nlihc_id = left( put( id, Coop_catalog. ) );
  
  if missing( Nlihc_id ) then delete;
  
  %Address_clean( FULLADDRESS, bldg_addre )
  
  cluster_tr2000_name = left( put( cluster_tr2000, clus00b. ) );
  
  keep Nlihc_id Proj_name bldg_addre address_id latitude longitude x y zip
       anc2012 cluster_tr2000 cluster_tr2000_name geo2010 psa2012 ward2012;
  
  rename address_id=bldg_address_id latitude=bldg_lat longitude=bldg_lon x=bldg_x y=bldg_y zip=bldg_zip;

run;

proc sort data=Coop_addresses_update nodupkey;
  by Nlihc_id bldg_addre;
run;

proc print data=Coop_addresses_update;

data Building_geocode_update;

  update
    PresCat.Building_geocode
    Coop_addresses_update;
  by nlihc_id bldg_addre;
  
run;

%Finalize_data_set( 
  /** Finalize data set parameters **/
  data=Building_geocode_update,
  out=Building_geocode,
  outlib=PresCat,
  label="Preservation Catalog, Building-level geocoding info",
  sortby=nlihc_id bldg_addre,
  archive=Y,
  /** Metadata parameters **/
  revisions=%str(&revisions),
  /** File info parameters **/
  printobs=0
)

proc compare base=PresCat.Building_geocode compare=Building_geocode_update listall maxprint=(40,32000) method=percent criterion=0.01;
  id nlihc_id bldg_addre;
run;

%Dup_check(
  data=Building_geocode_update,
  by=nlihc_id bldg_address_id,
  id=bldg_addre,
  out=_dup_check,
  listdups=Y
)


%Create_project_geocode( 
  data=Building_geocode_update, 
  out=Project_geocode, 
  revisions=%str(&revisions)
)
  
  
** Parcels **;

data Coop_parcel_update;

  length Nlihc_id $ 16;

  set Coop_ssl_by_owner;
  
  Nlihc_id = left( put( id, Coop_catalog. ) );
  
  if missing( Nlihc_id ) then delete;
  
  keep Nlihc_id ssl in_last_ownerpt address_id ownerpt_extractdat_last ownername_full ownercat ui_proptype
       x_coord y_coord;
  
  rename address_id=Parcel_address_id ownerpt_extractdat_last=Parcel_info_source_date 
         ownername_full=Parcel_owner_name ownercat=Parcel_owner_type ui_proptype=Parcel_type
         x_coord=Parcel_x y_coord=Parcel_y;
         
  informat _all_ ;

run;

proc sort data=Coop_parcel_update;
  by Nlihc_id ssl;
run;

proc print data=Coop_parcel_update;

data Parcel_update;

  update
    PresCat.Parcel
    Coop_parcel_update;
  by nlihc_id ssl;
  
run;

%Finalize_data_set( 
  /** Finalize data set parameters **/
  data=Parcel_update,
  out=Parcel,
  outlib=PresCat,
  label="Preservation Catalog, Real property parcels",
  sortby=nlihc_id ssl,
  archive=Y,
  /** Metadata parameters **/
  revisions=%str(&revisions),
  /** File info parameters **/
  printobs=0
)

proc compare base=PresCat.Parcel compare=Parcel_update listall maxprint=(40,32000) method=percent criterion=0.01;
  id nlihc_id ssl;
run;

%Dup_check(
  data=Parcel_update,
  by=nlihc_id ssl,
  id=,
  listdups=Y
)
  
  
** Real property **; 

%Update_real_property( Parcel=Parcel_update, revisions=%str(&revisions) )


** Project **;

data Project_update;

  merge 
    PresCat.Project
    Coop_db_geo_catalog 
      (keep=Nlihc_id Proj_name management ownername
       in=isLEC)
    Project_geocode
      (keep=Nlihc_id anc2012 cluster_tr2000 cluster_tr2000_name geo2010 
            proj_addre proj_address_id proj_image_url proj_lat proj_lon
            proj_streetview_url proj_x proj_y proj_zip psa2012 ward2012 zip)
    Project_subsidy_update
    ;
  by Nlihc_id;
  
  if isLEC then do;
  
    i = index( management, '(' );
    
    if i > 0 then hud_mgr_name = left( substr( management, 1, i - 1 ) );
    else hud_mgr_name = left( management );
    
    %Project_name_clean( ownername, hud_own_name )
    
    hud_own_type = 'NP';
    
    status = 'A';
    
    subsidized = 1;
    
    update_dtm = &UPDATE_DTM;
    
  end;
  
  drop i management ownername;
  
run;

%Finalize_data_set( 
  /** Finalize data set parameters **/
  data=Project_update,
  out=Project,
  outlib=PresCat,
  label="Preservation Catalog, Projects",
  sortby=nlihc_id,
  archive=Y,
  /** Metadata parameters **/
  revisions=%str(&revisions),
  /** File info parameters **/
  printobs=0
)

proc compare base=PresCat.Project compare=Project_update listall maxprint=(40,32000);
  id Nlihc_id;
run;


** Project_category **;

data Project_category_update;

  update
    PresCat.Project_category
    Coop_db_geo_catalog (keep=Nlihc_id Proj_name);
  by Nlihc_id;
  
run;

%Finalize_data_set( 
  /** Finalize data set parameters **/
  data=Project_category_update,
  out=Project_category,
  outlib=PresCat,
  label="Preservation Catalog, Projects",
  sortby=nlihc_id,
  archive=Y,
  /** Metadata parameters **/
  revisions=%str(&revisions),
  /** File info parameters **/
  printobs=0
)

proc compare base=PresCat.Project_category compare=Project_category_update listall maxprint=(40,32000);
  id Nlihc_id;
run;

