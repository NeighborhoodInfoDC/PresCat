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

%include "L:\SAS\Inc\StdLocal.sas";

** Define libraries **;
%DCData_lib( PresCat, local=n )

%let MAXPROGS = 8;
%let PUBHSNG  = 1;
%let S8PROG   = 2;
%let LIHTC    = 3;
%let HOME     = 4;
%let CDBG     = 5;
%let HPTF     = 6;
%let TEBOND   = 7;
%let OTHER    = 8;

proc format;
  value ProgCat (notsorted)
    1 = 'Public Housing only'
    2 = 'Section 8 only'
    9 = 'Section 8 and other subsidies'
    3 = 'LIHTC only'
    4 = 'HOME only'
    5 = 'CDBG only'
    6 = 'HPTF only'
    /*7 = 'Other single subsidy'*/
    8 = 'LIHTC and Tax Exempt Bond only'
    7, 10 = 'All other combinations';
  value ward
    1 = 'Ward 1'
    2 = 'Ward 2'
    3 = 'Ward 3'
    4 = 'Ward 4'
    5 = 'Ward 5'
    6 = 'Ward 6'
    7 = 'Ward 7'
    8 = 'Ward 8';
    
** Combine project and subsidy data **;

data Project_subsidy;

  merge
    PresCat.Project
      (drop=Cat_: Hud_Mgr_: Hud_Own_:)
    PresCat.Subsidy
      (keep=NLIHC_ID Portfolio Subsidy_Active Units_Assist POA_end
       where=(Subsidy_Active));
  by NLIHC_ID;

run;

data Assisted_units;

  set Project_subsidy 
        (where=(portfolio~='Project Rental Assistance Contract (PRAC)'));
  by NLIHC_ID;
  
  retain num_progs total_units min_asst_units max_asst_units asst_units1-asst_units&MAXPROGS
         poa_end_min poa_end_max;

  array a_aunits{&MAXPROGS} asst_units1-asst_units&MAXPROGS;
  
  if first.NLIHC_ID then do;
  
    total_units = .;
    num_progs = 0;
    
    min_asst_units = .;
    mid_asst_units = .;
    max_asst_units = .;
    
    poa_end_min = .;
    poa_end_max = .;

    do i = 1 to &MAXPROGS;
      a_aunits{i} = 0;
    end;
      
  end;
  
  num_progs + 1;
  
  total_units = max( total_units, Proj_Units_Tot, Units_Assist );

  select ( portfolio );
    when ( 'PUBHSNG' ) a_aunits{&PUBHSNG} = Units_Assist;
    when ( 'PB8' ) a_aunits{&S8PROG} = Units_Assist;
    when ( "LIHTC" ) a_aunits{&LIHTC} = Units_Assist;
    when ( "HOME" ) a_aunits{&HOME} = Units_Assist;
    when ( 'CDBG' ) a_aunits{&CDBG} = Units_Assist;
    when ( 'DC HPTF' ) a_aunits{&HPTF} = Units_Assist;
    when ( 'TEBOND' ) a_aunits{&TEBOND} = Units_Assist;
    otherwise a_aunits{&OTHER} = sum( Units_Assist, a_aunits{&OTHER} );
  end;
  
  min_asst_units = max( Units_Assist, min_asst_units );
  
  poa_end_min = min( poa_end, poa_end_min );
  poa_end_max = min( poa_end, poa_end_max );
  
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
      else if a_aunits{&TEBOND} > 0 or a_aunits{&OTHER} > 0 then ProgCat = 7;
    
    end;
    else do;
    
      if num_progs = 2 and a_aunits{&LIHTC} > 0 and a_aunits{&TEBOND} > 0 then ProgCat = 8;
      else if a_aunits{&S8PROG} > 0 then ProgCat = 9;
      else ProgCat = 10;
      
    end;
    
    if min_asst_units > 0 then output;
  
  end;
  
  format poa_end_min poa_end_max mmddyy10.;
  
  drop i portfolio Subsidy_Active Units_Assist poa_end;

run;

proc sort data=Assisted_units out=PresCat.Project_assisted_units;
  by ProgCat NLIHC_ID;

%File_info( data=PresCat.Project_assisted_units, printobs=0, freqvars=ProgCat Ward2012 Geo2010 )

proc print data=PresCat.Project_assisted_units n='Projects = ';
  by ProgCat;
  id NLIHC_ID;
  var total_units min_asst_units mid_asst_units max_asst_units asst_units: poa_end_min poa_end_max;
  sum total_units min_asst_units mid_asst_units max_asst_units asst_units: ;
  format ProgCat ProgCat. total_units min_asst_units mid_asst_units max_asst_units asst_units: comma6.0
         poa_end_min poa_end_max mmddyy8.;
run;

ods rtf file="&_dcdata_r_path\PresCat\Prog\Project_assisted_units.rtf" style=Styles.Rtf_arial_9pt;

options missing='0';

proc tabulate data=PresCat.Project_assisted_units format=comma10. noseps missing;
  where ProgCat ~= .;
  class ProgCat / preloadfmt order=data;
  class ward2012;
  var mid_asst_units err_asst_units;
  table 
    /** Rows **/
    all='\b Total' ProgCat=' ',
    /** Columns **/
    n='Projects'
    sum='Assisted Units' * ( mid_asst_units='Est.' err_asst_units='+/-' )
    ;
  table 
    /** Rows **/
    all='\b Total' ProgCat=' ',
    /** Columns **/
    sum='Assisted Units by Ward' * ward2012=' ' * ( mid_asst_units='Est.' err_asst_units='+/-' )
    ;
  format ProgCat ProgCat.;
  
run;

ods rtf close;

run;
