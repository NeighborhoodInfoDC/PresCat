/**************************************************************************
 Program:  Update_MFIS_2015_08.sas
 Library:  PresCat
 Project:  NeighborhoodInfo DC
 Author:   P. Tatian
 Created:  9/19/15
 Version:  SAS 9.2
 Environment:  Local Windows session (desktop)
 
 Description:  Update Preservation Catalog with latest 
 HUD MFIS update file.

 Modifications:
**************************************************************************/

%include "L:\SAS\Inc\StdLocal.sas";

** Define libraries **;
%DCData_lib( PresCat, local=y )
%DCData_lib( HUD, local=n )


%Update_MFIS( Update_file=MFIS_2015_08, Finalize=N, Quiet=N )


data _null_;
  set Update_subsidy_result_except_tr (where=(nlihc_id='NL000037'));
  file print;
  put / '--------------------';
  put (_all_) (= /);
run;

