/**************************************************************************
 Program:  443_Duplicate_project_check.sas
 Library:  PresCat
 Project:  Urban-Greater DC
 Author:   P. Tatian
 Created:  01/10/24
 Version:  SAS 9.4
 Environment:  Local Windows session (desktop)
 GitHub issue:  443
 
 Description:  Review projects added to Catalog for TOPA study to
 find any duplicate project entries.

 Modifications:
**************************************************************************/

%include "\\sas1\DCdata\SAS\Inc\StdLocal.sas";

** Define libraries **;
%DCData_lib( PresCat )

/** Macro Check_for_dups - Start Definition **/

%macro Check_for_dups( data1=, data2=, matching_project_list= );

  ** Check new projects for pre-existing addresses in Catalog **;
  
  proc sql noprint;
    create table catalog_match as
    select 
      coalesce( new.bldg_address_id, cat.bldg_address_id ) as bldg_address_id, 
  	/*new.id,*/
      new.nlihc_id as nlihc_id_new, cat.nlihc_id as nlihc_id_cat,
  	/*new.proj_name as proj_name_new, cat.proj_name as proj_name_cat,*/
  	new.bldg_addre as bldg_addre_new, cat.bldg_addre as bldg_addre_cat
    from &data1 as new full join &data2 as cat
    on new.bldg_address_id = cat.bldg_address_id
    where not( missing( new.nlihc_id ) or missing( cat.nlihc_id ) ) and new.nlihc_id ~= cat.nlihc_id
    order by nlihc_id_new, nlihc_id_cat;
  quit;

  proc sort data=catalog_match out=catalog_match_nodup (drop=bldg_address_id bldg_addre_:) nodupkey;
    by nlihc_id_new nlihc_id_cat;
  run;

  title2 '********************************************************************************************';
  title3 '** Addresses in new projects that match existing Catalog projects OR';
  title4 '** New projects with common addresses';
  title4 '** Check to make sure these projects are not already in Catalog or deduplicate in input data';
  
  %if %length( &matching_project_list ) > 0 %then %do;
    ods tagsets.excelxp file="&matching_project_list" style=Normal options(sheet_interval='None' );
    ods tagsets.excelxp options( sheet_name="Catalog matches" );
  %end;

  proc print data=catalog_match_nodup;
    /*id id;*/
  run;

  %if %length( &matching_project_list ) > 0 %then %do;
    ods tagsets.excelxp close;
  %end;
  
  title2;

%mend Check_for_dups;

/** End Macro Definition **/

proc freq data=Prescat.project;
  tables added_to_catalog;
run;

** Split projects into those before 8/27/2023 and later **;

data Building_geocode_new Building_geocode_old;

  merge
    Prescat.Project_category_view (keep=nlihc_id added_to_catalog status proj_name in=in1)
    Prescat.Building_geocode (keep=nlihc_id bldg_address_id bldg_addre in=in2);
  by nlihc_id;
  
  if in1 and in2;
  
  if added_to_catalog >= '27aug2023'd then output Building_geocode_new;
  else output Building_geocode_old;

run;

/*
%File_info( data=Building_geocode_new, contents=n, stats=, printobs=50 )
%File_info( data=Building_geocode_old, contents=n, stats=, printobs=50 )
*/

%Check_for_dups( data1=Building_geocode_new, data2=Building_geocode_old, matching_project_list=C:\DCData\Libraries\PresCat\Prog\Dev\443_Duplicate_project_check_new_old.xls )

%Check_for_dups( data1=Building_geocode_new, data2=Building_geocode_new, matching_project_list=C:\DCData\Libraries\PresCat\Prog\Dev\443_Duplicate_project_check_new_new.xls )


** Check for large geographic spread in points **; 

proc sort data=Prescat.Building_geocode out=Building_geocode_srt;
  by nlihc_id descending bldg_units_mar;
run;

data A;

  set Building_geocode_srt;
  by nlihc_id;
  
  retain bldg_x_ret bldg_y_ret;
  
  if first.nlihc_id then do;
    bldg_x_ret = bldg_x;
    bldg_y_ret = bldg_y;
    dist = 0;
  end;
  else do;
    dist = sqrt( ( bldg_x_ret - bldg_x ) ** 2 + ( bldg_y_ret - bldg_y ) ** 2 );
  end;
  
run;

proc summary data=A;
  by nlihc_id;
  var dist;
  output out=geo_spread_dist_max max=max_dist;
run;

data geo_spread_dist;

  merge A geo_spread_dist_max (keep=nlihc_id max_dist);
  by nlihc_id;
  
run;

proc sort data=geo_spread_dist;
  by nlihc_id dist;
run;

proc print data=geo_spread_dist;
  where max_dist > 600;
  id nlihc_id;
  by nlihc_id;
  var dist bldg_x bldg_y cluster2017 bldg_address_id bldg_addre bldg_units_mar;
  format cluster2017 ;
run;





/******
proc summary data=Prescat.Building_geocode;
  by nlihc_id;
  var bldg_x bldg_y;
  output out=geo_spread min=bldg_x_min bldg_y_min max=bldg_x_max bldg_y_max;
run;

data geo_spread_dist;

  set geo_spread;
  
  max_dist = sqrt( ( bldg_x_max - bldg_x_min ) ** 2 + ( bldg_y_max - bldg_y_min ) ** 2 );
  
run;

proc univariate data=geo_spread_dist plot nextrobs=20;
  id nlihc_id;
  var max_dist;
run;

data list_large_spread;

  merge 
    Prescat.Building_geocode
    geo_spread_dist;
  by nlihc_id;
  
  if max_dist > 400;
  
run;

proc print data=list_large_spread;
  id nlihc_id;
  by nlihc_id;
  var max_dist bldg_x bldg_y cluster2017 bldg_address_id bldg_addre bldg_units_mar;
  format cluster2017 ;
run;



/*

%Check_for_dups( data1=Prescat.Building_geocode, data2=Prescat.Building_geocode, matching_project_list=C:\DCData\Libraries\PresCat\Prog\Dev\443_Duplicate_project_check.xls )


run;


CHECK:
C:\Temp\NL001189-detailed.pdf
