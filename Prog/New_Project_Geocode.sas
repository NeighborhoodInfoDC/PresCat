/**************************************************************************
 Program:  New_Project_Geocode.sas
 Library:  PresCat
 Project:  NeighborhoodInfo DC
 Author:   M. Cohen
 Created:  08/18/2016
 Version:  SAS 9.1
 Environment:  Local Windows session (desktop)
 
 Description:  Adds new projects into the project_geocode and building_geocode files.

 Modifications:

**************************************************************************/

%include "L:\SAS\Inc\StdLocal.sas";

** Define libraries **;
%DCData_lib( PresCat )
%DCData_lib( MAR )
%DCData_lib( RealProp, local=n )

%let input_file_pre = Buildings_for_geocoding_2017-05-25;

** Import geocoded project data **;

** Main sheet info **;

filename fimport "&_dcdata_r_path\PresCat\Raw\&input_file_pre._main.csv" lrecl=2000;

proc import out=New_Proj_Geocode
    datafile=fimport
    dbms=csv replace;
  datarow=2;
  getnames=yes;
  guessingrows=500;

run;

filename fimport clear;

** Create Unique NLIHC IDs for New Projects **;

data NLIHC_ID;

	set PresCat.project
	(keep=NLIHC_id);
	nlihc_sans = compress(NLIHC_ID, , "a");
	nlihc_num = input(NLIHC_SANS, 6.);
	_drop_constant = 1;
	run;

data NLIHC_ID;
	
	set NLIHC_ID;
	by _drop_constant nlihc_num;
	lastid = last._drop_constant;
	if lastid = 0 then delete;
	run;

	****unnecessary if we have already dropped all other observations except the last. Test without this proc*;
/*proc sort data=nlihc_id;
	by nlihc_num;
	run;*/

proc sort data = New_Proj_Geocode;
	by proj_name;
	run;

data New_Proj_Geocode;
  set New_Proj_Geocode;
	by proj_name;
	firstproj = first.proj_name;
  format _all_ ;
  informat _all_ ;
	run;

*** Current format of nlihc_id is $16. Test with the new format***;
data New_Proj_Geocode;
  retain proj_name nlihc_id;
  format nlihc_id $16.;
	set Nlihc_id New_Proj_Geocode;
	  retain nlihc_hold;
	  if nlihc_num > nlihc_hold then nlihc_hold = nlihc_num;
	  select (firstproj);
	    when (1) do;
	      nlihc_hold = nlihc_hold + 1;
 	    end;
		  otherwise
		    nlihc_hold = nlihc_hold;
		  end;
	  if proj_name = '' then delete;
	  drop_nlihc = 'NL00';
	  nlihc_id = cats (drop_nlihc, nlihc_hold);
	  drop drop_nlihc firstproj nlihc_num nlihc_sans nlihc_hold lastid _drop_constant;
	run;

  ** MAR address info sheet **;

