/**************************************************************************
 Program:  Update_DCHA_Document_2016_04.sas
 Library:  PresCat
 Project:  NeighborhoodInfo DC
 Author:   K. Abazajian
 Created:  08/29/2016
 Version:  SAS 9.2
 Environment:  Local Windows session (desktop)
 
 Description:  Make manual adjustments to projects with edits from DCHA (04/16)

 Modifications:
**************************************************************************/

%include "L:\SAS\Inc\StdLocal.sas";

** Define libraries **;
%DCData_lib( PresCat )

%let Update_dtm = %sysfunc( datetime() );

%let Project_tracking_list =
"NL000033",
"NL000034",
"NL000043",
"NL000050",
"NL000085",
"NL000110",
"NL000133",
"NL000157",
"NL000169",
"NL000225",
"NL000232",
"NL000234",
"NL000242",
"NL000264",
"NL000301",
"NL000303",
"NL000329",
"NL000349",
"NL000353",
"NL000384",
"NL000388",
"NL000419",
"NL000990",
"NL001000"
;

/*******************UPDATE SUBSIDY DATA****************/


** Create blank record from PresCat.Subsidy data set **;
proc sql noprint;
  create table A like PresCat.Subsidy;
quit;

data B;
  set PresCat.Subsidy (keep=nlihc_id obs=1);
  nlihc_id = '';
run;

** Create new observations to add to data set **;
data Subsidy_new_recs;
  set A B;

  ** Add new observations **;
  
  Update_Dtm = &Update_Dtm; 

	*Glenncrest;
  nlihc_id = 'NL000085';
  subsidy_id = 5;
  units_assist=61;
  program="PUBHSNG";
  agency="DCHA";
  subsidy_info_source = "DCHA Document" ;
  subsidy_info_source_date = '12apr2016'd;
  Subsidy_active=1;
  output;
  	*Glenncrest;
  nlihc_id = 'NL000085';
  subsidy_id = 6;
  units_assist=61;
  program="HOPEVI";
  subsidy_info_source = "DCHA Document" ;
  subsidy_info_source_date = '12apr2016'd;
  Subsidy_active=1;
  output;
	*Gibson Plaza;
  nlihc_id = 'NL000133';
  subsidy_id = 5;
  units_assist=53;
  program="PUBHSNG";
   agency="DCHA";
  subsidy_info_source = "DCHA Document" ;
  subsidy_info_source_date = '12apr2016'd;
   Subsidy_active=1;
  output;
	*Phyllis Wheatley;
  nlihc_id = 'NL000242';
  subsidy_id = 3;
  units_assist=76;
  program="PUBHSNG";
   agency="DCHA";
  subsidy_info_source = "DCHA Document" ;
  subsidy_info_source_date = '12apr2016'd;
    Subsidy_active=1;
  output;
	*Phyllis Wheatley;
  nlihc_id = 'NL000242';
  subsidy_id = 4;
  units_assist=6;
  program="LIHTC";
  subsidy_info_source = "DCHA Document" ;
  subsidy_info_source_date = '12apr2016'd;
    Subsidy_active=1;
  output;
	*St. Martin's;
  nlihc_id = 'NL000384';
  subsidy_id = 4;
  units_assist=50;
  program="PUBHSNG";
  agency="DCHA";
  subsidy_info_source = "DCHA Document" ;
  subsidy_info_source_date = '12apr2016'd;
    Subsidy_active=1;
  output;
	*St. Martin's;
  nlihc_id = 'NL000384';
  subsidy_id = 5;
  units_assist=10;
  program="PBV";
  agency="DCHA";
  subsidy_info_source = "DCHA Document" ;
  subsidy_info_source_date = '12apr2016'd;
    Subsidy_active=1;
  output;
  	*The Avenue;
  nlihc_id = 'NL000225';
  subsidy_id = 2;
  units_assist=83;
  program="LIHTC";
  subsidy_info_source = "DCHA Document" ;
  subsidy_info_source_date = '12apr2016'd;
    Subsidy_active=1;
  output;
  	*Highland Dwellings; 
  nlihc_id="NL000157";
  subsidy_id=3;
  program="LIHTC";
  units_assist=30;
  subsidy_info_source = "DCHA Document" ;
  subsidy_info_source_date = '12apr2016'd;
    Subsidy_active=1;
  output;
  	*Henson UFAs;
  nlihc_id = "NL000388";
  subsidy_id=5;
  program="PBV";
  units_assist=22;
  agency="DCHA";
  subsidy_info_source = "DCHA Document" ;
  subsidy_info_source_date = '12apr2016'd;
    Subsidy_active=1;
  output;

  	*Capper Senior II - Capitol Quarter Senior II;
  nlihc_id = "NL000990";
  subsidy_id=4;
  program="TEBOND";
  subsidy_info_source = "DCHA Document" ;
  subsidy_info_source_date = '12apr2016'd;
    Subsidy_active=1;
  output;

    *Capper Senior II - Capitol Quarter Senior II;
  nlihc_id = "NL000990";
  subsidy_id=5;
  program="HOPEVI";
  subsidy_info_source = "DCHA Document" ;
  subsidy_info_source_date = '12apr2016'd;
  output;


