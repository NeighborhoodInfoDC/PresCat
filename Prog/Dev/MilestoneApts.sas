/**************************************************************************
 Program:  MilestoneApts.sas
 Library:  PresCat
 Project:  NeighborhoodInfo DC
 Author:   P. Tatian
 Created:  06/21/17
 Version:  SAS 9.2
 Environment:  Local Windows session (desktop)
 
 Description:  Restructure New Beginnings Coop (NL000374) into
 separate scattered site developments for Milestone Apts. 

 Modifications:
**************************************************************************/

%include "\\sas1\DCdata\SAS\Inc\StdLocal.sas";

** Define libraries **;
%DCData_lib( PresCat )
%DCData_lib( MAR )
%DCData_lib( Realprop )
%DCData_lib( ROD )
%DCData_lib( DHCD )

%let revisions = Correct data for Milestone Apts.;

%let Update_dtm = %sysfunc( datetime() );

%let cat_id_list = 'NL000374', 'NL001036', 'NL001037', 'NL001038', 'NL001039';


/** Macro Fix_proj_name - Start Definition **/

%macro Fix_proj_name(  );

  select ( nlihc_id );
    when ( 'NL000374' ) Proj_name = "Milestone Apts - Sherman Ave";
    when ( 'NL001036' ) Proj_name = "Milestone Apts - Belmont St";
    when ( 'NL001037' ) Proj_name = "Milestone Apts - Mount Pleasant St";
    when ( 'NL001038' ) Proj_name = "Milestone Apts - N Street";
    when ( 'NL001039' ) Proj_name = "Milestone Apts - Marian Russell";
    otherwise /** DO NOTHING **/;
  end;

%mend Fix_proj_name;

/** End Macro Definition **/


**************************************************************************;
  title2 '--BEFORE CHANGES--';
**************************************************************************;  

proc print data=PresCat.Project;
  where nlihc_id in ( &cat_id_list );
  id nlihc_id;
  var proj_name proj_addre proj_units_tot bldg_count status subsidized;
run;

proc print data=PresCat.Subsidy;
  where nlihc_id in ( &cat_id_list );
  id nlihc_id subsidy_id;
  by nlihc_id;
  var subsidy_active portfolio program units_assist poa_start compl_end poa_end;
run;

proc print data=PresCat.Subsidy_except;
  where nlihc_id in ( &cat_id_list );
  id nlihc_id subsidy_id;
run;

proc print data=PresCat.Building_geocode;
  where nlihc_id in ( &cat_id_list );
  format bldg_lon bldg_lat 12.6;
run;

proc print data=PresCat.Parcel;
  where nlihc_id in ( &cat_id_list );
  id nlihc_id ssl;
  by nlihc_id;
run;

title2;


**************************************************************************
  Make changes to files
**************************************************************************;

** Building_geocode **;

data Building_geocode;

  set PresCat.Building_geocode;
  
  if nlihc_id = 'NL000374' then do;
  
    select ( bldg_addre );
      when ( "115 16th Street NE" )
        nlihc_id = 'NL001039';
      when ( "1430 Belmont Street NW" )
        nlihc_id = 'NL001036';
      when ( "2505 N Street SE" )
        nlihc_id = 'NL001038';
      when ( "2922 Sherman Avenue NW" )
        nlihc_id = 'NL000374';
      when ( "3121 Mount Pleasant Street NW" )  
        nlihc_id = 'NL001037';
      otherwise
        /** DO NOTHING **/;
    end;
    
    %Fix_proj_name()
  
  end;
  
  if nlihc_id = 'NL001038' then do;
  
    output;
  
    bldg_addre = "2501 N Street SE";
    bldg_lat = 38.874999;
    bldg_lon = -76.969462;
    bldg_x = 402649.95;
    bldg_y = 134130.43;
    Bldg_image_url = "http://citizenatlas.dc.gov/mobilevideo/20041026/OQ093527.jpg";
    
  end;
  
  output;

run;

proc sort data=Building_geocode;
  by nlihc_id bldg_addre;

