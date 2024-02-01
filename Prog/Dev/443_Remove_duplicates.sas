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
  
  ** Adjust unit counts for scattered site project **;
  
  if nlihc_id = 'NL001286' then units_assist = 18;
  else if nlihc_id = 'NL001287' then units_assist = 12;
  
  ** Fix subsidy date **;
  
  if nlihc_id = 'NL001333' and poa_start = '17jun2029'd then do;
    poa_start = '17jun2019'd;
    poa_start_orig = '17jun2019'd;
  end;
  
  drop _subsidy_id_hold;
  
run;

proc print data=Subsidy;
  where nlihc_id in ( 'NL001201', 'NL001221', 'NL001286', 'NL001287', 'NL001301' );
  by nlihc_id; 
  id nlihc_id subsidy_id;
  var program poa_start units_assist;
run;

proc compare base=PresCat.Subsidy compare=Subsidy listall maxprint=(40,32000);
  id nlihc_id subsidy_id;
run;

%Create_project_subsidy_update( data=Subsidy, out=Project_subsidy_update, project_file=Project_del )

data Project;

  merge Project_del Project_subsidy_update;
  by nlihc_id;
  
  ** Update project names **;
  
  if put( nlihc_id, $nlihc_id_to_name. ) ~= "" then proj_name = left( put( nlihc_id, $nlihc_id_to_name. ) );
  
run;

proc compare base=PresCat.Project compare=Project listall maxprint=(40,32000);
  id nlihc_id;
run;

********** NEED TO FINISH THIS CODE >>>>>>>>
** Addresses to add **;

data Building_geocode_to_add;

  set Mar.Address_points_view (keep=address_id anc2012 fulladdress latitude longitude x y);
  
  where address_id in ( 277127 );
  
  length nlihc_id $ 16;
  
  if address_id = 277127 then nlihc_id = "NL001248";
  
  rename address_id=bldg_address_id fulladdress=bldg_addre latitude=bldg_lat longitude=bldg_lon x=bldg_x y=bldg_y;
  
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
  where nlihc_id = "NL001248";
  id nlihc_id;
  var bldg_addre;
run;

proc compare base=PresCat.Building_geocode compare=Building_geocode listall maxprint=(40,32000);
  id nlihc_id bldg_addre;
run;

%Create_project_geocode( 
  data=Building_geocode, 
  out=Project_geocode, 
  revisions=, 
  compare=Y,
  finalize=N
  )

** Correct parcels **;



** Update Project_category_view **;

