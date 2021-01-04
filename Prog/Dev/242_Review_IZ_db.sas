/**************************************************************************
 Program:  242_Review_IZ_db.sas
 Library:  PresCat
 Project:  Urban-Greater DC
 Author:   M. Cohen
 Created: 9/29/20
 Version:  SAS 9.4
 Environment:  Local Windows session (desktop)
 GitHub issue:  84
 
 Description:  Review the new iz database.  

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

  **Create AMI categories**;

  if index (MFI, "30") > 0 then AMI_0_30 = 1;
  if index (MFI, "50") > 0 then AMI_31_50 = 1;
  if index (MFI, "60") > 0 then AMI_51_60 = 1;
  if index (MFI, "80") > 0 then AMI_61_80 = 1;

  **Create Agency variables**;

  Agency = "DHCD";

  label address_ref = "Reference street address";

  if Tenure = "Sale" then delete;
  if Lottery_Date = "" then delete;

  
  %Project_name_clean( Project, Project )

run;

filename fimport clear;

run;

** Geocode addresses **;

%DC_mar_geocode(
  geo_match=Y,
  data=IZ_db,
  out=IZ_db_geo,
  staddr=Address,
  staddr_std=Address_ref,
  zip=zip,
  id=ID Project,
  ds_label=,
  listunmatched=Y,
  match_score_min=40,
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
