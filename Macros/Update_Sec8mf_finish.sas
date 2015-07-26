/**************************************************************************
 Program:  Update_Sec8mf_finish.sas
 Library:  PresCat
 Project:  NeighborhoodInfo DC
 Author:   P. Tatian
 Created:  07/18/15
 Version:  SAS 9.2
 Environment:  -
 
 Description:  Autocall macro to finish updating process  
 with Sec8mf data set.

 Modifications:
**************************************************************************/

/** Macro Update_Sec8mf_finish - Start Definition **/

%macro Update_Sec8mf_finish( Update_file=, Finalize= );

  
  **************************************************************************
  ** Initial setup and checks;
  
  %let Finalize = %upcase( &Finalize );
  
  
  **************************************************************************
  ** Add record to Update_history;

  data Update_history_rec;

    set Sec8MF_subsidy_update (obs=1 keep=Subsidy_Info_Source Subsidy_Info_Source_Date Update_Dtm);
    
    rename
      Subsidy_Info_Source=Info_Source
      Subsidy_Info_Source_Date=Info_Source_Date;
    
  run;

  proc sort data=PresCat.Update_history out=Update_history;
    by Info_source Info_source_date;
    
  data Update_history_new (label="Preservation Catalog, Update history");

    update updatemode=nomissingcheck Update_history Update_history_rec;
    by Info_source Info_source_date;
    
  run;
  
  proc sort data=Update_history_new;
    by descending Update_dtm;
  run;

  %File_info( data=Update_history_new, stats= )

  
  **************************************************************************
  ** Archive past Catalog datasets before finalizing;

  %if &Finalize = Y %then %do;
  
    %Archive_catalog_data( data=Project Subsidy Update_history Update_subsidy_history Update_project_history, zip_pre=Update_&Update_file, zip_suf= )
    
  %end;

  
  %File_info( data=Subsidy_Update_&Update_file, printobs=5 )
  
  %File_info( data=Update_subsidy_history_new, stats=, printobs=5 )
  
  %File_info( data=Project_Update_&Update_file, printobs=5 )
  
  %File_info( data=Update_project_history_new, stats=, printobs=5 )
  
  title2 'FINAL COMPARE AGAINST ORIGINAL';

  proc compare base=PresCat.Subsidy compare=Subsidy_Update_&Update_file maxprint=(40,32000) listall;
  id nlihc_id subsidy_id;
  run;

  proc compare base=PresCat.Project compare=Project_Update_&Update_file maxprint=(40,32000) listall;
  id nlihc_id;
  run;
  
  title2;

  /* proc copy */



%mend Update_Sec8mf_finish;

/** End Macro Definition **/

