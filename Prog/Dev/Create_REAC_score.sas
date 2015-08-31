/**************************************************************************
 Program:  Create_REAC_score.sas
 Library:  PresCat
 Project:  NeighborhoodInfo DC
 Author:   P. Tatian
 Created:  08/20/13
 Version:  SAS 9.1
 Environment:  Windows
 
 Description:  Create REAC_score table for DC Preservation Catalog.

 Modifications:
  12/19/14 PAT Updated for SAS1. Added variable labels.
  08/31/15 PAT Replace PresCat.DC_Info with PresCat.DC_Info_07_08_15.
**************************************************************************/

%include "L:\SAS\Inc\StdLocal.sas";

** Define libraries **;
%DCData_lib( PresCat, local=n )

proc print data=PresCat.DC_info_07_08_15 (obs=100);
  id nlihc_id;
  var pass: ;
run;

data PresCat.REAC_score (label="Preservation Catalog, REAC scores");

  length Nlihc_id $ 8;

  set PresCat.DC_Info_07_08_15 (keep=nlihc_id pass:);
  
  array scores{*} pass1_score pass2_score pass3_score;
  array dates{*} pass1_date pass2_date pass3_date;
  
  length REAC_date 8 REAC_score $ 8 REAC_score_num 8 REAC_score_letter $ 1 REAC_score_star $ 1;
  
  do i = 1 to dim( scores );
  
    if not( missing ( scores{i} ) ) then do;
    
      REAC_date = datepart( dates{i} );
      REAC_score = left( lowcase( scores{i} ) );
      
      j = indexc( REAC_score, 'abcdefghijklmnopqrstuvwxyz' );
      
      REAC_score_num = input( substr( REAC_score, 1, j - 1 ), 3. );
      REAC_score_letter = substr( REAC_score, j, 1 );
      REAC_score_star = substr( REAC_score, j + 1, 1 );
      
      output;
      
    end;
    
  end;
  
  label
    Nlihc_id = "Preservation Catalog project ID"
    REAC_date = "Date of REAC inspection"
    REAC_score = "REAC inspection score"
    REAC_score_num = "REAC inspection score, number part"
    REAC_score_letter = "REAC inspection score, letter part"
    REAC_score_star = "REAC inspection score, star (*) part";
      
  keep nlihc_id REAC_: ;
  
  format REAC_date mmddyy10.;

run;

proc sort data=PresCat.REAC_score;
  by nlihc_id descending REAC_date;

%File_info( data=PresCat.REAC_score, printobs=100, freqvars=REAC_score_letter REAC_score_star )


**** Compare with earlier version ****;

libname comp 'D:\DCData\Libraries\PresCat\Data\Old';

proc compare base=Comp.Reac_score compare=PresCat.Reac_score listall maxprint=(40,32000);
  id nlihc_id descending REAC_date;
run;
