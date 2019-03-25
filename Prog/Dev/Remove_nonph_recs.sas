/**************************************************************************
 Program:  Remove_nonph_recs.sas
 Library:  PresCat
 Project:  Urban-Greater DC
 Author:   P. Tatian
 Created:  03/25/19
 Version:  SAS 9.4
 Environment:  Local Windows session (desktop)
 GitHub issue:  194
 
 Description:  Remove or recode non-public housing records from Catalog.

 Modifications:
**************************************************************************/

%include "L:\SAS\Inc\StdLocal.sas";

** Define libraries **;
%DCData_lib( PresCat )

** Moderate rehab properties miscoded as public housing;

%let mod_rehab = 
"NL000010"
"NL000171"
"NL000362"
"NL000390"
"NL000393"
"NL000408"
;

** 
Properties not owned by DCHA but in HUD APSH public housing list.
Might have been PH at some point.
NEED MORE INFO.
**;

%let inactive_ph = 
"NL000133"  /** Gibson Plaza **/
"NL000400"  /** Willis Paul Greene Manor (Marshall Heights Community Dev) **/
"NL000221"  /** Oxford Manor **/
;

** Other properties miscoded as public housing;

%let delete_ph =
"NL000066"
"NL000079"
"NL000106"
"NL000115"
"NL000148"
"NL000204"
"NL000266"
"NL000270"
"NL000276"
"NL000312"
"NL000329"
"NL000337"
"NL000349"
"NL000389"
"NL000391"
"NL000392"
"NL000395"
"NL000396"
"NL000397"
"NL000398"
"NL000399"
"NL000401"
"NL000402"
"NL000403"
"NL000404"
"NL000405"
"NL000407"
"NL000409"
"NL000410"
"NL000411"
"NL000412"
"NL000413"
"NL000415"
"NL001007"
"NL001008"
"NL001009"
;

%let Update_dtm = %sysfunc( datetime() );

title2 'Projects incorrectly listed as public housing';

proc print data=PresCat.Project_category_view;
  where nlihc_id in ( &delete_ph );
  id nlihc_id;
  var status proj_name proj_addre;
run;

proc print data=PresCat.Subsidy;
  where nlihc_id in ( &delete_ph &mod_rehab &inactive_ph );
  by nlihc_id;
  id nlihc_id subsidy_id;
  var program subsidy_active;
run;

** Remove non PH records **;

data Subsidy;

  set PresCat.Subsidy;
  by nlihc_id subsidy_id;
  
  where program ~= 'PUBHSNG' or nlihc_id not in ( &delete_ph ) or not subsidy_active;
  
  retain subsidy_id_new;
  
  if first.nlihc_id then do;
    subsidy_id_new = 1;
  end;
  else do;
    subsidy_id_new + 1;
  end;
  
  if nlihc_id in ( &mod_rehab ) then do;
    if program = 'PUBHSNG' then do;
      program = 'S8-MR';
      portfolio = 'PB8';
      subsidy_info_source = 'DHCA Document';
      subsidy_info_source_date = '12Apr2016'd;
      update_dtm = &update_dtm;
    end;
  end;    
  
  if nlihc_id in ( &inactive_ph ) then do;
    if program = 'PUBHSNG' then do;
      subsidy_active = 0;
      update_dtm = &update_dtm;
    end;
  end;    
  
  drop subsidy_id;
  
  rename subsidy_id_new=Subsidy_id;
  
  label Subsidy_id_new = "Preservation Catalog subsidy ID";

run;

title2 'With public housing subsidy removed or recoded';

proc print data=Subsidy;
  where nlihc_id in ( &delete_ph &mod_rehab &inactive_ph );
  by nlihc_id;
  id nlihc_id subsidy_id;
  var program subsidy_active;
run;

proc means data=Subsidy n sum;
  where subsidy_active and program = 'PUBHSNG';
  var units_assist;
run;

proc compare base=PresCat.Subsidy compare=Subsidy listall maxprint=(40,32000);
  id Nlihc_id Subsidy_id;
run;

title2;

** Update Project data set **;

%Create_project_subsidy_update( data=Subsidy, out=Project_subsidy_update, project_file=PresCat.Project )

data Project;

  update 
    PresCat.Project
    Project_subsidy_update
    updatemode=nomissingcheck;
  by nlihc_id;
  
run;

proc compare base=PresCat.Project compare=Project listall maxprint=(40,32000);
  id Nlihc_id;
run;

** Finalize data sets **;

%let revisions = Remove or recode non-public housing records.;

%Finalize_data_set( 
  /** Finalize data set parameters **/
  data=Project,
  out=Project,
  outlib=PresCat,
  label="Preservation Catalog, Projects",
  sortby=nlihc_id,
  archive=Y,
  /** Metadata parameters **/
  restrictions=None,
  revisions=%str(&revisions),
  /** File info parameters **/
  contents=N,
  printobs=0,
  freqvars=,
  stats=
)

%Finalize_data_set( 
  /** Finalize data set parameters **/
  data=Subsidy,
  out=Subsidy,
  outlib=PresCat,
  label="Preservation Catalog, Project subsidies",
  sortby=nlihc_id,
  archive=Y,
  /** Metadata parameters **/
  restrictions=None,
  revisions=%str(&revisions),
  /** File info parameters **/
  contents=N,
  printobs=0,
  freqvars=,
  stats=
)

%Dc_update_meta_file(
  ds_lib=PresCat,
  ds_name=Project_category_view,
  creator_process=Remove_nonph_recs.sas,
  restrictions=None,
  revisions=%str(&revisions)
)

** Updated list of public housing **;

%Data_to_format(
  FmtLib=work,
  FmtName=$nlihcid_to_projname,
  Desc=,
  Data=PresCat.Project_category_view,
  Value=nlihc_id,
  Label=trim( nlihc_id ) || '  ' || proj_name,
  OtherLabel=,
  DefaultLen=.,
  MaxLen=.,
  MinLen=.,
  Print=N,
  Contents=N
  )

ods listing close;
ods rtf file="&_dcdata_default_path\PresCat\Prog\Dev\Remove_nonph_recs.rtf" style=Styles.Rtf_arial_9pt;

%fdate()

options nodate nonumber;

title2 "Updated public housing list in DC Preservation Catalog";

footnote1 height=9pt "Prepared by Urban-Greater DC (greaterdc.urban.org), &fdate..";
footnote2 height=9pt j=r '{Page}\~{\field{\*\fldinst{\pard\b\i0\chcbpat8\qc\f1\fs19\cf1{PAGE }\cf0\chcbpat0}}}';

proc print data=Subsidy n label;
  where subsidy_active and program = 'PUBHSNG';
  id nlihc_id;
  var units_assist;
  sum units_assist;
  format nlihc_id $nlihcid_to_projname. units_assist comma10.;
run;

** Projects now without a subsidy **;

title2 "Projects removed from public housing list with no subsidies in Catalog";

proc print data=Project label;
  where nlihc_id in ( &delete_ph ) and not subsidized;
  id nlihc_id;
  var proj_addre proj_units_tot;
  format nlihc_id $nlihcid_to_projname. proj_units_tot comma10.;
run;

title2;

footnote1;

ods rtf close;
ods listing;

