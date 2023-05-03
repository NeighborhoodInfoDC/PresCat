/**************************************************************************
 Program:  360_Fix_LIHTC_update_pt1.sas
 Library:  Prescat
 Project:  Urban-Greater DC
 Author:   P. Tatian
 Created:  04/26/23
 Version:  SAS 9.4
 Environment:  Local Windows session (desktop)
 GitHub issue:  360
 
 Description:  Fix issues with latest LIHTC added projects (part 1).

 Modifications:
**************************************************************************/

%include "\\sas1\DCdata\SAS\Inc\StdLocal.sas";

** Define libraries **;
%DCData_lib( Prescat )

%let revisions = Fix new LIHTC subsidy for NL000310. Delete subsidy recs for DCB20161005 DCB20142003 DCB20162001.;

title2 'Prescat.Subsidy - Current version';

title3 'Tyler House Apartments';

proc print data=Prescat.Subsidy;
  where nlihc_id in ( 'NL000310' );
  id nlihc_id subsidy_id;
  var subsidy_active program units: subsidy_info: update_dtm;
run;

title3 'Selected contract numbers';

proc print data=Prescat.Subsidy;
  where Subsidy_info_source_id in ( 'DCB20161005', 'DCB20132002', 'DCB20142003', 'DCB20162001' );
  id nlihc_id subsidy_id;
  var subsidy_active program units: subsidy_info: update_dtm;
run;

title2;

** Edit Subsidy data set **;

data Subsidy;

  set Prescat.Subsidy;
  
  if Subsidy_info_source_id = 'DCB20132002' then do;
    nlihc_id = 'NL000310';
    subsidy_id = 3;
  end;
  else if Subsidy_info_source_id in ( 'DCB20161005', 'DCB20142003', 'DCB20162001' ) then do;
    delete;
  end;

run;

proc sort data=Subsidy;
  by nlihc_id subsidy_id;
run;

title2 'Subsidy - New version';

title3 'Tyler House Apartments';

proc print data=Subsidy;
  where nlihc_id in ( 'NL000310' );
  id nlihc_id subsidy_id;
  var subsidy_active program units: subsidy_info: update_dtm;
run;

title3 'Selected contract numbers';

proc print data=Subsidy;
  where Subsidy_info_source_id in ( 'DCB20161005', 'DCB20132002', 'DCB20142003', 'DCB20162001' );
  id nlihc_id subsidy_id;
  var subsidy_active program units: subsidy_info: update_dtm;
run;

title2;

/** Replace Prescat.Subsidy with new version **/

title2 '***** CHECKS *****';

proc compare base=PresCat.Subsidy compare=Subsidy listall maxprint=(40,32000);
  id nlihc_id subsidy_id;
run;

%Dup_check(
  data=Subsidy,
  by=nlihc_id subsidy_id,
  id=program,
  out=_dup_check,
  listdups=Y,
  count=dup_check_count,
  quiet=N,
  debug=N
)

title2;

%Finalize_data_set( 
  /** Finalize data set parameters **/
  data=Subsidy,
  out=Subsidy,
  outlib=Prescat,
  label="Preservation Catalog, Project subsidies",
  sortby=nlihc_id subsidy_id,
  /** Metadata parameters **/
  revisions=%str(&revisions),
  /** File info parameters **/
  printobs=0
)

/** Update subsidy vars in Prescat.Project **/

%Create_project_subsidy_update( data=Subsidy ) 

data Project;

  merge Prescat.project Project_Subsidy_update;
  by nlihc_id;
	
  if datepart( update_dtm ) = '5apr2023'd and missing( added_to_catalog ) then 
    added_to_catalog = '5apr2023'd;

run;

title2 '***** CHECKS *****';

proc compare base=PresCat.Project compare=Project listall maxprint=(80,32000);
  id nlihc_id;
run;

title2;

%Finalize_data_set( 
  /** Finalize data set parameters **/
  data=Project,
  out=Project,
  outlib=PresCat,
  label="Preservation Catalog, Projects",
  sortby=Nlihc_id,
  archive=N,
  /** Metadata parameters **/
  revisions=%str(&revisions),
  /** File info parameters **/
  printobs=0
)
  
