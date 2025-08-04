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

%macro Update_Sec8mf_finish( Update_file=, Finalize=N, Subsidy_except=, Project_except=, Final_compare= );

  
  **************************************************************************
  ** Initial setup and checks;
  
  
  
  **************************************************************************
  ** Final compare of update against current Catalog data sets;
  
  %if %upcase( &Final_compare ) = Y %then %do;

    proc compare base=PresCat.Subsidy compare=Subsidy_Update_&Update_file maxprint=(40,32000) listall;
    id nlihc_id subsidy_id;
    run;

    proc compare base=PresCat.Project compare=Project_Update_&Update_file maxprint=(40,32000) listall;
    id nlihc_id;
    run;
  
  %end;
    

  **************************************************************************
  ** Finalize datasets;

  %Finalize_data_set( 
    /** Finalize data set parameters **/
    finalize=&finalize,
    data=Subsidy_Update_&Update_file,
    out=Subsidy,
    outlib=PresCat,
    label="Preservation Catalog, Project subsidies",
    sortby=nlihc_id subsidy_id,
    archive=N,
    /*archive_name=,*/
    /** Metadata parameters **/
    restrictions=None,
    revisions=%str(Update with &Update_file..),
    /** File info parameters **/
    contents=Y,
    printobs=0,
    freqvars=,
    stats=n sum mean stddev min max
  )

  %Finalize_data_set( 
    /** Finalize data set parameters **/
    finalize=&finalize,
    data=Project_Update_&Update_file,
    out=Project,
    outlib=PresCat,
    label="Preservation Catalog, Projects",
    sortby=nlihc_id,
    archive=N,
    /*archive_name=,*/
    /** Metadata parameters **/
    restrictions=None,
    revisions=%str(Update with &Update_file..),
    /** File info parameters **/
    contents=Y,
    printobs=0,
    freqvars=,
    stats=n sum mean stddev min max
  )

  %Finalize_data_set( 
    /** Finalize data set parameters **/
    finalize=&finalize,
    data=Subsidy_update_history_new,
    out=Subsidy_update_history,
    outlib=PresCat,
    label="Preservation Catalog, Subsidy update history",
    sortby=nlihc_id subsidy_id update_dtm,
    archive=N,
    /*archive_name=,*/
    /** Metadata parameters **/
    restrictions=None,
    revisions=%str(Update with &Update_file..),
    /** File info parameters **/
    contents=Y,
    printobs=0,
    freqvars=,
    stats=
  )

  %Finalize_data_set( 
    /** Finalize data set parameters **/
    finalize=&finalize,
    data=Project_update_history_new,
    out=Project_update_history,
    outlib=PresCat,
    label="Preservation Catalog, Project update history",
    sortby=nlihc_id update_dtm,
    archive=N,
    /*archive_name=,*/
    /** Metadata parameters **/
    restrictions=None,
    revisions=%str(Update with &Update_file..),
    /** File info parameters **/
    contents=Y,
    printobs=0,
    freqvars=,
    stats=
  )

%mend Update_Sec8mf_finish;

/** End Macro Definition **/

