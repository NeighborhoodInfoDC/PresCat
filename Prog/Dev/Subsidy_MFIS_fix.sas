/**************************************************************************
 Program:  Subsidy_MFIS_fix.sas
 Library:  PresCat
 Project:  NeighborhoodInfo DC
 Author:   P. Tatian
 Created:  09/19/15
 Version:  SAS 9.2
 Environment:  Local Windows session (desktop)
 
 Description:  Fix coding of MFIS projects in Subsidy data set.

 Modifications:
**************************************************************************/

/*%include "L:\SAS\Inc\StdLocal.sas";*/
%include "C:\DCData\SAS\Inc\StdLocal.sas";

** Define libraries **;
%DCData_lib( PresCat )

data Subsidy_fix;

  set PresCat.Subsidy;
  
  if Subsidy_info_source in (
    "HUD - Insured Mulitfamily Mortgages",
    "HUD - Insured Multifamily Mortgages",
    "HUD - Terminated Multifamily Mortgages",
    "HUD-Insured Mulitfamily Mortgages",
    "HUD-Insured Multifamily Mortgages"
  ) then
    Subsidy_info_source = "HUD/MFIS";

run;

proc print data=Subsidy_fix n;
  where Subsidy_info_source = "HUD/MFIS";
  id nlihc_id;
  var portfolio program Subsidy_Info_Source_Date Subsidy_Info_Source_ID;
run;

  