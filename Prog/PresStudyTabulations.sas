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
%DCData_lib( NCDB )

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


***Creating new variables from parcel_own_type***;
data parcel_owner_type;
set Prescat.Parcel; 
	if parcel_owner_type = "010" then parcel_owner_type_010 = 1;
	if parcel_owner_type = "020" then parcel_owner_type_020 = 1;
	if parcel_owner_type = "030" then parcel_owner_type_030 = 1;
	if parcel_owner_type = "040" then parcel_owner_type_040 = 1;
	if parcel_owner_type = "045" then parcel_owner_type_045 = 1;
	if parcel_owner_type = "050" then parcel_owner_type_050 = 1;
	if parcel_owner_type = "070" then parcel_owner_type_070 = 1;
	if parcel_owner_type = "080" then parcel_owner_type_080 = 1;
	if parcel_owner_type = "100" then parcel_owner_type_100 = 1;
	if parcel_owner_type = "111" then parcel_owner_type_111 = 1;
	if parcel_owner_type = "115" then parcel_owner_type_115 = 1;

	run;

***Summarizing new variables by Nlihc_id***;
proc summary data=parcel_owner_type nway; 
  class nlihc_id;
  var parcel_owner_type_111 parcel_owner_type_045 parcel_owner_type_115 parcel_owner_type_020 parcel_owner_type_030
parcel_owner_type_050 parcel_owner_type_040 parcel_owner_type_080 parcel_owner_type_010 parcel_owner_type_100 parcel_owner_type_070;
  output out=parcel_owner_type max=;
run;

***Creating a combined summary variable of project owner type***;
data Project_Owner_Summary;
	set parcel_owner_type;
	if parcel_owner_type_111 = 1 then parcel_owner_type = "111";
	else if parcel_owner_type_045 = 1 then parcel_owner_type = "045";
	else if parcel_owner_type_115 = 1 then parcel_owner_type = "115";
	else if parcel_owner_type_020 = 1 then parcel_owner_type = "020";
	else if parcel_owner_type_030 = 1 then parcel_owner_type = "030";
	else if parcel_owner_type_050 = 1 then parcel_owner_type = "050";
	else if parcel_owner_type_040 = 1 then parcel_owner_type = "040";
	else if parcel_owner_type_080 = 1 then parcel_owner_type = "080";
	else if parcel_owner_type_010 = 1 then parcel_owner_type = "010";
	else if parcel_owner_type_100 = 1 then parcel_owner_type = "100";
	else if parcel_owner_type_070 = 1 then parcel_owner_type = "070";
	run;


** Combine project and subsidy data **;

data Project_subsidy;

  merge
    Prescat.Project_category_view
      (in=inProject)
    Subsidy_unique
      (in=inSubsidy)
	Project_Owner_Summary
	  (in=inOwner);
  by NLIHC_ID;
  
  if inProject and inSubsidy and inOwner;
  
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

  poa_end_min_year = year( poa_end_min );
    
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

ods rtf file="&_dcdata_default_path\PresCat\Prog\PresStudyTabulations.rtf" style=Styles.Rtf_arial_9pt;

footnote1 height=9pt "Prepared by Urban-Greater DC (greaterdc.urban.org), &fdate..";
footnote2 height=9pt j=r '{Page}\~{\field{\*\fldinst{\pard\b\i0\chcbpat8\qc\f1\fs19\cf1{PAGE }\cf0\chcbpat0}}}';


*****************Study Tabulations below here*********
************Tables by Location and Subsidy*********;

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

title3 "Project and assisted unit unique counts by ANC";

proc tabulate data=Project_assisted_units format=comma10. noseps missing;
  where ProgCat ~= . and not( missing( anc2012 ) );
  class ProgCat / preloadfmt order=data;
  class anc2012;
  var mid_asst_units err_asst_units;
  table 
    /** Rows **/
    ( all='DC Total' anc2012=' ' )
    ,
    /** Columns **/
    n='Projects' * ( all='\b Total' ProgCat=' ' ) * mid_asst_units=' '
    ;
  table 
    /** Rows **/
    ( all='DC Total' anc2012=' ' )
    ,
    /** Columns **/
    sum='Assisted Units' * ( all='\b Total' ProgCat=' ' ) * mid_asst_units=' '
    ;
  format ProgCat ProgCat.;
run;

title3 "Project and assisted unit unique counts by Neighborhood Custer";

