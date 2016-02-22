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
  value $tempphfix
    "NL000413" = "DEL"
    "NL000394" = "???"
    "NL000410" = "???"
    "NL000362" = "LECOOP"
    "NL000414" = "???"
    "NL000393" = "LECOOP"
    "NL000390" = "???"
    "NL000399" = "???"
    "NL000010" = "NO"
    "NL000392" = "???"
    "NL000115" = "NO"
    "NL000391" = "???"
    "NL000405" = "???"
    "NL000396" = "???"
    "NL000404" = "COMCON"
    "NL000409" = "???"
    "NL000408" = "???"
    "NL000397" = "???"
    "NL000264" = "PUBHSNG"
    "NL000337" = "???"
    "NL000033" = "???"
    "NL000034" = "PUBHSNG"
    "NL000043" = "PUBHSNG"
    "NL001000" = "PUBHSNG"
    "NL000050" = "PUBHSNG"
    "NL000375" = "PUBHSNG"
    "NL000990" = "PUBHSNG"
    "NL000056" = "???"
    "NL000058" = "PUBHSNG"
    "NL001007" = "???"
    "NL000411" = "LECOOP"
    "NL000066" = "???"
    "NL000398" = "???"
    "NL000071" = "PUBHSNG"
    "NL000075" = "PUBHSNG"
    "NL000078" = "PUBHSNG"
    "NL000079" = "???"
    "NL000403" = "COMCON"
    "NL000402" = "COMCON"
    "NL000301" = "PUBHSNG"
    "NL000097" = "PUBHSNG"
    "NL000106" = "???"
    "NL000110" = "PUBHSNG"
    "NL000407" = "???"
    "NL000121" = "PUBHSNG"
    "NL000129" = "PUBHSNG"
    "NL000130" = "PUBHSNG"
    "NL000148" = "???"
    "NL000132" = "???"
    "NL000145" = "PUBHSNG"
    "NL000146" = "PUBHSNG"
    "NL000325" = "???"
    "NL000150" = "PUBHSNG"
    "NL000388" = "PUBHSNG"
    "NL000158" = "PUBHSNG"
    "NL000157" = "PUBHSNG"
    "NL000161" = "PUBHSNG"
    "NL000162" = "PUBHSNG"
    "NL000169" = "???"
    "NL000171" = "???"
    "NL000173" = "PUBHSNG"
    "NL000174" = "PUBHSNG"
    "NL000401" = "???"
    "NL000177" = "PUBHSNG"
    "NL000178" = "PUBHSNG"
    "NL000181" = "PUBHSNG"
    "NL000184" = "PUBHSNG"
    "NL000418" = "PUBHSNG"
    "NL000188" = "PUBHSNG"
    "NL000191" = "PUBHSNG"
    "NL000192" = "PUBHSNG"
    "NL000193" = "PUBHSNG"
    "NL000194" = "PUBHSNG"
    "NL000204" = "???"
    "NL000205" = "PUBHSNG"
    "NL000412" = "LECOOP"
    "NL000219" = "PUBHSNG"
    "NL000232" = "???"
    "NL000221" = "???"
    "NL000231" = "???"
    "NL000389" = "LECOOP"
    "NL000244" = "PUBHSNG"
    "NL000245" = "PUBHSNG"
    "NL000248" = "PUBHSNG"
    "NL000249" = "PUBHSNG"
    "NL001009" = "???"
    "NL000266" = "???"
    "NL000268" = "PUBHSNG"
    "NL000276" = "???"
    "NL000282" = "PUBHSNG"
    "NL000287" = "PUBHSNG"
    "NL000289" = "PUBHSNG"
    "NL001008" = "???"
    "NL000225" = "PUBHSNG"
    "NL000302" = "PUBHSNG"
    "NL000419" = "PUBHSNG"
    "NL000312" = "???"
    "NL000270" = "???"
    "NL000349" = "???"
    "NL000317" = "PUBHSNG"
    "NL000415" = "???"
    "NL000395" = "???"
    "NL000327" = "PUBHSNG"
    "NL000329" = "PUBHSNG"
    "NL000400" = "???"
    "NL000333" = "PUBHSNG";
  
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
  var Units_assist Poa_end Compl_end;
  output out=Subsidy_unique 
    sum(Units_assist)= min(Poa_end Compl_end)=;
run;

** Combine project and subsidy data **;

data Project_subsidy;

  merge
    PresCat.Project
      (drop=Cat_: Hud_Mgr_: Hud_Own_:
       where=(put( nlihc_id, $nlihcid2cat. ) in ( '1', '2', '3', '4', '5' ))
       in=inProject)
    Subsidy_unique
      (in=inSubsidy);
  by NLIHC_ID;
  
  if inProject and inSubsidy;
  
  if Portfolio = "PUBHSNG" then do;
    Portfolio = put( Portfolio, $tempphfix. );
    if Portfolio ~= "PUBHSNG" then delete;
  end;

run;

data Assisted_units;

  set Project_subsidy;
  by NLIHC_ID;
  
  retain num_progs total_units min_asst_units max_asst_units asst_units1-asst_units&MAXPROGS
         poa_end_min poa_end_max compl_end_min compl_end_max;

  array a_aunits{&MAXPROGS} asst_units1-asst_units&MAXPROGS;
  
  if first.NLIHC_ID then do;
  
    total_units = .;
    num_progs = 0;
    
    min_asst_units = .;
    mid_asst_units = .;
    max_asst_units = .;
    
    poa_end_min = .;
    poa_end_max = .;

    compl_end_min = .;
    compl_end_max = .;

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
  
  poa_end_min = min( poa_end, poa_end_min );
  poa_end_max = max( poa_end, poa_end_max );
  
  compl_end_min = min( compl_end, compl_end_min );
  compl_end_max = max( compl_end, compl_end_max );
  
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
  
  format poa_end_min poa_end_max compl_end_min compl_end_max mmddyy10.;
  
  drop i portfolio Units_Assist poa_end compl_end _freq_ _type_;

run;

proc sort data=Assisted_units 
    out=PresCat.Project_assisted_units 
          (label="Preservation Catalog, Assisted unit counts by project and subsidy portfolio");
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
options nodate nonumber;

%fdate()

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
  title2 " ";
  title3 "Project and assisted unit counts by subsidy portfolio (nonunique counts)";
  footnote1 height=9pt "Source: DC Preservation Catalog";
  footnote2 height=9pt "Prepared by NeighborhoodInfo DC (www.NeighborhoodInfoDC.org), &fdate..";
  footnote3 height=9pt j=r '{Page}\~{\field{\*\fldinst{\pard\b\i0\chcbpat8\qc\f1\fs19\cf1{PAGE }\cf0\chcbpat0}}}';
run;

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
  title3 "Project and assisted unit unique counts";
run;

ods rtf close;

run;
