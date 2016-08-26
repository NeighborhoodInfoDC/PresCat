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


** Import subsidy data **;

filename fimport "D:\DCData\Libraries\PresCat\Raw\Buildings_for_geocoding_2016-08-01_subsidy.csv" lrecl=2000;

data WORK.NEW_PROJ_SUBS    ;
%let _EFIERR_ = 0; /* set the ERROR detection macro variable */
infile FIMPORT delimiter = ',' MISSOVER DSD lrecl=32767 firstobs=2 ;
informat MARID best32. ;
informat Units_assist 8. ;
informat POA_start mmddyy10. ;
informat POA_end mmddyy10. ;
informat rent_to_fmr_description $40. ;
informat Subsidy_Info_Source_ID $40. ;
informat Subsidy_Info_Source $40. ;
informat Subsidy_Info_Source_Date 8. ;
informat Subsidy_Notes $40. ;
informat Update_Dtm DATETIME16.;
informat Program $32. ;
informat Compl_end mmddyy10. ;
informat POA_end_prev mmddyy10. ;
informat Agency $80. ;
informat POA_start_orig mmddyy10. ;
informat Portfolio $16. ;
informat Subsidy_info_source_property $40. ;
informat POA_end_actual mmddyy10. ;
format MARID best12. ;
format Units_assist 8. ;
format POA_start mmddyy10. ;
format POA_end mmddyy10. ;
format rent_to_fmr_description $40. ;
format Subsidy_Info_Source_ID $40. ;
format Subsidy_Info_Source $40. ;
format Subsidy_Info_Source_Date 8. ;
format Subsidy_Notes $40. ;
format Update_Dtm DATETIME16. ;
format Program $32. ;
format Compl_end mmddyy10. ;
format POA_end_prev mmddyy10. ;
format Agency $80. ;
format POA_start_orig mmddyy10. ;
format Portfolio $16. ;
format Subsidy_info_source_property $40. ;
format POA_end_actual mmddyy10. ;
input
MARID
Units_assist
POA_start
POA_end
rent_to_fmr_description $
Subsidy_Info_Source_ID $
Subsidy_Info_Source $
Subsidy_Info_Source_Date
Subsidy_Notes $
Update_Dtm
Program $
Compl_end 
POA_end_prev 
Agency $
POA_start_orig
Portfolio $
Subsidy_info_source_property $
POA_end_actual
;
if _ERROR_ then call symputx('_EFIERR_',1);  /* set ERROR detection macro variable */
_drop = 0;
run;

filename fimport clear;
  
data NLIHC_ID;

	set work.project_geocode
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

run;

data prescat.Subsidy;

set  prescat.subsidy Subsidy_a;
run;