/*filename fimport "&_dcdata_r_path\PresCat\Raw\&input_file_pre._mar_address.csv" lrecl=2000;

data WORK.MAR_ADDRESS    ;
%let _EFIERR_ = 0; /* set the ERROR detection macro variable */
/*infile FIMPORT delimiter = ',' MISSOVER DSD lrecl=32767 firstobs=2 ;
informat ADDRESS_ID best32. ;
informat STATUS $6. ;
informat FULLADDRESS $19. ;
informat ADDRNUM best32. ;
informat ADDRNUMSUFFIX $1. ;
informat STNAME $5. ;
informat STREET_TYPE $6. ;
informat QUADRANT $2. ;
informat CITY $10. ;
informat STATE $2. ;
informat XCOORD best32. ;
informat YCOORD best32. ;
informat SSL $17. ;
informat ANC $6. ;
informat PSA $23. ;
informat WARD $6. ;
informat NBHD_ACTION $1. ;
informat CLUSTER_ $10. ;
informat POLDIST $34. ;
informat ROC $2. ;
informat CENSUS_TRACT best32. ;
informat VOTE_PRCNCT $12. ;
informat SMD $8. ;
informat ZIPCODE best32. ;
informat NATIONALGRID $18. ;
informat ROADWAYSEGID best32. ;
informat FOCUS_IMPROVEMENT_AREA $2. ;
informat HAS_ALIAS $1. ;
informat HAS_CONDO_UNIT $1. ;
informat HAS_RES_UNIT $1. ;
informat HAS_SSL $1. ;
informat LATITUDE best32. ;
informat LONGITUDE best32. ;
informat STREETVIEWURL $104. ;
informat RES_TYPE $11. ;
informat WARD_2002 $6. ;
informat WARD_2012 $6. ;
informat ANC_2002 $6. ;
informat ANC_2012 $6. ;
informat SMD_2002 $8. ;
informat SMD_2012 $8. ;
informat MARID best32. ;
informat IMAGEURL $38. ;
informat IMAGEDIR best32. ;
informat IMAGENAME $12. ;
informat CONFIDENCELEVEL $1. ;
format ADDRESS_ID best12. ;
format STATUS $6. ;
format FULLADDRESS $19. ;
format ADDRNUM best12. ;
format ADDRNUMSUFFIX $1. ;
format STNAME $5. ;
format STREET_TYPE $6. ;
format QUADRANT $2. ;
format CITY $10. ;
format STATE $2. ;
format XCOORD best12. ;
format YCOORD best12. ;
format SSL $17. ;
format ANC $6. ;
format PSA $23. ;
format WARD $6. ;
format NBHD_ACTION $1. ;
format CLUSTER_ $10. ;
format POLDIST $34. ;
format ROC $2. ;
format CENSUS_TRACT best12. ;
format VOTE_PRCNCT $12. ;
format SMD $8. ;
format ZIPCODE best12. ;
format NATIONALGRID $18. ;
format ROADWAYSEGID best12. ;
format FOCUS_IMPROVEMENT_AREA $2. ;
format HAS_ALIAS $1. ;
format HAS_CONDO_UNIT $1. ;
format HAS_RES_UNIT $1. ;
format HAS_SSL $1. ;
format LATITUDE best12. ;
format LONGITUDE best12. ;
format STREETVIEWURL $104. ;
format RES_TYPE $11. ;
format WARD_2002 $6. ;
format WARD_2012 $6. ;
format ANC_2002 $6. ;
format ANC_2012 $6. ;
format SMD_2002 $8. ;
format SMD_2012 $8. ;
format MARID best12. ;
format IMAGEURL $38. ;
format IMAGEDIR best12. ;
format IMAGENAME $12. ;
format CONFIDENCELEVEL $1. ;
input
ADDRESS_ID
                   STATUS $
                   FULLADDRESS $
                   ADDRNUM
                   ADDRNUMSUFFIX $
                   STNAME $
                   STREET_TYPE $
                   QUADRANT $
                   CITY $
                   STATE $
                   XCOORD
                   YCOORD
                   SSL $
                   ANC $
                   PSA $
                   WARD $
                   NBHD_ACTION $
                   CLUSTER_ $
                   POLDIST $
                   ROC $
                   CENSUS_TRACT
                   VOTE_PRCNCT $
                   SMD $
                   ZIPCODE
                   NATIONALGRID $
                   ROADWAYSEGID
                   FOCUS_IMPROVEMENT_AREA $
                   HAS_ALIAS $
                   HAS_CONDO_UNIT $
                   HAS_RES_UNIT $
                   HAS_SSL $
                   LATITUDE
                   LONGITUDE
                   STREETVIEWURL $
                   RES_TYPE $
                   WARD_2002 $
                   WARD_2012 $
                   ANC_2002 $
                   ANC_2012 $
                   SMD_2002 $
                   SMD_2012 $
                   MARID
                   IMAGEURL $
                   IMAGEDIR
                   IMAGENAME $
                   CONFIDENCELEVEL $
       ;
       if _ERROR_ then call symputx('_EFIERR_',1);  /* set ERROR detection macro variable */
       /*run;

filename fimport clear;
*/
proc sort data=New_Proj_Geocode;
  by marid;
