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


** Get start dates for subsidy data. Match based on project names. **;

%Data_to_format(
  FmtLib=work,
  FmtName=$proj_name_to_id,
  Data=New_projects,
  Value=Proj_name,
  Label=id,
  OtherLabel="",
  Print=N,
  Contents=N
  )


data Subsidy_start_date;

  set Prescat.Dc_pipeline_2022_07;
  
  if project_name = "Ivy City/ Trinidad" then project_name = trim( project_name ) || " - " || address;
  
  id = input( put( project_name, $proj_name_to_id. ), 12. );
  
  if missing( id ) then do;
    %warn_put( msg="Project not found. " project_name= address_for_mar= address= )
  end;
  
run;

ENDSAS;


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

  set New_subsidy;
  
  nlihc_id = put( id, id_to_nlihc_id. );
  
  if nlihc_id = "" then output New_subsidy_new;
  else output New_subsidy_exist;
  
run;

%File_info( data=New_subsidy_new, contents=N )
%File_info( data=New_subsidy_exist, contents=N )



run;
