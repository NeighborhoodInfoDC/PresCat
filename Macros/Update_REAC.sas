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
  Final_compare=Y,
  Finalize=N
  );

  %Update_REAC_init( Update_file=&Update_file )
    
  %Update_REAC_score( Update_file=&Update_file, Quiet=&Quiet )
  
  %Update_REAC_finish( Update_file=&Update_file, Final_compare=&Final_compare, Finalize=&Finalize )
    
%mend Update_REAC;

/** End Macro Definition **/

