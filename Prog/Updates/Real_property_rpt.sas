/**************************************************************************
 Program:  Real_property_rpt.sas
 Library:  PresCat
 Project:  NeighborhoodInfo DC
 Author:   P. Tatian
 Created:  11/10/16
 Version:  SAS 9.2
 Environment:  Local Windows session (desktop)
 
 Description:  Real property events report

 Modifications:
**************************************************************************/

%include "L:\SAS\Inc\StdLocal.sas";

** Define libraries **;
%DCData_lib( PresCat )

%let Start_date = today()-60;  %** Look for events two months prior **;

** Create report **;

data Real_property_rpt;

  merge
    PresCat.Real_property
      (where=(rp_date>=(&Start_date)) in=in1)
    Prescat.Project_category_view 
      (keep=nlihc_id proj_name category_code);
  by nlihc_id;
  
  if in1;
  
  rpt_id = nlihc_id || ' / ' || proj_name;
  
run;

proc sort data=Real_property_rpt;
  by category_code rpt_id;
run;

%let rpt_suffix = %sysfunc( putn( %sysfunc( today() ), yymmddn8. ) );

%fdate()

ods tagsets.excelxp file="&_dcdata_default_path\PresCat\Prog\Updates\Real_property_rpt_&rpt_suffix..xls" 
  style=Normal 
  options(sheet_interval='None' sheet_name="Real_property" orientation='landscape'
          absolute_column_width='40,12,80' row_height_fudge='16' );
ods listing close;

proc report data=Real_property_rpt nowd
      style(header)=[fontsize=2 font_weight=bold textalign=left]
      style(column)=[fontsize=2 textalign=left];
  by Category_code;
  column rpt_id rp_date rp_desc;
  define rpt_id / "Project" order;
  define rp_date / display;
  define rp_desc / "Description" display;
  break before rpt_id /;
  label category_code = 'Category';
  title1;
  footnote1 height=9pt "Prepared by NeighborhoodInfo DC (www.NeighborhoodInfoDC.org), &fdate..";
run;

ods tagsets.excelxp close;
ods listing;

run;

