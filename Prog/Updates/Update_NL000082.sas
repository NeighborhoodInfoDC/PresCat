/**************************************************************************
 Program:  Update_NL000082.sas
 Library:  PresCat
 Project:  Urban-Greater DC
 Author:   P. Tatian
 Created:  08/06/2026
 Version:  SAS 9.4
 Environment:  Remote session (SAS1)
 GitHub issue:  
 
 Description:  Change status of NL000082 to inactive. Subsidies moved to
 NL001344.

 Modifications:
**************************************************************************/

%include "F:\DCDATA\SAS\Inc\StdRemote.sas";

** Define libraries **;
%DCData_lib( PresCat )
%DCData_lib( RealProp )

%let revisions = Set NL000082 to inactive.;

** Project **;

data Project;

  set PresCat.Project;
  
  if nlihc_id = 'NL000082' then do;
    category_code = '7';
    cat_at_risk = 0;
    cat_expiring = 0;
    cat_failing_insp = 0;
    cat_lost = 0;
    cat_more_info = 0;
    cat_replaced = 1;
    status = 'I';
    subsidized = 0;
    update_dtm = datetime();
  end;
  
run;

proc compare base=PresCat.Project compare=Project listall maxprint=(40,32000);
  id nlihc_id;
run;

%Finalize_data_set( 
  /** Finalize data set parameters **/
  data=Project,
  out=Project,
  outlib=PresCat,
  label="Preservation Catalog, Projects",
  sortby=nlihc_id,
  /** Metadata parameters **/
  revisions=%str(&revisions),
  /** File info parameters **/
  contents=N,
  printobs=0,
  freqvars=,
  stats=
)


** Project_category **;

data Project_category;

  set PresCat.Project_category;
  
  if nlihc_id = 'NL000082' then do;
    category_code = '7';
    cat_at_risk = 0;
    cat_lost = 0;
    cat_more_info = 0;
    cat_replaced = 1;
  end;
  
run;

proc compare base=PresCat.Project_category compare=Project_category listall maxprint=(40,32000);
  id nlihc_id;
run;

%Finalize_data_set( 
  /** Finalize data set parameters **/
  data=Project_category,
  out=Project_category,
  outlib=PresCat,
  label="Preservation Catalog, Project category",
  sortby=nlihc_id,
  /** Metadata parameters **/
  revisions=%str(&revisions),
  /** File info parameters **/
  contents=N,
  printobs=0,
  freqvars=,
  stats=
)


** Subsidy **;

data Subsidy;

  set PresCat.Subsidy;
  
  if nlihc_id = 'NL000082' then do;
    poa_end_actual = today();
    subsidy_active = 0;
    update_dtm = datetime();
  end;
  
run;

proc compare base=PresCat.Subsidy compare=Subsidy listall maxprint=(40,32000);
  id nlihc_id subsidy_id;
run;

%Finalize_data_set( 
  /** Finalize data set parameters **/
  data=Subsidy,
  out=Subsidy,
  outlib=PresCat,
  label="Preservation Catalog, Project subsidies",
  sortby=nlihc_id subsidy_id,
  /** Metadata parameters **/
  revisions=%str(&revisions),
  /** File info parameters **/
  contents=N,
  printobs=0,
  freqvars=,
  stats=
)

