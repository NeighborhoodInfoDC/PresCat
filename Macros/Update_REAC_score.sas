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
    
 
  ** Normalize exception file;

  /*%Except_norm( data=&REAC_score_except, by=nlihc_id reac_date )*/


  **************************************************************************
  ** Get data for updating REAC_score file;

  data Update_&Update_file;

	set Hud.&Update_file._dc;

	length 
	REAC_date 8 
	REAC_score $ 8 
	REAC_score_num 8 
	REAC_score_letter $ 1 
	REAC_score_star $ 1
	REAC_ID $ 9;

    nlihc_id = put( rems_property_id, $reac_nlihcid. );
	array arelease_date(3) release_date_1 release_date_2 release_date_3 ;
	array ascore(3) inspec_score_1 inspec_score_2 inspec_score_3 ;

  	DO num = 1 to 3 ;
    date = arelease_date(num);
	reac_score = ascore(num);

	j = indexc( reac_score, 'abcdefghijklmnopqrstuvwxyz' );
      
      REAC_score_num = input( substr( reac_score, 1, j - 1 ), 3. );
      REAC_score_letter = substr( reac_score, j, 1 );
      REAC_score_star = substr( reac_score, j + 1, 1 );
	  REAC_date = input(compress(date, '-'), date7.);
	  REAC_ID = rems_property_id;
	  put reac_date mmddyy10.;

    OUTPUT;
  END;

  DROP release_date_1 release_date_2 release_date_3 inspec_id_1 inspec_id_2 inspec_id_3
	   inspec_score_1 inspec_score_2 inspec_score_3 num;


	label
    Nlihc_id = "Preservation Catalog project ID"
    REAC_date = "REAC inspection date"
    REAC_score = "REAC inspection score"
    REAC_score_num = "REAC inspection score, number part"
    REAC_score_letter = "REAC inspection score, letter part"
    REAC_score_star = "REAC inspection score, star (*) part"
	REAC_ID = "REMS Property ID";
      
  keep nlihc_id REAC_: ;
  
  format REAC_date mmddyy10.;

run;

/*  title2 '**** THERE SHOULD NOT BE ANY DUPLICATE RECORDS IN THE UPDATE FILE ****';

  %Dup_check(
    data=reac_update_recs,
    by=REAC_id,
    id=Nlihc_id
  )
  
  title2;*/

data reac_score_test;
set prescat.reac_score;
run;

  proc sort data=Update_&Update_file;
  by nlihc_id reac_date;
  run;

  proc sort data=reac_score_test;
  by nlihc_id reac_date;
  run;

data Update_&Update_file;
update reac_score_test Update_&Update_file;
by nlihc_id reac_date;
run;

  **************************************************************************
  ** End of macro;
  
  
%mend Update_REAC_score;

/** End Macro Definition **/

