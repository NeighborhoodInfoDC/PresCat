/**************************************************************************
 Program:  263_Review_PH.sas
 Library:  PresCat
 Project:  Urban-Greater DC
 Author:   P. Tatian
 Created:  02/13/21
 Version:  SAS 9.4
 Environment:  Local Windows session (desktop)
 GitHub issue:  263
 
 Description:  Review public housing projects in Catalog.

 Modifications:
**************************************************************************/

%include "\\sas1\DCdata\SAS\Inc\StdLocal.sas";

** Define libraries **;
%DCData_lib( PresCat )
%DCData_lib( RealProp )

%let Update_dtm = %sysfunc( datetime() );

%let revisions = ;

  
** Compile data on public housing **;

%Dup_check(
  data=PresCat.Subsidy (where=(program = 'PUBHSNG')),
  by=nlihc_id,
  id=subsidy_id subsidy_active subsidy_info_source subsidy_info_source_date subsidy_info_source_id,
  listdups=Y
)

proc summary data=PresCat.Subsidy;
  where program = 'PUBHSNG';
  var units_assist subsidy_active update_dtm;
  by nlihc_id program;
  output out=PH_Subsidy max(subsidy_active update_dtm)= sum(units_assist)=;
run;

data PH_Subsidy_Proj;

  merge 
    PH_Subsidy (in=in_subsidy)
    PresCat.Project_category_view 
      (keep=nlihc_id ward2012 bldg_count category_code proj_addre proj_name proj_owner_type proj_units_tot status);
  by nlihc_id;
  
  if in_subsidy;
  
run;

ods tagsets.excelxp file="&_dcdata_default_path\PresCat\Prog\Dev\263_Review_PH.xls" style=Normal options(sheet_interval='Proc' );
ods listing close;

%fdate()

options nodate nonumber;

footnote1 height=9pt "Prepared by Urban-Greater DC (greaterdc.urban.org), &fdate..";
footnote2 height=9pt j=r '{Page}\~{\field{\*\fldinst{\pard\b\i0\chcbpat8\qc\f1\fs19\cf1{PAGE }\cf0\chcbpat0}}}';

ods tagsets.excelxp options( sheet_name="ACTIVE" );

title2 '** Updated Catalog list of ACTIVE public housing **';

proc print data=PH_Subsidy_Proj n label;
  where subsidy_active;
  id nlihc_id proj_name;
  var proj_addre ward2012 units_assist status category_code proj_owner_type;
  sum units_assist;
  format units_assist comma10. category_code ;
  label nlihc_id = "ID";
run;

ods tagsets.excelxp options( sheet_name="INACTIVE" );

title2 '** Updated Catalog list of INACTIVE public housing **';

proc print data=PH_Subsidy_Proj n label;
  where not( subsidy_active );
  id nlihc_id proj_name;
  var proj_addre ward2012 units_assist status category_code proj_owner_type;
  sum units_assist;
  format units_assist comma10. category_code ;
  label nlihc_id = "ID";
run;

ods tagsets.excelxp close;

title2;
footnote1;

