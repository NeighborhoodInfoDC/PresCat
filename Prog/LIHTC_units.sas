/**************************************************************************
 Program:  LIHTC_units.sas
 Library:  PresCat
 Project:  NeighborhoodInfo DC
 Author:   P. Tatian
 Created:  02/22/16
 Version:  SAS 9.2
 Environment:  Local Windows session (desktop)
 
 Description:  Summarize LIHTC units by ward and compliance end date.

 Modifications:
**************************************************************************/

%include "\\sas1\DCdata\SAS\Inc\StdLocal.sas";

** Define libraries **;
%DCData_lib( PresCat )


** Format for adding updated project category **;

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

proc summary data=PresCat.Subsidy (where=(Subsidy_Active and Portfolio='LIHTC')) nway;
  class nlihc_id portfolio;
  var Units_assist Poa_end Compl_end;
  output out=Subsidy_unique 
    sum(Units_assist)= min(Poa_end Compl_end)=;
run;

** Combine project and subsidy data **;

data LIHTC_units;

  merge
    PresCat.Project
      (drop=Cat_: Hud_Mgr_: Hud_Own_:
       where=(put( nlihc_id, $nlihcid2cat. ) in ( '1', '2', '3', '4', '5' ))
       in=inProject)
    Subsidy_unique
      (in=inSubsidy);
  by NLIHC_ID;
  
  if inProject and inSubsidy;
  
  Compl_end_yr = year( Compl_end );
  
run;


proc format;
  value year_rng
    . = 'Unknown'
    low - 2015 = 'Before 2016'
    2016 - 2020 = '2016-20'
    2021 - 2025 = '2021-25'
    2026 - 2030 = '2026-30'
    2031 - 2035 = '2031-35'
    2036 - 2040 = '2036-40'
    2041 - 2045 = '2041-45'
    2046 - 2050 = '2046-50'
    2051 - high = '2051+';

ods rtf file="&_dcdata_r_path\PresCat\Prog\LIHTC_units.rtf" style=Styles.Rtf_arial_9pt;

options missing='0';
options nodate nonumber;

%fdate()

proc tabulate data=LIHTC_units format=comma12.0 noseps missing;
  class Compl_end_yr Ward2012;
  var Units_assist;
  table 
    /** Rows **/
    all='Total' Compl_end_yr='\line\i Compliance end year',
    /** Columns **/
    Units_assist='LIHTC-assisted units' * sum=' ' * ( all='Total' Ward2012=' ' )
  ;
  format Compl_end_yr year_rng.;
  title2 " ";
  title3 "LIHTC-assisted units by 15-year compliance end date and ward";
  footnote1 height=9pt "Source: DC Preservation Catalog";
  footnote2 height=9pt "Prepared by Urban-Greater DC (greaterdc.urban.org), &fdate..";
  footnote3 height=9pt j=r '{Page}\~{\field{\*\fldinst{\pard\b\i0\chcbpat8\qc\f1\fs19\cf1{PAGE }\cf0\chcbpat0}}}';

run;

ods rtf close;

