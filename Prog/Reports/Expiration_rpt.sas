/**************************************************************************
 Program:  Expiration_rpt.sas
 Library:  PresCat
 Project:  Urban-Greater DC
 Author:   P. Tatian
 Created:  6/3/2018
 Version:  SAS 9.4
 Environment:  Local Windows session (desktop)
 
 Description:  Subsidy expiration report

 Modifications:
**************************************************************************/

%include "\\sas1\DCdata\SAS\Inc\StdLocal.sas";

** Define libraries **;
%DCData_lib( PresCat )


** Create $nlihcid_proj. format to add project name and addresses to report output **;

%Data_to_format(
  FmtLib=work,
  FmtName=$nlihcid_proj,
  Desc=,
  Data=PresCat.Project_category_view,
  Value=nlihc_id,
  Label=trim(proj_name) || ' - ' || left(proj_addre),
  OtherLabel='** Unidentified project **',
  DefaultLen=.,
  MaxLen=.,
  MinLen=.,
  Print=N,
  Contents=N
  )


** Create report **;

data Expiration_rpt;

  merge
    PresCat.Subsidy (in=in1)
    Prescat.Project_category_view 
      (keep=nlihc_id proj_name category_code);
  by nlihc_id;
  
  if in1 and category_code ~= '6';
  
  if program = 'TEBOND' then delete;
  
  length rpt_id $ 120;
  
  rpt_id = left( put( nlihc_id, $nlihcid_proj. ) );
  
run;
proc sort data=Expiration_rpt;
  by category_code poa_end;
run;


%let rpt_suffix = %sysfunc( putn( %sysfunc( today() ), yymmddn8. ) );

%fdate()

options LeftMargin=.5in RightMargin=.5in TopMargin=.5in BottomMargin=.5in;

ods tagsets.excelxp file="&_dcdata_default_path\PresCat\Prog\Reports\Expiration_rpt_&rpt_suffix..xls" 
  style=Normal 
  options(sheet_interval='Proc' orientation='landscape'
          absolute_column_width='12,12,60,40' row_height_fudge='16' 
          pages_fitwidth='1' pages_fitheight='10'
          embedded_titles='yes' embedded_footnotes='yes' embed_titles_once='yes' );

ods listing close;

footnote1 height=9pt "Prepared by Urban-Greater DC (GreaterDC.urban.org), &fdate..";
footnote2 height=9pt "Tax exempt bonds excluded.";

ods tagsets.excelxp options(sheet_name="Expiration 11 mos");

title1 "DC Preservation Catalog: Project-Based Subsidies Expiring Within 6 - 11 Months";

proc report data=Expiration_rpt nowd
      style(header)=[fontsize=2 font_weight=bold textalign=left]
      style(column)=[fontsize=2 textalign=left];
  where (intnx( 'month', today(), 6, 'same' )) <= poa_end <= (intnx( 'month', today(), 11, 'same' )) and 
    subsidy_active and portfolio ~= "LIHTC";
  column nlihc_id poa_end rpt_id program;
  define nlihc_id / "Catalog ID" display;
  define rpt_id / "Project" display;
  define poa_end / display;
  define program / display;
  label category_code = 'Category';
run;

ods tagsets.excelxp options(sheet_name="Expiration 90 days");

title1 "DC Preservation Catalog: Project-Based Subsidies Expiring Within 90 Days";

proc report data=Expiration_rpt nowd
      style(header)=[fontsize=2 font_weight=bold textalign=left]
      style(column)=[fontsize=2 textalign=left];
  where (intnx( 'day', today(), 0, 'same' )) <= poa_end <= (intnx( 'day', today(), 90, 'same' )) and 
    subsidy_active and portfolio ~= "LIHTC";
  column nlihc_id poa_end rpt_id program;
  define nlihc_id / "Catalog ID" display;
  define rpt_id / "Project" display;
  define poa_end / display;
  define program / display;
  label category_code = 'Category';
run;

ods tagsets.excelxp options(sheet_name="LIHTC compliance");

title1 "DC Preservation Catalog: LIHTC Compliance Period Ending Within 2 years";

proc report data=Expiration_rpt nowd
      style(header)=[fontsize=2 font_weight=bold textalign=left]
      style(column)=[fontsize=2 textalign=left];
  where (intnx( 'year', today(), 0, 'same' )) <= compl_end <= (intnx( 'year', today(), 2, 'same' )) and 
    subsidy_active and portfolio = "LIHTC";
  column nlihc_id compl_end rpt_id program;
  define nlihc_id / "Catalog ID" display;
  define rpt_id / "Project" display;
  define compl_end / display;
  define program / display;
  label category_code = 'Category';
run;

ods tagsets.excelxp options(sheet_name="LIHTC extended use");

title1 "DC Preservation Catalog: LIHTC Extended Use Period Ending Within 2 years";
footnote2 height=9pt "Tax exempt bonds excluded. LIHTC end date may be approximate.";

proc report data=Expiration_rpt nowd
      style(header)=[fontsize=2 font_weight=bold textalign=left]
      style(column)=[fontsize=2 textalign=left];
  where (intnx( 'year', today(), 0, 'same' )) <= poa_end <= (intnx( 'year', today(), 2, 'same' )) and 
    subsidy_active and portfolio = "LIHTC";
  column nlihc_id poa_end rpt_id program;
  define nlihc_id / "Catalog ID" display;
  define rpt_id / "Project" display;
  define poa_end / display;
  define program / display;
  label category_code = 'Category';
run;

ods tagsets.excelxp close;
ods listing;

run;