proc tabulate data=Project_assisted_units format=comma10. noseps missing;
  where ProgCat ~= . and not( missing( cluster2017 ) );
  class ProgCat / preloadfmt order=data;
  class cluster2017;
  var mid_asst_units err_asst_units;
  table 
    /** Rows **/
    ( all='DC Total' cluster2017=' ' )
    ,
    /** Columns **/
    n='Projects' * ( all='\b Total' ProgCat=' ' ) * mid_asst_units=' '
    ;
  table 
    /** Rows **/
    ( all='DC Total' cluster2017=' ' )
    ,
    /** Columns **/
    sum='Assisted Units' * ( all='\b Total' ProgCat=' ' ) * mid_asst_units=' '
    ;
  format ProgCat ProgCat.;
run;

****Creat Data set for Age of Building Table***;
data Project_AOB;

  merge
    Project_assisted_units
		(in=inProject)
    Prescat.Parcel
		(in=inParcel);
  by NLIHC_ID;
  	if inProject and inParcel;
   
run;

proc sort data=Project_AOB;
	by SSL;
	run;


data Project_Age_Of_Building;

  merge
   Project_AOB
   	(in=inProject)
   Realprop.Cama_parcel_2025_02
   	(in=inCama);

  by SSL;
 	 if inProject and inCama;
   
run;

proc summary data=Project_Age_Of_Building nway; 
  class nlihc_id;
  output out=Project_Building_Age
    min(AYB)=
	min(EYB)=;
run;
****Age of Building Table***;

proc format;
value year_built (notsorted)
	    1 -< 1910 = 'Before 1910'
	    1910 -< 1920 = '1910 to 1919'
	    1920 -< 1930 = '1920 to 1929'
	    1930 -< 1940 = '1930 to 1939'
	    1940 -< 1950 = '1940 to 1949'
	    1950 -< 1960 = '1950 to 1959'
	    1960 -< 1970 = '1960 to 1969'
	    1970 -< 1980 = '1970 to 1979'
	    1980 -< 1990 = '1980 to 1989'
	    1990 -< 2000 = '1990 to 2000'
	    2000 - high  = '2000 or later'
	    .u = 'Unknown'; 
	run;

title3 "Project and assisted unit unique counts by Age of Building";

proc tabulate data=Project_Age_Of_Building format=comma10. noseps missing;
  where ProgCat ~= . and not( missing( AYB ) );
  class ProgCat / preloadfmt order=data;
  class AYB;
  var mid_asst_units err_asst_units;
  table 
    /** Rows **/
    ( all='DC Total' AYB=' ' )
    ,
    /** Columns **/
    n='Projects' * ( all='\b Total' ProgCat=' ' ) * mid_asst_units=' '
    ;
  table 
    /** Rows **/
    ( all='DC Total' AYB=' ' )
    ,
    /** Columns **/
    sum='Assisted Units' * ( all='\b Total' ProgCat=' ' ) * mid_asst_units=' '
    ;
  format ProgCat ProgCat.;
  format AYB year_built.;
run;

***Year Improved Table***;

proc format;
value year_improved (notsorted)
	    1 -< 1910 = 'Before 1910'
	    1910 -< 1920 = '1910 to 1919'
	    1920 -< 1930 = '1920 to 1929'
	    1930 -< 1940 = '1930 to 1939'
	    1940 -< 1950 = '1940 to 1949'
	    1950 -< 1960 = '1950 to 1959'
	    1960 -< 1970 = '1960 to 1969'
	    1970 -< 1980 = '1970 to 1979'
	    1980 -< 1990 = '1980 to 1989'
	    1990 -< 2000 = '1990 to 2000'
	    2000 - high  = '2000 or later'
	    .u = 'Unknown'; 
	run;

title3 "Project and assisted unit unique counts by Year Improvements were made to Property";

proc tabulate data=Project_Age_Of_Building format=comma10. noseps missing;
  where ProgCat ~= . and not( missing( EYB ) );
  class ProgCat / preloadfmt order=data;
  class EYB;
  var mid_asst_units err_asst_units;
  table 
    /** Rows **/
    ( all='DC Total' EYB=' ' )
    ,
    /** Columns **/
    n='Projects' * ( all='\b Total' ProgCat=' ' ) * mid_asst_units=' '
    ;
  table 
    /** Rows **/
    ( all='DC Total' EYB=' ' )
    ,
    /** Columns **/
    sum='Assisted Units' * ( all='\b Total' ProgCat=' ' ) * mid_asst_units=' '
    ;
  format ProgCat ProgCat.;
  format EYB year_improved.;
