/**************************************************************************
 Program:  443_Remove_duplicates.sas
 Library:  PresCat
 Project:  Urban-Greater DC
 Author:   P. Tatian
 Created:  01/31/24
 Version:  SAS 9.4
 Environment:  Local Windows session (desktop)
 GitHub issue:  443
 
 Description:  Remove duplicate/invalid address, SSLs, and projects
 from Catalog.

 Modifications:
**************************************************************************/

%include "\\sas1\DCdata\SAS\Inc\StdLocal.sas";

** Define libraries **;
%DCData_lib( PresCat )
%DCData_lib( MAR )
%DCData_lib( RealProp )

%let projects_to_delete = 
  'NL001189', 'NL001219', 'NL001240', 'NL001253', 'NL001256', 'NL001270', 'NL001302', 'NL001309', 'NL001328';

%let revisions = %str( Correct addresses, SSLs, other info for recently added projects. );

** Adjusted project names **;

proc format;
  value $nlihc_id_to_name
    "NL001180" = "11 Nicholson St NW Cooperative"
    "NL001196" = "2530-2532 Park Place SE"
    "NL001201" = "3200 Thirteenth Street SE Re-Acquisition / Congress Heights Metro Redevelopment"
    "NL001204" = "3500 East Capitol Street NE (Phase II)"
    "NL001205" = "3534 East Capitol Street NE"
    "NL001206" = "Thompson Place (Change All Souls)"
    "NL001207" = "4040 8th St NW"
    "NL001210" = "5400-5408 5th St Acquisition"
    "NL001215" = "701 K St NE Cooperative"
    "NL001221" = "Abrams Hall Assisted Living/HELP Walter Reed"
    "NL001241" = "Cornerstone Community"
    "NL001248" = "EucKal (Kalorama Road NW)"
    "NL001254" = "HFH Transition House (DHCD HIV/AIDS Housing Initiative)"
    "NL001268" = "EucKal (Euclid Street NW)"
    "NL001269" = "Jubilee Reentry Housing Initiative"
    "NL001286" = "Mi Casa Rental Preservation Phase 1 (Good Hope Rd SE)"
    "NL001287" = "Mi Casa Rental Preservation Phase 1 (5th St NW)"
    "NL001301" = "Ridgecrest Village Apartments"
    "NL001306" = "Mi Casa Small Rental Preservation Project"
    "NL001313" = "Taylor Flats"
    "NL001320" = "The Courts at South Capitol Apartments"
    "NL001326" = "The Todd A. Lee Senior Residences at Kennedy Street"
    "NL001341" = "Woodley House (Connecticut Ave NW)"
    "NL001342" = "Woodley House (13th St NW)"
    "NL001327" = "The Yards Parcel L2/ The Estate"
    other = " ";
run;


** Delete duplicate projects **;

data Project_del;

  set PresCat.Project;
  
  if nlihc_id in ( &projects_to_delete ) then delete;

run;


** Subsidies **;

data Subsidy_to_add;

  set PresCat.Subsidy;

  select ( nlihc_id );
  
    when ( 'NL001240' ) do;
      subsidy_id = .;
      nlihc_id = 'NL001201';
    end;
    
    when ( 'NL001248' ) do;
      subsidy_id = .;
      nlihc_id = 'NL001268';
    end;
    
    when ( 'NL001253' ) do;
      subsidy_id = .;
      nlihc_id = 'NL001221';
    end;
    
    when ( 'NL001189' ) do;
      subsidy_id = .;
      nlihc_id = 'NL001286';
    end;

    when ( 'NL001302' ) do;
      subsidy_id = .;
      nlihc_id = 'NL001301';
    end;
    
    otherwise
      delete;
      
  end;
    
run;

proc sort data=Subsidy_to_add;
  by nlihc_id poa_start;
run;

proc print data=Subsidy_to_add;
  by nlihc_id; 
  id nlihc_id subsidy_id;
  var program poa_start units_assist;
run;

data Subsidy;

  retain _subsidy_id_hold;

  set PresCat.Subsidy Subsidy_to_add;
  by nlihc_id;
  
  if nlihc_id in ( &projects_to_delete ) then delete;

  if first.nlihc_id then do;
    if missing( subsidy_id ) then subsidy_id = 1;
    _subsidy_id_hold = .;
  end;
  
  if missing( subsidy_id ) then subsidy_id = _subsidy_id_hold;
  
  _subsidy_id_hold = subsidy_id + 1;
  
  ** Adjust unit counts for scattered site projects **;
  
  if nlihc_id = 'NL001286' then units_assist = 18;
  else if nlihc_id = 'NL001287' then units_assist = 12;
  
  if nlihc_id in ( 'NL001248', 'NL001268' ) and poa_start = '01aug2022'd then units_assist = 25;
  
  ** Fix subsidy date **;
  
  if nlihc_id = 'NL001333' and poa_start = '17jun2029'd then do;
    poa_start = '17jun2019'd;
    poa_start_orig = '17jun2019'd;
  end;
  
  drop _subsidy_id_hold;
  
