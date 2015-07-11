/**************************************************************************
 Program:  Export_table_structure.sas
 Library:  PresCat
 Project:  NeighborhoodInfo DC
 Author:   P. Tatian
 Created:  11/22/14
 Version:  SAS 9.2
 Environment:  Windows
 
 Description: Export Preservation Catalog data set structures to Excel
 workbook.

 Modifications:
**************************************************************************/

%include "L:\SAS\Inc\StdLocal.sas";

** Define libraries **;
%DCData_lib( PresCat, local=n )

proc format;
  value vtype
    1 = 'Num'
    2 = 'Char';

/** Macro Export - Start Definition **/

%macro Export( libname=PresCat, memname= );

proc contents data=&libname..&memname noprint 
  out=&memname._str (keep=libname memname name type length varnum label format);
run;

proc sort data=&memname._str;
  by varnum;

data &memname._str;

  retain libname memname varnum name type length format;
  
  set &memname._str;
  
run;

ods tagsets.excelxp options( sheet_name="&libname..&memname" );

proc print data=&memname._str label style(data)=[fontsize=11pt verticalalign=middle];
  id varnum;
  var name type length format label;
  format type vtype.;
run;

%mend Export;

/** End Macro Definition **/

ods tagsets.excelxp file="&_dcdata_r_path\PresCat\Prog\Export_table_structure.xls" style=barrettsBlue
  options(sheet_interval='proc' );

%Export( memname=Project )
%Export( memname=Subsidy )
%Export( memname=Reac_score )
%Export( memname=Parcel )
%Export( memname=Real_property )
%Export( memname=Update_history )

ods tagsets.excelxp close;