run;


****Table for Project by Owner Type****;

title3 "Project and assisted unit unique counts by Type of Owner";

proc tabulate data=Project_assisted_units format=comma10. noseps missing;
  where ProgCat ~= . and not( missing( parcel_owner_type ) );
  class ProgCat / preloadfmt order=data;
  class parcel_owner_type;
  var mid_asst_units err_asst_units;
  table 
    /** Rows **/
    ( all='DC Total' parcel_owner_type=' ' )
    ,
    /** Columns **/
    n='Projects' * ( all='\b Total' ProgCat=' ' ) * mid_asst_units=' '
    ;
  table 
    /** Rows **/
    ( all='DC Total' parcel_owner_type=' ' )
    ,
    /** Columns **/
    sum='Assisted Units' * ( all='\b Total' ProgCat=' ' ) * mid_asst_units=' '
    ;
  format ProgCat ProgCat.;
  format parcel_owner_type $OWNCAT.;
run;

***Projects and assisted units by size of development***;
proc format;
value development_size (notsorted)
	    1 - 10 = '1 - 10 units'
	    11 - 50 = '11 - 50 units'
	    51 - 100 = '51 - 100 units'
	    101 - high  = '101 units or more'
	    .u = 'Unknown'; 
	run;

title3 "Projects and assisted units by size of development";

proc tabulate data=Project_assisted_units format=comma10. noseps missing;
  where ProgCat ~= . and not( missing( total_units ) );
  class ProgCat / preloadfmt order=data;
  class total_units;
  var mid_asst_units err_asst_units;
  table 
    /** Rows **/
    ( all='DC Total' total_units=' ' )
    ,
    /** Columns **/
    n='Projects' * ( all='\b Total' ProgCat=' ' ) * mid_asst_units=' '
    ;
  table 
    /** Rows **/
    ( all='DC Total' total_units=' ' )
    ,
    /** Columns **/
    sum='Assisted Units' * ( all='\b Total' ProgCat=' ' ) * mid_asst_units=' '
    ;
  format ProgCat ProgCat.;
  format total_units development_size.;
run;

***Projects and assisted units by earliest subsidy expiration date***;


proc format;
value earliest_expiration (notsorted)
	    2025 - 2029 = '2025-2029'
	    2030 - 2034 = '2030-2034'
	    2035 - 2039 = '2035-2039'
		2040 - 2045 = '2040-2045'
		2045 - 2049 = '2045-2049'
	    2050 - high  = '2050 or later'
	    .u = 'Unknown'; 
	run;

title3 "Projects and assisted units by earliest subsidy expiration date";

proc tabulate data=Project_assisted_units format=comma10. noseps missing;
  where ProgCat ~= . and not( missing( poa_end_min_year ) ) and poa_end_min_year >= 2025 and ProgCat in ( 2, 9, 8, 3, 10 );
  class ProgCat / preloadfmt order=data;
  class poa_end_min_year;
  var mid_asst_units err_asst_units;
  table 
    /** Rows **/
    ( all='DC Total' poa_end_min_year=' ' )
    ,
    /** Columns **/
    n='Projects' * ( all='\b Total' ProgCat=' ' ) * mid_asst_units=' '
    ;
  table 
    /** Rows **/
    ( all='DC Total' poa_end_min_year=' ' )
    ,
    /** Columns **/
    sum='Assisted Units' * ( all='\b Total' ProgCat=' ' ) * mid_asst_units=' '
    ;
  format ProgCat ProgCat.;
  format poa_end_min_year earliest_expiration.;
run;


title3 "Section 8 Projects and assisted units by earliest subsidy expiration date";

proc tabulate data=Project_assisted_units format=comma10. noseps missing;
  where ProgCat ~= . and not( missing( poa_end_min_year ) ) and poa_end_min_year >= 2025 and ProgCat in ( 2, 9,);
  class ProgCat / preloadfmt order=data;
  class poa_end_min_year;
  var mid_asst_units err_asst_units;
  table 
    /** Rows **/
    ( all='DC Total' poa_end_min_year=' ' )
    ,
    /** Columns **/
    n='Projects' * ( all='\b Total' ) * mid_asst_units=' '
	sum='Assisted Units' * ( all='\b Total' ) * mid_asst_units=' '
    ;
  format ProgCat ProgCat.;
  format poa_end_min_year earliest_expiration.;