run;

** Combine new and old observations **;
** Make corrections on existing data **;
proc sort data=subsidy_new_recs; by nlihc_id subsidy_id; run;

data Subsidy_old_plus_new;

  set PresCat.Subsidy Subsidy_new_recs;
  by nlihc_id subsidy_id;

/******** From document checking Public Housing with other subsidies ********/
*The Avenue;
if nlihc_id = "NL000225" & subsidy_id=1 then do;
	Units_Assist=27;
	Update_Dtm = &Update_Dtm; 
end;

*Barnaby Manor;
if nlihc_id = "NL000033" & Subsidy_id=2 then do;
	program="PBV" ;
	agency="DCHA";
	Subsidy_Info_Source = "DCHA Document";
  	subsidy_info_source_date = '12apr2016'd;
	Update_Dtm = &Update_Dtm; 
end;

*Highland Dwellings; 
if nlihc_id="NL000157" & subsidy_id=1 then do; 
	program="TEBOND";
	Subsidy_Info_Source = "DCHA Document";
  	subsidy_info_source_date = '12apr2016'd;
	units_assist=.;
	Update_Dtm = &Update_Dtm; 
end;

*SOME;
if nlihc_id = "NL000169" & Subsidy_id=2 then do;
	program="PBV" ;
	units_assist=22;
	agency="DCHA";
	Subsidy_Info_Source = "DCHA Document";
  	subsidy_info_source_date = '12apr2016'd;
	Update_Dtm = &Update_Dtm; 
end;

*Overlook at Oxon Run;
if nlihc_id = "NL000232" & Subsidy_id=3 then do; 
	program="PBV" ;
	agency="DCHA";
	Subsidy_Info_Source = "DCHA Document";
  	subsidy_info_source_date = '12apr2016'd;
	Update_Dtm = &Update_Dtm; 
end;

*Gibson Plaza; 
if nlihc_id="NL000133" & program="LMSA" then do;
	program="PBV";
	units_assist=20;
	agency="DCHA";
	Subsidy_Info_Source = "DCHA Document";
  	subsidy_info_source_date = '12apr2016'd;
	Subsidy_Info_Source_ID = .;
	POA_start=.;
	POA_end=.;
	contract_number=.;
	rent_to_fmr_description=.;
	Compl_end=.;
	POA_start_orig=.;
	Subsidy_info_source_property=.;
	Update_Dtm = &Update_Dtm; 
end;

*Henson UFAs;
if nlihc_id = "NL000388" & Subsidy_id=3 then Units_Assist=280 ;
if nlihc_id = "NL000388" & Subsidy_id=1 then do;
	program="CDBG" ;
	Subsidy_Info_Source = "DCHA Document";
  	subsidy_info_source_date = '12apr2016'd;
   	Update_Dtm = &Update_Dtm; 
