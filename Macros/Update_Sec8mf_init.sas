/**************************************************************************
 Program:  Update_Sec8mf.sas
 Library:  PresCat
 Project:  NeighborhoodInfo DC
 Author:   P. Tatian
 Created:  07/18/15
 Version:  SAS 9.2
 Environment:  -
 
 Description:  Autocall macro to initialize macro variables and formats
 for Sec8mf update.

 Modifications:
**************************************************************************/

/** Macro Update_Sec8mf - Start Definition **/

%macro Update_Sec8mf_init( Update_file= );

  %global 
    Update_dtm Subsidy_info_source NO_SUBSIDY_ID Subsidy_Info_Source_Date
    Subsidy_update_vars Subsidy_tech_vars Subsidy_missing_info_vars
    Project_mfa_update_vars Project_subsidy_update_vars Project_missing_info_vars 
    Last_update_date Last_update_date_fmt;
    
  %let Update_dtm = %sysfunc( datetime() );

  %let Subsidy_info_source = "HUD/MFA";
  
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
      Units_Assist POA_start POA_end Compl_end 
      rent_to_FMR_description Subsidy_Active Program 
      ;
      
  %let Subsidy_tech_vars = Subsidy_Info_Source Subsidy_Info_Source_ID Subsidy_Info_Source_Date contract_number Update_Dtm;

  %let Subsidy_missing_info_vars = 
      property_name_text address_line1_text program_type_name
      ;
      
  %let Project_mfa_update_vars = 
      Hud_Own_Effect_dt Hud_Own_Name Hud_Own_Type Hud_Mgr_Name
      Hud_Mgr_Type;

  %let Project_subsidy_update_vars =
      Subsidized Proj_Units_Assist_Min Subsidy_Start_First Subsidy_End_First 
      Proj_Units_Assist_Max Subsidy_Start_Last Subsidy_End_Last;

  %let Project_missing_info_vars = 
      contract_number property_name_text address_line1_text program_type_name;

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

  ** Create $property_nlihcid. format to add NLIHC ID from HUD MFA property ID **;
  
  proc sql noprint;
    create table property_nlihcid as
    select scan(subsidy_info_source_id, 1, '/') as property_id, nlihc_id, count(nlihc_id) as N
      from PresCat.Subsidy (where=(Subsidy_Info_Source=&Subsidy_Info_Source and not(missing(subsidy_info_source_id))))
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

%mend Update_Sec8mf_init;

/** End Macro Definition **/

