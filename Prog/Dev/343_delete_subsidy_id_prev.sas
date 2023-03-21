/**************************************************************************
 Program:  343_delete_subsidy_id_prev.sas
 Library:  Prescat
 Project:  Urban-Greater DC
 Author:   P. Tatian
 Created:  03/15/23
 Version:  SAS 9.4
 Environment:  Local Windows session (desktop)
 GitHub issue:  343
 
 Description:  Delete subsidy_id_prev from Prescat.Subsidy
 (correcting mistake from issue #341).
 
 Also update subsidy variables in Prescat.Project.

 Modifications:
**************************************************************************/

%include "\\sas1\DCdata\SAS\Inc\StdLocal.sas";

** Define libraries **;
%DCData_lib( Prescat )

data Subsidy;

  set PresCat.Subsidy (drop=subsidy_id_prev);

run;

proc compare base=Prescat.Subsidy compare=Subsidy listall maxprint=(40,32000);
  id nlihc_id subsidy_id;
run;

%Finalize_data_set( 
  /** Finalize data set parameters **/
  data=Subsidy,
  out=Subsidy,
  outlib=Prescat,
  label="Preservation Catalog, Project subsidies",
  sortby=nlihc_id subsidy_id,
  /** Metadata parameters **/
  restrictions=None,
  revisions=%str(Delete subsidy_id_prev.),
  /** File info parameters **/
  contents=Y,
  printobs=0,
  freqvars=,
  stats=n sum mean stddev min max
)


** Update subsidy vars in Prescat.Project **;

%Create_project_subsidy_update( data=Subsidy ) 

data Project;
  	merge Prescat.project Project_Subsidy_update;
	by nlihc_id;
run;

**** Compare with earlier version ****;

proc compare base=Prescat.project compare=Project listbasevar listcompvar maxprint=(40,32000);
  id nlihc_id;
run;

%Finalize_data_set( 
  /** Finalize data set parameters **/
  data=Project,
  out=Project,
  outlib=PresCat,
  label="Preservation Catalog, Projects",
  sortby=Nlihc_id,
  archive=N,
  /** Metadata parameters **/
  revisions=%str(Update subsidy vars.),
  /** File info parameters **/
  printobs=0
)
