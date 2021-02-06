/**************************************************************************
 Program:  Strategy_at_risk.sas
 Library:  PresCat
 Project:  NeighborhoodInfo DC
 Author:   P. Tatian
 Created:  11/25/14
 Version:  SAS 9.2
 Environment:  Local Windows session (desktop)
 
 Description:  Count units in at risk section and units expiring by
2020. Also counts of section 8 and public housing. 

 Modifications:
**************************************************************************/

%include "\\sas1\DCdata\SAS\Inc\StdLocal.sas";

** Define libraries **;
%DCData_lib( PresCat )

data Subsidy;

/*
  merge 
    PresCat.Subsidy
    PresCat.Project (keep=nlihc_id category);
  by nlihc_id;
*/

  set PresCat.Subsidy;
  
  if portfolio ~= "Project Rental Assistance Contract (PRAC)";
  
  if Subsidy_active and 2014 <= year( POA_end ) <= 2020 then Units_expire_2020 = Units_Assist;
  else Units_expire_2020 = 0;
  
  if Subsidy_active and portfolio = 'Project-based Section 8' then Units_sec8 = Units_Assist;
  else Units_sec8 = 0;
  
  if Subsidy_active and portfolio = 'Public Housing' then Units_pubhsng = Units_Assist;
  else Units_pubhsng = 0;
  
run;


proc summary data=Subsidy;
  by nlihc_id;
  var Units_expire_2020 Units_sec8 Units_pubhsng;
  output out=Subsidy_sum sum=;
run;

data Project_subsidy;

  merge 
    PresCat.Project 
      (where=(status = 'A' and Subsidized)
       in=in1)
    Subsidy_sum (drop=_freq_ _type_);
  by nlihc_id;

  if in1;
  
  Units_expire_2020 = min( Proj_Units_Assist_Max, Units_expire_2020 );

  Units_sec8 = min( Proj_Units_Assist_Max, Units_sec8 );

  Units_pubhsng = min( Proj_Units_Assist_Max, Units_pubhsng );
  
run;

proc format;
  value $catsum
    '1' = 'At risk'
    other = 'Other';
run;  

proc tabulate data=Project_subsidy format=comma10.0 noseps missing;
  class category_code;
  var Proj_units_assist_max Units_expire_2020 Units_sec8 Units_pubhsng;
  table 
    /** Rows **/
    all='Total' category_code,
    /** Columns **/
    sum='Assisted units' * ( 
      Proj_units_assist_max='Total' 
      Units_expire_2020='Expiring by 2020' 
      Units_sec8 = 'Section 8'
      Units_pubhsng = 'Public housing' )
  ;
  format category_code $catsum.;
run;
