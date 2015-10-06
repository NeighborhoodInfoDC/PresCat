/**************************************************************************
 Program:  Update_MFIS.sas
 Library:  PresCat
 Project:  NeighborhoodInfo DC
 Author:   P. Tatian
 Created:  09/19/15
 Version:  SAS 9.2
 Environment:  -
 
 Description:  Autocall macro to update PresCat.Project and
 PresCat.Subsidy with MFIS data set.

 Modifications:
**************************************************************************/

/** Macro Update_MFIS - Start Definition **/

%macro Update_MFIS( 
  Update_file=, 
  Finalize=N,
  Project_except=Project_except,
  Subsidy_except=Subsidy_except,
  Quiet=Y,
  Final_compare=Y
  );
  
  %if %upcase( &Finalize ) = Y and not &_remote_batch_submit %then %do;
    %warn_mput( macro=Update_MFIS, msg=%str(Not a remote batch submit session. Finalize will be set to N.) )
    %let Finalize = N;
  %end;

  %Update_MFIS_init( Update_file=&Update_file )

  %if &Last_update_date = or &Last_update_date < &Subsidy_Info_Source_Date %then %do;
  
    %Update_MFIS_subsidy( Update_file=&Update_file, Subsidy_except=&Subsidy_except, Quiet=&Quiet )
    
    %Update_MFIS_project( Update_file=&Update_file, Project_except=&Project_except, Quiet=&Quiet )
    
    %Update_MFIS_finish( Update_file=&Update_file, Finalize=&Finalize, Subsidy_except=&Subsidy_except, Project_except=&Project_except, Final_compare=&Final_compare )
    
  %end;
  %else %do;
  
    %err_mput( macro=Update_MFIS, msg=%str(Update file &Update_file is not after last update for this data source (&Last_update_date_fmt).) )
    %err_mput( macro=Update_MFIS, msg=%str(Update will NOT be applied to Catalog.) )

  %end;

  %note_mput( macro=Update_MFIS, msg=%str(Macro exiting.) )
    
%mend Update_MFIS;

/** End Macro Definition **/

