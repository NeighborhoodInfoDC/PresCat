/**************************************************************************
 Program:  New_projects_issue_300.sas
 Library:  PresCat
 Project:  Urban-Greater DC
 Author:   Donovan Harvey
 Created:  11/2/2022
 Version:  SAS 9.4
 Environment:  Local Windows session (desktop)
 
 Description:  Add new projects to Preservation Catalog. 
 

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
  input_file_pre = New_projects_issue_300_rev,
  address_data_edits =
    /** Fix Scattered Site II LLC location mismatches **/
    if nlihc_id in ( 'NL001145', 'NL001151' ) and address_id in ( 52616 ) then delete;
    if nlihc_id in ( 'NL001132', 'NL001151' ) and address_id in ( 278559, 278560 ) then delete;
    if nlihc_id in ( 'NL001132', 'NL001145' ) and address_id in ( 285530, 293195 ) then delete;
  ,
  parcel_data_edits =
    /** Fix Scattered Site II LLC location mismatches **/
    if nlihc_id in ( 'NL001145', 'NL001151' ) and ssl = "5777    0952" then delete;
    if nlihc_id in ( 'NL001132', 'NL001151' ) and ssl = "5984    0800" then delete;
    if nlihc_id in ( 'NL001132', 'NL001145' ) and ssl = "0557    0888" then delete;
)


run;