run;

title3 "LIHTC Projects and assisted units by earliest subsidy expiration date";

proc tabulate data=Project_assisted_units format=comma10. noseps missing;
  where ProgCat ~= . and not( missing( poa_end_min_year ) ) and poa_end_min_year >= 2025 and ProgCat in ( 3, 8,);
  class ProgCat / preloadfmt order=data;
  class poa_end_min_year;
  var mid_asst_units err_asst_units;
  table 
    /** Rows **/
    ( all='DC Total' poa_end_min_year=' ' )
    ,
    /** Columns **/
    n='Projects' * ( all='\b Total' ) * mid_asst_units=' '
	sum='Assisted Units' * ( all='\b Total' ) * mid_asst_units=' '
    ;
  format ProgCat ProgCat.;
  format poa_end_min_year earliest_expiration.;
run;


***Neighborhood characteristics (demographics, housing sale price level and trends)***;

*create cluster data set to combine with Project_assisted_units to create data set for neighborhood characteristics tables*;
data cluster;
 merge
	Ncdb.Ncdb_sum_2020_cl17
	Ncdb.Ncdb_sum_2010_cl17
	Realprop.Sales_sum_cl17;
	by cluster2017;
pctblacknonhispbridge_2020 = 100 * ( popblacknonhispbridge_2020 / popwithrace_2020 );
pctblacknonhispbridge_2010 = 100 * ( popblacknonhispbridge_2010 / popwithrace_2010 );
pcthisp_2020 = 100 * ( pophisp_2020 / popwithrace_2020 );
pcthisp_2010 = 100 * ( pophisp_2010 / popwithrace_2010 );
pctpopchg_2010_2020 = %pctchg( totpop_2010 , totpop_2020 );
pctmpricechg_2010_2023 = %pctchg( r_mprice_sf_2010, r_mprice_sf_2023 );

run;

proc sort data= Project_assisted_units;
	by cluster2017;
	run;

data Project_Clusters;
	merge Project_assisted_units cluster;
	by cluster2017;
run;


title3 'Quantiles of Neighborhood Cluster Characteristics';

proc tabulate data=Cluster format=comma16.2 noseps missing;
  var pctblacknonhispbridge_2010 pctblacknonhispbridge_2020 pcthisp_2010 pcthisp_2020 pctpopchg_2010_2020 r_mprice_sf_2023 pctmpricechg_2010_2023;
  table 
    /** Rows **/
    pctblacknonhispbridge_2010 pctblacknonhispbridge_2020 pcthisp_2010 pcthisp_2020 pctpopchg_2010_2020 r_mprice_sf_2023 pctmpricechg_2010_2023
    ,
    /** Columns **/
    n*f=comma6.0 min='Minimum' p25='25th percentile' p50='50th percentile' p75='75th percentile' max='Maximum'
  ;
  label
    pctblacknonhispbridge_2010 = '% Non-Hispanic Black population, 2010'
    pctblacknonhispbridge_2020 = '% Non-Hispanic Black population, 2020'
    pcthisp_2010 = '% Hispanic population, 2010'
    pcthisp_2020 = '% Hispanic population, 2020'
    pctpopchg_2010_2020 = '% population change, 2010 - 2020'
    r_mprice_sf_2023 = 'Median sales price of SF homes ($ 2024), 2023'
    pctmpricechg_2010_2023 = '% change in Median sales price of SF homes ($ 2024), 2010 - 2023'
  ;  
run;


proc format;
  value pctmpricechg_2010_2023_quantile
    low - 20.07786 = "Q1 (0-25%)"
    20.07786 <- 37.72638 = "Q2 (25-50%)"
    37.72638 <- 54.51864 = "Q3 (50-75%)"
    54.51864 <- high = "Q4 (75-100%)";
run;

proc format;
  value r_mprice_sf_2023_quantile
    low - 588175 = "Q1 (0-25%)"
    588175 <- 923852 = "Q2 (25-50%)"
    923852 <- 1283980 = "Q3 (50-75%)"
    1283980 <- high = "Q4 (75-100%)";
run;

