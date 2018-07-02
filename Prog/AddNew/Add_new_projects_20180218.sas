/**************************************************************************
 Program:  Add_new_projects_20180218.sas
 Library:  PresCat
 Project:  NeighborhoodInfo DC
 Author:   P Tatian
 Created:  02/18/2018
 Version:  SAS 9.4
 Environment:  Local Windows session (desktop)
 
 Description:  Add new projects to Preservation Catalog. 

 LIHTC projects from DHCD FOIA update
 
 Geocoded project data:
   L:\Libraries\PresCat\Raw\AddNew\Buildings_for_geocoding_2017-05-25_main.csv
   L:\Libraries\PresCat\Raw\AddNew\Buildings_for_geocoding_2017-05-25_subsidy.csv

 Modifications:
**************************************************************************/

%include "L:\SAS\Inc\StdLocal.sas";

** Define libraries **;
%DCData_lib( PresCat )
%DCData_lib( MAR, local=n )
%DCData_lib( RealProp, local=n )
%DCData_lib( ROD, local=n )
%DCData_lib( DHCD, local=n )


%Add_new_projects(
  input_file_pre = Buildings_for_geocoding_2017-05-25,
  streetalt_file = 
)


run;


** Add affordabiity start, end dates, units to exception file because **;
** data in DHCD FOIA data are more precise than in the HUD updates    **;

data Subsidy_except;

  set 
    PresCat.Subsidy_except
    Subsidy_a2 
      (keep=nlihc_id subsidy_id poa_start poa_end compl_end units_assist
       in=in2);
  by nlihc_id subsidy_id;

  if in2 then do;
    Except_date = today();
    Except_init = 'PAT';
  end;

run;

%Finalize_data_set( 
  /** Finalize data set parameters **/
  data=Subsidy_except,
  out=Subsidy_except,
  outlib=PresCat,
  label="Preservation Catalog, Subsidy exception file",
  sortby=nlihc_id subsidy_id except_date,
  archive=Y,
  /** Metadata parameters **/
  revisions=%str(Add new projects from Buildings_for_geocoding_2017-05-25_*.csv.),
  /** File info parameters **/
  printobs=0,
  stats=n sum mean stddev min max
)

