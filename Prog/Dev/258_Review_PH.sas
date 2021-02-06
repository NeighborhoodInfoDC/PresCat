/**************************************************************************
 Program:  258_Review_PH.sas
 Library:  PresCat
 Project:  Urban-Greater DC
 Author:   P. Tatian
 Created:  01/31/21
 Version:  SAS 9.4
 Environment:  Local Windows session (desktop)
 GitHub issue:  258
 
 Description:  Review public housing projects in Catalog.

 Modifications:
**************************************************************************/

%include "\\sas1\DCdata\SAS\Inc\StdLocal.sas";

** Define libraries **;
%DCData_lib( PresCat )

%let Update_dtm = %sysfunc( datetime() );

%let revisions = Correct PH subsidy record for NL000301/Edgewood Commons III.;


** Correct PH subsidy record for NL000301/Edgewood Commons III
** This property was acquired by Enterprise Community Development from DCHA in 2001
** See https://www.enterprisecommunity.org/financing-and-development/development-and-consulting/edgewood-commons-iii
** Unit count went from 292 to 200. 
**;

data Subsidy;

  set PresCat.Subsidy;
  
  if nlihc_id = 'NL000301' and program = 'PUBHSNG' then do;
    subsidy_active = 0;
    units_assist = 292;
    update_dtm = &Update_dtm;
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
  archive=Y,
  /** Metadata parameters **/
  revisions=%str(&revisions),
  /** File info parameters **/
  contents=N,
  printobs=0,
  freqvars=,
  stats=
)


data Project;

  set PresCat.Project;
  
  if nlihc_id = 'NL000301' then do;
    proj_name = 'Edgewood Commons III';
    update_dtm = &Update_dtm;
  end;
  
run;

%Finalize_data_set( 
  /** Finalize data set parameters **/
  data=Project,
  out=Project,
  outlib=PresCat,
  label="Preservation Catalog, Projects",
  sortby=nlihc_id,
  archive=Y,
  /** Metadata parameters **/
  revisions=%str(&revisions),
  /** File info parameters **/
  contents=N,
  printobs=0,
  freqvars=,
  stats=
)


data Project_category;

  set PresCat.Project_category;
  
  if nlihc_id = 'NL000301' then do;
    proj_name = 'Edgewood Commons III';
    update_dtm = &Update_dtm;
  end;
  
run;

%Finalize_data_set( 
  /** Finalize data set parameters **/
  data=Project_category,
  out=Project_category,
  outlib=PresCat,
  label="Preservation Catalog, Project category",
  sortby=nlihc_id,
  archive=Y,
  /** Metadata parameters **/
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
  creator_process=258_Review_PH.sas,
  restrictions=None,
  revisions=%str(&revisions)
)


** Review current list of public housing projects **;

%Data_to_format(
  FmtLib=work,
  FmtName=$nlihcid_to_projname,
  Desc=,
  Data=Project_category,
  Value=nlihc_id,
  Label=trim( nlihc_id ) || '  ' || trim( proj_name ),
  /**Label=trim( nlihc_id ) || '  ' || trim( proj_name ) || '  ' || trim( proj_addre ),**/
  OtherLabel=,
  DefaultLen=.,
  MaxLen=.,
  MinLen=.,
  Print=N,
  Contents=N
  )

ods rtf file="&_dcdata_default_path\PresCat\Prog\Dev\258_Review_PH.rtf" style=Styles.Rtf_arial_9pt /*bodytitle*/;
ods listing close;

%fdate()

options nodate nonumber;

footnote1 height=9pt "Prepared by Urban-Greater DC (greaterdc.urban.org), &fdate..";
footnote2 height=9pt j=r '{Page}\~{\field{\*\fldinst{\pard\b\i0\chcbpat8\qc\f1\fs19\cf1{PAGE }\cf0\chcbpat0}}}';

ods tagsets.excelxp file="&_dcdata_default_path\PresCat\Prog\Dev\258_Review_PH.xls" style=Normal options(sheet_interval='Proc' );

ods tagsets.excelxp options( sheet_name="ACTIVE" );

title2 '** Updated Catalog list of ACTIVE public housing **';

proc print data=Subsidy n label;
  where subsidy_active and program = 'PUBHSNG';
  id nlihc_id;
  var units_assist;
  sum units_assist;
  format nlihc_id $nlihcid_to_projname. units_assist comma10.;
run;

ods tagsets.excelxp options( sheet_name="INACTIVE" );

title2 '** Updated Catalog list of INACTIVE public housing **';

proc print data=Subsidy n label;
  where not( subsidy_active ) and program = 'PUBHSNG';
  id nlihc_id;
  var units_assist;
  sum units_assist;
  format nlihc_id $nlihcid_to_projname. units_assist comma10.;
run;

ods tagsets.excelxp close;

title2;

title2 '** Review of subsidies for projects with public housing records **';

proc sort data=Subsidy (where=(program='PUBHSNG')) out=Subsidy_PH nodupkey;
  by nlihc_id;
run;

%Data_to_format(
  FmtLib=work,
  FmtName=$PubHsgRec,
  Desc=,
  Data=Subsidy_PH,
  Value=nlihc_id,
  Label='1',
  OtherLabel=' ',
  Print=N,
  Contents=N
  )

proc print data=Subsidy label;
  where put( nlihc_id, $PubHsgRec. ) = '1';
  by nlihc_id;
  id subsidy_id;
  var subsidy_active program units_assist update_dtm;
  format nlihc_id $nlihcid_to_projname. units_assist comma10.;
  label subsidy_id = "Subsidy ID";
run;

title2;

ods rtf close;
ods listing;

footnote1;

