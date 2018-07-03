/**************************************************************************
 Program:  Update_REAC_finish.sas
 Library:  PresCat
 Project:  NeighborhoodInfo DC
 Author:   M. Cohen
 Created:  06/28/17
 Version:  SAS 9.2
 Environment:  -
 
 Description:  Autocall macro to finish updating process  
 with REAC data set.

 Modifications:
**************************************************************************/

/** Macro Update_Sec8mf_finish - Start Definition **/

%macro Update_REAC_finish( Update_file=, Finalize=, Final_compare= );

  
  **************************************************************************
  ** Initial setup and checks;
  
  %let Finalize = %upcase( &Finalize );
  
  
  **************************************************************************
  ** Final compare of update against current Catalog data sets;
  
  %if %upcase( &Final_compare ) = Y %then %do;

    proc compare base=PresCat.REAC_Score compare=Update_&Update_file maxprint=(40,32000) listall;
    id nlihc_id ;
    run;

  %end;
    

  **************************************************************************
  ** Archive past Catalog datasets before finalizing;

  %if %upcase( &Finalize ) = Y %then %do;
  
    ** Copy data sets to final versions **;
    
    proc datasets library=Work memtype=(data) nolist;
      change 
        Update_&Update_file=Reac_Score
      copy in=Work out=PresCat;
      select Reac_Score;
    quit;
    run;
    
    ** Archive final versions for this update **;
  
    %Archive_catalog_data( data=Reac_Score /*&Reac_Score_except*/, zip_pre=Update_&Update_file, zip_suf=,
      overwrite=y, quiet=y )
      
    ** Write file info to output **;
    
    %File_info( data=PresCat.Reac_Score, printobs=0 )
    
   
    ** Add updates to metadata **;
    
    %Dc_update_meta_file(
      ds_lib=PresCat,
      ds_name=REAC_Score,
      creator_process=Update_&Update_file..sas,
      restrictions=None,
      revisions=%str(Update with Update_&Update_file..)
    )

  %end;
  %else %do;
  
    ** Write file info to output **;

    %File_info( data=Update_&Update_file, printobs=0 )
   
    
  %end;


%mend Update_REAC_finish;

/** End Macro Definition **/

