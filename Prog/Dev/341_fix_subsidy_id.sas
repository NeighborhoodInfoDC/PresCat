/**************************************************************************
 Program:  341_fix_subsidy_id.sas
 Library:  PresCat
 Project:  Urban-Greater DC
 Author:   P. Tatian
 Created:  03/15/23
 Version:  SAS 9.4
 Environment:  Local Windows session (desktop)
 GitHub issue:  341
 
 Description:  Fix duplicate subsidy_id issue in Prescat.Subsidy

 Modifications:
**************************************************************************/

%include "\\sas1\DCdata\SAS\Inc\StdLocal.sas";

** Define libraries **;
%DCData_lib( PresCat )

proc sort data=PresCat.Subsidy out=Subsidy_sort;
  by nlihc_id subsidy_id subsidy_info_source_date;
run;

%Dup_check(
  data=Subsidy_sort,
  by=nlihc_id subsidy_id,
  id=program units_assist subsidy_info_source_id subsidy_info_source_date subsidy_active poa_start poa_end,
  out=_dup_check,
  listdups=Y,
  count=dup_check_count,
  quiet=N,
  debug=N
)

data Subsidy;

  set Subsidy_sort;
  by nlihc_id;
  
  if nlihc_id in ( 'NL000259', 'NL000264', 'NL000384', 'NL001056', 'NL001058' ) and portfolio = 'LIHTC' then do;
      if subsidy_info_source_date < '08apr2022'd then subsidy_active = 0;
  end;
  
  retain subsidy_id_prev;
  
  if first.nlihc_id then do;
    subsidy_id_prev = 0;
  end;
  
  subsidy_id = subsidy_id_prev + 1;
  
  subsidy_id_prev = subsidy_id;

run;

proc print data=Subsidy;
  where nlihc_id in ( 'NL000259', 'NL000264', 'NL000384', 'NL001056', 'NL001058' );
  id nlihc_id subsidy_id;
  by nlihc_id;
  var subsidy_active program units_assist subsidy_info_source_id subsidy_info_source_date ;
  format program ;
run;

proc compare base=Prescat.Subsidy compare=Subsidy listall maxprint=(40,32000);
  id nlihc_id;
run;

%Dup_check(
  data=Subsidy,
  by=nlihc_id subsidy_id,
  id=program units_assist subsidy_info_source_id subsidy_info_source_date subsidy_active poa_start poa_end,
  out=_dup_check,
  listdups=Y,
  count=dup_check_count,
  quiet=N,
  debug=N
)

%Finalize_data_set( 
  /** Finalize data set parameters **/
  data=Subsidy,
  out=Subsidy,
  outlib=Prescat,
  label="Preservation Catalog, Project subsidies",
  sortby=nlihc_id subsidy_id,
  /** Metadata parameters **/
  restrictions=None,
  revisions=%str(Fix subsidy_id numbering for new LIHTC entries.),
  /** File info parameters **/
  contents=Y,
  printobs=0,
  freqvars=,
  stats=n sum mean stddev min max
)

