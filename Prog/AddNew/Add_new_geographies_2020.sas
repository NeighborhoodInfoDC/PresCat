/**************************************************************************
 Program:  Add_new_geographies_2020.sas
 Library:  PresCat
 Project:  Urban-Greater DC
 Author:   Elizabeth Burton
 Created:  7/15/2022
 Version:  SAS 9.4
 Environment:  Local Windows session (desktop)
 
 Description:  Add 2020 census geographies, 2017 nhbd clusters, 2022 wards to Preservation Catalog. 
 
 Modifications:
**************************************************************************/

%include "\\sas1\DCdata\SAS\Inc\StdLocal.sas";

** Define libraries **;
%DCData_lib( PresCat )
%DCData_lib( MAR )

proc sort data = PresCat.Building_geocode out=Building_geocode;
	by Bldg_address_id;
run;

proc sort data = MAR.address_points_2022_07(keep=Geo2020 GeoBg2020 GeoBlk2020 Ward2022 cluster2017 ADDRESS_ID)
		  out=address_points_2022_07(rename=(ADDRESS_ID=bldg_address_id));
	by ADDRESS_ID;
run;

data left_join;
	merge Building_geocode (in=a) 
		address_points_2022_07 (in=b);
	by bldg_address_id;

	if a then output; 
run;

  %Finalize_data_set( 
    /** Finalize data set parameters **/
    data=left_join,
    out=Building_geocode,
    outlib=PresCat,
    label="Preservation Catalog, Building-level geocoding info",
    sortby=Nlihc_id Bldg_addre,
    /** Metadata parameters **/
    revisions=%str(Add new Census geos, neighborhood clusters, and wards),
    /** File info parameters **/
    printobs=10 
  )
