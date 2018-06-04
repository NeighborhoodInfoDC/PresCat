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

%include "L:\SAS\Inc\StdLocal.sas";

** Define libraries **;
%DCData_lib( PresCat )

%** Subsidies expiring within next year **;
%let Start_date = intnx( 'year', today(), -1, 'same' );  
%let End_date = intnx( 'year', today(), 1, 'same' );

** Create report **;

data Expiration_rpt;

  merge
    PresCat.Subsidy
      (where=(((&Start_date)<=poa_end<(&End_date)) and subsidy_active) in=in1)
    Prescat.Project_category_view 
      (keep=nlihc_id proj_name category_code);
  by nlihc_id;
  
  if in1 and category_code ~= '6';
  
  if program = 'TEBOND' then delete;
  
  rpt_id = trim( nlihc_id ) || ' / ' || proj_name;
  
run;

proc sort data=Expiration_rpt;
  by category_code poa_end;
run;

%let rpt_suffix = %sysfunc( putn( %sysfunc( today() ), yymmddn8. ) );

%fdate()

options LeftMargin=.5in RightMargin=.5in TopMargin=.5in BottomMargin=.5in;

ods tagsets.excelxp file="&_dcdata_default_path\PresCat\Prog\Updates\Expiration_rpt_&rpt_suffix..xls" 
  style=Normal 
  options(sheet_interval='None' sheet_name="Expiration" orientation='landscape'
          absolute_column_width='60,12,40' row_height_fudge='16' 
          pages_fitwidth='1' pages_fitheight='10'
          embedded_titles='yes' embedded_footnotes='yes' embed_titles_once='yes' );

ods listing close;

proc report data=Expiration_rpt nowd
      style(header)=[fontsize=2 font_weight=bold textalign=left]
      style(column)=[fontsize=2 textalign=left];
  by Category_code;
  column rpt_id poa_end program;
  define rpt_id / "Project" display;
  define poa_end / display;
  define program / display;
  label category_code = 'Category';
  title1 "DC Preservation Catalog: Upcoming Subsidy Expiration Report (within next year)";
  footnote1 height=9pt "Prepared by Urban-Greater DC (GreaterDC.urban.org), &fdate..";
  footnote2 height=9pt "Includes subsidies expiring within past year. Tax exempt bonds excluded.";
run;

ods tagsets.excelxp close;
ods listing;

run;