end;

*Arthur Capper Phase I; *Need to add HOPEVI program;
if nlihc_id = "NL000264" & Subsidy_id=3 then do; 
	Subsidy_Info_Source = "DCHA Document";
  	subsidy_info_source_date = '12apr2016'd;
	program="HOPEVI" ;
	Update_Dtm = &Update_Dtm; 
end;

*Capitol Gateway SF; *Need to add HOPEVI program;
if nlihc_id = "NL000050" & Subsidy_id=2 then do; 
	program="HOPEVI" ;
	Subsidy_Info_Source = "DCHA Document";
  	subsidy_info_source_date = '12apr2016'd;
	Update_Dtm = &Update_Dtm; 
end;


/**********From document checking all PUBHSNG subsidy info ************/

*Pollin memorial;
if nlihc_id="NL000353" & subsidy_id=1 then do;
	Program="PUBHSNG";
	Subsidy_Info_Source = "DCHA Document";
  	subsidy_info_source_date = '12apr2016'd;
	POA_start=.;
	POA_end=.;
	Compl_end=.;
	POA_start_orig=.;
	Update_Dtm = &Update_Dtm; 
end;

*Triangle View;
if nlihc_id="NL000419" then Units_Assist=25;

*Williston; 
if nlihc_id="NL000303" & subsidy_id=2 then do; 
 	Subsidy_Info_Source="DCHA Document";
  	subsidy_info_source_date = '12apr2016'd;
 	Program="PBV";
	Units_assist=28;
	Update_Dtm = &Update_Dtm; 
end;
if nlihc_id="NL000303" & (subsidy_id=1 | subsidy_id=4) then do;
	Units_assist=28;
	Update_Dtm = &Update_Dtm; 
end;

/***************From APSH************************/
if Nlihc_id="NL000034" then do;
	Units_Assist=439;
	Subsidy_Info_Source="APSH";
	subsidy_info_source_date = '16jun2016'd;
	Update_Dtm = &Update_Dtm; 
end;

if nlihc_id="NL000043" then do;
	Units_Assist=284;
	Subsidy_Info_Source="APSH";
	subsidy_info_source_date = '16jun2016'd;
	Update_Dtm = &Update_Dtm; 
end;

/************Delete subsidies****************/
  *Glenncrest;
if nlihc_id = "NL000085" & program="DC-HPTF" then delete;
if nlihc_id = "NL000085" then do; 
	if subsidy_id=3 then new_sub_id=2;
	else if subsidy_id=4 then new_sub_id=3;
	else if subsidy_id=5 then new_sub_id=4;
	else if subsidy_id=6 then new_sub_id=5;
	else new_sub_id=subsidy_id;
	subsidy_id=new_sub_id;
end;

  *Fort lincoln no LIHTC all pub housing;
if nlihc_id = "NL000110" & program="LIHTC" then delete; 
if nlihc_id = "NL000110" then do; 
	if subsidy_id=2 then new_sub_id=1;
	subsidy_id=new_sub_id;
end;

  *Capitol Gateway Senior Estates;
if Nlihc_id= "NL001000" & Portfolio="PUBHSNG" then delete;
if nlihc_id = "NL001000" then do; 
	if subsidy_id=2 then new_sub_id=1;
	else if subsidy_id=3 then new_sub_id=2;
	else if subsidy_id=4 then new_sub_id=3;
	else new_sub_id=subsidy_id;
	subsidy_id=new_sub_id;
end;

  Portfolio = put( Program, $progtoportfolio. );
  drop new_sub_id;
run;

/*Compare files*/
proc sort data=subsidy_old_plus_new out=update_subsidy; by nlihc_id subsidy_id; run;

