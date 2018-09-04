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

%macro Update_REAC_finish( Update_file=, Final_compare= );

  **************************************************************************
  ** Final compare of update against current Catalog data sets;
  
  %if %upcase( &Final_compare ) = Y %then %do;

    proc compare base=PresCat.REAC_Score compare=Update_&Update_file maxprint=(40,32000) listall;
    id nlihc_id descending reac_date;
    run;

  %end;

  %Finalize_data_set( 
    /** Finalize data set parameters **/
    data=Update_&Update_file,
    out=Reac_score,
    outlib=PresCat,
    label="Preservation Catalog, REAC scores",
    sortby=nlihc_id descending reac_date,
    archive=Y,
    /** Metadata parameters **/
    restrictions=None,
    revisions=%str(Updated with &Update_file..),
    /** File info parameters **/
    contents=Y,
    printobs=0
  )
    
%mend Update_REAC_finish;

/** End Macro Definition **/

