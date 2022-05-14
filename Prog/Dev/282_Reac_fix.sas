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

proc sort data=Prescat.Reac_score (where=(not(missing(reac_id)))) out=xwalk nodupkey;
  by nlihc_id reac_id;
run;

%Data_to_format(
  FmtLib=work,
  FmtName=$reac_id_to_nlihc_id,
  Desc=,
  Data=xwalk,
  Value=reac_id,
  Label=nlihc_id,
  OtherLabel=" ",
  Print=N,
  Contents=N
  )


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
    nlihc_id = left( put( reac_id, $reac_id_to_nlihc_id. ) );
    
    %output_score( 1 )
    %output_score( 2 )
    %output_score( 3 )
    
    format reac_date mmddyys10.;
    
    keep file nlihc_id reac_date reac_id reac_score reac_inspec_id reac_score_letter reac_score_num reac_score_star;

  run;


%mend process_files;

/** End Macro Definition **/


%process_files()


proc print data=A (obs=100);
run;
