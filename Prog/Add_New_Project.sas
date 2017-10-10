/**************************************************************************
 Program:  Add_New_Project.sas
 Library:  PresCat
 Project:  NeighborhoodInfo DC
 Author:   M. Cohen
 Created:  08/26/2016
 Version:  SAS 9.1
 Environment:  Local Windows session (desktop)
 
 Description:  Add New Projects to Project Data Set

 Modifications:
**************************************************************************/

%include "L:\SAS\Inc\StdLocal.sas";

** Define libraries **;
%DCData_lib( PresCat )
%DCData_lib( RealProp )

proc sort data=project_geocode;
by proj_address_id;
run;

proc sort data=building_geocode;
by bldg_address_id;
run;

data Project_Status;
	merge building_geocode (keep = nlihc_id bldg_address_id rename=(bldg_address_id=proj_address_id))
		project_geocode;
	by proj_address_id;
	if proj_name = "" then delete;
	run;

proc sort data=Project_Status out=Status;
	by nlihc_id;
	run;

** Create subsidy update data set **;

%Create_project_subsidy_update( data=Subsidy ) 


data Project_New (label="Preservation Catalog, projects update");

  merge 
	Status 
	Project_Subsidy_update (keep=Nlihc_id Proj_Units_Assist_: Subsidy_Start_: Subsidy_End_: Subsidized);
	
  by Nlihc_id;
  
  run;

  Data new_project;
  	set Prescat.project (keep = Nlihc_id) project_new;
	by nlihc_id;
	run;
 
  Data add_project;

  set new_project;
  by nlihc_id;
  if not (first.nlihc_id and last.nlihc_id) then delete;


  ** Set Categories (default as 'other subsidized property') **;

  if cat_at_risk = . then cat_at_risk = 0;
  if cat_failing_insp = . then cat_failing_insp = 0;
  if cat_more_info = . then cat_more_info = 0;
  if cat_lost = . then cat_lost = 0;
  if cat_replaced = . then cat_replaced = 0;

  if category_code = "" then category_code = "5";
  
  if category_code = "6" then status = "I";
  else status = "A";


  ** Set project units **;
  if proj_units_assist_max = proj_units_assist_min then proj_units_tot = proj_units_assist_max;
  else proj_units_tot=.;

  ** Mark projects with subsidy less than one year away as expiring **;
  
  if -100 < intck( 'year', Subsidy_End_First, date() ) < 1 then Cat_Expiring = 1;
  if cat_expiring = . then cat_expiring = 0;

  Proj_units_tot = Units;
  
  ** Label City and State **;
  Proj_City = "Washington";
  Proj_St = "DC";
  
  ** Format information on Owner and Manager **;

  if Own_Name ~= "" then do;
  
    Hud_Own_Name = left( Own_Name );

    select ( Own_type );
      when ( 'Limited Dividend' ) Hud_Own_type = 'LD';
      when ( 'Non-Profit' ) Hud_Own_type = 'NP';
      when ( 'Non-Profit Controlled' ) Hud_Own_type = 'NC';
      when ( 'Other' ) Hud_Own_type = 'OT';
      when ( 'PHA' ) Hud_Own_type = 'HA';
      when ( 'Profit Motivated' ) Hud_Own_type = 'PM';
      when ( '' ) Hud_Own_type = '  ';
      otherwise do;
        %warn_put( msg='Unknown company type: ' _n_= nlihc_id= Hud_Own_name= )
      end;
    end;
  
  end;
  else do;
  
    Hud_Own_Name = "Unknown";
    Hud_Own_type = 'OT';
  
  end;
  
  if Mgr_Name ~= "" then do;
  
    Hud_Mgr_Name = left( Mgr_Name );
    
    select ( Mgr_type );
      when ( 'Limited Dividend' ) Hud_Mgr_type = 'LD';
      when ( 'Non-Profit' ) Hud_Mgr_type = 'NP';
      when ( 'Non-Profit Controlled' ) Hud_Mgr_type = 'NC';
      when ( 'Other' ) Hud_Mgr_type = 'OT';
      when ( 'PHA' ) Hud_Mgr_type = 'HA';
      when ( 'Profit Motivated', 'Proft Motivated' ) Hud_Mgr_type = 'PM';
      when ( '' ) Hud_Mgr_type = '  ';
      otherwise do;
        %warn_put( msg='Unknown company type: ' _n_= nlihc_id= Hud_Mgr_name= )
      end;
    end;
    
  end;
  else do;
  
    Hud_Mgr_Name = "Unknown";
    Hud_Mgr_type = 'OT';
    
  end;
  
  Update_Dtm = datetime();
  
  ** Subsidy status **;
  
  if missing( Subsidized ) then Subsidized = 0;
  
  if missing( PBCA ) then PBCA = 0;
  
  label
    NLIHC_ID = "Preservation Catalog project ID"
    Status = "Project is active"
    Subsidized = "Project is subsidized"
    Category_code = "Preservation Catalog project category"
    Cat_At_Risk = "Project at risk"
    Cat_Expiring = "Project has upcoming expiring subsidy"
    Cat_Failing_Insp = "Project has failed recent REAC inspection"
    Cat_More_Info = "Project flagged for gathering more information"
    Cat_Lost = "Lost affordable housing"
    Cat_Replaced = "Replaced affordable housing"
    Proj_Name = "Project name"
    Proj_Addre = "Project main address"
    Proj_City = "Project city"
    Proj_ST = "Project state"
    Proj_Zip = "Project ZIP code"
    Proj_Units_Tot = "Total housing units in project"
    Proj_Units_Assist_Min = "Total assisted housing units in project (minimum)"
    Proj_Units_Assist_Max = "Total assisted housing units in project (maximum)"
    Hud_Own_Effect_dt = "Date current owner acquired property (from HUD)"
    Hud_Own_Name = "Current property owner name (from HUD)"
    Hud_Own_Type = "Current property owner type (from HUD)"
    Hud_Mgr_Name = "Current property manager name (from HUD)"
    Hud_Mgr_Type = "Current property manager type (from HUD)"
    Subsidy_Start_First = "First subsidy start date"
    Subsidy_Start_Last = "Last subsidy start date"
    Subsidy_End_First = "First subsidy end date"
    Subsidy_End_Last = "Last subsidy end date"
    Ward2012 = 'Ward (2012)'
    Anc2012 = 'Advisory Neighborhood Commission (2012)'
    Psa2012 = 'Police Service Area (2012)'
    Geo2010 = 'Full census tract ID (2010): ssccctttttt'
    Cluster_tr2000 = 'Neighborhood cluster (tract-based, 2000)'
    Cluster_tr2000_name = 'Neighborhood cluster names (tract-based, 2000)'
    Zip = 'ZIP code (5 digit)'
    Proj_image_url = 'OCTO property image URL'
    Proj_streetview_url = 'Google Street View URL'
    Proj_address_id = 'Project MAR address ID'
    Proj_x = 'Project longitude (MD State Plane Coord., NAD 1983 meters)'
    Proj_y = 'Project latitude (MD State Plane Coord., NAD 1983 meters)'
    Proj_lat = 'Project latitude'
    Proj_lon = 'Project longitude'
    Bldg_count = 'Number of buildings for project'
    Update_Dtm = "Datetime of last project update"
    PBCA = "Performance-Based Contract Administrator Program property"
  ;

  format Status $Status. Category_code $Categry. Hud_Own_Effect_dt mmddyy10.
    Hud_Own_type Hud_Mgr_type $ownmgrtype.
    Subsidized Cat_At_Risk Cat_Expiring Cat_Failing_Insp Cat_More_Info Cat_Lost Cat_Replaced PBCA dyesno.
    Update_Dtm datetime16.
  ;
 
  drop units  own_name own_type mgr_name mgr_type;
  
