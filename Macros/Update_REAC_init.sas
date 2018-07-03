/**************************************************************************
 Program:  Update_REAC_init.sas
 Library:  PresCat
 Project:  NeighborhoodInfo DC
 Author:   M. Cohen
 Created:  07/3/18
 Version:  SAS 9.2
 Environment:  -
 
 Description:  Autocall macro to initialize macro variables and formats
 for REAC update.

 Modifications:
**************************************************************************/

/** Macro Update_REAC - Start Definition **/

%macro Update_REAC_init( Update_file= );

  %global 
	Update_dtm REAC_date REAC_score REAC_score_num REAC_score_letter REAC_score_star REAC_ID Subsidy_Info_Source_ID_src rems_property_id 
	inspec_score_1 release_date_1 inspec_score_2 release_date_2 inspec_score_3 release_date_3 property_name state city state_code;
    
  %let Update_dtm = %sysfunc( datetime() );
  
  %** REAC_score source specific parameters **;
  
  *%let REAC_score = ;
  *%let REAC_date = ;
    
  ** Create $nlihcid_proj. format to add project ID and names to update report **;

  %Data_to_format(
    FmtLib=work,
    FmtName=$nlihcid_proj,
    Desc=,
    Data=PresCat.Project (where=(not(missing(nlihc_id)))),
    Value=nlihc_id,
    Label=trim(nlihc_id)||' / '||left(proj_name),
    OtherLabel='** Unidentified project **',
    DefaultLen=.,
    MaxLen=.,
    MinLen=.,
    Print=N,
    Contents=N
    )

   ** Create $reac_nlihcid. format to add NLIHC ID from HUD property ID **;
  
  proc sql noprint;
    create table reac_nlihcid as
    select Subsidy_info_source_property as reac_id, nlihc_id, count(nlihc_id) as N
      from PresCat.Subsidy (where=(not(missing(subsidy_info_source_id)) and 
                                   not(missing(Subsidy_info_source_property))))
      group by reac_id, nlihc_id;
  quit;
  
  %Data_to_format(
    FmtLib=work,
    FmtName=$reac_nlihcid,
    Desc=,
    Data=reac_nlihcid,
    Value=reac_id,
    Label=nlihc_id,
    OtherLabel="",
    DefaultLen=.,
    MaxLen=.,
    MinLen=.,
    Print=N,
    Contents=N
    )

  ** Traffic-lighting format $except_tl. for update report **;
  /*
  proc format;
    value $except_tl
      "-", "n/a" = 'white'
      other = 'yellow';
  run;
*/
%mend Update_REAC_init;

/** End Macro Definition **/

