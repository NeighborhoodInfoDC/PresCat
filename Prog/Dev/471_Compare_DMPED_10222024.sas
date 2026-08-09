/**************************************************************************
 Program:  471_Compare_DMPED_10222024.sas
 Library:  PresCat
 Project:  Urban-Greater DC
 Author:   P. Tatian
 Created:  11/02/24
 Version:  SAS 9.4
 Environment:  Local Windows session (desktop)
 GitHub issue:  471
 
 Description:  Compare projects in
 \\sas1\DCDATA\Libraries\PresCat\Raw\DMPED Pipeline\dc_affordable_housing_10-22-24.csv 
 with PresCat.

 Modifications:
**************************************************************************/

%include "\\sas1\DCdata\SAS\Inc\StdLocal.sas";

** Define libraries **;
%DCData_lib( PresCat )
%DCData_lib( MAR )

%global yes_no_char_var_list yes_no_num_var_list;

%let yes_no_char_var_list = DCHA_Project DCHFA_Project DHCD_Long_term_loan DMPED_Project HPTF_Project Housing_Pres_Project IZ_Project PUD Non_DC_Gov_Project;
%let yes_no_num_var_list = %ListChangeDelim( &yes_no_char_var_list, prefix=Is_, new_delim=%str( ) );

filename fimport "\\sas1\DCDATA\Libraries\PresCat\Raw\DMPED Pipeline\dc_affordable_housing_10-22-24.csv" lrecl=2000;

proc import out=dmped_list
    datafile=fimport
    dbms=csv replace;
  datarow=2;
  getnames=yes;
  guessingrows=max;
run;

filename fimport clear;

data dmped_list_clean;

  Dmped_id = _n_;

  set dmped_list
       (rename=(
          Agency__Calculated_ = Agency_Calculated
          Status__Public = Status_Public
          Project__NAME = Project_name
          Units__0_30_ = Units_0_30
          Units__31_50_ = Units_31_50
          Units__51_60_ = Units_51_60
          Units__61_80_ = Units_61_80
          Units__81__ = Units_81
          Units__Affordable = Units_Affordable
          Units__Affordable_Preserved = Units_Affordable_Preserved
          Units__Affordable_Production = Units_Affordable_Production
          Units__Market = Units_Market
          Units__Newly_Covenanted_Existing = Units_Newly_Covenanted_Existing
          DCHA_Project_ = DCHA_Project
          DCHFA_Project_ = DCHFA_Project
          DHCD_Long_term_loan_ = DHCD_Long_term_loan
          DMPED_Project_ = DMPED_Project
          HPTF_Project_ = HPTF_Project
          Housing_Preservation_Fund_Projec = Housing_Pres_Project
          IZ_Project_ = IZ_Project
          Is_PUD_ = PUD
          Non_DC_Gov_Project_ = Non_DC_Gov_Project
        ));
  
  length street_address $ 400;
  length zip $ 5;
  
  ** Extract street address from full address **;
  street_address = left( propcase( scan( address, 1, ',' ) ) );
  
  ** Convert quadrants to standard abbreviations **;
  street_address = tranwrd( street_address, "Northeast", "NE" );
  street_address = tranwrd( street_address, "Northwest", "NW" );
  street_address = tranwrd( street_address, "Southeast", "SE" );
  street_address = tranwrd( street_address, "Southwest", "SW" );
  
  ** Extract ZIP code **;
  zip = scan( address, -1, ' ' );
  if substr( zip, 1, 2 ) ~= "20" then zip = "";
  else nzip = input( zip, 5. );
  
  ** Convert yes/no vars **;
  
  length &yes_no_num_var_list 3;
  
  array c{*} &yes_no_char_var_list;
  array n{*} &yes_no_num_var_list;
  
  do i = 1 to dim( c );
    if lowcase( c{i} ) = 'yes' then n{i} = 1;
    else if lowcase( c{i} ) = 'no' then n{i} = 0;
  end;
  
  ** Remove unneeded informats and formats **;
  
  informat _all_ ;
  format _all_ ;
  
  format Construction_End_Date mmddyy10.;
  format &yes_no_num_var_list dyesno.;
  
  ** Rename pre-existing address_id **;
  
  rename address_id = orig_address_id;
  
  drop i &yes_no_char_var_list;
  
run;

%File_info( data=dmped_list_clean, printobs=5, freqvars=zip status_public Non_DC_Gov_Project_Type )

proc freq data=dmped_list_clean;
  tables 
    Is_IZ_Project * Is_DCHA_Project * Is_DCHFA_Project * Is_DHCD_Long_term_loan *
    Is_DMPED_Project * Is_HPTF_Project * Is_Housing_Pres_Project *
    Is_PUD * Is_Non_DC_Gov_Project / list missing nocum nopercent;
run;

title2 'IZ Units';
proc means data=dmped_list_clean n sum;
  where Is_IZ_Project;
  var units_affordable;
run;
title2;

** Geocode addresses **;

%DC_mar_geocode( 
  data = dmped_list_clean,
  out = dmped_list_geocoded,
  staddr = street_address,
  zip = nzip
)

data dmped_list_geocoded_2;

  set dmped_list_geocoded;
  
  if not M_EXACTMATCH then address_id = orig_address_id;
  
run;

proc sql noprint;
  create table Match as
  select pcbg.nlihc_id, dmped.dmped_id, dmped.Project_name as DMPED_project_name, 
    dmped.street_address, dmped.M_EXACTMATCH, dmped.Ward2022, dmped.Geo2020,
    dmped.Units_Affordable, dmped.Construction_End_Date, dmped.Status_public,
    coalesce( pcbg.bldg_address_id, dmped.address_id ) as address_id
  from PresCat.Building_geocode as pcbg full join dmped_list_geocoded_2 as dmped
  on pcbg.bldg_address_id = dmped.address_id
  where dmped.M_EXACTMATCH
  order by nlihc_id, address_id;
quit;

title2 '**** NON-MATCHING PROJECTS ****';
proc print data=Match N;
  where missing( nlihc_id );
  id address_id;
  var DMPED_project_name Construction_End_Date Ward2022 Units_Affordable;
  sum Units_Affordable;
run;

title2 '**** MATCHING PROJECTS ****';
proc print data=Match N;
  where not( missing( nlihc_id ) );
  id nlihc_id;
  var DMPED_project_name Units_Affordable;
  sum Units_Affordable;
run;

%Dup_check(
  data=Match (where=(not(missing(nlihc_id)))),
  by=nlihc_id,
  id=dmped_id dmped_project_name,
  out=_dup_check,
  listdups=Y,
  count=dup_check_count,
  quiet=N,
  debug=N
)



title2;


** Export total units for non-matching projects **;

data DMPED_nonmatch_export;

  set Match;
  where missing( nlihc_id );
  
  array a{2000:2022} mid_asst_units_2000-mid_asst_units_2022;
  
  do y = 2000 to 2022;
  
    if status_public = "Completed Before 2015" or 0 < year( Construction_End_Date ) <= y then a{y} = Units_Affordable;
    else a{y} = 0;
    
  end;  
  
run;

  
proc print data=DMPED_nonmatch_export (obs=20);
  var status_public Construction_End_Date Units_Affordable mid_asst_units_2000-mid_asst_units_2022;
run;

proc summary data=DMPED_nonmatch_export nway;
  class geo2020;
  var mid_asst_units_2000-mid_asst_units_2022;
  output out=PresCat.DMPED_nonmatch_sum (drop=_type_ _freq_) sum=;
run;

proc print data=PresCat.DMPED_nonmatch_sum;
  id geo2020;
run;


