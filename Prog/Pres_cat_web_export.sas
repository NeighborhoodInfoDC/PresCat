/**************************************************************************
 Program:  Pres_cat_web_export.sas
 Library:  PresCat
 Project:  NeighborhoodInfo DC
 Author:   P. Tatian
 Created:  03/24/16
 Version:  SAS 9.2
 Environment:  Windows
 
 Description:  Export data files for Preservation Catalog web site.

 Modifications:
**************************************************************************/

%include "L:\SAS\Inc\StdLocal.sas"; 

** Define libraries **;
%DCData_lib( PresCat, local=n )
%DCData_lib( RealProp, local=n )

options missing=' ';

proc format;
  value $substat
    'N' = 'Never'
    'C' = 'Current'
    'F' = 'Former';
run;

**** Collapse subsidy data by project ****;

proc freq data=PresCat.Subsidy;
  tables portfolio;
  format portfolio ;
run;

data Subsidy_project;

  set PresCat.Subsidy;
  by nlihc_id;
  
  length Agencies Portfolios $ 500 
    Hud_Fin_Ins_Status HUD_PBRA_Status LIHTC_Status DC_HPTF_Status DC_IZ_ADU_Status $ 1;
    
  retain Agencies Portfolios 
    Hud_Fin_Ins_Status HUD_PBRA_Status LIHTC_Status DC_HPTF_Status DC_IZ_ADU_Status
    Hud_Fin_Ins_Year HUD_PBRA_Year LIHTC_Year DC_HPTF_Year DC_IZ_ADU_Year;
    
  if first.Nlihc_id then do;
    Agencies = "";
    Portfolios = "";
    Hud_Fin_Ins_Status = "N";
    HUD_PBRA_Status = "N";
    LIHTC_Status = "N";
    DC_HPTF_Status = "N";
    DC_IZ_ADU_Status = "N";
    Hud_Fin_Ins_Year = .;
    HUD_PBRA_Year = .;
    LIHTC_Year = .;
    DC_HPTF_Year = .;
    DC_IZ_ADU_Year = .;
  end;
  
  if Agencies = "" then Agencies = Agency;
  else if indexw( compress( Agencies ), compress( Agency ), ';' ) = 0 then 
    Agencies = trim( Agencies ) || "; " || Agency;
  
  if Portfolios = "" then Portfolios = put( Portfolio, $portfolio. );
  else if indexw( compress( Portfolios ), compress( Portfolio ), ';' ) = 0 then 
    Portfolios = trim( Portfolios ) || "; " || put( Portfolio, $portfolio. );
 
  select ( Portfolio );
  
    /** HUD financing/insurance programs **/
    when ( "202/811", 
           "HUDMORT"
          ) do;
      if Subsidy_active then Hud_Fin_Ins_Status = "C";
      else Hud_Fin_Ins_Status = "F";
      Hud_Fin_Ins_Year = year( POA_start );
    end;
    
    /** HUD project-based rental assistance **/
    when ( "PB8",
           "PRAC" ) do;
      if Subsidy_active then Hud_PBRA_Status = "C";
      else Hud_PBRA_Status = "F";
      Hud_PBRA_Year = year( POA_start );
    end;
    
    /** LIHTC **/
    when ( "LIHTC" ) do;
      if Subsidy_active then LIHTC_Status = "C";
      else LIHTC_Status = "F";
      LIHTC_Year = year( POA_start );
    end;
      
    /** DC Housing Production Trust Fund **/
    when ( "DC HPTF" ) do;
      if Subsidy_active then DC_HPTF_Status = "C";
      else DC_HPTF_Status = "F";
      DC_HPTF_Year = year( POA_start );
    end;

    /** DC Inclusionary Zoning/ADU **/
    when ( "DC IZ/ADU" ) do;
      if Subsidy_active then DC_IZ_ADU_Status = "C";
      else DC_IZ_ADU_Status = "F";
      DC_IZ_ADU_Year = year( POA_start );
    end;

    otherwise
      /** DO NOTHING **/
      ;
 end;

 if last.Nlihc_id then do;
   output;
 end;
 
 format 
   Hud_Fin_Ins_Status HUD_PBRA_Status LIHTC_Status DC_HPTF_Status DC_IZ_ADU_Status $substat.;

 keep Nlihc_id Agencies Portfolios 
    Hud_Fin_Ins_Status HUD_PBRA_Status LIHTC_Status DC_HPTF_Status DC_IZ_ADU_Status
    Hud_Fin_Ins_Year HUD_PBRA_Year LIHTC_Year DC_HPTF_Year DC_IZ_ADU_Year;
    
run;

/*%File_info( data=Subsidy_project, printobs=50 )*/

******   Project   ******;