proc compare base=PresCat.Building_geocode compare=Building_geocode listall maxprint=(40,32000);
  id nlihc_id bldg_addre;
run;

%Finalize_data_set( 
  /** Finalize data set parameters **/
  data=Building_geocode,
  out=Building_geocode,
  outlib=PresCat,
  label="Preservation Catalog, Building-level geocoding info",
  sortby=nlihc_id bldg_addre,
  archive=Y,
  /** Metadata parameters **/
  revisions=%str(&revisions),
  /** File info parameters **/
  contents=Y,
  printobs=0,
  stats=
)

proc print data=Building_geocode;
  where nlihc_id in ( &cat_id_list );
  format bldg_lon bldg_lat 12.6;
run;


** Subsidy **;

data Subsidy;

  set PresCat.Subsidy;
  
  if nlihc_id = 'NL000374' and subsidy_id = 2 then do;
  
    units_assist = 21;  /** Sherman **/
    
    output;
    
    subsidy_id = 1;
    nlihc_id = 'NL001036';  /** Belmont **/
    units_assist = 48;
    output;
    
    nlihc_id = 'NL001037';  /** Mount Pleasant **/
    units_assist = 21;
    output;
  
    nlihc_id = 'NL001038';  /** N Street **/
    units_assist = 35;
    output;

    nlihc_id = 'NL001039';  /** Marian Russell **/
    units_assist = 11;
    output;
    
  end;
  else do;
  
    output;
  
  end;
  
run;

proc sort data=Subsidy;
  by nlihc_id subsidy_id;
  
proc compare base=PresCat.Subsidy compare=Subsidy listall maxprint=(40,32000);
  id nlihc_id subsidy_id;
run;

%Finalize_data_set( 
  /** Finalize data set parameters **/
  data=Subsidy,
  out=Subsidy,
  outlib=PresCat,
  label="Preservation Catalog, Project subsidies",
  sortby=nlihc_id subsidy_id,
  archive=Y,
  /** Metadata parameters **/
  revisions=%str(&revisions),
  /** File info parameters **/
  contents=Y,
  printobs=0,
  stats=
)

proc print data=Subsidy;
  where nlihc_id in ( &cat_id_list );
  id nlihc_id subsidy_id;
  by nlihc_id;
  var subsidy_active portfolio program units_assist poa_start compl_end poa_end;
run;


** Subsidy_except **;

data Subsidy_except;

  set PresCat.Subsidy_except;
  
  if nlihc_id = 'NL000374' and subsidy_id = 2 then do;
  
    Except_date = today();
    Except_init = 'PAT';

    units_assist = 21;  /** Sherman **/
    
    output;
    
    subsidy_id = 1;
    nlihc_id = 'NL001036';  /** Belmont **/
    units_assist = 48;
    output;
    
    nlihc_id = 'NL001037';  /** Mount Pleasant **/
    units_assist = 21;
    output;
  
    nlihc_id = 'NL001038';  /** N Street **/
    units_assist = 35;
    output;

    nlihc_id = 'NL001039';  /** Marian Russell **/
    units_assist = 11;
    output;
    
  end;
  else do;
  
    output;
  
  end;
  
run;

proc sort data=Subsidy_except;
  by nlihc_id subsidy_id except_date;

proc compare base=PresCat.Subsidy_except compare=Subsidy_except listall maxprint=(40,32000);
  id nlihc_id subsidy_id except_date;
run;

%Finalize_data_set( 
  /** Finalize data set parameters **/
  data=Subsidy_except,
  out=Subsidy_except,
  outlib=PresCat,
  label="Preservation Catalog, Subsidy exception file",
  sortby=nlihc_id subsidy_id except_date,
  archive=Y,
  /** Metadata parameters **/
  revisions=%str(&revisions),
  /** File info parameters **/
  contents=Y,
  printobs=0,
  stats=
)

proc print data=Subsidy_except;
  where nlihc_id in ( &cat_id_list );
  id nlihc_id subsidy_id;
run;


** Project_geocode **;

%Create_project_geocode( data=Building_geocode, revisions=%str(&revisions) )


** Project **;

