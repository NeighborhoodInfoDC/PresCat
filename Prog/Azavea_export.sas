/**************************************************************************
 Program:  Azavea_export.sas
 Library:  PresCat
 Project:  NeighborhoodInfo DC
 Author:   P. Tatian
 Created:  08/11/13
 Version:  SAS 9.1
 Environment:  Windows
 
 Description:  Export data files for Avazea.

 Modifications:
  10/27/13 PAT Incorporated subsidy vars: Portfolios, Agencies, subsidy
               status and starting year. 
               Added Bldg_count.
               Fixed Subsidized variable.
  10/28/13 PAT Replaced Subsidized var with version in Project data set.
  03/11/14 PAT Added n/a for Parcel_owner_type.
**************************************************************************/

%include "K:\Metro\PTatian\DCData\SAS\Inc\Stdhead.sas";
/*%include "C:\DCData\SAS\Inc\Stdhead.sas";*/

** Define libraries **;
%DCData_lib( PresCat )
%DCData_lib( RealProp )

options missing=' ';

proc format;
  value $substat
    'N' = 'Never'
    'C' = 'Current'
    'F' = 'Former';
run;

**** Collapse subsidy data by project ****;

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
  
  if Portfolios = "" then Portfolios = Portfolio;
  else if indexw( compress( Portfolios ), compress( Portfolio ), ';' ) = 0 then 
    Portfolios = trim( Portfolios ) || "; " || Portfolio;
 
  select ( Portfolio );
  
    /** HUD financing/insurance programs **/
    when ( "Section 202/811", 
           "Section 221(d)(3) below market rate interest (BMIR)",
           "Section 221(d)(3)&(4) with affordability restrictions",
           "Section 236",
           "Section 542(b)&(c)"
          ) do;
      if Subsidy_active then Hud_Fin_Ins_Status = "C";
      else Hud_Fin_Ins_Status = "F";
      Hud_Fin_Ins_Year = year( POA_start );
    end;
    
    /** HUD project-based rental assistance **/
    when ( "Project-based Section 8",
           "Project Rental Assistance Contract (PRAC)" ) do;
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
      
    /** DC HPTF **/
    when ( "DC Housing Production Trust Fund" ) do;
      if Subsidy_active then DC_HPTF_Status = "C";
      else DC_HPTF_Status = "F";
      DC_HPTF_Year = year( POA_start );
    end;

    /** DC IZ/ADU **/
    when ( "DC Inclusionary Zoning/ADU" ) do;
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
    coalesce( Project.NLIHC_ID, Subsidy.NLIHC_ID ) as NLIHC_ID, 
    Status,
    Subsidized,
    Category,
    Proj_Name,
    Proj_Addre,
    Proj_City,
    Proj_ST,
    Proj_Zip,
    Proj_Units_Tot,
    Proj_Units_Assist_Min,
    Proj_Units_Assist_Max,
    Bldg_count,
    Own_Effect,
    Own_Name,
    "" as Own_Type,
    Mgr_Name,
    "" as Mgr_Type,
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
    Geo2010 as Census_Tract_2010,
    Proj_X,
    Proj_Y,
    Proj_lat,
    Proj_lon,
    Proj_Streetview_url as Streetview_url,
    Proj_Image_url as Image_url
  from PresCat.Project as Project 
    left join Subsidy_project as Subsidy
  on Project.Nlihc_id = Subsidy.Nlihc_id 
  where not( missing( Proj_lat ) ) and not( missing( Proj_lon ) ) 
  order by NLIHC_ID;
quit;

**** Clean up missing values for projects not in subsidy table ****;

data Project;

  set Project;
  
  if missing( Subsidized ) then Subsidized = 0;
  
  array a{*} Hud_Fin_Ins_Status HUD_PBRA_Status LIHTC_Status DC_HPTF_Status DC_IZ_ADU_Status;
  
  do i = 1 to dim( a );
    if missing( a{i} ) then a{i} = 'N';
  end;
  
  drop i;
  
run;

filename fexport "&_dcdata_path\PresCat\Raw\Project.csv" lrecl=3000;

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
    Subsidy_Active,
    Program,
    Subsidy,
    Contract_Number,
    Units_Assist,
    POA_Start,
    POA_End,
    Subsidy_Info_Source,
    "" as Subsidy_Notes,
    Update_Date as Subsidy_Update
  from PresCat.Subsidy
  order by NLIHC_ID;
quit;

filename fexport "&_dcdata_path\PresCat\Raw\Subsidy.csv" lrecl=2000;

proc export data=Subsidy
    outfile=fexport
    dbms=csv replace;

run;

filename fexport clear;


******  REAC_score  ******;

proc sql noprint;
  create table REAC_score as
  select 
    NLIHC_ID,
    Reac_date,
    Reac_score,
    Reac_score_num,
    Reac_score_letter
  from PresCat.Reac_score
  order by NLIHC_ID;
quit;

filename fexport "&_dcdata_path\PresCat\Raw\REAC_score.csv" lrecl=2000;

proc export data=Reac_score
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
    Parcel_type,
    Parcel_owner_name,
    Parcel_owner_date,
    "n/a" as Parcel_owner_type,
    "" as Parcel_units,
    Parcel_x,
    Parcel_y
  from Parcel_bis
  order by NLIHC_ID;
quit;

filename fexport "&_dcdata_path\PresCat\Raw\Parcel.csv" lrecl=2000;

proc export data=Parcel
    outfile=fexport
    dbms=csv replace;

run;

filename fexport clear;


******  Real Property  ******;

proc sql noprint;
  create table Real_property as
  select 
    NLIHC_ID,
    ssl,
    rp_date,
    rp_type,
    rp_desc
  from PresCat.Real_property
  order by NLIHC_ID, RP_date desc, sort_order desc;
quit;

filename fexport "&_dcdata_path\PresCat\Raw\Real_property.csv" lrecl=2000;

proc export data=Real_property
    outfile=fexport
    dbms=csv replace;

run;

filename fexport clear;

