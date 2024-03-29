/**************************************************************************
 Program:  Update_MFIS_finish.sas
 Library:  PresCat
 Project:  NeighborhoodInfo DC
 Author:   P. Tatian
 Created:  09/19/15
 Version:  SAS 9.2
 Environment:  -
 
 Description:  Autocall macro to finish updating process  
 with MFIS data set.

 Modifications:
**************************************************************************/

/** Macro Update_MFIS_finish - Start Definition **/

%macro Update_MFIS_finish( Update_file=, Finalize=, Subsidy_except=, Project_except=, Final_compare= );

  
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


%MACRO SKIP;
  
  **************************************************************************
  ** Archive past Catalog datasets before finalizing;

  %if %upcase( &Finalize ) = Y %then %do;
  
    ** Copy data sets to final versions **;
    
    proc datasets library=Work memtype=(data) nolist;
      change 
        Subsidy_Update_&Update_file=Subsidy
        Project_Update_&Update_file=Project
        Subsidy_update_history_new=Subsidy_update_history
        Project_update_history_new=Project_update_history;
      copy in=Work out=PresCat;
      select Subsidy Project Subsidy_update_history Project_update_history;
    quit;
    run;
    
    ** Archive final versions for this update **;
  
    %Archive_catalog_data( data=Project Subsidy &Subsidy_except &Project_except, zip_pre=Update_&Update_file, zip_suf=,
      overwrite=y, quiet=y )
      
    ** Write file info to output **;
    
    %File_info( data=PresCat.Subsidy, printobs=0 )
    
    %File_info( data=PresCat.Subsidy_update_history, stats=, printobs=5 )
    
    %File_info( data=PresCat.Project, printobs=0 )
    
    %File_info( data=PresCat.Project_update_history, stats=, printobs=5 )
    
    ** Add updates to metadata **;
    
    %Dc_update_meta_file(
      ds_lib=PresCat,
      ds_name=Subsidy,
      creator_process=Update_&Update_file..sas,
      restrictions=None,
      revisions=%str(Update with &Update_file..)
    )

    %Dc_update_meta_file(
      ds_lib=PresCat,
      ds_name=Subsidy_update_history,
      creator_process=Update_&Update_file..sas,
      restrictions=None,
      revisions=%str(Update with &Update_file..)
    )

    %Dc_update_meta_file(
      ds_lib=PresCat,
      ds_name=Project,
      creator_process=Update_&Update_file..sas,
      restrictions=None,
      revisions=%str(Update with &Update_file..)
    )

    %Dc_update_meta_file(
      ds_lib=PresCat,
      ds_name=Project_category_view,
      creator_process=Update_&Update_file..sas,
      restrictions=None,
      revisions=%str(Update with &Update_file..)
    )

    %Dc_update_meta_file(
      ds_lib=PresCat,
      ds_name=Project_update_history,
      creator_process=Update_&Update_file..sas,
      restrictions=None,
      revisions=%str(Update with &Update_file..)
    )

  %end;
  %else %do;
  
    ** Write file info to output **;

    %File_info( data=Subsidy_Update_&Update_file, printobs=0 )
    
    %File_info( data=Subsidy_update_history_new, stats=, printobs=5 )
    
    %File_info( data=Project_Update_&Update_file, printobs=0 )
    
    %File_info( data=Project_update_history_new, stats=, printobs=5 )
    
  %end;

%MEND SKIP;

%mend Update_MFIS_finish;

/** End Macro Definition **/

