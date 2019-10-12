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

filename fimport "&_dcdata_r_path\PresCat\Raw\Coops\Coop Database_with ID_LEC_or_affordable.csv" lrecl=5000;

data Coop_db;

  infile fimport dsd missover firstobs=2;

  input
    ID
    Cooperative : $40. 
    Address : $40.
    Coop_db_SSL : $16.
    Ward : $8.
    Year_coop_formed : $40.
    Year_Constructed : $40.
    Units : $40.
    TA_Provider : $80.
    Management : $80.
    Contact_Management : $40.
    On_DHCD_Asset_Management_List : $40.
    Affordability_Covenant : $40.
    Other_Notes : $40.
    First_Loan : $40.
    Type_of_Development : $40.
    Second_Loan : $40.
    Type_of_Development : $40.
    Use_Code : $40.
    Third_Loan : $40.
    Type_of_Development : $40.
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
  
  i = index( upcase( address ), "WASHINGTON" );
  
  if i > 0 then do;
    put address=;
    address = substr( address, 1, i - 1 );
    put address=;
  end;
  
  drop i;

run;

filename fimport clear;

run;

** Geocode addresses **;

%DC_mar_geocode(
  geo_match=Y,
  data=Coop_db,
  out=Coop_db_geo,
  staddr=Address,
  zip=,
  id=ID Cooperative,
  ds_label=,
  listunmatched=Y,
  match_score_min=75,
  streetalt_file=&_dcdata_default_path\PresCat\Prog\Dev\084_StreetAlt_LECoop.txt
)

%File_info( data=Coop_db_geo, freqvars=overall_status ward2012 _score_ M_EXACTMATCH )

