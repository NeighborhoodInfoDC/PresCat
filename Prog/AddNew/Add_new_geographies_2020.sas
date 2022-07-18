/**************************************************************************
 Program:  Add_new_geographies_2020.sas
 Library:  PresCat
 Project:  Urban-Greater DC
 Author:   Elizabeth Burton
 Created:  7/15/2022
 Version:  SAS 9.4
 Environment:  Local Windows session (desktop)
 
 Description:  Add new geographies to Preservation Catalog. 
 

 Modifications:
**************************************************************************/

%include "\\sas1\DCdata\SAS\Inc\StdLocal.sas";

** Define libraries **;
%DCData_lib( PresCat )
%DCData_lib( MAR )

proc sort data = PresCat.Building_geocode out=work.Building_geocode;
	by Bldg_address_id;
run;

data work.Building_geocode;
	rename Bldg_address_id=ADDRESS_ID;
run;

proc sort data = MAR.address_points_2022_07 out=work.address_points_2022_07;
	by ADDRESS_ID;
run;

data Building_geocode;
	merge work.Building_geocode work.address_points_2022_07;
	by ADDRESS_ID;
run;

  %Finalize_data_set( 
    /** Finalize data set parameters **/
    data=Building_geocode,
    out=Building_geocode,
    outlib=PresCat,
    label="Preservation Catalog, Building-level geocoding info",
    sortby=Nlihc_id Bldg_addre,
    /** Metadata parameters **/
    revisions=%str(Add new Census geos, neighborhood clusters, and wards),
    /** File info parameters **/
    printobs=10 
  )