ods html body="&_dcdata_default_path\PresCat\Prog\Updates\Update_DCHA_Document_2016_04_subsidy_compare.html" style=Default; 
proc compare base=PresCat.Subsidy compare=update_subsidy listall maxprint=(40,32000);
id nlihc_id subsidy_id;
run;
ods html close;

data update_subsidy_tracking;
set update_subsidy (where=( nlihc_id in ( &Project_tracking_list ) ));
run;
ods html body="&_dcdata_default_path\PresCat\Prog\Updates\Update_DCHA_Document_2016_04_Subsidy_changes.html" style=Default; 

proc print data=update_subsidy_tracking; run;

ods html close;


/*******************UPDATE PROJECT DATA****************/


%let Update_dtm = %sysfunc( datetime() );

data update_project;
set prescat.project;

/******************Adjusting ownership****************/
*Parkway Overlook - subsidies are LIHTC, LMSA - need project_except?;
if Nlihc_id= "NL000234" then do;
	Hud_Own_Name="Parkway Overlook, LP (DCHA affiliate)";
Update_Dtm = &Update_Dtm; 
end;

*Henson UFAs - subsidies are TEBOND, HPTF, LIHTC, PH, PBV;
if nlihc_id = "NL000388" then do; 
	Proj_Units_Assist_Max=280 ;
	Proj_Units_Tot=600 ;
	Hud_Mgr_Name="Edgewood Management Corporation";
Update_Dtm = &Update_Dtm; 
end;

*Highland Dwellings;
if nlihc_id = "NL000157" then do;
	Hud_Mgr_Name="CIH Properties, Inc.";
	Hud_Own_Name="Highland Dwellings Residential, LP";
Update_Dtm = &Update_Dtm; 
end;

/*******Adjusting number units to match subsidy file*******/

*Glenncrest;
if nlihc_id = "NL000085" then do;
Proj_Units_Tot=61;
Update_Dtm = &Update_Dtm; 
end;

*Phyllis Wheatley - HPTF says 117 units, HOME says 115? DCHA corrections below;
if nlihc_id="NL000242" then do; 
	Proj_Units_Tot=84;
	Proj_Units_Assist_Min = 6; 
Update_Dtm = &Update_Dtm; 
end;

*St. Martin;
if nlihc_id = "NL000384" then do;
	Proj_Units_Assist_Min=10;
Update_Dtm = &Update_Dtm; 
end;

*The Avenue;
if nlihc_id = "NL000225" then do;
	Proj_Units_Assist_Min=27;
	Proj_Units_assist_Max=83;
	Update_Dtm = &Update_Dtm; 
end;

*Triangle View;
if nlihc_id="NL000419" then do;
	Proj_Units_Tot=100;
	Proj_Units_Assist_Min=25;
	Update_Dtm = &Update_Dtm; 
end;

*Williston;
if nlihc_id="NL000303" then do;
	Proj_Units_Tot=28;
	Proj_Units_Assist_Min=28;
	Proj_Units_Assist_Max=28;
	Update_Dtm = &Update_Dtm; 
end;


run;

proc sort data=update_project; by nlihc_id; run;

ods html body="&_dcdata_default_path\PresCat\Prog\Updates\Update_DCHA_Document_2016_04_project_compare.html" style=Default; 
proc compare base=PresCat.Project compare=update_project listall maxprint=(40,32000);
id nlihc_id;
run;
ods html close;

data update_project_tracking;
set update_project(where=(nlihc_id in ( &Project_tracking_list ) ) );
run;
ods html body="&_dcdata_default_path\PresCat\Prog\Updates\Update_DCHA_Document_2016_04_Project_changes.html" style=Default; 

proc print data=update_project_tracking ; run;
ods html close;
/*
data prescat.subsidy;
set Subsidy_old_plus_new;
run;

data prescat.project;
set update_project;
run;
*/


/*Projects to delete

Capitol Gateway Townhomes part of single family, nlihc_id = "NL000375" 

Capper Senior duplicate, nlihc_id = "NL001019" 

*/