run;

** Add year built to Project **;

proc sql noprint;
  create table Parcel_yb as
    select a.nlihc_id, coalesce( a.ssl, b.ssl ) as ssl, coalesce( a.ayb, b.ayb ) as ayb, coalesce( a.eyb, b.eyb ) as eyb
    from RealProp.Camarespt_2014_03 as b right join (
      select a.nlihc_id, coalesce( a.ssl, b.ssl ) as ssl, coalesce( a.ayb, b.ayb ) as ayb, coalesce( a.eyb, b.eyb ) as eyb
      from RealProp.camacondopt_2013_08 as b right join (
        select a.nlihc_id, coalesce( a.ssl, b.ssl ) as ssl, b.ayb, b.eyb
        from RealProp.camacommpt_2013_08 as b right join 
        Parcel as a   
        on a.ssl = b.ssl ) as a 
      on a.ssl = b.ssl ) as a
    on a.ssl = b.ssl
    order by nlihc_id, ssl;
  quit;

data Parcel_yb_2;

  set Parcel_yb;
  
  if ayb < 1900 then ayb = .u;
  if eyb < 1900 then eyb = .u;

  label
    ayb = "Project year built (original)"
    eyb = "Project year built (improvements)";

  keep nlihc_id ayb eyb; 

  rename ayb=Proj_ayb eyb=Proj_eyb;

run;

proc summary data=Parcel_yb_2;
  by nlihc_id;
  var Proj_ayb Proj_eyb;
  output out=Project_yb (drop=_type_ _freq_) min=;
run;

** Add owner category to Project **;

proc summary data=Parcel nway; 
  class nlihc_id parcel_owner_type;
  output out=Project_owner;
run;

proc sort data=Project_owner;
  by nlihc_id descending _freq_;
run;

data Project_owner_nodup;

  set Project_owner;
  by nlihc_id;
  
  if first.nlihc_id;

  label
    Parcel_owner_type = "Project owner type (majority of parcels)";

  keep nlihc_id Parcel_owner_type; 

  rename Parcel_owner_type=Proj_owner_type;

run;

data add_project;

  merge
    add_project (in=in1)
    Project_yb
    Project_owner_nodup;
  by nlihc_id;
  
  if in1;
  
run;

data Project;
set PresCat.Project Add_Project;
run;

proc sort data=Project;
  by nlihc_id;
run;

%File_info( data=Project, printobs=5, 
            freqvars=Status Category_code Proj_City Proj_ST Ward2012 Proj_Zip Hud_Own_type Hud_Mgr_type PBCA )

title2 'File = PresCat.Project';

%Dup_check(
  data=Project,
  by=nlihc_id,
  id=Proj_name Proj_addre
)
title2;

proc print data=Project;
  where missing( Nlihc_id );
  var status Proj_name Proj_addre Proj_zip Ward2012;
  title2 '---MISSING NLIHC_ID---';
run;
title2;

proc print data=Project;
  where missing( Ward2012 );
  id nlihc_id;
  var status Proj_name Proj_addre Proj_zip Ward2012;
  title2 '---MISSING WARD---';
run;
title2;

proc freq data=Project;
  tables Hud_Own_Effect_dt;
  tables Category_code * Cat_At_Risk * Cat_Expiring * Cat_Failing_Insp * Cat_More_Info * Cat_Lost 
         * Cat_Replaced 
    / list missing nocum nopercent;
  format Hud_Own_Effect_dt year.;
run;

**** Compare with earlier version ****;

proc compare base=Prescat.project compare=Project listall maxprint=(40,32000);
  id nlihc_id;
run;
