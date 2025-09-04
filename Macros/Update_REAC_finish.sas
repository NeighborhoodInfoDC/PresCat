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

%macro Update_REAC_finish( Update_file=, Final_compare=, Finalize=N, Revisions= );

  %local numobs;
  
  proc sort data=PresCat.REAC_Score out=REAC_Score;
    by nlihc_id REAC_inspec_id;
  run;

  **************************************************************************
  ** Final compare of update against current Catalog data sets;
  
  %if %upcase( &Final_compare ) = Y %then %do;

    proc compare base=REAC_Score compare=Update_&Update_file maxprint=(40,32000);
    id nlihc_id REAC_inspec_id;
    run;
    
  %end;

  **************************************************************************
  ** List new REAC scores;
  
  data New_reac;
  
    merge 
      REAC_Score (keep=nlihc_id REAC_inspec_id in=inBase) 
      Update_&Update_file (keep=nlihc_id REAC_inspec_id reac_date reac_score in=inUpdate);
    by nlihc_id REAC_inspec_id;

    if not inBase and inUpdate;
    
    length Proj_info $ 160;
    
    Proj_info = 
      trim( left( put( nlihc_id, $nlihcid_proj. ) ) ) || ': ' ||
      trim( reac_score ) || ', ' ||
      trim( left( put( reac_date, mmddyy10. ) ) );
    
  run;
  
  proc sql noprint;
    select count(nlihc_id) into :numobs
    from New_reac;
  quit;
  
  %if &numobs > 0 %then %do;
  
    proc sort data=New_reac;
      by descending Reac_date nlihc_id;
    run;
  
    ods pdf file="&_dcdata_default_path\PresCat\Prog\Updates\Update_&Update_file._new_scores.pdf" 
      style=Styles.Rtf_arial_9pt pdftoc=2 bookmarklist=hide uniform;

    ods listing close;
    
    title2 "Newly reported REAC scores in &Update_file";
    
    proc print data=New_reac label noobs;
      var Proj_info;
      label Proj_info = "Projects with new REAC scores";
    run;
    
    title2;
    
    ods pdf close;
    ods listing;
    
  %end;
  %else %do;
  
    %note_mput( macro=Update_REAC_finish, msg=No new REAC scores in this update. )
    
  %end;
    
  **************************************************************************
  ** Finalize datasets;

  %Finalize_data_set( 
    /** Finalize data set parameters **/
    finalize=&finalize,
    data=Update_&Update_file,
    out=Reac_score,
    outlib=PresCat,
    label="Preservation Catalog, REAC scores",
    sortby=nlihc_id REAC_inspec_id reac_date,
    archive=N,
    /** Metadata parameters **/
    restrictions=None,
    revisions=%str(&revisions),
    /** File info parameters **/
    contents=Y,
    printobs=0
  )
  
%mend Update_REAC_finish;

/** End Macro Definition **/

