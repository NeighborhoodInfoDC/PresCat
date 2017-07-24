/**************************************************************************
 Program:  PresCat_global_mvars.sas
 Library:  PresCat
 Project:  NeighborhoodInfo DC
 Author:   P. Tatian
 Created:  07/24/17
 Version:  SAS 9.2
 Environment:  Local Windows session (desktop)
 
 Description:  Autocall macro to create globabl macro variables with
 Preservation Catalog data set labels, variable lists, and sort by
 variable lists.

 Modifications:
**************************************************************************/


%macro PresCat_global_mvars(  );

  /*------------- PresCat.Project -------------*/

  %global _PC_project_vars _PC_project_dslb _PC_project_sort;

  %let _PC_project_vars = Nlihc_id Status Category_Code Cat_At_Risk Cat_Expiring Cat_Failing_Insp Cat_More_Info Cat_Lost 
  Cat_Replaced Proj_Name Proj_City Proj_ST Proj_Units_Tot Hud_Own_Effect_dt Hud_Own_Name Hud_Own_Type Hud_Mgr_Name 
  Hud_Mgr_Type Proj_Name_old Proj_Addre_old PBCA Update_Dtm Subsidy_info_source_property contract_number Subsidy_Start_First 
  Subsidy_End_First Subsidy_Start_Last Subsidy_End_Last Subsidized Proj_Units_Assist_Min Proj_Units_Assist_Max Anc2012 
  Psa2012 Geo2010 Cluster_tr2000 Cluster_tr2000_name Ward2012 Proj_addre Proj_zip Zip Proj_image_url Proj_streetview_url 
  Proj_address_id Proj_x Proj_y Proj_lat Proj_lon Bldg_count;

  %let _PC_project_dslb = "Preservation Catalog, Projects";

  %let _PC_project_sort = Nlihc_id;


  /*------------- PresCat.Subsidy -------------*/

  %global _PC_subsidy_vars _PC_subsidy_dslb _PC_subsidy_sort;

  %let _PC_subsidy_vars = Nlihc_id Subsidy_id Units_Assist POA_start POA_end contract_number rent_to_fmr_description 
  Subsidy_Active Subsidy_Info_Source_ID Subsidy_Info_Source Subsidy_Info_Source_Date Update_Dtm Program Compl_end 
  POA_end_prev Agency POA_start_orig Portfolio Subsidy_info_source_property POA_end_actual;

  %let _PC_subsidy_dslb = "Preservation Catalog, Project subsidies";

  %let _PC_subsidy_sort = Nlihc_id Subsidy_id;


  /*------------- PresCat.Building_geocode -------------*/

  %global _PC_building_geocode_vars _PC_building_geocode_dslb _PC_building_geocode_sort;

  %let _PC_building_geocode_vars = Nlihc_id Proj_name Bldg_addre Bldg_image_url Bldg_streetview_url Bldg_address_id Anc2012 
  Psa2012 Geo2010 Cluster_tr2000 Cluster_tr2000_name Bldg_zip Ward2012 Ssl Bldg_x Bldg_y Bldg_lon Bldg_lat;

  %let _PC_building_geocode_dslb = "Preservation Catalog, Building-level geocoding info";

  %let _PC_building_geocode_sort = Nlihc_id Bldg_addre;


  /*------------- PresCat.Parcel -------------*/

  %global _PC_parcel_vars _PC_parcel_dslb _PC_parcel_sort;

  %let _PC_parcel_vars = Nlihc_id Ssl Parcel_address_id Ssl_orig Parcel_owner_date Parcel_Info_Source_Date in_last_ownerpt 
  Parcel_type Parcel_x Parcel_y Parcel_owner_name Parcel_owner_type;

  %let _PC_parcel_dslb = "Preservation Catalog, Real property parcels";

  %let _PC_parcel_sort = Nlihc_id Ssl;


  /*------------- PresCat.Project_category -------------*/

  %global _PC_project_category_vars _PC_project_category_dslb _PC_project_category_sort;

  %let _PC_project_category_vars = Nlihc_id Proj_Name Category_Code Cat_At_Risk Cat_More_Info Cat_Lost Cat_Replaced;

  %let _PC_project_category_dslb = "Preservation Catalog, Project category";

  %let _PC_project_category_sort = Nlihc_id;


  /*------------- PresCat.Project_geocode -------------*/

  %global _PC_project_geocode_vars _PC_project_geocode_dslb _PC_project_geocode_sort;

  %let _PC_project_geocode_vars = Nlihc_id Proj_name Anc2012 Psa2012 Geo2010 Cluster_tr2000 Cluster_tr2000_name Ward2012 
  Proj_addre Proj_zip Zip Proj_image_url Proj_streetview_url Proj_address_id Proj_x Proj_y Proj_lat Proj_lon Bldg_count;

  %let _PC_project_geocode_dslb = "Preservation Catalog, Project-level geocoding info";

  %let _PC_project_geocode_sort = Nlihc_id;


  /*------------- PresCat.Reac_score -------------*/

  %global _PC_reac_score_vars _PC_reac_score_dslb _PC_reac_score_sort;

  %let _PC_reac_score_vars = Nlihc_id REAC_date REAC_score REAC_score_num REAC_score%letter REAC_score_star;

  %let _PC_reac_score_dslb = "Preservation Catalog, REAC scores";

  %let _PC_reac_score_sort = Nlihc_id;


  /*------------- PresCat.Real_property -------------*/

  %global _PC_real_property_vars _PC_real_property_dslb _PC_real_property_sort;

  %let _PC_real_property_vars = Nlihc_id Ssl RP_date RP_type RP_desc;

  %let _PC_real_property_dslb = "Preservation Catalog, Real property events";

  %let _PC_real_property_sort = Nlihc_id RP_type;


  /*------------- PresCat.Subsidy_except -------------*/

  %global _PC_subsidy_except_vars _PC_subsidy_except_dslb _PC_subsidy_except_sort;

  %let _PC_subsidy_except_vars = Nlihc_id Subsidy_id Units_Assist POA_start POA_end contract_number rent_to_fmr_description 
  Subsidy_Active Program Compl_end POA_end_prev Agency POA_start_orig POA_end_actual Except_date Except_init;

  %let _PC_subsidy_except_dslb = "Preservation Catalog, Subsidy exception file";

  %let _PC_subsidy_except_sort = Nlihc_id Subsidy_id Except_date;


  /*------------- PresCat.Project_update_history -------------*/

  %global _PC_project_update_history_vars _PC_project_update_history_dslb _PC_project_update_history_sort;

  %let _PC_project_update_history_vars = Nlihc_id Subsidy_Info_Source Subsidy_Info_Source_Date Update_Dtm 
  Hud_Own_Effect_dt_BASE Hud_Own_Effect_dt_COMPARE Hud_Own_Effect_dt_EXCEPT Hud_Own_Name_BASE Hud_Own_Name_COMPARE 
  Hud_Own_Name_EXCEPT Hud_Own_Type_BASE Hud_Own_Type_COMPARE Hud_Own_Type_EXCEPT Hud_Mgr_Name_BASE Hud_Mgr_Name_COMPARE 
  Hud_Mgr_Name_EXCEPT Hud_Mgr_Type_BASE Hud_Mgr_Type_COMPARE Hud_Mgr_Type_EXCEPT Subsidy_Info_Source_ID Subsidized_BASE 
  Subsidized_COMPARE Subsidized_DIF Proj_Units_Assist_Min_BASE Proj_Units_Assist_Min_COMPARE Proj_Units_Assist_Min_DIF 
  Subsidy_Start_First_BASE Subsidy_Start_First_COMPARE Subsidy_Start_First_DIF Subsidy_End_First_BASE 
  Subsidy_End_First_COMPARE Subsidy_End_First_DIF Proj_Units_Assist_Max_BASE Proj_Units_Assist_Max_COMPARE 
  Proj_Units_Assist_Max_DIF Subsidy_Start_Last_BASE Subsidy_Start_Last_COMPARE Subsidy_Start_Last_DIF Subsidy_End_Last_BASE 
  Subsidy_End_Last_COMPARE Subsidy_End_Last_DIF In_EXCEPT;

  %let _PC_project_update_history_dslb = "Preservation Catalog, Project update history";

  %let _PC_project_update_history_sort = Nlihc_id;


  /*------------- PresCat.Subsidy_update_history -------------*/

  %global _PC_subsidy_update_history_vars _PC_subsidy_update_history_dslb _PC_subsidy_update_history_sort;

  %let _PC_subsidy_update_history_vars = Nlihc_id Subsidy_id Subsidy_Info_Source Subsidy_Info_Source_Date Update_Dtm 
  Subsidy_Info_Source_ID Compl_end_BASE Compl_end_COMPARE Compl_end_EXCEPT POA_end_BASE POA_end_COMPARE POA_end_EXCEPT 
  POA_start_BASE POA_start_COMPARE POA_start_EXCEPT Program_BASE Program_COMPARE Program_EXCEPT Subsidy_Active_BASE 
  Subsidy_Active_COMPARE Subsidy_Active_EXCEPT Units_Assist_BASE Units_Assist_COMPARE Units_Assist_EXCEPT 
  rent_to_FMR_description_BASE rent_to_FMR_description_COMPARE rent_to_FMR_description_EXCEPT contract_number In_BASE 
  In_COMPARE In_DIF POA_end_actual_BASE POA_end_actual_COMPARE POA_end_actual_EXCEPT;

  %let _PC_subsidy_update_history_dslb = "Preservation Catalog, Subsidy update history";

  %let _PC_subsidy_update_history_sort = Nlihc_id Subsidy_id;

%mend PresCat%global_mvars;


