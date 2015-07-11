/**************************************************************************
 Program:  Create_project_subsidy_update.sas
 Library:  PresCat
 Project:  NeighborhoodInfo DC
 Author:   P. Tatian
 Created:  02/21/15
 Version:  SAS 9.2
 Environment:  Local Windows session (desktop)
 
 Description:  Autocall macro to create project update file from
 Subsidy data set.

 Modifications:
  07/04/15 PAT Changed POA_START to POA_START_ORIG for subsidy start dates.
               Adjusted length of Subsidized var to match Project file.
**************************************************************************/

/** Macro Create_project_subsidy_update - Start Definition **/

%macro Create_project_subsidy_update( data=PresCat.Subsidy, out=Project_subsidy_update );

  ** Get min/max assisted units by program **;

  proc summary data=&data nway;
    class Nlihc_id Program;
    var units_assist poa_start_orig poa_end Subsidy_active;
    output out=_Project_subsidy_update_a
      sum(units_assist)=
      min(poa_start_orig poa_end)=Subsidy_Start_First Subsidy_End_First
      max(poa_start_orig poa_end)=Subsidy_Start_Last Subsidy_End_Last
      max(Subsidy_active)=xSubsidized;
  run;

  ** Summarize by project **;

  proc summary data=_Project_subsidy_update_a;
    by Nlihc_id;
    var units_assist Subsidy_Start_First Subsidy_End_First Subsidy_Start_Last Subsidy_End_Last xSubsidized;
    output out=_Project_subsidy_update_b (drop=_freq_ _type_)
      min(units_assist Subsidy_Start_First Subsidy_End_First)=Proj_Units_Assist_Min Subsidy_Start_First Subsidy_End_First
      max(units_assist Subsidy_Start_Last Subsidy_End_Last)=Proj_Units_Assist_Max Subsidy_Start_Last Subsidy_End_Last
      max(xSubsidized)=;
  run;
  
  ** Adjust length of Subsidized var **;
  
  data &out;
  
    set _Project_subsidy_update_b;
    
    length Subsidized 3;
    
    Subsidized = xSubsidized;
    
    drop xSubsidized;
    
  run;

  proc datasets library=work nolist nowarn;
    delete _Project_subsidy_update_a _Project_subsidy_update_b /memtype=data;
  quit;

%mend Create_project_subsidy_update;

/** End Macro Definition **/

