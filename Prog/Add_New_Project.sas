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
%DCData_lib( PresCat, local=n )


data project_old;
	set prescat.project;
	run;

** Import project info and match to NLIHC_ID **;
	filename fimport "D:\DCData\Libraries\PresCat\Raw\Buildings_for_geocoding_2016-08-01_status.csv" lrecl=2000;

data WORK.PROJECT_STATUS    ;
%let _EFIERR_ = 0; /* set the ERROR detection macro variable */
infile FIMPORT delimiter = ',' MISSOVER DSD lrecl=32767 firstobs=2 ;
informat Proj_Name $20. ;
informat NLIHC_ID $8. ;
informat MARID best32. ;
informat At_Risk 3. ;
informat Failing_Inspection 3. ;
informat More_Info 3. ;
informat Lost 3. ;
informat Replaced 3. ;
informat Own_Name $60. ;
informat Own_Type $20. ;
informat Mgr_Name $60. ;
informat Mgr_Type $20. ;
format Proj_Name $20. ;
format NLIHC_ID $8. ;
format MARID best12. ;
format At_Risk DYESNO3. ;
format Failing_Inspection DYESNO3. ;
format More_Info DYESNO3. ;
format Lost DYESNO3. ;
format Replaced DYESNO3. ;
format Own_Name $60. ;
format Own_Type $20. ;
format Mgr_Name $60. ;
format Mgr_Type $20. ;
input
Proj_Name $
NLIHC_ID $
Bldg_SSL $
Bldg_City $
Bldg_ST $
MARID
At_Risk 
Failing_Inspection 
More_Info 
Lost 
Replaced $
Own_Name $
Own_Type $
Mgr_Name $
Mgr_Type $
     ;
if _ERROR_ then call symputx('_EFIERR_',1);  /* set ERROR detection macro variable */
run;

filename fimport clear;

proc sort data=project_status;
by marid;
run;

proc sort data=tmp1.building_geocode;
by bldg_address_id;
run;

data Project_Status;

	merge Project_Status (rename=(marid=Proj_address_id)) 
	prescat.Building_Geocode (keep = nlihc_id bldg_address_id rename=(bldg_address_id=proj_address_id));
	by Proj_address_id;
	if proj_name = "" then delete;
	run;

proc sort data=Project_Status out=Status;
	by nlihc_id;
	run;

** Get min/max assisted units **;

proc summary data=PresCat.Subsidy nway;
  class Nlihc_id Program;
  var units_assist poa_start poa_end Subsidy_active;
  output out=Subsidy_a 
    sum(units_assist)=
    min(poa_start poa_end)=Subsidy_Start_First Subsidy_End_First
    max(poa_start poa_end)=Subsidy_Start_Last Subsidy_End_Last
    max(Subsidy_active)=Subsidized;
run;

proc summary data=Subsidy_a;
  by Nlihc_id;
  var units_assist Subsidy_Start_First Subsidy_End_First Subsidy_Start_Last Subsidy_End_Last Subsidized;
  output out=Subsidy 
    min(units_assist Subsidy_Start_First Subsidy_End_First)=Proj_Units_Assist_Min Subsidy_Start_First Subsidy_End_First
    max(units_assist Subsidy_Start_Last Subsidy_End_Last)=Proj_Units_Assist_Max Subsidy_Start_Last Subsidy_End_Last
    max(Subsidized)=;
run;

data Project_New (label="Preservation Catalog, projects update");

  */length
    Nlihc_id $ 8
    Status $ 1
    Subsidized 3
    Category_Code $ 1 
    Cat_At_Risk 3
    Cat_Expiring 3
    Cat_Failing_Insp 3
    Cat_More_Info 3
    Cat_Lost 3
    Cat_Replaced 3
    Proj_Name $ 80
    Proj_Addre $ 160
    Proj_City $ 80
    Proj_ST $ 2
    Proj_Zip $ 5
    Proj_Units_Tot 8
    Proj_Units_Assist_Min 8
    Proj_Units_Assist_Max 8
    Subsidy_Start_First 8
    Subsidy_Start_Last 8
    Subsidy_End_First 8
    Subsidy_End_Last 8
	Ward2012 $ 1
	own_name $60
	own_type $20
	mgr_name $60
	mgr_type $20
    */;

  merge 
	PresCat.Project_geocode
    Subsidy (keep=Nlihc_id Proj_Units_Assist_: Subsidy_Start_: Subsidy_End_: Subsidized)
	Status (keep=nlihc_id at_risk failing_inspection more_info lost replaced own_name own_type mgr_name mgr_type 
					rename=(at_risk=cat_at_risk failing_inspection=cat_failing_insp more_info=cat_more_info lost=cat_lost replaced=cat_replaced))
            ;
  by Nlihc_id;
  
  ***if in1;
  
  **%Project_name_clean( Proj_name_old, Proj_name );
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
  if cat_more_info = . then cat_more_info = 1;
  if cat_lost = . then cat_lost = 0;
  if cat_replaced = . then cat_replaced = 0;

  if category_code = "" then category_code = "5";
  
  if category_code = "6" then status = "I";
  else status = "A";

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

data PresCat.Project;
set PresCat.Project Add_Project;
run;

proc sort data=PresCat.Project;
  by nlihc_id;
run;

%File_info( data=PresCat.Project, printobs=5, 
            freqvars=Status Category_code Proj_City Proj_ST Ward2012 Proj_Zip Hud_Own_type Hud_Mgr_type PBCA )

title2 'File = PresCat.Project';

%Dup_check(
  data=PresCat.Project,
  by=nlihc_id,
  id=Proj_name Proj_addre
)
title2;

proc print data=PresCat.Project;
  where missing( Nlihc_id );
  var status Proj_name Proj_addre Proj_zip Ward2012;
  title2 '---MISSING NLIHC_ID---';
run;
title2;

proc print data=PresCat.Project;
  where missing( Ward2012 );
  id nlihc_id;
  var status Proj_name Proj_addre Proj_zip Ward2012;
  title2 '---MISSING WARD---';
run;
title2;

proc freq data=PresCat.Project;
  tables Hud_Own_Effect_dt;
  tables Category_code * Cat_At_Risk * Cat_Expiring * Cat_Failing_Insp * Cat_More_Info * Cat_Lost 
         * Cat_Replaced 
    / list missing nocum nopercent;
  format Hud_Own_Effect_dt year.;
run;

**** Compare with earlier version ****;

libname comp 'D:\DCData\Libraries\PresCat\Data\Old';

proc compare base=project_old compare=PresCat.Project listall maxprint=(40,32000);
  id nlihc_id;
run;
