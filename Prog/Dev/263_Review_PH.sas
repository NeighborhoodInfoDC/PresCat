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

%let Update_dtm = %sysfunc( datetime() );

%let revisions = ;


** Review current list of public housing projects **;

%Data_to_format(
  FmtLib=Work,
  FmtName=$nlihcid_to_projname,
  Desc=,
  Data=PresCat.Project_category,
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

ods tagsets.excelxp file="&_dcdata_default_path\PresCat\Prog\Dev\263_Review_PH.xls" style=Normal options(sheet_interval='Proc' );
ods listing close;

%fdate()

options nodate nonumber;

footnote1 height=9pt "Prepared by Urban-Greater DC (greaterdc.urban.org), &fdate..";
footnote2 height=9pt j=r '{Page}\~{\field{\*\fldinst{\pard\b\i0\chcbpat8\qc\f1\fs19\cf1{PAGE }\cf0\chcbpat0}}}';

ods tagsets.excelxp options( sheet_name="ACTIVE" );

title2 '** Updated Catalog list of ACTIVE public housing **';

proc print data=PresCat.Subsidy n label;
  where subsidy_active and program = 'PUBHSNG';
  id nlihc_id;
  var units_assist;
  sum units_assist;
  format nlihc_id $nlihcid_to_projname. units_assist comma10.;
run;

ods tagsets.excelxp options( sheet_name="INACTIVE" );

title2 '** Updated Catalog list of INACTIVE public housing **';

proc print data=PresCat.Subsidy n label;
  where not( subsidy_active ) and program = 'PUBHSNG';
  id nlihc_id;
  var units_assist;
  sum units_assist;
  format nlihc_id $nlihcid_to_projname. units_assist comma10.;
run;

ods tagsets.excelxp close;

title2;
footnote1;