run;

proc print data=Subsidy;
  where nlihc_id in ( 'NL001201', 'NL001221', 'NL001286', 'NL001287', 'NL001301', 'NL001248', 'NL001268' );
  by nlihc_id; 
  id nlihc_id subsidy_id;
  var program poa_start units_assist subsidy_info_source_date;
run;

proc compare base=PresCat.Subsidy compare=Subsidy listall maxprint=(40,32000);
  id nlihc_id subsidy_id;
run;

%Finalize_data_set( 
  /** Finalize data set parameters **/
  data=Subsidy,
  out=Subsidy,
  outlib=Prescat,
  label="Preservation Catalog, Project subsidies",
  sortby=nlihc_id subsidy_id,
  /** Metadata parameters **/
  revisions=%str(&revisions),
  /** File info parameters **/
  printobs=0,
  freqvars=
)

** Projects **;

%Create_project_subsidy_update( data=Subsidy, out=Project_subsidy_update, project_file=Project_del )

data Project;

  update Project_del Project_subsidy_update;
  by nlihc_id;
  
  ** Update project names **;
  
  if put( nlihc_id, $nlihc_id_to_name. ) ~= "" then proj_name = left( put( nlihc_id, $nlihc_id_to_name. ) );
  
run;

proc compare base=PresCat.Project compare=Project listall maxprint=(40,32000);
  id nlihc_id;
run;

%Finalize_data_set( 
  /** Finalize data set parameters **/
  data=Project,
  out=Project,
  outlib=Prescat,
  label="Preservation Catalog, Projects",
  sortby=nlihc_id,
  /** Metadata parameters **/
  revisions=%str(&revisions),
  /** File info parameters **/
  printobs=0,
  freqvars=
)

** Addresses to add **;

data Building_geocode_to_add;

  set Mar.Address_points_view 
        (keep=address_id anc2012 cluster2017 cluster_tr2000 psa2012 
              ward2012 ward2022 ssl geo2010 geo2020 geobg2020 geoblk2020 
              fulladdress latitude longitude x y zip
              active_res_occupancy_count
        );
  
  where address_id in ( 277127 );
  
  length nlihc_id $ 16 proj_name $ 80 cluster_tr2000_name $ 120;
  
  if address_id = 277127 then nlihc_id = "NL001248";
  
  proj_name = left( put( nlihc_id, $nlihc_id_to_name. ) );
  
  cluster_tr2000_name = left( put( cluster_tr2000, $clus00b. ) );
  
  rename 
    address_id=bldg_address_id 
    active_res_occupancy_count=bldg_units_mar
    fulladdress=bldg_addre 
    latitude=bldg_lat 
    longitude=bldg_lon 
    x=bldg_x 
    y=bldg_y
    zip=bldg_zip;
  
run;

proc sort data=Building_geocode_to_add;
  by nlihc_id bldg_addre;
run;

** Correct addresses **;

data Building_geocode;

  set PresCat.Building_geocode Building_geocode_to_add;
  by nlihc_id bldg_addre;
  
  if nlihc_id in ( &projects_to_delete ) then delete;

  ** Remove invalid addresses **;
  
  select;

    when ( nlihc_id = "NL001180" ) do;
      if bldg_address_id in ( 245617 );
    end;

    when ( nlihc_id = "NL001196" ) do;
      if bldg_address_id in ( 155365, 46174 );
    end;

    when ( nlihc_id = "NL001204" ) do;
      if bldg_address_id in ( 331864 );
    end;

    when ( nlihc_id = "NL001205" ) do;
      if bldg_address_id in ( 287970 );
    end;

    when ( nlihc_id = "NL001207" ) do;
      if bldg_address_id in ( 289376, 289377 );
    end;

    when ( nlihc_id = "NL001210" ) do;
      if bldg_address_id in ( 285180, 298106, 298107 );
    end;

    when ( nlihc_id = "NL001215" ) do;
      if bldg_address_id in ( 151117 );
    end;

    when ( nlihc_id = "NL001241" ) do;
      if bldg_address_id in ( 255160 );
    end;

    when ( nlihc_id = "NL001248" ) do;
      if bldg_address_id in ( 277127 );
    end;

    when ( nlihc_id = "NL001286" ) do;
      if bldg_address_id in ( 148118, 150176 );
    end;

    when ( nlihc_id = "NL001287" ) do;
      if bldg_address_id in ( 285180, 298106, 298107 );
    end;

    when ( nlihc_id = "NL001306" ) do;
      if bldg_address_id in ( 79580 );
    end;

    when ( nlihc_id = "NL001313" ) do;
      if bldg_address_id in ( 252502 );
    end;

    when ( nlihc_id = "NL001320" ) do;
      if bldg_address_id in (  30288, 147436, 147435, 147434, 150759 );
    end;

    when ( nlihc_id = "NL001341" ) do;
      if bldg_address_id in ( 223240, 284474, 219203, 219200 );
    end;

    when ( nlihc_id = "NL001342" ) do;
      if bldg_address_id in ( 258151 );
    end;

    when ( nlihc_id = "NL001327" ) do;
      if bldg_address_id in ( 331891, 318195, 318145, 313295, 335869, 318654, 318653, 318655 );
    end;
    
    otherwise
      /** KEEP ALL ADDRESSES **/;
      
  end;

