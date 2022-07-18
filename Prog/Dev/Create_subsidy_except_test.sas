/**************************************************************************
 Program:  Create_subsidy_except_test.sas
 Library:  PresCat
 Project:  NeighborhoodInfo DC
 Author:   P. Tatian
 Created:  07/19/15
 Version:  SAS 9.2
 Environment:  Local Windows session (desktop)
 
 Description:  Create testing version of Subsidy_except.

 Modifications:
**************************************************************************/

%include "\\sas1\DCdata\SAS\Inc\StdLocal.sas";

** Define libraries **;
%DCData_lib( PresCat )

data Subsidy_except_recs;

  length Nlihc_id $ 8 Except_init $ 8 rent_to_fmr_description $ 40;
  
  ** Exception for updated var **;
  nlihc_id = "NL000001";
  Subsidy_id = 3;
  POA_start = '01oct2004'd;
  Except_date = date();
  Except_init = 'PAT';
  output;
  
  ** Exception for nonupdated var **;
  nlihc_id = "NL000021";
  Subsidy_id = 2;
  POA_start = .;
  POA_end = '30nov2024'd;
  Compl_end = .;
  Except_date = date();
  Except_init = 'PAT';
  output;
  
  ** Exception same as updated var **;
  nlihc_id = "NL000023";
  Subsidy_id = 2;
  POA_start = '21dec2011'd;
  POA_end = .;
  Except_date = date();
  Except_init = 'PAT';
  output;
  
  ** Exception for nonupdated obs **;
  nlihc_id = "NL000029";
  Subsidy_id = 2;
  POA_start = .;
  POA_end = '31oct2044'd;
  Except_date = date();
  Except_init = 'PAT';
  output;

  ** Multiple exception records **;
  nlihc_id = "NL000046";
  Subsidy_id = 3;
  POA_start = '28feb2014'd;
  POA_end = '28feb2025'd;
  rent_to_fmr_description = 'Old desc';
  Except_date = '28feb2014'd;
  Except_init = 'PAT';
  output;
  POA_start = .;
  POA_end = '28feb2030'd;
  Units_assist = .u;
  Except_date = date();
  Except_init = 'PAT';
  rent_to_fmr_description = 'New desc';
  output;
    
run; 

data PresCat.Subsidy_except_test;

  set PresCat.Subsidy_except;
  
run;

proc append base=PresCat.Subsidy_except_test data=Subsidy_except_recs force;
run;

%File_info( data=PresCat.Subsidy_except_test, contents=y, stats= )

run;

