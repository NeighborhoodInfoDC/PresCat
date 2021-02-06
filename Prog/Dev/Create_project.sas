/**************************************************************************
 Program:  Create_project.sas
 Library:  PresCat
 Project:  NeighborhoodInfo DC
 Author:   P. Tatian
 Created:  07/25/13
 Version:  SAS 9.1
 Environment:  Local Windows session (desktop)
 
 Description:  Create first Projects data set from Access DB DC_Info table.

 Modifications:
  10/27/13 PAT Added Subsidy_Start_First and Subsidy_Start_Last.
               Merge with new geocoding file (PresCat.Project_geocode).
  10/28/13 PAT Added Subsidized var. Changed Cat_* vars to numeric.
               Dropped Subsidy_PH, Subsidy_LIHTC.
  09/27/14 PAT Updated for SAS1.
  10/19/14 PAT Updated DC_info file.
               Corrected min/max assisted units calculation so that 
               units are first summed by program. 
  12/18/14 PAT Created Own_Type and Mgr_Type vars. 
               Labeled all variables. Dropped unnecessary variables.               
  01/29/15 PAT Assigning NLIHC_IDs to 1919 Calvert Street NW (NL001031), 
               Congress Heights PUD (NL001032).
  06/18/15 PAT Change category for Wah Luck to 2 (expiring).
  08/31/15 PAT Replace PresCat.DC_Info_10_19_14 with PresCat.DC_Info_07_08_15.
  09/03/15 PAT Add PBCA flag to data set.
**************************************************************************/

%include "\\sas1\DCdata\SAS\Inc\StdLocal.sas";

** Define libraries **;
%DCData_lib( PresCat, local=n )

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

data DC_Info;

  set PresCat.DC_Info_07_08_15;
  
  ** Apply standard corrections **;
  
  %DCInfo_corrections()
  
  ** Missing project IDs **;
  
  select ( Proj_name );
    when ( '1919 Calvert Street NW' )
      Nlihc_id = 'NL001031';
    when ( 'CONGRESS HEIGHTS PUD' )
      Nlihc_id = 'NL001032';
    otherwise
      /** Do nothing **/;
  end;
  
run;  

proc sort data=DC_Info;
  by Nlihc_id;

title2 'File = DC_Info';

%Dup_check(
  data=DC_Info,
  by=Nlihc_id,
  id=proj_name proj_addre category,
  out=_dup_check,
  listdups=Y,
  count=dup_check_count,
  quiet=N,
  debug=N
)

title2;

