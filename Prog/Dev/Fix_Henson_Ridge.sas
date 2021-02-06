/**************************************************************************
 Program:  Fix_Henson_Ridge.sas
 Library:  PresCat
 Project:  NeighborhoodInfo DC
 Author:   P. Tatian
 Created:  06/01/17
 Version:  SAS 9.2
 Environment:  Local Windows session (desktop)
 
 Description:  Correct information for Henson Ridge HOPE VI
 redevelopment.
 
 Rental properties: NL000153, NL000154
 UFAS: NL000388

 Drop from NL000154
 5901 0037 1811 ALABAMA AVE SE Residential: Other PARKLANDS MANOR ASSOC LP 

 Add to NL000388
 5885 0103 1455 BRUCE ST SE Residential: Single-family home ACCESSIBUILD I LP 

 Modifications:
**************************************************************************/

%include "\\sas1\DCdata\SAS\Inc\StdLocal.sas";

** Define libraries **;
%DCData_lib( PresCat )
%DCData_lib( MAR )
%DCData_lib( RealProp )
%DCData_lib( ROD )
%DCData_lib( DHCD )

%let revisions = Correct data for Henson Ridge.;

%let Update_dtm = %sysfunc( datetime() );

%let cat_id_list = 'NL000153', 'NL000154', 'NL000388';


/** Macro Fix_proj_name - Start Definition **/

%macro Fix_proj_name(  );

  select ( nlihc_id );
    when ( 'NL000153' ) Proj_name = "Henson Ridge II";
    when ( 'NL000154' ) Proj_name = "Henson Ridge I";
    when ( 'NL000388' ) Proj_name = "Henson Ridge UFAS";
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
  by nlihc_id;
run;

title2;


**************************************************************************
  Make changes to files
**************************************************************************;

** Building_geocode **;

data Building_geocode;

  set PresCat.Building_geocode end=last;
  
  if nlihc_id in ( 'NL000154' ) and ssl = '5901    0037' then delete;
  
  %Fix_proj_name()
  
  output;
  
  if last then do;
    nlihc_id = 'NL000388';
    bldg_addre = '1455 Bruce Street SE';
    bldg_address_id = 305742;
    anc2012 = '8E';
    bldg_image_url = '';
    bldg_lat = 38.850196;
    bldg_lon = -76.983991;
    bldg_streetview_url = '';
    bldg_x = 401389.64;
    bldg_y = 131376.76;
    bldg_zip = '20020';
    cluster_tr2000 = '38';
    cluster_tr2000_name = 'Douglas, Shipley Terrace';
    geo2010 = '11001007404';
    proj_name = 'Henson Ridge UFAS';
    psa2012 = '704';
    output;
  end;
    
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


** Subsidy **;

data Subsidy_pubhsng;

  set PresCat.Subsidy;
  where nlihc_id = 'NL000388' and subsidy_id = 3;
  
  subsidy_id = 4;
  nlihc_id = 'NL000153';
  units_assist = 156;
  output;
  
  nlihc_id = 'NL000154';
  units_assist = 124;
  output;
  
run;
  
data Subsidy;

  set 
    PresCat.Subsidy
    Subsidy_pubhsng;
  by nlihc_id subsidy_id;
  
  select ( nlihc_id );
  
    when ( 'NL000153' ) do;
    
      if subsidy_id = 2 then units_assist = 156;
      
      update_dtm = &update_dtm;
      
      output;
      
    end;
    
    when ( 'NL000388' ) do;
    
      if subsidy_id = 3 then delete;
      else if subsidy_id > 3 then subsidy_id = subsidy_id - 1;
      
      update_dtm = &update_dtm;

      output;
      
    end;
    
    otherwise do;
    
      output;
    
    end;
    
  end;
  
run;
      
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
  
  if nlihc_id = 'NL000153' and subsidy_id = 2 then do;
  
    units_assist = 156;
    Except_date = today();
    Except_init = 'PAT';

  end;
    
run;

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
  by nlihc_id;
run;


** Project_geocode **;

%Create_project_geocode( data=Building_geocode, revisions=%str(&revisions) )


** Project **;

%Create_project_subsidy_update( data=Subsidy, out=Project_subsidy_update )

data Project;

  merge
    PresCat.Project
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
  
  if nlihc_id = 'NL000388' then proj_units_tot = 22;
  
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
  var proj_name proj_addre proj_units_tot bldg_count status subsidized;
run;


** Project_category **;

data Project_category;

  set PresCat.Project_category;
  
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


** Parcel **;

%Create_parcel( data=Building_geocode, revisions=%str(&revisions) )


** Real_property **;

%Create_real_property( data=Parcel, revisions=%str(&revisions) )


