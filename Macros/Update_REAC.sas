/**************************************************************************
 Program:  Update_REAC.sas
 Library:  PresCat
 Project:  NeighborhoodInfo DC
 Author:   M. Cohen
 Created:  06/18/17
 Version:  SAS 9.2
 Environment:  -
 
 Description:  Autocall macro to update Prescat.REAC_SCORE and
 PresCat.Project with REAC data set.

 Modifications:
**************************************************************************/

/** Macro Update_Sec8mf - Start Definition **/

%macro Update_REAC( 
  Update_file=, 
  Quiet=Y,
  Final_compare=Y
  );

  /*This program will look very different because it's updating the REAC_score dataset

  How do I generate the ID? */

  %Update_REAC_init( Update_file=&Update_file )
  
  /*%if &Last_update_date = or &Last_update_date < &Subsidy_Info_Source_Date %then %do;*/
  
    %Update_REAC_score( Update_file=&Update_file, Quiet=&Quiet )
    
    %Update_REAC_finish( Update_file=&Update_file, Final_compare=&Final_compare );
    
  /*%end;
  %else %do;
  
    %err_mput( macro=Update_REAC, msg=%str(Update file &Update_file is not after last update for this data source (&Last_update_date_fmt).) )
    %err_mput( macro=Update_REAC, msg=%str(Update will NOT be applied to Catalog.) )

  %end;*/

  /*%note_mput( macro=Update_REAC, msg=%str(Macro exiting.) )*/
    
%mend Update_REAC;

/** End Macro Definition **/

