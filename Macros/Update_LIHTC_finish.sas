/**************************************************************************
 Program:  Update_LIHTC_finish.sas
 Library:  PresCat
 Project:  NeighborhoodInfo DC
 Author:   P. Tatian
 Created:  07/03/17
 Version:  SAS 9.2
 Environment:  -
 
 Description:  Autocall macro to finish updating process  
 with LIHTC data set.

 Modifications:
**************************************************************************/

/** Macro Update_LIHTC_finish - Start Definition **/

%macro Update_LIHTC_finish( Update_file=, Finalize=, Subsidy_except=, Project_except=, Final_compare= );

  
  **************************************************************************
  ** Finalize data sets;
  
  ** Subsidy **;
  
  data Subsidy;
  
    set Subsidy_Update_&Update_file;
    
    ** Remove temporary variables **;

    keep &Subsidy_final_vars;
  
  run; 
  
  %Finalize_data_set( 
    /** Finalize data set parameters **/
    data=Subsidy,
    out=Subsidy,
    outlib=PresCat,
    label="Preservation Catalog, Project subsidies",
    sortby=nlihc_id subsidy_id,
    archive=Y,
    /** Metadata parameters **/
    revisions=%str(Update with &Update_file..),
    /** File info parameters **/
    contents=Y,
    printobs=0,
    printchar=N,
    printvars=,
    freqvars=,
    stats=n sum mean stddev min max
  )
  
  %if %mparam_is_yes( &Final_compare ) %then %do;

    proc compare base=PresCat.Subsidy compare=Subsidy maxprint=(40,32000) listall;
      id nlihc_id subsidy_id;
    run;

  %end;
  
  
  ** Project **;
  
  %Finalize_data_set( 
    /** Finalize data set parameters **/
    data=Project_Update_&Update_file,
    out=Project,
    outlib=PresCat,
    label="Preservation Catalog, Projects",
    sortby=nlihc_id,
    archive=Y,
    /** Metadata parameters **/
    revisions=%str(Update with &Update_file..),
    /** File info parameters **/
    contents=Y,
    printobs=0,
    printchar=N,
    printvars=,
    freqvars=,
    stats=n sum mean stddev min max
  )

  %if %mparam_is_yes( &Final_compare ) %then %do;

    proc compare base=PresCat.Project compare=Project_Update_&Update_file maxprint=(40,32000) listall;
    id nlihc_id;
    run;
  
  %end;
    
  
  ** Subsidy_update_history **;
  
  %Finalize_data_set( 
    /** Finalize data set parameters **/
    data=Subsidy_update_history_new,
    out=Subsidy_update_history,
    outlib=PresCat,
    label="Preservation Catalog, Subsidy update history",
    sortby=nlihc_id subsidy_id descending update_dtm,
    archive=Y,
    /** Metadata parameters **/
    revisions=%str(Update with &Update_file..),
    /** File info parameters **/
    contents=Y,
    printobs=0,
    printchar=N,
    printvars=,
    freqvars=,
    stats=n sum mean stddev min max
  )


%mend Update_LIHTC_finish;

/** End Macro Definition **/