data Project_a;

  set PresCat.Project;
  
  if nlihc_id = 'NL000374' then do;
  
    /** Sherman **/
    output;
    
    nlihc_id = 'NL001036';  /** Belmont **/
    output;
    
    nlihc_id = 'NL001037';  /** Mount Pleasant **/
    output;
  
    nlihc_id = 'NL001038';  /** N Street **/
    output;

    nlihc_id = 'NL001039';  /** Marian Russell **/
    output;
    
  end;
  else do;
  
    output;
  
  end;
  
run;

proc sort data=Project_a;
  by nlihc_id;

%Create_project_subsidy_update( data=Subsidy, out=Project_subsidy_update, project_file=Project_a )

data Project;

  merge
    Project_a
      (keep=nlihc_id category_code cat_: contract_number hud_: pbca proj_addre_old
            proj_city proj_name proj_name_old proj_st proj_units_tot status
            subsidy_info_source_property update_dtm)
    Project_subsidy_update
      (keep=nlihc_id proj_units_assist_max proj_units_assist_min subsidized
            subsidy_end_first subsidy_end_last subsidy_start_first subsidy_start_last)
    Project_geocode
      (keep=nlihc_id anc2012 bldg_count cluster_tr2000 cluster_tr2000_name geo2010
            proj_addre proj_address_id proj_image_url proj_lat proj_lon
            proj_streetview_url proj_x proj_y proj_zip psa2012 ward2012 zip);
  by nlihc_id;
  
  %Fix_proj_name()
  
  if nlihc_id in ( &cat_id_list ) then update_dtm = &update_dtm;
  
run;
    
proc compare base=PresCat.Project compare=Project listall maxprint=(40,32000);
  id nlihc_id;
run;

%Finalize_data_set( 
  /** Finalize data set parameters **/
  data=Project,
  out=Project,
  outlib=PresCat,
  label="Preservation Catalog, Projects",
  sortby=nlihc_id,
  archive=Y,
  /** Metadata parameters **/
  revisions=%str(&revisions),
  /** File info parameters **/
  contents=Y,
  printobs=0,
  stats=
)

proc print data=Project;
  where nlihc_id in ( &cat_id_list );
  id nlihc_id;
  *var proj_name proj_addre proj_units_tot bldg_count status subsidized;
run;


** Project_category **;

data Project_category_a;

  set PresCat.Project_category;
  
  if nlihc_id = 'NL000374' then do;
  
    /** Sherman **/
    output;
    
    nlihc_id = 'NL001036';  /** Belmont **/
    output;
    
    nlihc_id = 'NL001037';  /** Mount Pleasant **/
    output;
  
    nlihc_id = 'NL001038';  /** N Street **/
    output;

    nlihc_id = 'NL001039';  /** Marian Russell **/
    output;
    
  end;
  else do;
  
    output;
  
  end;

run;

proc sort data=Project_category_a;
  by nlihc_id;

data Project_category;

  set Project_category_a;
  
  %Fix_proj_name()
  
run;

proc compare base=PresCat.Project_category compare=Project_category listall maxprint=(40,32000);
  id nlihc_id;
run;

%Finalize_data_set( 
  /** Finalize data set parameters **/
  data=Project_category,
  out=Project_category,
  outlib=PresCat,
  label="Preservation Catalog, Project category",
  sortby=nlihc_id,
  archive=Y,
  /** Metadata parameters **/
  revisions=%str(&revisions),
  /** File info parameters **/
  contents=Y,
  printobs=0,
  stats=
)

proc print data=Project_category;
  where nlihc_id in ( &cat_id_list );
  id nlihc_id;
run;

** Parcel **;

%Create_parcel( data=Building_geocode, revisions=%str(&revisions) )

proc print data=Parcel;
  where nlihc_id in ( &cat_id_list );
  id nlihc_id ssl;
  by nlihc_id;
run;


** Real_property **;

%Create_real_property( data=Parcel, revisions=%str(&revisions) )

proc print data=Real_property;
  where nlihc_id in ( &cat_id_list );
  id nlihc_id ssl;
  by nlihc_id;
run;

