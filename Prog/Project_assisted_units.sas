/**************************************************************************
 Program:  Project_assisted_units.sas
 Library:  PresCat
 Project:  NeighborhoodInfo DC
 Author:   P. Tatian
 Created:  10/15/14
 Version:  SAS 9.2
 Environment:  Local Windows session (desktop)
 
 Description:  Summarize assisted units by project.
 Program based on NLIHC\Prog\Assisted_units.sas, which was used for 
 the 2011 DC Housing Monitor analysis.

 Modifications:
**************************************************************************/

%include "\\sas1\DCdata\SAS\Inc\StdLocal.sas";

** Define libraries **;
%DCData_lib( PresCat )
%DCData_lib( RealProp )

%let PUBHSNG  = 1;
%let S8PROG   = 2;
%let LIHTC    = 3;
%let HOME     = 4;
%let CDBG     = 5;
%let HPTF     = 6;
%let TEBOND   = 7;
%let HUDMORT  = 8;
%let S202811  = 9;
%let OTHER    = 10;
%let MAXPROGS = 10;

proc format;
  value ProgCat (notsorted)
    1 = 'Public housing'
    2 = 'Section 8 only'
    9 = 'Section 8 and other subsidies'
    8 = 'LIHTC w/tax exempt bonds'
    3 = 'LIHTC w/o tax exempt bonds'
    7 = 'HUD-insured mortgage only'
    4,5 = 'HOME/CDBG only'
    6 = 'DC HPTF only'
    10 = 'Section 202/811 only'
    20, 30 = 'Other subsidies/combinations';
  value ward
    1 = 'Ward 1'
    2 = 'Ward 2'
    3 = 'Ward 3'
    4 = 'Ward 4'
    5 = 'Ward 5'
    6 = 'Ward 6'
    7 = 'Ward 7'
    8 = 'Ward 8';

%Data_to_format(
  FmtLib=work,
  FmtName=$nlihcid2cat,
  Desc=,
  Data=PresCat.Project_category,
  Value=nlihc_id,
  Label=category_code,
  OtherLabel='',
  DefaultLen=1,
  Print=N,
  Contents=N
  )

** Aggregate subsidies so one record per portfolio **;

proc summary data=PresCat.Subsidy (where=(Subsidy_Active and Portfolio~='PRAC')) nway;
  class nlihc_id portfolio;
  var Units_assist Poa_start Poa_end Compl_end;
  output out=Subsidy_unique 
    sum(Units_assist)= min(Poa_start Poa_end Compl_end)=;
run;

** Combine project and subsidy data **;

data Project_subsidy;

  merge
    Prescat.Project_category_view
      (in=inProject)
    Subsidy_unique
      (in=inSubsidy);
  by NLIHC_ID;
  
  if inProject and inSubsidy;
  
run;

data Project_assisted_units;

  set Project_subsidy;
  by NLIHC_ID;
  
  retain num_progs total_units min_asst_units max_asst_units asst_units1-asst_units&MAXPROGS
         poa_start_min poa_end_min poa_end_max compl_end_min compl_end_max proj_ayb_min;

  array a_aunits{&MAXPROGS} asst_units1-asst_units&MAXPROGS;
  
  if first.NLIHC_ID then do;
  
    total_units = .;
    num_progs = 0;
    
    min_asst_units = .;
    mid_asst_units = .;
    max_asst_units = .;
    
    poa_start = .;
    poa_end_min = .;
    poa_end_max = .;

    compl_end_min = .;
    compl_end_max = .;
    
    proj_ayb_min = .;

    do i = 1 to &MAXPROGS;
      a_aunits{i} = 0;
    end;
      
  end;
  
  num_progs + 1;
  
  total_units = max( total_units, Proj_Units_Tot, Units_Assist );

  select ( portfolio );
    when ( 'PUBHSNG' ) a_aunits{&PUBHSNG} = sum( Units_Assist, a_aunits{&PUBHSNG} );
    when ( 'PB8' ) a_aunits{&S8PROG} = sum( Units_Assist, a_aunits{&S8PROG} );
    when ( 'LIHTC' ) a_aunits{&LIHTC} = sum( Units_Assist, a_aunits{&LIHTC} );
    when ( 'HOME' ) a_aunits{&HOME} = sum( Units_Assist, a_aunits{&HOME} );
    when ( 'CDBG' ) a_aunits{&CDBG} = sum( Units_Assist, a_aunits{&CDBG} );
    when ( 'DC HPTF' ) a_aunits{&HPTF} = sum( Units_Assist, a_aunits{&HPTF} );
    when ( 'TEBOND' ) a_aunits{&TEBOND} = sum( Units_Assist, a_aunits{&TEBOND} );
    when ( 'HUDMORT' ) a_aunits{&HUDMORT} = sum( Units_Assist, a_aunits{&HUDMORT} );
    when ( '202/811' ) a_aunits{&S202811} = sum( Units_Assist, a_aunits{&S202811} );
    otherwise a_aunits{&OTHER} = sum( Units_Assist, a_aunits{&OTHER} );
  end;
  
  min_asst_units = max( Units_Assist, min_asst_units );
  
  poa_start_min = min( poa_start, poa_start_min );
  
  if poa_end > 0 then do;
    poa_end_min = min( poa_end, poa_end_min );
    poa_end_max = max( poa_end, poa_end_max );
  end;
  
  compl_end_min = min( compl_end, compl_end_min );
  compl_end_max = max( compl_end, compl_end_max );
  
  if proj_ayb > 0 then proj_ayb_min = min( proj_ayb, proj_ayb_min );
  
  if last.NLIHC_ID then do;
  
    do i = 1 to &MAXPROGS;
      a_aunits{i} = min( a_aunits{i}, total_units );
    end;

    max_asst_units = min( sum( of asst_units1-asst_units&MAXPROGS ), total_units );
    
    mid_asst_units = min( round( mean( min_asst_units, max_asst_units ), 1 ), max_asst_units );
    
    if mid_asst_units ~= max_asst_units then err_asst_units = max_asst_units - mid_asst_units;
    
    ** Reporting categories **;
    
    if num_progs = 1 then do;
    
      if a_aunits{&PUBHSNG} > 0 then ProgCat = 1;
      else if a_aunits{&S8PROG} > 0 then ProgCat = 2;
      else if a_aunits{&LIHTC} > 0 then ProgCat = 3;
      else if a_aunits{&HOME} > 0 then ProgCat = 4;
      else if a_aunits{&CDBG} > 0 then ProgCat = 5;
      else if a_aunits{&HPTF} > 0 then ProgCat = 6;
      else if a_aunits{&HUDMORT} > 0 then ProgCat = 7;
      else if a_aunits{&S202811} > 0 then ProgCat = 10;
      else if a_aunits{&TEBOND} > 0 or a_aunits{&OTHER} > 0 then ProgCat = 20;
    
    end;
    else do;
    
      if a_aunits{&S8PROG} > 0 then ProgCat = 9;
      else if a_aunits{&LIHTC} > 0 and a_aunits{&TEBOND} > 0 then ProgCat = 8;
      else if a_aunits{&LIHTC} > 0 then ProgCat = 3;
      else ProgCat = 30;
      
    end;
    
    if min_asst_units > 0 then output;
  
  end;
  
  format poa_start_min poa_end_min poa_end_max compl_end_min compl_end_max mmddyy10.;
  
  drop i portfolio Units_Assist poa_start poa_end compl_end proj_ayb _freq_ _type_;

