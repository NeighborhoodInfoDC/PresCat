/**************************************************************************
 Program:  Update_REAC_score.sas
 Library:  PresCat
 Project:  NeighborhoodInfo DC
 Author:   M. Cohen
 Created:  05/04/2017
 Version:  SAS 9.2
 Environment:  -
 
 Description:  Autocall macro to update PresCat.REAC_score
 with REAC data set.
 
 Modifications:
**************************************************************************/

/** Macro Update_Sec8mf_subsidy - Start Definition **/

%macro Update_REAC_score( Update_file=, Quiet=Y );

  
  **************************************************************************
  ** Initial setup and checks;
  
  %local Compare_opt;
  
  %if %upcase( &Quiet ) = N %then %do;
    %let Compare_opt = listall;
  %end;
  %else %do;
    %let Compare_opt = noprint;
  %end;
    
 
  **************************************************************************
  ** Get data for updating REAC_score file;

  data 
    Update_&Update_file._a (keep=nlihc_id REAC_:)
    Nomatch_&Update_file (keep=REAC_: property_name);

    set Hud.&Update_file._dc;

    length 
    REAC_inspec_id $ 8
    REAC_date 8 
    REAC_score $ 8 
    REAC_score_num 8 
    REAC_score_letter $ 1 
    REAC_score_star $ 1
    REAC_ID $ 9;

    nlihc_id = put( rems_property_id, $reac_nlihcid. );
    array arelease_date(3) release_date_1 release_date_2 release_date_3 ;
    array ascore(3) inspec_score_1 inspec_score_2 inspec_score_3 ;
    array ainspec_id(3) inspec_id_1 inspec_id_2 inspec_id_3 ;

    do num = 1 to 3 ;
    
      date = arelease_date(num);
      reac_score = lowcase(ascore(num));
      
      if not missing( reac_score ) then do;

        j = indexc( reac_score, 'abcdefghijklmnopqrstuvwxyz' );
        
        REAC_inspec_id = left( ainspec_id(num) );
        REAC_score_num = input( substr( reac_score, 1, j - 1 ), 3. );
        REAC_score_letter = substr( reac_score, j, 1 );
        REAC_score_star = substr( reac_score, j + 1, 1 );
        REAC_date = input(date, anydtdte10.);
        REAC_ID = rems_property_id;
      
        if missing( REAC_inspec_id ) then do;
          %err_put( macro=Update_REAC_score, msg="REAC inspection ID missing. " rems_property_id= reac_score= REAC_inspec_id= )
        end;

        else if missing( REAC_date ) then do;
          %err_put( macro=Update_REAC_score, msg="REAC date missing. " rems_property_id= reac_score= date= )
        end;

        else if not( missing( nlihc_id ) ) then output Update_&Update_file._a;

        else output Nomatch_&Update_file;
        
      end;
    
  end;

  label
    Nlihc_id = "Preservation Catalog project ID"
    REAC_inspec_id = "REAC inspection ID number"
    REAC_date = "REAC inspection date"
    REAC_score = "REAC inspection score"
    REAC_score_num = "REAC inspection score, number part"
    REAC_score_letter = "REAC inspection score, letter part"
    REAC_score_star = "REAC inspection score, star (*) part"
  REAC_ID = "REMS Property ID";
      
  format REAC_date mmddyy10.;

run;

title2 '**** Nonmatching REAC records';
title3 '**** Where possible, add matching NLIHC_ID to $reac_nlihcid. format in Macros\Update_REAC_init.sas';

proc print data=Nomatch_&Update_file;
  id REAC_id property_name;
  by REAC_id property_name;
  var REAC_date REAC_score;
run;

title2;

  ** Apply REAC update to existing data **;

  proc sort data=Update_&Update_file._a;
  by nlihc_id REAC_inspec_id;
  run;
  
  proc sort data=prescat.reac_score out=reac_score_test;
  by nlihc_id REAC_inspec_id;
  run;

  data Update_&Update_file;
    update reac_score_test Update_&Update_file._a;
    by nlihc_id REAC_inspec_id;
  run;

  **************************************************************************
  ** End of macro;
  
  
%mend Update_REAC_score;

/** End Macro Definition **/

