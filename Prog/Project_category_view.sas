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
  07/21/2022 EB updated to include 20 census geos, 17 nbhd cluster, 22 wards. Issue #292
  07/09/2025 PT Add ANC2023.
  07/17/2025 PT Add Place_name, Place_name_id.
**************************************************************************/

%include "\\sas1\DCdata\SAS\Inc\StdLocal.sas";

** Define libraries **;
%DCData_lib( PresCat )

%let revisions = %str( Add Place_name, Place_name_id. );

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
      Project.Proj_ayb,
      Project.Proj_eyb,
      Project.Proj_owner_type,
      Project.Added_to_catalog,
      Category.Proj_name,
      Category.Category_Code,
      ( Category.Category_Code = '1' ) as Cat_at_risk label="Project at risk" format=dyesno. length=3,
      ( Category.Category_Code = '4' ) as Cat_more_info label="Project flagged for gathering more information" format=dyesno. length=3,
      ( Category.Category_Code = '6' ) as Cat_lost label="Lost affordable housing" format=dyesno. length=3,
      ( Category.Category_Code = '7' ) as Cat_replaced label="Replaced affordable housing" format=dyesno. length=3,
      Geocode.Anc2012,
      Geocode.Anc2023,
      Geocode.Psa2012,
      Geocode.Geo2010,
      Geocode.Cluster_tr2000,
      Geocode.Cluster_tr2000_name,
      Geocode.Ward2012,
      Geocode.Proj_zip,
      Geocode.Zip,
      Geocode.Proj_image_url,
      Geocode.Proj_streetview_url,
      Geocode.Proj_address_id,
      Geocode.Proj_x,
      Geocode.Proj_y,
      Geocode.Proj_lat,
      Geocode.Proj_lon,
      Geocode.Bldg_count,
      Geocode.Proj_units_mar,
	  Geocode.Geo2020,
	  Geocode.GeoBg2020,
	  Geocode.GeoBlk2020,
	  Geocode.Ward2022,
	  Geocode.cluster2017,
	  put( Geocode.cluster2017, $clus17b. ) as cluster2017_name length=120 label="Neighborhood cluster names (2017)",
	  Geocode.Place_name,
	  Geocode.Place_name_id
    from 
      PresCat.Project as Project 
    left join 
      PresCat.Project_category as Category
    on Project.Nlihc_id = Category.Nlihc_id
    left join
      PresCat.Project_geocode as Geocode
    on Project.Nlihc_id = Geocode.Nlihc_id
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
  revisions=%str(&revisions)
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

