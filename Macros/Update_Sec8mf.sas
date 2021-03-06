/**************************************************************************
 Program:  Update_Sec8mf.sas
 Library:  PresCat
 Project:  NeighborhoodInfo DC
 Author:   P. Tatian
 Created:  07/18/15
 Version:  SAS 9.2
 Environment:  -
 
 Description:  Autocall macro to update PresCat.Project and
 PresCat.Subsidy with Sec8mf data set.

 Modifications:
**************************************************************************/

/** Macro Update_Sec8mf - Start Definition **/

%macro Update_Sec8mf( 
  Update_file=, 
  Finalize=,  /** OPTION NO LONGER IN USE **/
  Project_except=Project_except,
  Subsidy_except=Subsidy_except,
  Quiet=Y,
  Final_compare=Y
  );
  
  %Update_Sec8mf_init( Update_file=&Update_file )
  
  %if &Last_update_date = or &Last_update_date < &Subsidy_Info_Source_Date %then %do;
  
    %Update_Sec8mf_subsidy( Update_file=&Update_file, Subsidy_except=&Subsidy_except, Quiet=&Quiet )
    
    %Update_Sec8mf_project( Update_file=&Update_file, Project_except=&Project_except, Quiet=&Quiet )
    
    %Update_Sec8mf_finish( Update_file=&Update_file, Subsidy_except=&Subsidy_except, Project_except=&Project_except, Final_compare=&Final_compare )
    
  %end;
  %else %do;
  
    %err_mput( macro=Update_Sec8mf, msg=%str(Update file &Update_file is not after last update for this data source (&Last_update_date_fmt).) )
    %err_mput( macro=Update_Sec8mf, msg=%str(Update will NOT be applied to Catalog.) )

  %end;

  %note_mput( macro=Update_Sec8mf, msg=%str(Macro exiting.) )
    
%mend Update_Sec8mf;

/** End Macro Definition **/

