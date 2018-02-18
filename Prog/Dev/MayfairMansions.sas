/**************************************************************************
 Program:  MayfairMansions.sas
 Library:  PresCat
 Project:  NeighborhoodInfo DC
 Author:   P. Tatian
 Created:  06/23/17
 Version:  SAS 9.2
 Environment:  Local Windows session (desktop)
 
 Description:  Restructure data for Mayfair Mansions
   NL000202 - Original Mayfair Mansions
   NL001005 - Mayfair Mansions II
   NL001040 - Mayfair Mansions III

 Modifications:
**************************************************************************/

%include "L:\SAS\Inc\StdLocal.sas";

** Define libraries **;
%DCData_lib( PresCat )
%DCData_lib( MAR )
%DCData_lib( Realprop )
%DCData_lib( ROD )
%DCData_lib( DHCD )

%let revisions = Restructure data for Mayfair Mansions.;

%let Update_dtm = %sysfunc( datetime() );

%let cat_id_list = 'NL000202', 'NL001005', 'NL001040';

%let NO_SUBSIDY_ID = 9999999999;


/** Macro Fix_proj_name - Start Definition **/

%macro Fix_proj_name(  );

  select ( nlihc_id );
    when ( 'NL000202' ) Proj_name = "Mayfair Mansions (former)";
    when ( 'NL001005' ) Proj_name = "Mayfair Mansions II";
    when ( 'NL001040' ) Proj_name = "Mayfair Mansions III";
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

proc print data=PresCat.Project_category;
  where nlihc_id in ( &cat_id_list );
  id nlihc_id;
run;

proc print data=PresCat.Subsidy;
  where nlihc_id in ( &cat_id_list );
  id nlihc_id subsidy_id;
  by nlihc_id;
  var subsidy_active program units_assist poa_start compl_end poa_end subsidy_info_source subsidy_info_source_id;
  format program $progshrt.;
run;

proc print data=PresCat.Subsidy_except;
  where nlihc_id in ( &cat_id_list );
  id nlihc_id subsidy_id;
run;

proc print data=PresCat.Building_geocode n;
  where nlihc_id in ( &cat_id_list );
  id nlihc_id;
  by nlihc_id;
  var bldg_addre;
  format bldg_lon bldg_lat 12.6;
run;

proc print data=PresCat.Parcel;
  where nlihc_id in ( &cat_id_list );
  id nlihc_id ssl;
  by nlihc_id;
  var in_last_ownerpt Parcel_owner_name parcel_type;
run;

title2;


**************************************************************************
  Make changes to files
**************************************************************************;

** Building_geocode **;

data bldg_a;

  merge 
    PresCat.Building_geocode 
      (where=(nlihc_id='NL000202'))
    PresCat.Building_geocode
      (where=(nlihc_id='NL001005')
       keep=bldg_addre nlihc_id
       in=in2);
  by bldg_addre;
  
  if in2 or bldg_address_id in ( 295367, 295369, 295458 ) then nlihc_id = 'NL001005';
  else nlihc_id = 'NL001040';
  
run;

data Building_geocode;

  set 
    PresCat.Building_geocode 
      (where=(nlihc_id ~= 'NL001005'))
    bldg_a;
  
  %Fix_proj_name()
  
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

proc print data=Building_geocode n;
  where nlihc_id in ( &cat_id_list );
  id nlihc_id;
  by nlihc_id;
  var bldg_addre;
  format bldg_lon bldg_lat 12.6;
run;


** Subsidy **;

