/**************************************************************************
 Program:  Add_Subsidy.sas
 Library:  PresCat
 Project:  NeighborhoodInfo DC
 Author:   M. Cohen
 Created:  08/26/16
 Version:  SAS 9.1
 Environment:  Local Windows session (desktop)
 
 Description:  Add New Subsidy Data.

 Modifications:

**************************************************************************/

%include "L:\SAS\Inc\StdLocal.sas";

** Define libraries **;
%DCData_lib( PresCat )

%let input_file_pre = Buildings_for_geocoding_2016-08-01;

** Import subsidy data **;

filename fimport "&_dcdata_r_path\PresCat\Raw\New\&input_file_pre._subsidy1.csv" lrecl=2000;

data WORK.NEW_PROJ_SUBS    ;
%let _EFIERR_ = 0; /* set the ERROR detection macro variable */
infile FIMPORT delimiter = ',' MISSOVER DSD lrecl=32767 firstobs=2 ;
informat MARID best32. ;
informat Units_assist 8. ;
informat Current_Affordability_Start mmddyy10. ;
informat Current_Affordability_End mmddyy10. ;
informat Fair_Market_Rent_Ratio $40. ;
informat Subsidy_Info_Source_ID $40. ;
informat Subsidy_Info_Source $40. ;
informat Subsidy_Info_Source_Date 8. ;
informat Update_Date_Time DATETIME16.;
informat Program $32. ;
informat Compliance_end_date mmddyy10. ;
informat Previous_Affordability_End mmddyy10. ;
informat Agency $80. ;
informat Portfolio $16. ;
informat Date_Affordability_Ended mmddyy10. ;
format MARID best12. ;
format Units_assist 8. ;
format Current_Affordability_Start mmddyy10. ;
format Current_Affordability_End mmddyy10. ;
format Fair_Market_Rent_Ratio $40. ;
format Subsidy_Info_Source_ID $40. ;
format Subsidy_Info_Source $40. ;
format Subsidy_Info_Source_Date 8. ;
format Update_Date_Time DATETIME16. ;
format Program $32. ;
format Compliance_end_date mmddyy10. ;
format Previous_Affordability_End mmddyy10. ;
format Agency $80. ;
format Portfolio $16. ;
format Date_Affordability_Ended mmddyy10. ;
input
MARID
Units_assist
Current_Affordability_Start
Current_Affordability_End
Fair_Market_Rent_Ratio $
Subsidy_Info_Source_ID $
Subsidy_Info_Source $
Subsidy_Info_Source_Date
Update_Date_Time
Program $
Compliance_end_date 
Previous_Affordability_End 
Agency $
Portfolio $
Date_Affordability_Ended
;
if _ERROR_ then call symputx('_EFIERR_',1);  /* set ERROR detection macro variable */
_drop = 0;
run;

filename fimport clear;
  
data NLIHC_ID;

	set prescat.project_geocode
	(keep=NLIHC_id proj_address_id);
	_drop = 1;
	run;

proc sort data=nlihc_id;
by proj_address_id;
run;


proc sort data=New_Proj_Subs;
by marid;
run;


data Subsidy_a;

  merge NLIHC_ID (rename=(proj_address_id=address_id)) New_Proj_Subs (rename=(marid=address_id));
  by address_id;
  if _drop = 1 then delete;
  drop _drop address_id;
run;

proc sort data = Subsidy_a;
by nlihc_id;
run;

data Subsidy_a;
  set Subsidy_a;
  by nlihc_id;
  ** Subsidy ID number **;
  
  if first.Nlihc_id then Subsidy_id = 0;
  
  Subsidy_id + 1;
  
  
  if Date_Affordability_Ended = . then Subsidy_Active = 1;
  else Subsidy_Active = 0;

run;

data prescat.Subsidy;

set  prescat.subsidy Subsidy_a (rename=(current_affordability_start=POA_start current_affordability_end=POA_end 
								Fair_Market_Rent_Ratio=rent_to_fmr_description update_date_time=update_dtm 
								Compliance_End_Date=compl_end Date_Affordability_Ended=POA_End_actual Previous_affordability_end=POA_end_prev));
run;
