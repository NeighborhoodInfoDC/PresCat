/**************************************************************************
 Program:  Add_new_projects_subsidy.sas
 Library:  PresCat
 Project:  NeighborhoodInfo DC
 Author:   P. Tatian
 Created:  02/17/18
 Version:  SAS 9.2
 Environment:  Local Windows session (desktop)
 
 Description:  Autocall macro to add new projects to Preservation
 Catalog. 

 Macro updates:
   PresCat.Subsidy

 Modifications:
**************************************************************************/

%macro Add_new_projects_subsidy( 
  input_file_pre=, /** First part of input file names **/ 
  input_path=  /** Location of input files **/
  );
  
  ** Import subsidy data **;

  filename fimport "&input_path\&input_file_pre._subsidy.csv" lrecl=2000;

  data WORK.NEW_PROJ_SUBS    ;
  %let _EFIERR_ = 0; /* set the ERROR detection macro variable */
  infile FIMPORT delimiter = ',' MISSOVER DSD lrecl=32767 firstobs=2 ;
  informat MARID best32. ;
  informat Units_tot 8. ;
  informat Units_assist 8. ;
  informat Current_Affordability_Start mmddyy10. ;
  informat Affordability_End mmddyy10. ;
  informat rent_to_fmr_description $40. ;
  informat Subsidy_Info_Source_ID $40. ;
  informat Subsidy_Info_Source $40. ;
  informat Subsidy_Info_Source_Date mmddyy10. ;
  informat Program $32. ;
  informat Compliance_end_date mmddyy10. ;
  informat Previous_Affordability_End mmddyy10. ;
  informat Agency $80. ;
  informat Date_Affordability_Ended mmddyy10. ;
  format MARID best12. ;
  format Units_tot 8. ;
  format Units_assist 8. ;
  format Current_Affordability_Start mmddyy10. ;
  format Affordability_End mmddyy10. ;
  format rent_to_fmr_description $40. ;
  format Subsidy_Info_Source_ID $40. ;
  format Subsidy_Info_Source $40. ;
  format Subsidy_Info_Source_Date 8. ;
  format Program $progfull66. ;
  format Compliance_end_date mmddyy10. ;
  format Previous_Affordability_End mmddyy10. ;
  format Agency $80. ;
  format Date_Affordability_Ended mmddyy10. ;

  input
  MARID
  Units_tot
  Units_assist
  Current_Affordability_Start
  Affordability_End
  rent_to_fmr_description $
  Subsidy_Info_Source_ID $
  Subsidy_Info_Source $
  Subsidy_Info_Source_Date
  Program $
  Compliance_end_date 
  Previous_Affordability_End 
  Agency $
  Date_Affordability_Ended
  ;

  if _ERROR_ then call symputx('_EFIERR_',1);  /* set ERROR detection macro variable */
  _drop = 0;

  run;

  filename fimport clear;
    
  data NLIHC_ID;

    set building_geocode
    (keep=NLIHC_id bldg_address_id);
    _drop = 1;
    run;

  proc sort data=nlihc_id nodupkey;
  by bldg_address_id;
  run;

  proc sort data=New_Proj_Subs;
  by marid;
  run;


  data Subsidy_a;

    merge NLIHC_ID (rename=(bldg_address_id=address_id)) New_Proj_Subs (rename=(marid=address_id));
    by address_id;
    if _drop = 1 then delete;
    drop _drop address_id;
    format _all_ ;
    informat _all_ ;

  run;

  proc sort data = Subsidy_a;
  by nlihc_id;
  run;

  data Subsidy_a2;
    set Subsidy_a (where=(program~=""));
    by nlihc_id;

    ** Subsidy ID number **;

    if first.Nlihc_id then Subsidy_id = 0;
    
    Subsidy_id + 1;
    
    ** Create Active Subsidy Indicator **;

    length Subsidy_active 3;

    if Date_Affordability_Ended = . then Subsidy_Active = 1;
    else Subsidy_Active = 0;

    ** Fill in portfolio **;
    
    Portfolio = put( Program, $progtoportfolio. );
    
    ** First POA start date **;

    POA_start_orig = current_affordability_start;

    ** Create Timestamp for Update **;

    Update_dtm =datetime();

    rename current_affordability_start=POA_start affordability_end=POA_end 
                  Compliance_End_Date=compl_end 
                  Date_Affordability_Ended=POA_End_actual Previous_affordability_end=POA_end_prev;
  run;

  data Subsidy;

    set  prescat.subsidy Subsidy_a2 (drop=Units_tot);
    by nlihc_id subsidy_id;  

    ** Remove extraneous formats and informats **;

    format units_assist rent_to_fmr_description Subsidy_Info_Source_ID Agency ;

  run;

  %Finalize_data_set( 
    /** Finalize data set parameters **/
    data=Subsidy,
    out=Subsidy,
    outlib=PresCat,
    label="Preservation Catalog, Project subsidies",
    sortby=Nlihc_id Subsidy_id,
    archive=Y,
    /** Metadata parameters **/
    revisions=%str(Add new projects from &input_file_pre._*.csv.),
    /** File info parameters **/
    printobs=0
  )

  proc print data=Subsidy n;
    where put( nlihc_id, $New_nlihc_id. ) ~= "";
  run;

  ** Check against original subsidy file to ensure only new subsidy files have changed**;

  proc compare base=PresCat.Subsidy compare=Subsidy listall maxprint=(40,32000);
    id nlihc_id subsidy_id;
  run;

%mend Add_new_projects_subsidy;

/** End Macro Definition **/