run;
 
/*proc sort data=Mar_address;
  by address_id;*/


options spool;

%DC_mar_geocode(
  data = New_Proj_Geocode,
  staddr = bldg_addre,
  zip = bldg_zip,
  out = New_Proj_Geocode,
  geo_match = Y,
  debug = N,
  mprint = Y
);

**Merge project info and address info for new projects**;

  *****Geographies are not showing up in the project_geocode file;

data DC_info_geocode_mar;

 /* if in1;*/
  
  format _all_ ;
  informat _all_ ;
  
    ** Image url **;
  
  length Image_url $ 255;

  format Image_url $ 255.;
  
  ** Standard geos **;
  
  length Ward2012 $ 1;
  
  *Ward2012 = substr( Ward_2012, 6, 1 );
  
  format Ward2012 $ward12a.;
  
  length Anc2012 $ 2;
  
  *Anc2012 = substr( Anc_2012, 5, 2 );
  
  format Anc2012 $anc12a.;
  
  length Psa2012 $ 3;
  
  *Psa2012 = substr( Psa, 21, 3 ); 
  
  format Psa2012 $psa12a.;
  
  length Geo2010 $ 11;
  
  *if Census_tract ~= . then Geo2010 = "11001" || put( Census_tract, z6. );
  
  format Geo2010 $geo10a.;
  
  length Cluster_tr2000 $ 2 Cluster_tr2000_name $ 80;
  
  *if Cluster_ ~= "" then Cluster_tr2000 = put( 1 * substr( Cluster_, 9, 2 ), z2. );
  
  format Cluster_tr2000 $clus00a.;
  
  length Zip $ 5;
  
  ** Reformat addresses **;

  set New_Proj_Geocode /*(rename=(marid=address_id) in=in1) /*Mar_address Mar_intersection (rename=(marid=address_id))*/;
  
  %address_clean( MAR_MATCHADDRESS, MAR_rMATCHADDRESS );
  
  if not( missing( MAR_ZIPCODE ) ) then Zip = put( MAR_ZIPCODE, z5.0 );
  else Zip = put( Bldg_zip, z5.0 );
  
  format Zip $zipa.;

  ** Cluster names **;
  
  Cluster_tr2000_name = put( Cluster_tr2000, $clus00b. );
  
run;

proc sort data=DC_info_geocode_mar;
  by nlihc_id MAR_rMATCHADDRESS;
run;

** Create project and building geocode data sets for new projects **;

%let geo_vars = Ward2012 Anc2012 Psa2012 Geo2010 Cluster_tr2000 Cluster_tr2000_name Zip;

data 
  work.Building_geocode_a
    (keep=nlihc_id Proj_Name &geo_vars address_id Bldg_x Bldg_y Bldg_lat Bldg_lon Bldg_addre zip
          image_url Streetview_url ssl_std
     rename=(address_id=Bldg_address_id Zip=Bldg_zip image_url=Bldg_image_url Streetview_url=Bldg_streetview_url
             ssl_std=Ssl));
    
  set DC_info_geocode_mar (drop=bldg_addre);
  by nlihc_id;
  
  length Ward2012x $ 1;
  
  Ward2012x = left( Ward2012 );
  
  length
    Ssl_std $ 17;
  
  Ssl_std = left( Ssl );
  
  Bldg_x = MAR_XCOORD;
  Bldg_y = MAR_YCOORD;
  Bldg_lon = MAR_LONGITUDE;
  Bldg_lat = MAR_LATITUDE;
  Bldg_addre = MAR_rMATCHADDRESS;
  
  label
    Ward2012x = "Ward (2012)"
    Ssl_std = "Property identification number (square/suffix/lot)"
    Proj_Name = "Project name"
    NLIHC_ID = "Preservation Catalog project ID"
    address_id = "MAR address ID"
    streetview_url = "Google Street View URL"
    Anc2012 = "Advisory Neighborhood Commission (2012)"
    Psa2012 = "Police Service Area (2012)"
    Geo2010 = "Full census tract ID (2010): ssccctttttt"
    Cluster_tr2000 = "Neighborhood cluster (tract-based, 2000)"
    Cluster_tr2000_name = "Neighborhood cluster names (tract-based, 2000)"
    zip = "ZIP code (5 digit)"
    image_url = "OCTO property image URL"
    Bldg_addre = "Building address"
    Bldg_x = "Building longitude (MD State Plane Coord., NAD 1983 meters)"
    Bldg_y = "Building latitude (MD State Plane Coord., NAD 1983 meters)"
    Bldg_lon = "Building longitude"
    Bldg_lat = "Building latitude";
  
  format Ward2012x $ward12a.;
  format nlihc_id ;
  
  rename Ward2012x = Ward2012;
  drop Ward2012;
  
