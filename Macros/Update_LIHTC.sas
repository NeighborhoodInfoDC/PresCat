/**************************************************************************
 Program:  Update_LIHTC.sas
 Library:  PresCat
 Project:  NeighborhoodInfo DC
 Author:   P. Tatian
 Created:  12/21/15
 Version:  SAS 9.2
 Environment:  -
 
 Description:  Autocall macro to update PresCat.Project and
 PresCat.Subsidy with LIHTC data set.

 Modifications:
**************************************************************************/

/** Macro Update_LIHTC - Start Definition **/

%macro Update_LIHTC( 
  Update_file=, 
  Finalize=Y,
  Project_except=Project_except,
  Subsidy_except=Subsidy_except,
  Manual_subsidy_match=,
  Manual_project_match=,
  Address_correct=,
  Quiet=Y,
  Final_compare=Y
  );
  
  %if %upcase( &Finalize ) = Y and not &_remote_batch_submit %then %do;
    %warn_mput( macro=Update_LIHTC, msg=%str(Not a remote batch submit session. Finalize will be set to N.) )
    %let Finalize = N;
  %end;

  %Update_LIHTC_init( Update_file=&Update_file )

  %if &Last_update_date = or &Last_update_date < &Subsidy_Info_Source_Date %then %do;
  
    %Update_LIHTC_subsidy( Update_file=&Update_file, Subsidy_except=&Subsidy_except, Manual_subsidy_match=&Manual_subsidy_match, Manual_project_match=&Manual_project_match, Address_correct=&Address_correct, Quiet=&Quiet )

    %Update_LIHTC_project( Update_file=&Update_file, Project_except=&Project_except, Quiet=&Quiet )

    %Update_LIHTC_finish( Update_file=&Update_file, Finalize=&Finalize, Subsidy_except=&Subsidy_except, Project_except=&Project_except, Final_compare=&Final_compare )

  %end;
  %else %do;
  
    %err_mput( macro=Update_LIHTC, msg=%str(Update file &Update_file is not after last update for this data source (&Last_update_date_fmt).) )
    %err_mput( macro=Update_LIHTC, msg=%str(Update will NOT be applied to Catalog.) )

  %end;

  %note_mput( macro=Update_LIHTC, msg=%str(Macro exiting.) )
    
%mend Update_LIHTC;

/** End Macro Definition **/

