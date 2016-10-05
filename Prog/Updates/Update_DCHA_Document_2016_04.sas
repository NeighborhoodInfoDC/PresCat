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
%DCData_lib( PresCat, local=n, rreadonly=n )


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
  
	*Glenncrest;
  nlihc_id = 'NL000085';
  subsidy_id = 5;
  units_assist=61;
  program="PUBHSNG";
  subsidy_info_source = "DCHA Document" ;
  subsidy_info_source_date = '12apr2016'd;
  output;
	*Gibson Plaza;
  nlihc_id = 'NL000133';
  subsidy_id = 5;
  units_assist=53;
  program="PUBHSNG";
  subsidy_info_source = "DCHA Document" ;
  subsidy_info_source_date = '12apr2016'd;
  output;
	*Phyllis Wheatley;
  nlihc_id = 'NL000242';
  subsidy_id = 3;
  units_assist=76;
  program="PUBHSNG";
  subsidy_info_source = "DCHA Document" ;
  subsidy_info_source_date = '12apr2016'd;
  output;
	*Phyllis Wheatley;
  nlihc_id = 'NL000242';
  subsidy_id = 4;
  units_assist=6;
  program="LIHTC";
  subsidy_info_source = "DCHA Document" ;
  subsidy_info_source_date = '12apr2016'd;
  output;
	*St. Martin's;
  nlihc_id = 'NL000384';
  subsidy_id = 4;
  units_assist=50;
  program="PUBHSNG";
  subsidy_info_source = "DCHA Document" ;
  subsidy_info_source_date = '12apr2016'd;
  output;
	*St. Martin's;
  nlihc_id = 'NL000384';
  subsidy_id = 5;
  units_assist=10;
  program="PBV";
  agency="DCHA";
  subsidy_info_source = "DCHA Document" ;
  subsidy_info_source_date = '12apr2016'd;
  output;
  	*The Avenue;
  nlihc_id = 'NL000225';
  subsidy_id = 2;
  units_assist=83;
  program="LIHTC";
  subsidy_info_source = "DCHA Document" ;
  subsidy_info_source_date = '12apr2016'd;
  output;
  	*Highland Dwellings; 
  nlihc_id="NL000157";
  subsidy_id=3;
  program="LIHTC";
  units_assist=30;
  subsidy_info_source = "DCHA Document" ;
  subsidy_info_source_date = '12apr2016'd;
  output;
  	*Henson UFAs;
  nlihc_id = "NL000388";
  subsidy_id=5;
  program="PBV";
  units_assist=22;
  agency="DCHA";
  subsidy_info_source = "DCHA Document" ;
  subsidy_info_source_date = '12apr2016'd;
  output;
  	*Capper Senior II - Capitol Quarter Senior II;
  nlihc_id = "NL000990";
  subsidy_id=4;
  program="TEBOND";
  subsidy_info_source = "DCHA Document" ;
  subsidy_info_source_date = '12apr2016'd;
  output;

    *Capper Senior II - Capitol Quarter Senior II;
/* nlihc_id = "NL000990";
  subsidy_id=5;
  program="HOPEVI";
  subsidy_info_source = "DCHA Document" ;
  subsidy_info_source_date = '12apr2016'd;
  output;*/

  Portfolio = put( Program, $progtoportfolio. );
run;

** Combine new and old observations **;
** Make corrections on existing data **;
proc sort data=subsidy_new_recs; by nlihc_id subsidy_id; run;

data Subsidy_old_plus_new;

  set PresCat.Subsidy Subsidy_new_recs;
  by nlihc_id subsidy_id;



/******** From document checking Public Housing with other subsidies ********/
*The Avenue;
if nlihc_id = "NL000225" & subsidy_id=1 then Units_Assist=27;

*Barnaby Manor;
if nlihc_id = "NL000033" & Subsidy_id=2 then do;
	program="PBV" ;
	agency="DCHA";
end;

*Highland Dwellings; 
if nlihc_id="NL000157" & subsidy_id=1 then program="TEBOND";

*SOME;
if nlihc_id = "NL000169" & Subsidy_id=2 then do;
	program="PBV" ;
	units_assist=22;
	agency="DCHA";
end;

*Overlook at Oxon Run;
if nlihc_id = "NL000232" & Subsidy_id=3 then do; 
	program="PBV" ;
	agency="DCHA";
end;

*Gibson Plaza; 
if nlihc_id="NL000133" & program="LMSA" then do;
	program="PBV";
	units_assist=20;
	agency="DCHA";
end;

*Henson UFAs;
if nlihc_id = "NL000388" & Subsidy_id=3 then Units_Assist=22 ;
if nlihc_id = "NL000388" & Subsidy_id=1 then program="CDBG" ;

*Arthur Capper Phase I; *Need to add HOPEVI program;
*if nlihc_id = "NL000264" & Subsidy_id=3 then program="HOPEVI" ;

*Capitol Gateway SF; *Need to add HOPEVI program;
*if nlihc_id = "NL000050" & Subsidy_id=2 then program="HOPEVI" ;


/**********From document checking all PUBHSNG subsidy info ************/

*Pollin memorial;
if nlihc_id="NL000353" & subsidy_id=1 then do;
	Program="PUBHSNG";
	Subsidy_Info_Source = "DCHA Document";
end;

*Triangle View;
if nlihc_id="NL000419" then Units_Assist=25;

*Williston; 
if nlihc_id="NL000303" & subsidy_id=2 then do; 
 	Subsidy_Info_Source="DCHA Document";
 	Program="PUBHSNG";
end;

*FROM APSH;
if Nlihc_id="NL000034" then do;
	Units_Assist=439;
	Subsidy_Info_Source="APSH";
	subsidy_info_source_date = '16jun2016'd;
end;

if nlihc_id="NL000043" then do;
	Units_Assist=284;
	Subsidy_Info_Source="APSH";
	subsidy_info_source_date = '16jun2016'd;
end;



run;

/*Compare files*/
proc sort data=subsidy_old_plus_new out=update_subsidy; by nlihc_id subsidy_id; run;

ods html body="&_dcdata_default_path\PresCat\Prog\Update\Update_DCHA_Document_2016_04_subsidy_compare.html" style=Default; 
proc compare base=PresCat.Subsidy compare=update_subsidy listall maxprint=(40,32000);
id nlihc_id subsidy_id;
run;
ods html close;

/*
data prescat.subsidy;
set update_subsidy;
run;
*/
