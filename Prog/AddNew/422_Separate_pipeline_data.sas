/**************************************************************************
 Program:  422_Separate_pipeline_data.sas
 Library:  Prescat
 Project:  Urban-Greater DC
 Author:   P. Tatian
 Created:  08/25/23
 Version:  SAS 9.4
 Environment:  Local Windows session (desktop)
 GitHub issue:  422
 
 Description:  Separate new and existing projects for DC pipeline update.

 Modifications:
**************************************************************************/

%include "\\sas1\DCdata\SAS\Inc\StdLocal.sas";

** Define libraries **;
%DCData_lib( Prescat )


** Read in source data **;

filename fimport "\\sas1\DCData\Libraries\PresCat\Raw\AddNew\New_projects_issue_303_matching_project_list.csv" lrecl=2000;

proc import out=Matching_project_list
    datafile=fimport
    dbms=csv replace;
  datarow=2;
  getnames=yes;
  guessingrows=max;
run;

filename fimport clear;

%File_info( data=Matching_project_list, stats= )

%Dup_check(
  data=Matching_project_list,
  by=id,
  id=nlihc_id_cat,
  out=_dup_check,
  listdups=Y,
  count=dup_check_count,
  quiet=N,
  debug=N
)


filename fimport "\\sas1\DCData\Libraries\PresCat\Raw\AddNew\New_projects_issue_303.csv" lrecl=2000;

proc import out=New_projects
    datafile=fimport
    dbms=csv replace;
  datarow=2;
  getnames=yes;
  guessingrows=max;
run;

filename fimport clear;

** Create unique project names **;

data New_projects;

  set New_projects;
  
  if proj_name = "Ivy City/ Trinidad" then proj_name = trim( proj_name ) || " - " || Bldg_Addre;
  
run;

%File_info( data=New_projects, stats= )

/*
filename fimport "\\sas1\DCData\Libraries\PresCat\Raw\AddNew\New_projects_issue_303_subsidy.csv" lrecl=2000;

proc import out=New_subsidy
    datafile=fimport
    dbms=csv replace;
  datarow=2;
  getnames=yes;
  guessingrows=max;
run;

filename fimport clear;

%File_info( data=New_subsidy )
*/

filename fimport "\\sas1\DCData\Libraries\PresCat\Raw\AddNew\Pipeline_id_crosswalk.csv" lrecl=2000;

proc import out=Pipeline_id_crosswalk
    datafile=fimport
    dbms=csv replace;
  datarow=2;
  getnames=yes;
  guessingrows=max;
run;

filename fimport clear;

** Make ID var numeric **;

data Pipeline_id_crosswalk;

  length id_num 8.;

  set Pipeline_id_crosswalk;

  id_num = input( id, 8. );

  drop id;
  rename id_num = id;

run;

%File_info( data=Pipeline_id_crosswalk, stats= )

proc sort data=Pipeline_id_crosswalk out=Pipeline_id_crosswalk_nodup nodupkey;
  by id project_name;
run;

** Create subsidy export file **;

proc sql noprint;
  create table Pipeline_w_id as 
  select distinct xwalk.project_name, xwalk.id, pipeline.*
  from Pipeline_id_crosswalk_nodup as xwalk left join Prescat.Dc_pipeline_2022_07 as pipeline
  on xwalk.project_name = pipeline.project_name
  order by id;
quit;

** Create subsidy export **;

data Subsidy;

  length
ID Units_tot Units_Assist Current_Affordability_Start Affordability_End 8
application_fiscal_year selection_date Proj_or_Act_Loan_Closing_Date $ 80
rent_to_fmr_description Subsidy_Info_Source_ID Subsidy_Info_Source $ 40 
Subsidy_Info_Source_Date 8
Program $ 32
Compliance_End_Date Previous_Affordability_end 8
Agency $ 80 Date_Affordability_Ended 8;

  set Pipeline_w_id;

  retain
Affordability_End . 
rent_to_fmr_description ""
Subsidy_Info_Source_ID "" 
Subsidy_Info_Source "DC/AFFPIPELINE" 
Subsidy_Info_Source_Date '01jul2022'd
Compliance_End_Date .
Previous_Affordability_end .
Date_Affordability_Ended .;

  Units_tot = total_units;
 
  ** Use project or loan closing date as subsidy start date. 
  ** If closing date missing, use one year after selection date.
  ** If selection date missing, use two years after end of FY of application.
  *****************************************************************************;

  select ( upcase( Proj_or_Act_Loan_Closing_Date ) );
    when ( "2022 4Q" ) Current_Affordability_Start = '31dec2022'd;
	when ( "2023 1Q" ) Current_Affordability_Start = '31mar2023'd;
	when ( "UNKNOWN", "" ) Current_Affordability_Start = intnx( 'year', input( selection_date, anydtdte21. ), 1, 'same' );
	otherwise Current_Affordability_Start = input( Proj_or_Act_Loan_Closing_Date, anydtdte12. );
  end;

  if missing( Current_Affordability_Start ) and not( missing( application_fiscal_year ) ) then
    Current_Affordability_Start = mdy( 9, 30, application_fiscal_year + 1 + 2 );

  ** Output subsidy records for these subsidies
	DC-FRPP - DC First Right Purchase Program [NONE IN FILE]