data PresCat.Project (label="Preservation Catalog, projects");

  length
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
    Hud_Own_Effect_dt 8
    Hud_Own_Name $ 80
    Hud_Own_Type $ 2
    Hud_Mgr_Name $ 80
    Hud_Mgr_Type $ 2
    Subsidy_Start_First 8
    Subsidy_Start_Last 8
    Subsidy_End_First 8
    Subsidy_End_Last 8
    Ward2012 $ 1
    ;

  merge 
    DC_Info 
      (keep=NLIHC_ID Category Proj_Name Proj_Addre Proj_City Proj_ST 
            Units Own_Effect Own_Compan Own_Comp_1 Own_Indivi Mgr_Compan 
            Mgr_Comp_1 Mgr_Indivi PBCA
       rename=(Proj_Name=Proj_Name_old Proj_Addre=Proj_Addre_old)
       in=in1)
    PresCat.Project_geocode (drop=Proj_name)
    Subsidy (keep=Nlihc_id Proj_Units_Assist_: Subsidy_Start_: Subsidy_End_: Subsidized)
            ;
  by Nlihc_id;
  
  ***if in1;
  
  %Project_name_clean( Proj_name_old, Proj_name )
  
  ** DROP DUPLICATES OF NL001007 **;
  
  if nlihc_id = "NL001007" and proj_addre = "401 Chaplin St, SE" then delete;
  
  ** 54th Street Housing **;
  
  ** New Catalog projects **;
  
  select ( Nlihc_id );

    when ( "NL001030" ) do;
      Subsidized = 1;
    end;
      
    when ( "NL001031" ) do;
      Subsidized = 1;
    end;
      
    when ( "NL001033" ) do;
      Category = '5';
      Subsidized = 1;
      Proj_name = '54th Street Housing';
      Proj_city = 'Washington';
      Proj_st = 'DC';
    end;
    
    otherwise
      /** Do nothing **/;
    
  end;
  
  Category_Code = Category;
  
  if Category_Code ~= '6' then Status = 'A';
  else Status = 'I';
  
  array cat{*} Cat_: ;
  
  do i = 1 to dim( cat );
    cat{i} = 0;
  end;
  
  select ( Category_code );
    when ( '1' )
      Cat_At_Risk = 1;
    when ( '2' )
      Cat_Expiring = 1;
    when ( '3' )
      Cat_Failing_Insp = 1;
    when ( '4' )
      Cat_More_Info = 1;
    when ( '5' )
      /** Skip category 5 **/;
    when ( '6' )
      Cat_Lost = 1;
    when ( '7' )
      Cat_Replaced = 1;
    otherwise
      do;
        %warn_put( msg="Invalid Category value. " _n_= NLIHC_ID= Category= Category_code= )
      end;
  end;
  
  ** Mark projects with subsidy less than one year away as expiring **;
  
  if -100 < intck( 'year', Subsidy_End_First, date() ) < 1 then Cat_Expiring = 1;

  Proj_units_tot = Units;
  
  Hud_Own_Effect_dt = Own_Effect;
  
  array a{*} Proj_Addre Proj_City Own_Compan Own_Indivi Mgr_Compan 
          Mgr_Indivi;
  
  do i = 1 to dim( a );
    if a{i} = upcase( a{i} ) then a{i} = propcase( a{i} );
  end;
  
  if Proj_City = "Wash" then Proj_City = "Washington";
  
  if Own_Compan ~= "" then do;
  
    Hud_Own_Name = left( Own_Compan );
    
    if Own_Indivi ~= "" then Hud_Own_Name = trim( Hud_Own_Name ) || ' / ' || left( Own_Indivi );

    select ( Own_comp_1 );
      when ( 'Limited Dividend' ) Hud_Own_type = 'LD';
      when ( 'Non-Profit' ) Hud_Own_type = 'NP';
      when ( 'Non-Profit Controlled' ) Hud_Own_type = 'NC';
      when ( 'Other' ) Hud_Own_type = 'OT';
      when ( 'PHA' ) Hud_Own_type = 'HA';
      when ( 'Profit Motivated' ) Hud_Own_type = 'PM';
      when ( '' ) Hud_Own_type = '  ';
      otherwise do;
        %warn_put( msg='Unknown company type: ' _n_= nlihc_id= Hud_Own_name= Own_comp_1= )
      end;
    end;
  
  end;
  else do;
  
    Hud_Own_Name = left( Own_Indivi );
    Hud_Own_type = 'IN';
  
  end;
  
  if Mgr_Compan ~= "" then do;
  
    Hud_Mgr_Name = left( Mgr_Compan );
    
    if Mgr_Indivi ~= "" then Hud_Mgr_Name = trim( Hud_Mgr_Name ) || ' / ' || left( Mgr_Indivi );
    
    select ( Mgr_comp_1 );
      when ( 'Limited Dividend' ) Hud_Mgr_type = 'LD';
      when ( 'Non-Profit' ) Hud_Mgr_type = 'NP';
      when ( 'Non-Profit Controlled' ) Hud_Mgr_type = 'NC';
      when ( 'Other' ) Hud_Mgr_type = 'OT';
      when ( 'PHA' ) Hud_Mgr_type = 'HA';
      when ( 'Profit Motivated', 'Proft Motivated' ) Hud_Mgr_type = 'PM';
      when ( '' ) Hud_Mgr_type = '  ';
      otherwise do;
        %warn_put( msg='Unknown company type: ' _n_= nlihc_id= Hud_Mgr_name= Mgr_comp_1= )
      end;
    end;
    
  end;
  else do;
  
    Hud_Mgr_Name = left( Mgr_Indivi );
    Hud_Mgr_type = 'IN';
    
  end;
  
  Update_Dtm = datetime();
  
  ** Subsidy status **;
  
  if missing( Subsidized ) then Subsidized = 0;
  
  **** CORRECTIONS ****;
  
  if nlihc_id = 'NL000208' then do;
    ** Museum Square One **;
    Cat_Expiring = 1;
  end;
  
  if nlihc_id = 'NL000319' then do;
    ** Wah Luck House **;
    Category_code = '2';
  end;
  
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
    Proj_Name_old = "Old project name from Access DB"
    Proj_Addre_old = "Old project address from Access DB"
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
 
  drop i units category Own_Effect Own_Compan Own_Comp_1 Own_Indivi Mgr_Compan Mgr_Comp_1 Mgr_Indivi;
  
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

proc compare base=Comp.Project compare=PresCat.Project listall maxprint=(40,32000);
  id nlihc_id;
run;