proc sql noprint;
  create table Project as
  select 
    coalesce( Project_category.NLIHC_ID, Subsidy.NLIHC_ID ) as NLIHC_ID, 
    Status,
    Subsidized,
    put( category_code, $categrn. ) as Category,
    Proj_Name,
    Proj_Addre,
    Proj_City,
    Proj_ST,
    Proj_Zip,
    Proj_Units_Tot,
    Proj_Units_Assist_Min,
    Proj_Units_Assist_Max,
    Bldg_count,
    Hud_own_effect_dt as Own_Effect,
    Hud_own_name as Own_Name,
    Hud_Own_Type as Own_Type,
    Hud_Mgr_Name as Mgr_Name,
    Hud_Mgr_type as Mgr_Type,
    Subsidy_End_First,
    Subsidy_End_Last,
    Agencies,
    Portfolios, 
    Hud_Fin_Ins_Status,
    Hud_Fin_Ins_Year,
    HUD_PBRA_Status,
    HUD_PBRA_Year,
    LIHTC_Status,
    LIHTC_Year,
    DC_HPTF_Status,
    DC_HPTF_Year,
    DC_IZ_ADU_Status,
    DC_IZ_ADU_Year,
    Ward2012,
    ANC2012,
    PSA2012,
    Cluster_tr2000,
    Cluster_tr2000_name,
    /*put( Cluster_tr2000, $clus00f. ) as Cluster_combo,*/
    Geo2010 as Census_Tract_2010,
    "" as Blank1,
    "" as Blank2,
    Proj_lat,
    Proj_lon,
    Proj_Streetview_url as Streetview_url,
    Proj_Image_url as Image_url
  from
    ( select * from 
      PresCat.Project (drop=Category_code) as Project 
      left join PresCat.Project_category (keep=nlihc_id Category_code) as Category
      on Project.Nlihc_id = Category.Nlihc_id ) as Project_category
    left join Subsidy_project as Subsidy
  on Project_category.Nlihc_id = Subsidy.Nlihc_id 
  where not( missing( Proj_lat ) ) and not( missing( Proj_lon ) ) 
  order by NLIHC_ID;
quit;

**** Clean up missing values ****;

data Project;

  set Project;
  
  if missing( Subsidized ) then Subsidized = 0;
  
  ** Projects not in subsidy table **;
  
  array a{*} Hud_Fin_Ins_Status HUD_PBRA_Status LIHTC_Status DC_HPTF_Status DC_IZ_ADU_Status;
  
  do i = 1 to dim( a );
    if missing( a{i} ) then a{i} = 'N';
  end;
  
  ** Change user missing values to . **;
  
  array b{*} Proj_Units_Assist_Min Proj_Units_Assist_Max Subsidy_End_First Subsidy_End_Last;
  
  do i = 1 to dim( b );
    if missing( b{i} ) then b{i} = .;
  end;
  
  drop i;
  
run;

filename fexport "&_dcdata_r_path\PresCat\Raw\Web\Project.csv" lrecl=3000;

proc export data=Project
    outfile=fexport
    dbms=csv replace;

run;

filename fexport clear;


******  Subsidy  ******;

proc sql noprint;
  create table Subsidy as
  select 
    NLIHC_ID,
    Subsidy_Active as SubsidyActive,
    Program as ProgramName,
    Portfolio as Subsidy,
    Contract_Number as Contractnumber,
    Units_Assist as UnitsAssist,
    POA_Start as programactivestart,
    POA_End as programactiveend,
    Subsidy_Info_Source as SubsidyInfoSource ,
    "" as SubsidyNotes,
    Subsidy_info_source_date as SubsidyUpdate
  from PresCat.Subsidy
  order by NLIHC_ID;
quit;

** Recode missing values **;

data Subsidy;

  set Subsidy;
  
  ** Change user missing values to . **;

  array a{*} SubsidyUpdate;
  
  do i = 1 to dim( a );
    if missing( a{i} ) then a{i} = .;
  end;
  
  drop i;
  
run;
  
filename fexport "&_dcdata_r_path\PresCat\Raw\Web\Subsidy.csv" lrecl=2000;

proc export data=Subsidy
    outfile=fexport
    dbms=csv replace;

run;

filename fexport clear;


******  REAC  ******;

proc sql noprint;
  create table REAC as
  select 
    NLIHC_ID,
    Reac_date as scoredate,
    Reac_score as score,
    Reac_score_num as scorenum,
    trim( Reac_score_letter ) || Reac_score_star as scoreletter
  from PresCat.Reac_score
  order by NLIHC_ID;
quit;

filename fexport "&_dcdata_r_path\PresCat\Raw\Web\REAC.csv" lrecl=2000;

proc export data=Reac
    outfile=fexport
    dbms=csv replace;

run;

filename fexport clear;


******  Parcel  ******;

data Parcel_bis;

  set PresCat.Parcel;
  
  if missing( Parcel_owner_date ) then Parcel_owner_date = .;
  
run;

proc sql noprint;
  create table Parcel as
  select 
    NLIHC_ID,
    ssl,
    Parcel_type as parceltype,
    Parcel_owner_name as ownername,
    Parcel_owner_date as ownerdate,
    Parcel_owner_type as ownertype,
    "" as units,
    Parcel_x as x,
    Parcel_y as y
  from Parcel_bis
  order by NLIHC_ID;
quit;

filename fexport "&_dcdata_r_path\PresCat\Raw\Web\Parcel.csv" lrecl=2000;

proc export data=Parcel
    outfile=fexport
    dbms=csv replace;

run;

filename fexport clear;


******  Real Property  ******;

proc sql noprint;
  create table RealPropertyEvent as
  select 
    NLIHC_ID,
    ssl,
    rp_date as eventdate,
    rp_type as eventtype,
    rp_desc as eventdescription
  from PresCat.Real_property
  order by NLIHC_ID, RP_date desc;
quit;

filename fexport "&_dcdata_r_path\PresCat\Raw\Web\RealPropertyEvent.csv" lrecl=2000;

proc export data=RealPropertyEvent
    outfile=fexport
    dbms=csv replace;

run;

filename fexport clear;