run;

proc print data=Building_geocode;
  where nlihc_id in ( "NL001248", "NL001268", "NL001204", "NL001205" );
  id nlihc_id;
  var bldg_addre;
run;

proc compare base=PresCat.Building_geocode compare=Building_geocode listall maxprint=(40,32000);
  id nlihc_id bldg_addre;
run;

%Create_project_geocode( 
  data=Building_geocode, 
  out=Project_geocode, 
  revisions=&revisions, 
  compare=Y,
  finalize=N
  )

** Parcel to add **;

data Parcel_to_add;

  merge 
    Realprop.Parcel_base 
      (keep=ssl in_last_ownerpt ownerpt_extractdat_last saledate ui_proptype x_coord y_coord)
    Realprop.Parcel_base_who_owns 
      (keep=ssl ownername_full ownercat);
  by ssl;
  
  where ssl = '2567    0090';
  
  length nlihc_id $ 16;
  
  if ssl = '2567    0090' then nlihc_id = 'NL001248';
  
  rename 
    ownerpt_extractdat_last=parcel_info_source_date 
    saledate=parcel_owner_date 
    ui_proptype=parcel_type 
    x_coord=parcel_x
    y_coord=parcel_y
    ownername_full=parcel_owner_name
    ownercat=parcel_owner_type
  ;
  
run;

proc sort data=Parcel_to_add;
  by nlihc_id ssl;
run;

** Correct parcels **;

data Parcel;

  set PresCat.Parcel Parcel_to_add;
  by nlihc_id ssl;

  if nlihc_id in ( &projects_to_delete ) then delete;

  select;
  
    when ( nlihc_id = "NL001180" ) do;
      if compbl( ssl ) in ( "3383 0002" );
    end;

    when ( nlihc_id = "NL001196" ) do;
      if compbl( ssl ) in ( "5579 0066" );
    end;

    when ( nlihc_id = "NL001207" ) do;
      if compbl( ssl ) in ( "3026 0052" );
    end;

    when ( nlihc_id = "NL001210" ) do;
      if compbl( ssl ) in ( "3208 0849" );
    end;

    when ( nlihc_id = "NL001215" ) do;
      if compbl( ssl ) in ( "0888 0810" );
    end;

    when ( nlihc_id = "NL001241" ) do;
      if compbl( ssl ) in ( "2808 0068" );
    end;

    when ( nlihc_id = "NL001248" ) do;
      if compbl( ssl ) in ( "2567 0090" );
    end;

    when ( nlihc_id = "NL001286" ) do;
      if compbl( ssl ) in ( "5764 0053" );
    end;

    when ( nlihc_id = "NL001287" ) do;
      if compbl( ssl ) in ( "3208 0849" );
    end;

    when ( nlihc_id = "NL001306" ) do;
      if compbl( ssl ) in ( "3814 0061", "3814 0807" );
    end;

    when ( nlihc_id = "NL001313" ) do;
      if compbl( ssl ) in ( "3026 0034" ) then delete;
    end;

    when ( nlihc_id = "NL001320" ) do;
      if compbl( ssl ) in ( "6129 0076", "6129 0080" );
    end;

    when ( nlihc_id = "NL001341" ) do;
      if compbl( ssl ) in ( "2208 0065", "2208 0808" );
    end;

    when ( nlihc_id = "NL001342" ) do;
      if compbl( ssl ) in ( "2777 0029" );
    end;

    when ( nlihc_id = "NL001327" ) do;
      if compbl( ssl ) in ( "0771 0014", "0771 0818" );
    end;

    otherwise
      /** KEEP ALL PARCELS **/;
      
  end;

run;

proc print data=Parcel;
  where nlihc_id in ( "NL001180", "NL001313", "NL001248", "NL001268", "NL001306");
  by nlihc_id;
  id nlihc_id;
  var ssl;
run;

proc compare base=PresCat.Parcel compare=Parcel listall maxprint=(40,32000);
  id nlihc_id ssl;
run;


** Update Project_category **;

data Project_category;

  set PresCat.Project_category;
  
  if nlihc_id in ( &projects_to_delete ) then delete;

  ** Update project names **;
  
  if put( nlihc_id, $nlihc_id_to_name. ) ~= "" then proj_name = left( put( nlihc_id, $nlihc_id_to_name. ) );
  
run;

proc compare base=PresCat.Project_category compare=Project_category listall maxprint=(40,32000);
  id nlihc_id;
run;


