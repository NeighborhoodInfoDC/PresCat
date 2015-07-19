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
  Finalize=N,
  Project_except=Project_except,
  Subsidy_except=Subsidy_except
  );

  %Update_Sec8mf_init( Update_file=&Update_file )
  
  %Update_Sec8mf_subsidy( Update_file=&Update_file, Subsidy_except=&Subsidy_except )
  
  %Update_Sec8mf_project( Update_file=&Update_file, Project_except=&Project_except )
  
  %Update_Sec8mf_finish( Update_file=&Update_file, Finalize=&Finalize )

%mend Update_Sec8mf;

/** End Macro Definition **/

