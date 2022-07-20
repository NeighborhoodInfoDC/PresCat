/**************************************************************************
 Program:  Create_project_geocode.sas
 Library:  PresCat
 Project:  Urban-Greater DC
 Author:   Elizabeth Burton
 Created:  07/20/22
 Version:  SAS 9.4
 Environment:  Windows
 
 Description:  Create project_geocode data set (new census geos, nhbd cluster, wards) 
			   and add geo vars to Prescat.Project dataset

 Modifications:
**************************************************************************/

%include "\\sas1\DCdata\SAS\Inc\StdLocal.sas";

** Define libraries **;
%DCData_lib( PresCat )

** invoke macro to create dataset **;
%Create_project_geocode( revisions=%str(Add new Census geos, neighborhood clusters, and wards)  )

** merge the new variables from Project_geocode onto Prescat.Project by nlihc_id to create a new temporary data set. **; 

proc sort data = PresCat.Project out=Project;
	by nlihc_id;
run;

proc sort data = Project_geocode(keep=Geo2020 GeoBg2020 GeoBlk2020 Ward2022 cluster2017 nlihc_id)
		  out=Project_geocode;
	by nlihc_id;
run;

data left_join;
	merge Project (in=a) 
		Project_geocode (in=b);
	by nlihc_id;

	if a then output; 
run;


%Finalize_data_set( 
  /** Finalize data set parameters **/
  data=left_join,
  out=Project,
  outlib=PresCat,
  label="Preservation Catalog, Projects",
  sortby=nlihc_id,
  /** Metadata parameters **/
  revisions=%str(Add new Census geos, neighborhood clusters, and wards),
  /** File info parameters **/
  printobs=0
)
