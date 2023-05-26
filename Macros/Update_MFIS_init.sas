/**************************************************************************
 Program:  Update_MFIS_init.sas
 Library:  PresCat
 Project:  NeighborhoodInfo DC
 Author:   P. Tatian
 Created:  09/19/15
 Version:  SAS 9.2
 Environment:  -
 
 Description:  Autocall macro to initialize macro variables and formats
 for MFIS update.

 Modifications:
**************************************************************************/

/** Macro Update_MFIS - Start Definition **/

%macro Update_MFIS_init( Update_file= );

  %global 
    Update_dtm NO_SUBSIDY_ID NONMATCH_YEARS_CUTOFF 
    Subsidy_info_source Subsidy_Info_Source_Date
    Subsidy_update_vars Subsidy_tech_vars Subsidy_missing_info_vars
    Subsidy_dupcheck_id_vars Subsidy_compare_id_vars Subsidy_char_diff_vars
    Project_src_update_vars Project_subsidy_update_vars Project_missing_info_vars 
    Last_update_date Last_update_date_fmt
    Assisted_units_src POA_start_src POA_end_src Compl_end_src Is_inactive_src
    Program_src Subsidy_Info_Source_ID_src Subsidy_info_source_property_src
    POA_end_actual_src Rent_to_fmr_description_src
    ownership_effective_date_src owner_organization_name_src owner_individual_full_name_src
    Hud_Own_Type_src mgmt_agent_org_name_src mgmt_agent_full_name_src Hud_Mgr_Type_src;
    
  %let Update_dtm = %sysfunc( datetime() );
  
  %** Subsidy source specific parameters **;
  
  %let Subsidy_info_source = "HUD/MFIS";
  %let Subsidy_Info_Source_ID_src = HUD_project_number;
  %let Assisted_units_src = Units;
  %let POA_start_src = intnx( 'month', maturity_date, -1 * term_in_months, 'same' );
  %let POA_end_src = maturity_date;
  %let Compl_end_src = POA_end;
  %let Is_inactive_src = ( MFIS_status in ( 'T' ) );
  %let POA_end_actual_src = term_date;
  %let Program_src = SOA_cat_sub_cat;
  %let Subsidy_info_source_property_src = Premise_id;
  %let Rent_to_fmr_description_src = ' ';
  
  %let ownership_effective_date_src = .;
  %let owner_organization_name_src = "";
  %let owner_individual_full_name_src = "";
  %let Hud_Own_Type_src = "";
  %let mgmt_agent_org_name_src = "";
  %let mgmt_agent_full_name_src = "";
  %let Hud_Mgr_Type_src = "";
    
  %let NONMATCH_YEARS_CUTOFF = 10;   /** Maximum years since expiration to report nonmatching subsidy records **/
  %let NO_SUBSIDY_ID = 9999999999;

  proc sql noprint;
    select Extract_date format best32. into :Subsidy_Info_Source_Date from Hud.&Update_file._dc;
  quit;

  proc sql noprint;
    select max( Subsidy_Info_Source_Date ) format best32. into :Last_update_date 
      from PresCat.Subsidy_update_history (where=(Subsidy_Info_Source=&Subsidy_Info_Source));
  quit;
  
  %let Last_update_date_fmt = %sysfunc( putn( &Last_update_date, mmddyy10. ) );
  
  %let Subsidy_update_vars = 
      Units_Assist POA_start POA_end Compl_end POA_end_actual Subsidy_Active Program Rent_to_FMR_description
      ;
      
  %let Subsidy_tech_vars = Subsidy_Info_Source Subsidy_Info_Source_ID Subsidy_Info_Source_Date subsidy_info_source_property Update_Dtm;
  
  %let Subsidy_missing_info_vars = 
      &Subsidy_Info_Source_ID_src Premise_id Property_name Property_street SOA_cat_sub_cat
      ;
      
  %let Subsidy_dupcheck_id_vars = Premise_id Property_name;
  
  %let Subsidy_compare_id_vars = ;
  
  %let Subsidy_char_diff_vars = ;
  
  %let Project_src_update_vars = 
      ;

  %let Project_subsidy_update_vars =
      Subsidized Proj_Units_Assist_Min Subsidy_Start_First Subsidy_End_First 
      Proj_Units_Assist_Max Subsidy_Start_Last Subsidy_End_Last;

  %let Project_missing_info_vars = 
      Premise_id Property_name Property_street SOA_cat_sub_cat;

  %put _user_;
  
  ** Create $nlihcid2cat. format with category IDs **;

  %Data_to_format(
    FmtLib=work,
    FmtName=$nlihcid2cat,
    Desc=,
    Data=PresCat.Project_category,
    Value=nlihc_id,
    Label=category_code,
    OtherLabel='',
    DefaultLen=1,
    Print=N,
    Contents=N
    )
    
  ** Create $nlihcid_proj. format to add project ID and names to update report **;

  %Data_to_format(
    FmtLib=work,
    FmtName=$nlihcid_proj,
    Desc=,
    Data=PresCat.Project (where=(not(missing(nlihc_id)))),
    Value=nlihc_id,
    Label=trim(nlihc_id)||' / '||left(proj_name),
    OtherLabel='** Unidentified project **',
    DefaultLen=.,
    MaxLen=.,
    MinLen=.,
    Print=N,
    Contents=N
    )

  ** Create $property_nlihcid. format to add NLIHC ID from HUD property ID **;
  
  proc sql noprint;
    create table property_nlihcid as
    select Subsidy_info_source_property as property_id, nlihc_id, count(nlihc_id) as N
      from PresCat.Subsidy (where=(Subsidy_Info_Source=&Subsidy_Info_Source and 
                                   not(missing(subsidy_info_source_id)) and 
                                   not(missing(Subsidy_info_source_property))))
      group by property_id, nlihc_id;
  quit;
  
  %Data_to_format(
    FmtLib=work,
    FmtName=$property_nlihcid,
    Desc=,
    Data=property_nlihcid,
    Value=property_id,
    Label=nlihc_id,
    OtherLabel="",
    DefaultLen=.,
    MaxLen=.,
    MinLen=.,
    Print=N,
    Contents=N
    )
  
  ** Traffic-lighting format $except_tl. for update report **;
  
  proc format;
    value $except_tl
      "-", "n/a" = 'white'
      other = 'yellow';
  run;

%mend Update_MFIS_init;

/** End Macro Definition **/

