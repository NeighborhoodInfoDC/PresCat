/**************************************************************************
 Program:  Monthly_rpt_export.sas
 Library:  PresCat
 Project:  NeighborhoodInfo DC
 Author:   P. Tatian
 Created:  09/03/15
 Version:  SAS 9.2
 Environment:  Local Windows session (desktop)
 
 Description:  Export CSV data to import into Access db to create
 monthly Preservation Catalog report.

 Modifications:
**************************************************************************/

%include "L:\SAS\Inc\StdLocal.sas";

** Define libraries **;
%DCData_lib( PresCat, local=n )

** Process REAC scores: one obs per project **;

proc sort data=PresCat.Reac_score out=Reac_score_sorted;
  by nlihc_id descending Reac_date;
run;

data Reac_score;

  set Reac_score_sorted (keep=nlihc_id Reac_date Reac_score);
  by nlihc_id;
  
  if first.nlihc_id then do;
    Num = 0;
  end;
  
  Num + 1;
  
  if Num <= 3;
  
run;

%Super_transpose(  
  data=Reac_score,
  out=Reac_score_tr,
  var=Reac_Date Reac_Score,
  id=Num,
  by=nlihc_id,
  mprint=N
)

** Create monthly report data **;

options validvarname=any;

data Monthly_rpt;

  length
    CATEGORY $ 40
    NLIHC_ID $ 16
    Subsidy_id 8
    Proj_Name $ 80
    PBCA 4
    Proj_Addre $ 160
    Proj_City $ 80
    Proj_ST $ 2
    Proj_Zip $ 5
    Ward $ 1
    Own_Compan $ 80
    Own_Comp_1 $ 80
    Mgr_Compan $ 80
    TA_PROVIDER $ 80
    TA_NOTES $ 2000
    'PASS1 Score'n $ 8
    'PASS1 Date'n 8
    'PASS2 Score'n $ 8
    'PASS2 Date'n 8
    'PASS3 Score'n $ 8
    'PASS3 Date'n 8
    SOURCE $ 160
    PROGRAM $ 80
    UNITS_ASS 8
    UNITS_TOT 8
    POA_START 8
    POA_END 8
    NOTES $ 2000;

  merge
    PresCat.Project_category_view
      (keep=nlihc_id proj_name proj_addre proj_city proj_st proj_zip
            hud_own_name hud_own_type hud_mgr_name proj_units_tot ward2012 pbca category_code) 
    PresCat.TA_notes (keep=nlihc_id ta_provider ta_notes)
    Reac_score_tr
    PresCat.Subsidy
      (keep=nlihc_id subsidy_id subsidy_active subsidy_info_source_date subsidy_info_source program 
            units_assist poa_start poa_end);
  by nlihc_id;
  
  if category_code in ( '1', '2', '3', '4', '5' );

  CATEGORY = put( category_code, $categrn. );
  Ward = ward2012;
  Own_Compan = hud_own_name;
  Own_Comp_1 = put( hud_own_type, $OWNMGRTYPE. );
  Mgr_Compan = hud_mgr_name;
  TA_NOTES = left( compbl( TA_NOTES ) );

  'PASS1 Score'n = Reac_Score_1; 
  'PASS1 Date'n = Reac_Date_1;
  'PASS2 Score'n = Reac_Score_2;
  'PASS2 Date'n = Reac_Date_2;
  'PASS3 Score'n = Reac_Score_3;
  'PASS3 Date'n = Reac_Date_3;
  
  if subsidy_info_source_date > 0 then
    SOURCE = trim( put( subsidy_info_source, $infosrc. ) ) || ' (' || trim( left( put( subsidy_info_source_date, mmddyy8. ) ) ) || ')';
  else 
    SOURCE = put( subsidy_info_source, $infosrc. );
  
  /*PROGRAM = put( portfolio, $portfolio. );*/
  UNITS_ASS = units_assist;
  UNITS_TOT = proj_units_tot;
  
  if subsidy_active then Notes = "";
  else Notes = "Inactive";

  format poa_start poa_end 'PASS1 Date'n 'PASS2 Date'n 'PASS3 Date'n mmddyy10.;

  keep
    CATEGORY
    NLIHC_ID
    Subsidy_ID
    Proj_Name
    PBCA
    Proj_Addre
    Proj_City
    Proj_ST
    Proj_Zip
    Ward
    Own_Compan
    Own_Comp_1
    Mgr_Compan
    TA_PROVIDER
    TA_NOTES
    'PASS1 Score'n
    'PASS1 Date'n
    'PASS2 Score'n
    'PASS2 Date'n
    'PASS3 Score'n
    'PASS3 Date'n
    SOURCE
    PROGRAM
    UNITS_ASS
    UNITS_TOT
    POA_START
    POA_END
    NOTES;
    
run;

** Export to CSV **;

options missing=' ';

filename fexport "&_dcdata_default_path\PresCat\Prog\Reports\MonthlyReport.csv" lrecl=2000;

proc export data=Monthly_rpt
    outfile=fexport
    dbms=csv replace;

run;

filename fexport clear;