run;

%File_info( data=Building_geocode_a, printobs=100, stats=, contents=n )

**remove projects from geocode datasets that are no longer in project dataset**;

proc sql;

   create table project as
   select *
   from prescat.project_geocode
   where nlihc_id in (select distinct nlihc_id from prescat.project)
   ;

quit;

proc sql;

   create table building as
   select *
   from prescat.building_geocode
   where nlihc_id in (select distinct nlihc_id from prescat.project)
   ;

quit;

title2 '********************************************************************************************';
title3 '** 1/ Check to see if any projects were removed in previous step';

proc compare base=prescat.project_geocode compare=work.project listall maxprint=(40,32000);
  id nlihc_id;
run;

title2 '********************************************************************************************';
title3 '** 2/ Check to see if any buildings were removed in previous step';

proc compare base=prescat.building_geocode compare=work.building listall maxprint=(40,32000);
  id nlihc_id Bldg_addre;
run;

title2;

** merge new geocode files onto existing geocode files**;

data Building_geocode;
	set Building Building_geocode_a;
  by nlihc_id Bldg_addre;
run;

%Finalize_data_set( 
  /** Finalize data set parameters **/
  data=Building_geocode,
  out=Building_geocode,
  outlib=PresCat,
  label="Preservation Catalog, Building-level geocoding info",
  sortby=Nlihc_id Bldg_addre,
  archive=Y,
  /** Metadata parameters **/
  revisions=%str(Add new projects from &input_file_pre._*.csv.),
  /** File info parameters **/
  printobs=10
)

%Create_project_geocode(
  data=Building_geocode, 
  revisions=%str(Add new projects from &input_file_pre._*.csv.),
  compare=N,
  archive=Y
)

** Create file with list of new NLIHC_IDs **;

proc sql;

   create table New_nlihc_id as
   select nlihc_id, proj_name
   from project_geocode
   where nlihc_id not in (select distinct nlihc_id from prescat.project)
   ;

quit;


title2 '********************************************************************************************';
title3 '** 3/ Check for changes in the new Project geocode file that is not related to the new projects';

proc compare base=prescat.project_geocode compare=work.project_geocode listall maxprint=(40,32000);
 id nlihc_id proj_name;
 run;

title2 '********************************************************************************************';
title3 '** 4/ Check for changes in the new Building geocode file that is not related to the new projects';

proc compare base=prescat.building_geocode compare=work.building_geocode listall maxprint=(40,32000);
 id nlihc_id proj_name Bldg_addre;
 run;
 
title2 '********************************************************************************************';
title3 '** Project_geocode: Check for duplicate project IDs';

%Dup_check(
  data=Project_geocode,
  by=nlihc_id,
  id=Proj_Name Proj_addre 
)

run;

title2 '********************************************************************************************';
title3 '** Building_geocode: Check for duplicate addresses in different projects';

%Dup_check(
  data=Building_geocode,
  by=Bldg_address_id,
  id=nlihc_id Proj_name Bldg_addre 
)

run;

title2;