DC-HPF - DC Housing Preservation Fund
DC-LRSP - DC Local Rent Supplement Program
DC-SAFI - DC Site Acquisition Funding Initiative
DC-HPTF - DC Housing Production Trust Fund
	LIHTC subsidy start after 2020 ONLY.
  **;

  if hpf_loan_amount ~= "" then do;
    Program = "DC-HPF";
	Units_Assist = affordable_units;
	Agency = "DC Dept of Housing and Community Development";
    output;
  end;

  if LRSP_Contract_Amount ~= "" then do;
    Program = "DC-LRSP";
	if lrsp_30_percent_units > 0 then Units_Assist = lrsp_30_percent_units;
	else Units_Assist = affordable_units;
	Agency = "DC Housing Authority";
    output;
  end;
	
  if safi_loan_amount ~= "" then do;
    Program = "DC-SAFI";
	Units_Assist = affordable_units;
	Agency = "DC Dept of Housing and Community Development";
    output;
  end;
	
  if hptf_amount not in ( "", "0" ) then do;
    Program = "DC-HPTF";
	Units_Assist = affordable_units;
	Agency = "DC Dept of Housing and Community Development";
    output;
  end;

  if lihtc_annual_allocation ~= "" and year( Current_Affordability_Start ) > 2020 then do;

    if indexw( lihtc_type, '4%' ) and indexw( lihtc_type, '9%' ) then Program = "LIHTC/4+9PCT";
	else if indexw( lihtc_type, '4%' ) then Program = "LIHTC/4PCT";
	else if indexw( lihtc_type, '9%' ) then Program = "LIHTC/9PCT"; 
	else Program = "LIHTC/UNKWN";

    Units_Assist = affordable_units;
	Agency = "DC Dept of Housing and Community Development; DC Housing Finance Agency";

    output;

  end;

  format Subsidy_Info_Source_Date Current_Affordability_Start mmddyy10.;

  keep 
ID Units_tot Units_Assist Current_Affordability_Start
Affordability_End rent_to_fmr_description
Subsidy_Info_Source_ID Subsidy_Info_Source
Subsidy_Info_Source_Date Program Compliance_End_Date
Previous_Affordability_end Agency Date_Affordability_Ended;

run;


** Need to create one unique NLIHC_ID per ID **;
** Preferably, an active project STATUS='A' **;

proc sql noprint;
  create table Matching_project_list_status as
  select id, coalesce( nlihc_id_cat, nlihc_id ) as nlihc_id_cat, status from Matching_project_list left join Prescat.Project
  on nlihc_id_cat = nlihc_id
  where not( missing( id ) )
  order by id, status, nlihc_id_cat;
  quit;
  
data Matching_project_list_nodup;

  set Matching_project_list_status;
  by id;
  
  if first.id;
  
run;

%Data_to_format(
  FmtLib=work,
  FmtName=id_to_nlihc_id,
  Desc=,
  Data=Matching_project_list_nodup,
  Value=id,
  Label=nlihc_id_cat,
  OtherLabel="",
  Print=N,
  Contents=N
  )


** Separate projects into new and existing **;

data 
  New_projects_new (drop=nlihc_id)
  New_projects_exist (drop=id);
  
  length nlihc_id $ 16;

  set New_projects;
  
  nlihc_id = put( id, id_to_nlihc_id. );
  
  if nlihc_id = "" then output New_projects_new;
  else output New_projects_exist;
  
run;

%File_info( data=New_projects_new, contents=N, stats= )
%File_info( data=New_projects_exist, contents=N, stats= )


** Separate subsidies into new and existing **;

data 
  New_subsidy_new (drop=nlihc_id)
  New_subsidy_exist (drop=id);
  
  length nlihc_id $ 16;

  set Subsidy;
  
  nlihc_id = put( id, id_to_nlihc_id. );
  
  if nlihc_id = "" then output New_subsidy_new;
  else output New_subsidy_exist;
  
run;

%File_info( data=New_subsidy_new, contents=N, freqvars=program )
%File_info( data=New_subsidy_exist, contents=N, freqvars=program )


** Create project & subsidy CSV files for issue 303 (new projects) **;

filename fexport "\\sas1\DCData\Libraries\PresCat\Raw\AddNew\New_projects_issue_303_rev.csv" lrecl=2000;

proc export data=New_projects_new
    outfile=fexport
    dbms=csv replace;

run;

filename fexport clear;

filename fexport "\\sas1\DCData\Libraries\PresCat\Raw\AddNew\New_projects_issue_303_rev_subsidy.csv" lrecl=2000;

proc export data=New_subsidy_new
    outfile=fexport
    dbms=csv replace;

run;

filename fexport clear;


** Create subsidy CSV file for issue 416 (existing projects) **;

filename fexport "\\sas1\DCData\Libraries\PresCat\Raw\416_pipeline_subsidies.csv" lrecl=2000;

proc export data=New_subsidy_exist
    outfile=fexport
    dbms=csv replace;

run;

filename fexport clear;


** 


run;
