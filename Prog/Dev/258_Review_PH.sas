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


** Review current list of public housing projects **;

%Data_to_format(
  FmtLib=work,
  FmtName=$nlihcid_to_projname,
  Desc=,
  Data=PresCat.Project_category_view,
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

title2 '** Catalog list of ACTIVE public housing **';

proc print data=PresCat.Subsidy n label;
  where subsidy_active and program = 'PUBHSNG';
  id nlihc_id;
  var units_assist;
  sum units_assist;
  format nlihc_id $nlihcid_to_projname. units_assist comma10.;
run;

ods tagsets.excelxp options( sheet_name="INACTIVE" );

title2 '** Catalog list of INACTIVE public housing **';

proc print data=PresCat.Subsidy n label;
  where not( subsidy_active ) and program = 'PUBHSNG';
  id nlihc_id;
  var units_assist;
  sum units_assist;
  format nlihc_id $nlihcid_to_projname. units_assist comma10.;
run;

ods tagsets.excelxp close;

title2;

title2 '** Specific project subsidy review **';

proc print data=PresCat.Subsidy n label;
  where nlihc_id in ( 'NL000056', 'NL000132', 'NL000133', 'NL000221', 'NL000231', 'NL000394', 'NL000400', 'NL000414', 'NL000301' );
  by nlihc_id;
  id subsidy_id;
  var subsidy_active portfolio program units_assist update_dtm;
  format nlihc_id $nlihcid_to_projname. units_assist comma10.;
  *format portfolio program ;
run;

title2;

ods rtf close;
ods listing;

footnote1;

