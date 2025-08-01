/**************************************************************************
 Program:  Test_add_new_projects.sas
 Library:  PresCat
 Project:  Urban-Greater DC
 Author:   P. Tatian
 Created:  07/31/25
 Version:  SAS 9.4
 Environment:  Local Windows session (desktop)
 GitHub issue:  
 
 Description:  Code for testing %Add_new_projects_geocode() macro. 
 
 Test input files are:
  - \\sas1\DCDATA\Libraries\PresCat\Raw\AddNew\Test_add_new_projects.csv
  - \\sas1\DCDATA\Libraries\PresCat\Raw\AddNew\Test_add_new_projects_subsidy.csv
  
 Test input files have two projects, one that matches an existing Catalog
 project and one that is not in the Catalog.

 THIS CODE IS FOR TESTING ONLY AND SHOULD NOT BE RUN AS FINALIZED CODE. 

 Modifications:
**************************************************************************/

%include "\\sas1\DCdata\SAS\Inc\StdLocal.sas";

** Define libraries **;
%DCData_lib( PresCat )
%DCData_lib( MAR, local=n )
%DCData_lib( RealProp, local=n )
%DCData_lib( ROD, local=n )
%DCData_lib( DHCD, local=n )


%Add_new_projects(
  input_file_pre = Test_add_new_projects,
   use_zipcode = N
)


run;


** FOR TESTING, compare updated files to current versions **;
** (Project and Project_category files already have Compares in main code.) **;

proc compare base=PresCat.Building_geocode compare=Building_geocode listall maxprint=(40,32000);
  id nlihc_id bldg_addre;
run;

proc compare base=PresCat.Project_geocode compare=Project_geocode listall maxprint=(40,32000);
  id nlihc_id;
run;

proc compare base=PresCat.Parcel compare=Parcel listall maxprint=(40,32000);
  id nlihc_id ssl;
run;

proc compare base=PresCat.Subsidy compare=Subsidy listall maxprint=(40,32000);
  id nlihc_id subsidy_id;
run;

proc sort data=PresCat.Real_property out=Real_property_base;
  where not( missing( rp_date ) );
  by nlihc_id rp_date rp_type rp_desc ssl;
run;

proc sort data=Real_property out=Real_property_compare;
  where not( missing( rp_date ) );
  by nlihc_id rp_date rp_type rp_desc ssl;
run;

proc compare base=Real_property_base compare=Real_property_compare listall maxprint=(40,32000);
  id nlihc_id rp_date rp_type rp_desc ssl;
run;

