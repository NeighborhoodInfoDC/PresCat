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

  data WORK.New_proj_subs    ;

  %let _EFIERR_ = 0; /* set the ERROR detection macro variable */
  
  infile FIMPORT delimiter = ',' MISSOVER DSD lrecl=32767 firstobs=2 ;
  
  informat ID best32. ;
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
  
  format Current_Affordability_Start mmddyy10. ;
  format Affordability_End mmddyy10. ;
  format Subsidy_Info_Source_Date mmddyy10. ;
  format Compliance_end_date mmddyy10. ;
  format Previous_Affordability_End mmddyy10. ;
  format Date_Affordability_Ended mmddyy10. ;

  input
  ID
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
    
  proc sort data=New_Proj_Subs (where=(id > 0));
  by id;
  run;

  title2 '********************************************************************************************';
  title3 "** New subsidy data read from &input_path\&input_file_pre._subsidy.csv";

  proc print data=New_Proj_Subs noobs;
    id id;
  run;
  
  title2;

  data NLIHC_ID;

    set New_Proj_projects_geoc_nlihc_id
    (keep=NLIHC_id id);
    run;

  proc sort data=nlihc_id;
  by id;
  run;

  data Subsidy_a;

    merge 
      NLIHC_ID (in=in_bldg) New_Proj_Subs (in=in_subs);
    by id;

    if in_subs and not in_bldg then do;
      %err_put( macro=Add_new_projects_subsidy, msg="Subsidy record with no matching project record. " id= program= )
    end;
    else if not in_subs and in_bldg then do;
      %warn_put( macro=Add_new_projects_subsidy, msg="Project record with no matching subsidy records. " id= nlihc_id= )
    end;
    
    drop _drop id;
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
    
    if Portfolio = "" then %warn_put( macro=Add_new_projects_subsidy, msg="Subsidy program code unrecognized. " nlihc_id= program= );
    
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

  title2 '********************************************************************************************';
  title3 '** 5/ Check for changes in the new Subsidy file that are not related to the new projects';

  proc compare base=PresCat.Subsidy compare=Subsidy nosummary listbasevar listcompvar maxprint=(40,32000);
    id nlihc_id subsidy_id;
  run;
  
  title2;

  %Finalize_data_set( 
    /** Finalize data set parameters **/
    data=Subsidy,
    out=Subsidy,
    outlib=PresCat,
    label="Preservation Catalog, Project subsidies",
    sortby=Nlihc_id Subsidy_id,
    archive=N,
    /** Metadata parameters **/
    revisions=%str(Add new projects from &input_file_pre._*.csv.),
    /** File info parameters **/
    printobs=0
  )

  title2 'Subsidy: New records';

  proc print data=Subsidy;
    where put( nlihc_id, $New_nlihc_id. ) ~= "";
    by nlihc_id;
    id nlihc_id subsidy_id;
    var program portfolio units_assist poa_start poa_end;
  run;
  
  title2;

%mend Add_new_projects_subsidy;

/** End Macro Definition **/