run;

%File_info( data=Project_assisted_units, printobs=0, freqvars=ProgCat Ward2022 Geo2020 )

%let rpt_suffix = %sysfunc( putn( %sysfunc( today() ), yymmddn8. ) );

options orientation=landscape;

options missing='0';
options nodate nonumber;

%fdate()

ods rtf file="&_dcdata_default_path\PresCat\Prog\Project_assisted_units_&rpt_suffix..rtf" style=Styles.Rtf_arial_9pt;

title2 " ";
title3 "Project and assisted unit counts by subsidy portfolio (nonunique counts)";

proc tabulate data=PresCat.Subsidy format=comma10. noseps missing;
  where Subsidy_Active and put( nlihc_id, $nlihcid2cat. ) in ( '1', '2', '3', '4', '5' );
  class Portfolio;
  var units_assist;
  table 
    /** Rows **/
    Portfolio=' ',
    /** Columns **/
    ( n='Projects' sum='Assisted\~Units' ) * units_assist=' '
  ;
  footnote1 height=9pt "Source: DC Preservation Catalog";
  footnote2 height=9pt "Prepared by Urban-Greater DC (greaterdc.urban.org), &fdate..";
  footnote3 height=9pt j=r '{Page}\~{\field{\*\fldinst{\pard\b\i0\chcbpat8\qc\f1\fs19\cf1{PAGE }\cf0\chcbpat0}}}';
run;


title3 "Project and assisted unit unique counts";

proc tabulate data=Project_assisted_units format=comma10. noseps missing;
  where ProgCat ~= .;
  class ProgCat / preloadfmt order=data;
  class ward2022;
  var mid_asst_units err_asst_units;
  table 
    /** Rows **/
    all='\b Total' ProgCat=' ',
    /** Columns **/
    n='Projects'
    sum='Assisted Units' * ( mid_asst_units='Est.' err_asst_units='+/-' )
    ;
  format ProgCat ProgCat.;
run;


title3 "Project and assisted unit unique counts by ward";

proc tabulate data=Project_assisted_units format=comma10. noseps missing;
  where ProgCat ~= . and not( missing( ward2022 ) );
  class ProgCat / preloadfmt order=data;
  class ward2022;
  var mid_asst_units err_asst_units;
  table 
    /** Rows **/
    ( all='DC Total' ward2022=' ' )
    ,
    /** Columns **/
    n='Projects' * ( all='\b Total' ProgCat=' ' ) * mid_asst_units=' '
    ;
  table 
    /** Rows **/
    ( all='DC Total' ward2022=' ' )
    ,
    /** Columns **/
    sum='Assisted Units' * ( all='\b Total' ProgCat=' ' ) * mid_asst_units=' '
    ;
  format ProgCat ProgCat.;
run;


ods rtf close;

title2;
footnote1;

run;

