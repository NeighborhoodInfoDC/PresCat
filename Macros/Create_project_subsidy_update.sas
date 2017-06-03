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

%macro Create_project_subsidy_update( data=PresCat.Subsidy, out=Project_subsidy_update, project_file=PresCat.Project );

  ** Get min/max assisted units by program **;

  proc summary data=&data nway;
    where Subsidy_active;
    class Nlihc_id Program;
    var units_assist poa_start_orig poa_end Subsidy_active;
    output out=_Project_subsidy_update_a
      sum(units_assist)=
      min(poa_start_orig poa_end)=Subsidy_Start_First Subsidy_End_First
      max(poa_start_orig poa_end)=Subsidy_Start_Last Subsidy_End_Last
      max(Subsidy_active)=_Subsidized;
  run;

  ** Summarize by project **;

  proc summary data=_Project_subsidy_update_a;
    by Nlihc_id;
    var units_assist Subsidy_Start_First Subsidy_End_First Subsidy_Start_Last Subsidy_End_Last _Subsidized;
    output out=_Project_subsidy_update_b (drop=_freq_ _type_)
      sum(units_assist)=_units_assist_sum
      min(Subsidy_Start_First Subsidy_End_First)=Subsidy_Start_First Subsidy_End_First
      max(units_assist Subsidy_Start_Last Subsidy_End_Last)=_units_assist_max Subsidy_Start_Last Subsidy_End_Last
      max(_Subsidized)=;
  run;
  
  ** Adjust length of Subsidized var, max assisted unit count **;
  
  data &out;
  
    merge
      _Project_subsidy_update_b
      &project_file (keep=nlihc_id proj_units_tot);
    by nlihc_id;
    
    length Subsidized 3;
    
    Subsidized = _Subsidized;
    if missing( Subsidized ) then Subsidized = 0;
    
    if Subsidized then do;
      Proj_Units_Assist_Min = min( _units_assist_max, proj_units_tot );
      Proj_Units_Assist_Max = min( _units_assist_sum, proj_units_tot );
    end;
    else do;
      Proj_Units_Assist_Min = .n;
      Proj_Units_Assist_Max = .n;
      Subsidy_Start_First = .n;
      Subsidy_End_First =.n;
      Subsidy_Start_Last =.n;
      Subsidy_End_Last = .n;
    end;
    
    label
      proj_units_assist_max = "Total assisted housing units in project (maximum) [derived from PresCat.Subsidy]"
      proj_units_assist_min = "Total assisted housing units in project (minimum) [derived from PresCat.Subsidy]"
      subsidized = "Project is subsidized [derived from PresCat.Subsidy]"
      subsidy_end_first = "First subsidy end date"
      subsidy_end_last = "Last subsidy end date"
      subsidy_start_first = "First subsidy start date"
      subsidy_start_last = "Last subsidy start date";
    
    format Subsidized dyesno.;
    
    drop _Subsidized _units_assist_sum _units_assist_max proj_units_tot;
    
  run;

  proc datasets library=work nolist nowarn;
    delete _Project_subsidy_update_a _Project_subsidy_update_b /memtype=data;
  quit;

%mend Create_project_subsidy_update;

/** End Macro Definition **/

