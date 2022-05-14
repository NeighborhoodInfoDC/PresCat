/**************************************************************************
 Program:  282_Reac_fix.sas
 Library:  PresCat
 Project:  Urban-Greater DC
 Author:   P. Tatian
 Created:  05/14/22
 Version:  SAS 9.4
 Environment:  Local Windows session (desktop)
 GitHub issue:  282
 
 Description:  Remove duplicate entries from Prescat.Reac_score and
 refresh with HUD source data. 

 Modifications:
**************************************************************************/

%include "\\sas1\DCdata\SAS\Inc\StdLocal.sas";

** Define libraries **;
%DCData_lib( PresCat )
%DCData_lib( HUD )


** Create REMS - NLIHC_ID cross walk **;

%Update_reac_init()


** Compile HUD REAC data for DC **;

%global _files;

proc sql noprint;
  select memname into :_files separated by ' ' from dictionary.tables
  where upcase( libname ) = "HUD" and 
    upcase( substr( memname, 1, 5 ) ) = "REAC_" and upcase( substr( memname, length( memname ) - 1, 2 ) ) = "DC"
  order by memname;
quit;

%put _files=&_files;


/** Macro output_score - Start Definition **/

%macro output_score( num );

  if not( missing( inspec_score_&num. ) ) then do;

    reac_date = input( release_date_&num., anydtdte10. );
    reac_inspec_id = inspec_id_&num.;
    reac_score = left( lowcase( inspec_score_&num. ) );
    
    j = indexc( reac_score, 'abcdefghijklmnopqrstuvwxyz' );
    
    reac_score_num = input( substr( reac_score, 1, j - 1 ), 3. );
    reac_score_letter = substr( reac_score, j, 1 );
    reac_score_star = substr( reac_score, j + 1, 1 );
    
    output;
    
  end;

%mend output_score;

/** End Macro Definition **/


/** Macro process_files - Start Definition **/

%macro process_files(  );

  %local i v;
  
  data A;
  
    length file $ 32;
    
    set
    
    %let i = 1;
    %let v = %scan( &_files, &i, %str( ) );

    %do %until ( &v = );

      hud.&v (in=in_&v)

      %let i = %eval( &i + 1 );
      %let v = %scan( &_files, &i, %str( ) );

    %end;

    ;
    by rems_property_id;
    
    select;
    
      %let i = 1;
      %let v = %scan( &_files, &i, %str( ) );

      %do %until ( &v = );
    
        when ( in_&v ) file = "&v";
      
        %let i = %eval( &i + 1 );
        %let v = %scan( &_files, &i, %str( ) );

      %end;
    
    end;
        
    length nlihc_id $ 16 reac_id $ 9 reac_score reac_inspec_id $ 8 reac_score_letter reac_score_star $ 1;
    
    reac_id = rems_property_id;
    nlihc_id = left( put( reac_id, $reac_nlihcid. ) );
    
    %output_score( 1 )
    %output_score( 2 )
    %output_score( 3 )
    
    format reac_date mmddyy10.;
    
    label reac_inspec_id = "REAC inspection ID number";
    
    keep file nlihc_id reac_date reac_id reac_score reac_inspec_id reac_score_letter reac_score_num reac_score_star
         property_name;

  run;


%mend process_files;

/** End Macro Definition **/


%process_files()

proc print data=A (obs=100);
run;


** Create unique inspection records **;

proc sort data=A;
  by nlihc_id reac_inspec_id file;
run;

data unique_inspec;

  set A;
  by nlihc_id reac_inspec_id;
  
  if last.reac_inspec_id then output;
  
run;

proc print data=unique_inspec;
  where nlihc_id = "NL000217";
  id nlihc_id reac_inspec_id;
run;

title2 "Inspections with missing NLIHC_ID";

proc print data=unique_inspec;
  where missing( nlihc_id );
  id nlihc_id reac_inspec_id;
run;

title2;


** Find earliest inspection date in HUD data **;

proc summary data=unique_inspec nway;
  where not( missing( nlihc_id ) );
  class nlihc_id;
  var reac_date;
  output out=First_hud_date min()=first_hud_date;
run;

proc print data=First_hud_date (obs=20);
  id nlihc_id;
run;


** Update Prescat.Reac_score **;

proc sort data=unique_inspec;
  by nlihc_id descending reac_date;
run;

data Pre_HUD_scores;

  merge 
    Prescat.Reac_score 
    First_hud_date (keep=nlihc_id first_hud_date);
  by nlihc_id;
  
  if not( missing( reac_date ) ) and reac_date < first_hud_date;
  
  *drop first_hud_date;
  
run;

proc print data=Pre_HUD_scores;
  where nlihc_id = "NL000217";
  id nlihc_id reac_date;
run;

data Reac_score;

  set
    unique_inspec (where=(not(missing(nlihc_id))))
    Pre_HUD_scores;
  by nlihc_id descending reac_date;
  
  keep nlihc_id reac_date reac_id reac_inspec_id reac_score: ; 
  
run;

proc print data=Reac_score;
  where nlihc_id = "NL000217";
  id nlihc_id reac_date;
run;

proc compare base=Prescat.Reac_score compare=Reac_score listvars maxprint=(40,32000);
  id nlihc_id descending reac_date;
run;

%Finalize_data_set( 
  /** Finalize data set parameters **/
  data=Reac_score,
  out=Reac_score,
  outlib=PresCat,
  label="Preservation Catalog, REAC scores",
  sortby=nlihc_id descending reac_date,
  /** Metadata parameters **/
  restrictions=None,
  revisions=%str(Correct inspection records; add reac_inspec_id var.),
  /** File info parameters **/
  contents=Y,
  printobs=40,
  printchar=N,
  printvars=,
  freqvars=,
  stats=n sum mean stddev min max
)

