/**************************************************************************
 Program:  443_Remove_duplicates.sas
 Library:  PresCat
 Project:  Urban-Greater DC
 Author:   P. Tatian
 Created:  01/31/24
 Version:  SAS 9.4
 Environment:  Local Windows session (desktop)
 GitHub issue:  443
 
 Description:  Remove duplicate/invalid address, SSLs, and projects
 from Catalog.

 Modifications:
**************************************************************************/

%include "\\sas1\DCdata\SAS\Inc\StdLocal.sas";

** Define libraries **;
%DCData_lib( PresCat )

%let projects_to_delete = 
  'NL001189', 'NL001219', 'NL001240', 'NL001253', 'NL001256', 'NL001270', 'NL001302', 'NL001309', 'NL001328';


** Delete duplicate projects **;

data Project_del;

  set PresCat.Project;
  
  if nlihc_id in ( &projects_to_delete ) then delete;

run;


** Subsidies **;

data Subsidy_to_add;

  set PresCat.Subsidy;

  select ( nlihc_id );
  
    when ( 'NL001240' ) do;
      subsidy_id = .;
      nlihc_id = 'NL001201';
    end;
    
    when ( 'NL001253' ) do;
      subsidy_id = .;
      nlihc_id = 'NL001221';
    end;
    
    when ( 'NL001189' ) do;
      subsidy_id = .;
      nlihc_id = 'NL001286';
    end;

    when ( 'NL001302' ) do;
      subsidy_id = .;
      nlihc_id = 'NL001301';
    end;
    
    otherwise
      delete;
      
  end;
    
run;

proc sort data=Subsidy_to_add;
  by nlihc_id poa_start;
run;

proc print data=Subsidy_to_add;
  by nlihc_id; 
  id nlihc_id subsidy_id;
  var program poa_start units_assist;
run;

data Subsidy;

  retain _subsidy_id_hold;

  set PresCat.Subsidy Subsidy_to_add;
  by nlihc_id;
  
  if nlihc_id in ( &projects_to_delete ) then delete;

  if first.nlihc_id then do;
    if missing( subsidy_id ) then subsidy_id = 1;
    _subsidy_id_hold = .;
  end;
  
  if missing( subsidy_id ) then subsidy_id = _subsidy_id_hold;
  
  _subsidy_id_hold = subsidy_id + 1;
  
  ** Adjust unit counts for scattered site project **;
  
  if nlihc_id = 'NL001286' then units_assist = 18;
  else if nlihc_id = 'NL001287' then units_assist = 12;
  
  ** Fix subsidy date **;
  
  if nlihc_id = 'NL001333' and poa_start = '17jun2029'd then do;
    poa_start = '17jun2019'd;
    poa_start_orig = '17jun2019'd;
  end;
  
  drop _subsidy_id_hold;
  
run;

proc print data=Subsidy;
  where nlihc_id in ( 'NL001201', 'NL001221', 'NL001286', 'NL001287', 'NL001301' );
  by nlihc_id; 
  id nlihc_id subsidy_id;
  var program poa_start units_assist;
run;

proc compare base=PresCat.Subsidy compare=Subsidy listall maxprint=(40,32000);
  id nlihc_id subsidy_id;
run;

%Create_project_subsidy_update( data=Subsidy, out=Project_subsidy_update, project_file=Project_del )

data Project;

  merge Project_del Project_subsidy_update;
  by nlihc_id;

****** UPDATE PROJECT NAMES **********;
  
run;

proc compare base=PresCat.Project compare=Project listall maxprint=(40,32000);
  id nlihc_id;
run;


** Correct addresses **;



** Correct parcels **;



** Update Project_category_view **;