data Subsidy_a;

  set PresCat.Subsidy end=last;
  where nlihc_id in ( &cat_id_list );
  
  if nlihc_id = 'NL000202' then do;
    select ( subsidy_id );
      when ( 1, 2, 4, 6, 7 ) nlihc_id = 'NL001005';
      otherwise /** DO NOTHING **/;
    end;
    subsidy_id = &NO_SUBSIDY_ID;
  end;
  else if nlihc_id = 'NL001005' then do;
    select ( subsidy_id );
      when ( 1 ) nlihc_id = 'NL001040';
      when ( 2 ) nlihc_id = 'NL001005';
    end;
    subsidy_id = &NO_SUBSIDY_ID;
  end;
  
  if nlihc_id = 'NL000202' then subsidy_active = 0;
  
  output;
  
  if last then do;
  
    nlihc_id = 'NL001040';
    subsidy_id = &NO_SUBSIDY_ID;
    subsidy_active = 1;
    program = 'LIHTC';
    portfolio = 'LIHTC';
    units_assist = 160;
    poa_start = '01jan2012'd;
    poa_end = '01jan2042'd;
    compl_end = '01jan2027'd;
    Subsidy_Info_Source = 'HUD/LIHTC';
    Subsidy_Info_Source_id = 'DCB2012802';
    
    Agency = '';
    POA_end_prev = .;
    POA_start_orig = .;
    Subsidy_Info_Source_Date = .;
    Subsidy_info_source_property = '';
    Update_Dtm = .;
    contract_number = ' ';
    rent_to_fmr_description = ' ';
    
    output;
    
    Subsidy_Info_Source = 'HUD/MFIS';
    Subsidy_Info_Source_id = '00011258';
    nlihc_id = 'NL001005';
    subsidy_id = &NO_SUBSIDY_ID;
    subsidy_active = 1;
    program = '223A7223FREFI';
    portfolio = 'HUDMORT';
    units_assist = 410;
    poa_start = '01jul2016'd;
    poa_end = '01jul2051'd;
    compl_end = poa_end;
    POA_end_actual = .;
    
    output;
    
    Subsidy_Info_Source = 'HUD/MFIS';
    Subsidy_Info_Source_id = '00035349';
    nlihc_id = 'NL000202';
    subsidy_id = &NO_SUBSIDY_ID;
    subsidy_active = 0;
    program = '221D4MRMI';
    portfolio = 'HUDMORT';
    units_assist = 569;
    poa_start = '01jul1990'd;
    poa_end = '01jul2030'd;
    compl_end = poa_end;
    POA_end_actual = '01oct2007'd;
    
    output;
    
  end;

run;

proc sort data=Subsidy_a;
  by Nlihc_id Subsidy_id poa_start poa_end Subsidy_Info_Source_ID;
run;

data Subsidy;

  set 
    PresCat.Subsidy
      (where=(nlihc_id not in ( &cat_id_list )))
    Subsidy_a;
  by nlihc_id subsidy_id;

  retain Subsidy_id_ret;
  
  if first.nlihc_id then Subsidy_id_ret = 0;
  
  if Subsidy_id = &NO_SUBSIDY_ID then do;
    Subsidy_id = Subsidy_id_ret + 1;
  end;
  
  Subsidy_id_ret = Subsidy_id;
  
  drop Subsidy_id_ret;
  
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
  var subsidy_active program units_assist poa_start compl_end poa_end subsidy_info_source subsidy_info_source_id;
  format program $progshrt.;
run;


** Subsidy_except **;

data Subsidy_except;

  set PresCat.Subsidy_except;
  
  if nlihc_id = 'NL000202' and subsidy_id = 3 then do;
  
    Except_date = today();
    Except_init = 'PAT';
    
    subsidy_id = 2;
    subsidy_active = 0;
    
  end;
  else if nlihc_id = 'NL001005' and subsidy_id = 2 then do;

    Except_date = today();
    Except_init = 'PAT';
    
    subsidy_id = 5;
    
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
  
  if nlihc_id = 'NL000202' then do;
  
    status = 'I';
    cat_replaced = 1;
    category_code = 7;
    output;
  
  end;
  else if nlihc_id = 'NL001005' then do;
  
    /** Mayfair Mansions II **/
    Hud_Own_Name = '';
    Hud_Mgr_Name = '';
    Hud_Mgr_Type = '';
    cat_expiring = 0;
    proj_units_tot = 410;
    output;
    
    nlihc_id = 'NL001040';  /** Mayfair Mansions III **/
    proj_units_tot = 160;
    Proj_Name_old = '';
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
  
  if nlihc_id = 'NL000202' then do;
  
    cat_replaced = 1;
    category_code = 7;
    output;
  
  end;
  else if nlihc_id = 'NL001005' then do;
  
    /** Mayfair Mansions II **/
    output;
    
    nlihc_id = 'NL001040';  /** Mayfair Mansions III **/
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
  var in_last_ownerpt Parcel_owner_name parcel_type;
run;


** Real_property **;

%Create_real_property( data=Parcel, revisions=%str(&revisions) )

proc print data=Real_property;
  where nlihc_id in ( &cat_id_list );
  id nlihc_id ssl;
  by nlihc_id;
run;

