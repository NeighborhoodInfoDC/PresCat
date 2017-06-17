/**************************************************************************
 Program:  Update_LIHTC_2013.sas
 Library:  PresCat
 Project:  NeighborhoodInfo DC
 Author:   P. Tatian
 Created:  05/31/17
 Version:  SAS 9.2
 Environment:  Local Windows session (desktop)
 
 Description:  Update Preservation Catalog with HUD LIHTC data.

 Modifications:
**************************************************************************/

%include "L:\SAS\Inc\StdLocal.sas";

** Define libraries **;
%DCData_lib( PresCat )
%DCData_lib( HUD )
%DCData_lib( MAR )


%Update_LIHTC( Update_file=Lihtc_2013, quiet=n )


proc compare base=PresCat.Subsidy compare=Subsidy_Update_Lihtc_2013 listall maxprint=(40,32000);
  id nlihc_id subsidy_id;
run;

data _null_;
  set PresCat.Subsidy (where=(nlihc_id in ('NL000027') and portfolio='LIHTC'));
  file print;
  put / '---------PresCat.Subsidy-----------';
  put (_all_) (= /);
run;

data _null_;
  set Subsidy_Update_Lihtc_2013 (where=(nlihc_id in ('NL000027') and portfolio='LIHTC'));
  file print;
  put / '----------Subsidy_Update_Lihtc_2013----------';
  put (_all_) (= /);
run;