proc format;
  value pctpopchg_2010_2020_quantile
    low - 4.11005 = "Q1 (0-25%)"
    4.11005 <- 9.13567 = "Q2 (25-50%)"
    9.13567 <- 24.23243 = "Q3 (50-75%)"
    24.23243 <- high = "Q4 (75-100%)";
run;

proc format;
  value pcthisp_2010_quantile
    low - 1.85989 = "Q1 (0-25%)"
    1.85989 <- 5.32382 = "Q2 (25-50%)"
    5.32382 <- 8.31481 = "Q3 (50-75%)"
    8.31481 <- high = "Q4 (75-100%)";
run;

proc format;
  value pcthisp_2020_quantile
    low - 5.19194 = "Q1 (0-25%)"
    5.19194 <- 8.49419 = "Q2 (25-50%)"
    8.49419 <- 10.59019 = "Q3 (50-75%)"
    10.59019 <- high = "Q4 (75-100%)";
run;

proc format;
  value pctblacknonhispbridge_2010_quant
    low - 21.12676 = "Q1 (0-25%)"
    21.12676 <- 57.93004 = "Q2 (25-50%)"
    57.93004 <- 94.52055 = "Q3 (50-75%)"
    94.52055 <- high = "Q4 (75-100%)";
run;

proc format;
  value pctblacknonhispbridge_2020_quant
    low - 13.58539 = "Q1 (0-25%)"
    13.58539 <- 45.92395 = "Q2 (25-50%)"
    45.92395 <- 91.03701 = "Q3 (50-75%)"
    91.03701 <- high = "Q4 (75-100%)";
run;

*Neighborhood Characteristics Tables below here*;

title3 "Project and assisted unit unique counts by quantile of percentage of median change in price of single family homes in the cluster from 2010 to 2023";

proc tabulate data=Project_Clusters format=comma10. noseps missing;
  where ProgCat ~= . and not( missing( pctmpricechg_2010_2023 ) );
  class ProgCat / preloadfmt order=data;
  class pctmpricechg_2010_2023;
  var mid_asst_units err_asst_units;
  table 
    /** Rows **/
    ( all='DC Total' pctmpricechg_2010_2023=' ' )
    ,
    /** Columns **/
    n='Projects' * ( all='\b Total' ProgCat=' ' ) * mid_asst_units=' '
    ;
  table 
    /** Rows **/
    ( all='DC Total' pctmpricechg_2010_2023=' ' )
    ,
    /** Columns **/
    sum='Assisted Units' * ( all='\b Total' ProgCat=' ' ) * mid_asst_units=' '
    ;
  format ProgCat ProgCat.;
  format pctmpricechg_2010_2023 pctmpricechg_2010_2023_quantile.;
run;


title3 "Project and assisted unit unique counts by quantile of the median price of single family homes in the cluster in 2023";

proc tabulate data=Project_Clusters format=comma10. noseps missing;  
  where ProgCat ~= . and not( missing( r_mprice_sf_2023 ) );
  class ProgCat / preloadfmt order=data;
  class r_mprice_sf_2023;
  var mid_asst_units err_asst_units;
  table 
    /** Rows **/
    ( all='DC Total' r_mprice_sf_2023=' ' )
    ,
    /** Columns **/
    n='Projects' * ( all='\b Total' ProgCat=' ' ) * mid_asst_units=' '
    ;
  table 
    /** Rows **/
    ( all='DC Total' r_mprice_sf_2023=' ' )
    ,
    /** Columns **/
    sum='Assisted Units' * ( all='\b Total' ProgCat=' ' ) * mid_asst_units=' '
    ;
  format ProgCat ProgCat.;
  format r_mprice_sf_2023 r_mprice_sf_2023_quantile.;
run;


title3 "Project and assisted unit unique counts by quantile of percentage population change in the cluster from 2010 to 2020";

proc tabulate data=Project_Clusters format=comma10. noseps missing;
  where ProgCat ~= . and not( missing( pctpopchg_2010_2020 ) );
  class ProgCat / preloadfmt order=data;
  class pctpopchg_2010_2020;
  var mid_asst_units err_asst_units;
  table 
    /** Rows **/
    ( all='DC Total' pctpopchg_2010_2020=' ' )
    ,
    /** Columns **/
    n='Projects' * ( all='\b Total' ProgCat=' ' ) * mid_asst_units=' '
    ;
  table 
    /** Rows **/
    ( all='DC Total' pctpopchg_2010_2020=' ' )
    ,
    /** Columns **/
    sum='Assisted Units' * ( all='\b Total' ProgCat=' ' ) * mid_asst_units=' '
    ;
  format ProgCat ProgCat.;
  format pctpopchg_2010_2020 pctpopchg_2010_2020_quantile.;
