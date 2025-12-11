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
  Label=trim(proj_name) || ' - ' || left(scan( proj_addre, 1, ';' )),
  OtherLabel='** Unidentified project **',
  DefaultLen=.,
  MaxLen=.,
  MinLen=.,
  Print=N,
  Contents=N
  )

** Create report **;

data Real_property_rpt;

  merge
    PresCat.Real_property
      (in=in1)
    Prescat.Project_category_view 
      (keep=nlihc_id proj_name category_code);
  by nlihc_id;
  
  if in1 and category_code ~= '6';
  
  length rpt_line $ 400;
  
  rpt_line = catx( ' - ', put( nlihc_id, $nlihcid_proj. ), put( rp_date, mmddyy10. ), rp_desc );
  
run;

proc sort data=Real_property_rpt nodupkey;
  by nlihc_id rp_date rp_desc;
run;

%let rpt_suffix = %sysfunc( putn( %sysfunc( today() ), yymmddn8. ) );

%fdate()

options LeftMargin=.5in RightMargin=.5in TopMargin=.5in BottomMargin=.5in;

ods tagsets.excelxp file="&_dcdata_default_path\PresCat\Prog\Reports\Real_property_rpt_&rpt_suffix..xls" 
  style=Normal 
  options(sheet_interval='Proc' orientation='landscape'
          absolute_column_width='160' row_height_fudge='16'
          pages_fitwidth='1' pages_fitheight='10'
          embedded_titles='yes' embedded_footnotes='yes' embed_titles_once='yes' );

ods listing close;

ods tagsets.excelxp options( sheet_name="RCASD" );

proc report data=Real_property_rpt nowd
      style(header)=[fontsize=2 font_weight=bold textalign=left]
      style(column)=[fontsize=2 textalign=left];
  where rp_type = 'DHCD/RCASD' and rp_date >= ( today() - 90 );
  column rpt_line;
  define rpt_line / "Event" display;
  title1 "DC Preservation Catalog: Real Property Events Report: RCASD Notices: Previous Three Months";
  footnote1 height=9pt "Prepared by Urban-Greater DC (greaterdc.urban.org), &fdate..";
  footnote2 height=9pt "Sources: OTR=Office of Tax and Revenue, RCASD=DHCD Rental Conversion and Sale Division, ROD=Recorder of Deeds.";
run;

ods tagsets.excelxp options( sheet_name="Other" );

proc report data=Real_property_rpt nowd
      style(header)=[fontsize=2 font_weight=bold textalign=left]
      style(column)=[fontsize=2 textalign=left];
  where rp_type ~= 'DHCD/RCASD' and rp_date >= ( today() - 365 );
  column rpt_line;
  define rpt_line / "Event" display;
  title1 "DC Preservation Catalog: Real Property Events Report: Other Events: Previous Year";
  footnote1 height=9pt "Prepared by Urban-Greater DC (greaterdc.urban.org), &fdate..";
  footnote2 height=9pt "Sources: OTR=Office of Tax and Revenue, RCASD=DHCD Rental Conversion and Sale Division, ROD=Recorder of Deeds.";
run;

ods tagsets.excelxp close;
ods listing;

run;

