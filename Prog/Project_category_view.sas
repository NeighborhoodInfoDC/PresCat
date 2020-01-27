/**************************************************************************
 Program:  Project_category_view.sas
 Library:  PresCat
 Project:  Urban-Greater DC
 Author:   P. Tatian
 Created:  03/31/16
 Version:  SAS 9.2
 Environment:  Local Windows session (desktop)
 
 Description:  Create SAS View with combined Project and
 Project_category data sets.

 Modifications:
  03/16/2019 PAT Updated query. GitHub issue #190.
**************************************************************************/

%include "L:\SAS\Inc\StdLocal.sas";

** Define libraries **;
%DCData_lib( PresCat )

proc sql noprint;
  create view PresCat.Project_category_view (label="Preservation Catalog, Project + Project_Category") as
    select 
      coalesce( Project.Nlihc_id, Category.Nlihc_id ) as Nlihc_id label="Preservation Catalog project ID",
      Project.proj_addre,
      Project.Status,
      Project.Cat_Expiring,
      Project.Cat_Failing_Insp,
      Project.Proj_City,
      Project.Proj_ST,
      Project.Proj_Units_Tot,
      Project.Hud_Own_Effect_dt,
      Project.Hud_Own_Name,
      Project.Hud_Own_Type,
      Project.Hud_Mgr_Name,
      Project.Hud_Mgr_Type,
      Project.PBCA,
      Project.Update_Dtm,
      Project.Subsidy_info_source_property,
      Project.contract_number,
      Project.Subsidy_Start_First,
      Project.Subsidy_End_First,
      Project.Subsidy_Start_Last,
      Project.Subsidy_End_Last,
      Project.Subsidized,
      Project.Proj_Units_Assist_Min,
      Project.Proj_Units_Assist_Max,
      Project.Anc2012,
      Project.Psa2012,
      Project.Geo2010,
      Project.Cluster_tr2000,
      Project.Cluster_tr2000_name,
      Project.Ward2012,
      Project.Proj_zip,
      Project.Zip,
      Project.Proj_image_url,
      Project.Proj_streetview_url,
      Project.Proj_address_id,
      Project.Proj_x,
      Project.Proj_y,
      Project.Proj_lat,
      Project.Proj_lon,
      Project.Bldg_count,
      Project.Proj_ayb,
      Project.Proj_eyb,
      Project.Proj_owner_type,
      Project.Added_to_catalog,
      Category.Proj_name,
      Category.Category_Code,
      ( Category.Category_Code = '1' ) as Cat_at_risk label="Project at risk" format=dyesno. length=3,
      ( Category.Category_Code = '4' ) as Cat_more_info label="Project flagged for gathering more information" format=dyesno. length=3,
      ( Category.Category_Code = '6' ) as Cat_lost label="Lost affordable housing" format=dyesno. length=3,
      ( Category.Category_Code = '7' ) as Cat_replaced label="Replaced affordable housing" format=dyesno. length=3
    from 
      PresCat.Project as Project 
    left join 
      PresCat.Project_category as Category
    on Project.Nlihc_id = Category.Nlihc_id
    order by Project.Nlihc_id;
  quit;

run;

%File_info( data=PresCat.Project_category_view )

** Check Cat_ values **;

proc freq data=PresCat.Project_category_view;
  tables Category_code * Cat_at_risk * Cat_lost * cat_more_info * cat_replaced / missing list nopercent nocum;
run;

** Update metadata **;

%Dc_update_meta_file(
  ds_lib=PresCat,
  ds_name=Project_category_view,
  creator_process=Project_category_view.sas,
  restrictions=None,
  revisions=%str(Apply update from LEC_Database_10Jan20_LEC_or_Affordable.csv.)
)

/*****************************************
** Temporary testing code **;

data Base; 

  set PresCat.Project_category_view;
  
run;

data Compare;

  set Project_category_view;

run;

proc compare base=Base compare=Compare listall maxprint=(40,32000);
  id nlihc_id;
run;