run;


title3 "Project and assisted unit unique counts by quantile of percentage of hispanic population in the cluster in 2010";

proc tabulate data=Project_Clusters format=comma10. noseps missing;
  where ProgCat ~= . and not( missing( pcthisp_2010 ) );
  class ProgCat / preloadfmt order=data;
  class pcthisp_2010;
  var mid_asst_units err_asst_units;
  table 
    /** Rows **/
    ( all='DC Total' pcthisp_2010=' ' )
    ,
    /** Columns **/
    n='Projects' * ( all='\b Total' ProgCat=' ' ) * mid_asst_units=' '
    ;
  table 
    /** Rows **/
    ( all='DC Total' pcthisp_2010=' ' )
    ,
    /** Columns **/
    sum='Assisted Units' * ( all='\b Total' ProgCat=' ' ) * mid_asst_units=' '
    ;
  format ProgCat ProgCat.;
  format pcthisp_2010 pcthisp_2010_quantile.;
run;


title3 "Project and assisted unit unique counts by quantile of percentage of hispanic population in the cluster in 2020";

proc tabulate data=Project_Clusters format=comma10. noseps missing;
  where ProgCat ~= . and not( missing( pcthisp_2020 ) );
  class ProgCat / preloadfmt order=data;
  class pcthisp_2020;
  var mid_asst_units err_asst_units;
  table 
    /** Rows **/
    ( all='DC Total' pcthisp_2020=' ' )
    ,
    /** Columns **/
    n='Projects' * ( all='\b Total' ProgCat=' ' ) * mid_asst_units=' '
    ;
  table 
    /** Rows **/
    ( all='DC Total' pcthisp_2020=' ' )
    ,
    /** Columns **/
    sum='Assisted Units' * ( all='\b Total' ProgCat=' ' ) * mid_asst_units=' '
    ;
  format ProgCat ProgCat.;
  format pcthisp_2020 pcthisp_2020_quantile.;
run;

title3 "Project and assisted unit unique counts by quantile of percentage of the non-hispanic black population in the cluster in 2010";

proc tabulate data=Project_Clusters format=comma10. noseps missing;
  where ProgCat ~= . and not( missing( pctblacknonhispbridge_2010 ) );
  class ProgCat / preloadfmt order=data;
  class pctblacknonhispbridge_2010;
  var mid_asst_units err_asst_units;
  table 
    /** Rows **/
    ( all='DC Total' pctblacknonhispbridge_2010=' ' )
    ,
    /** Columns **/
    n='Projects' * ( all='\b Total' ProgCat=' ' ) * mid_asst_units=' '
    ;
  table 
    /** Rows **/
    ( all='DC Total' pctblacknonhispbridge_2010=' ' )
    ,
    /** Columns **/
    sum='Assisted Units' * ( all='\b Total' ProgCat=' ' ) * mid_asst_units=' '
    ;
  format ProgCat ProgCat.;
  format pctblacknonhispbridge_2010 pctblacknonhispbridge_2010_quant.;
run;


title3 "Project and assisted unit unique counts by quantile of percentage of the non-hispanic black population in the cluster in 2020";

proc tabulate data=Project_Clusters format=comma10. noseps missing;
  where ProgCat ~= . and not( missing( pctblacknonhispbridge_2020 ) );
  class ProgCat / preloadfmt order=data;
  class pctblacknonhispbridge_2020;
  var mid_asst_units err_asst_units;
  table 
    /** Rows **/
    ( all='DC Total' pctblacknonhispbridge_2020=' ' )
    ,
    /** Columns **/
    n='Projects' * ( all='\b Total' ProgCat=' ' ) * mid_asst_units=' '
    ;
  table 
    /** Rows **/
    ( all='DC Total' pctblacknonhispbridge_2020=' ' )
    ,
    /** Columns **/
    sum='Assisted Units' * ( all='\b Total' ProgCat=' ' ) * mid_asst_units=' '
    ;
  format ProgCat ProgCat.;
  format pctblacknonhispbridge_2020 pctblacknonhispbridge_2020_quant.;
run;




ods rtf close;

title2;
footnote1;

run;


