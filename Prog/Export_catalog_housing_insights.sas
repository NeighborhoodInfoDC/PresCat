/**************************************************************************
 Program:  Export_catalog_housing_insights.sas
 Library:  PresCat
 Project:  NeighborhoodInfo DC
 Author:   P. Tatian
 Created:  11/15/2017
 Version:  SAS 9.4
 Environment:  Local Windows session (desktop)
 
 Description:  Export all PresCat data sets to CSV files, with  
 data dictionary, for Housing Insights.

 Modifications:
**************************************************************************/

%include "L:\SAS\Inc\StdLocal.sas";

** Define libraries **;
%DCData_lib( PresCat )
%DCData_lib( RealProp )

options msglevel=n;


/** Macro Export - Start Definition **/

%macro Export( data=, out=, desc= );

  %local lib file;
  
  %if %scan( &data, 2, . ) = %then %do;
    %let lib = work;
    %let file = &data;
  %end;
  %else %do;
    %let lib = %scan( &data, 1, . );
    %let file = %scan( &data, 2, . );
  %end;

  %if &out = %then %let out = &file;
  
  %if %length( &desc ) = 0 %then %do;
    proc sql noprint;
      select memlabel into :desc from dictionary.tables
        where upcase(libname)=upcase("&lib") and upcase(memname)=upcase("&file");
      quit;
    run;
  %end;

  filename fexport "&out_folder\&out..csv" lrecl=2000;

  proc export data=&data
      outfile=fexport
      dbms=csv replace;

  run;
  
  filename fexport clear;

  proc contents data=&data out=_cnt_&out (keep=varnum name label label="&desc") noprint;

  proc sort data=_cnt_&out;
    by varnum;
  run;      
  
  %let file_list = &file_list &out;

%mend Export;

/** End Macro Definition **/


/** Macro Dictionary - Start Definition **/

%macro Dictionary( );

  %local desc;

  ** Start writing to XML workbook **;
    
  ods listing close;

  ods tagsets.excelxp file="&out_folder\Data dictionary.xls" style=Normal 
      options( sheet_interval='Proc' orientation='landscape' );

  ** Write data dictionaries for all files **;

  %local i k;

  %let i = 1;
  %let k = %scan( &file_list, &i, %str( ) );

  %do %until ( &k = );
   
    proc sql noprint;
      select memlabel into :desc from dictionary.tables
        where upcase(libname)="WORK" and upcase(memname)=upcase("_cnt_&k");
      quit;
    run;

    ods tagsets.excelxp 
        options( sheet_name="&k" 
                 embedded_titles='yes' embedded_footnotes='yes' 
                 embed_titles_once='yes' embed_footers_once='yes' );

    proc print data=_cnt_&k label;
      id varnum;
      var name label;
      label 
        varnum = 'Col #'
        name = 'Name'
        label = 'Description';
      title1 bold "Data dictionary for file: &k..csv";
      title2 bold "&desc";
      title3 height=10pt "Prepared by NeighborhoodInfo DC on %left(%qsysfunc(date(),worddate.)).";
      footnote1;
    run;

    %let i = %eval( &i + 1 );
    %let k = %scan( &file_list, &i, %str( ) );

  %end;

  ** Close workbook **;

  ods tagsets.excelxp close;
  ods listing;

  run;
  
%mend Dictionary;

/** End Macro Definition **/


%global file_list out_folder;

** DO NOT CHANGE - This initializes the file_list macro variable **;
%let file_list = ;

%let dtfolder = %sysfunc( putn( %sysfunc( today() ), yymmdd10. ) );

** Fill in the folder location where the export files should be saved **;
%let out_folder = &_dcdata_default_path\PresCat\Raw\Housing Insights\&dtfolder;

options noxwait;
x "md ""&out_folder""";

** Reformat owner types with shorter labels **;

proc format;
  value $OwnCat
    '010' = 'Homeowner'
    '020' = 'Resident owner'
    '030' = 'Other individuals'
    '040' = 'DC government'
    '050' = 'US government'
    '060' = 'Foreign government'
    '070' = 'Quasi-public'
    '080' = 'Community organization'
    '090' = 'Educational institution'
    '100' = 'Religious organization'
    '110' = 'Corporation/LLC'
    '111' = 'Non-profit'
    '115' = 'For-profit'
    '120' = 'GSE'
    '130' = 'Financial institution'
  ;
	
run;
    

** Export individual data sets **;
%Export( data=PresCat.Project_category_view, out=Project, desc=%str(DC Preservation Catalog, Projects) )
%Export( data=PresCat.Subsidy )
%Export( data=PresCat.Parcel )
%Export( data=PresCat.Reac_score ) 
%Export( data=PresCat.Real_property )
%Export( data=PresCat.Building_geocode )
%Export( data=PresCat.Project_geocode )

** Create data dictionary **;
%Dictionary()

run;
