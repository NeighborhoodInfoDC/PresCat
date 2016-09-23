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


%let MAX_PROJ_ADDRE = 3;   /** Maximum number of addresses to include in Proj_addre field in PresCat.Project_geo **/

** Import geocoded project data **;

** Main sheet info **;

filename fimport "D:\DCData\Libraries\PresCat\Raw\Buildings_for_geocoding_2016-08-01_main.csv" lrecl=2000;

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

proc sort data=nlihc_id;
	by nlihc_num;
	run;

proc sort data = New_Proj_Geocode;
	by proj_name;
	run;

data New_Proj_Geocode;
  set New_Proj_Geocode;
	by proj_name;
	firstproj = first.proj_name;
	run;


data New_Proj_Geocode;
  retain proj_name nlihc_id;
  format nlihc_id $8.;
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

filename fimport "D:\DCData\Libraries\PresCat\Raw\Buildings_for_geocoding_2016-08-01_mar_address.csv" lrecl=2000;

/*proc import out=mar_address
    datafile=fimport
    dbms=csv replace;
  datarow=2;
  getnames=yes;
  guessingrows=500;
  run;*/
 data WORK.MAR_ADDRESS    ;
%let _EFIERR_ = 0; /* set the ERROR detection macro variable */
infile FIMPORT delimiter = ',' MISSOVER DSD lrecl=32767 firstobs=2 ;
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
       run;

filename fimport clear;

proc sort data=New_Proj_Geocode;
  by marid;
  
proc sort data=Mar_address;
  by address_id;

**Merge project info and address info for new projects**;

data DC_info_geocode_mar;

  merge New_Proj_Geocode (rename=(marid=address_id) in=in1) Mar_address /*Mar_intersection (rename=(marid=address_id))*/;
  by address_id;
  
  if in1;
  
  format _all_ ;
  informat _all_ ;
  
  
  ** Standard geos **;
  
  length Ward2012 $ 1;
  
  Ward2012 = substr( Ward_2012, 6, 1 );
  
  format Ward2012 $ward12a.;
  
  length Anc2012 $ 2;
  
  Anc2012 = substr( Anc_2012, 5, 2 );
  
  format Anc2012 $anc12a.;
  
  length Psa2012 $ 3;
  
  Psa2012 = substr( Psa, 21, 3 ); 
  
  format Psa2012 $psa12a.;
  
  length Geo2010 $ 11;
  
  if Census_tract ~= . then Geo2010 = "11001" || put( Census_tract, z6. );
  
  format Geo2010 $geo10a.;
  
  length Cluster_tr2000 $ 2 Cluster_tr2000_name $ 80;
  
  if Cluster_ ~= "" then Cluster_tr2000 = put( 1 * substr( Cluster_, 9, 2 ), z2. );
  
  format Cluster_tr2000 $clus00a.;
  
  length Zip $ 5;
  
  if not( missing( MAR_ZIPCODE ) ) then Zip = put( MAR_ZIPCODE, z5.0 );
  else Zip = put( Bldg_zip, z5.0 );
  
  format Zip $zipa.;

  ** Cluster names **;
  
  Cluster_tr2000_name = put( Cluster_tr2000, $clus00b. );
  
  ** Image url **
  
  length Image_url $ 255;
  
  if imagename ~= "" and imagename ~=: "No_Image_Available" then 
    Image_url = trim( imageurl ) || "/" || left( imagedir ) || "/" || imagename;
    
  rename Streetviewurl=Streetview_url;
  
  ** Reformat addresses **;
  
  %address_clean( MAR_MATCHADDRESS, MAR_rMATCHADDRESS );
  

run;

proc sort data=DC_info_geocode_mar;
  by nlihc_id address_id /*bldg_ssl*/ MAR_MATCHADDRESS;
  
%File_info( data=DC_info_geocode_mar, freqvars=Ward2012 )

** Create project and building geocode data sets for new projects **;

%let geo_vars = Ward2012 Anc2012 Psa2012 Geo2010 Cluster_tr2000 Cluster_tr2000_name Zip;

data 
  work.Project_geocode_a 
    (label="Preservation Catalog, Project-level geocoding info"
     keep=nlihc_id Proj_Name &geo_vars Proj_address_id Proj_x Proj_y Proj_lat Proj_lon 
          Proj_addre Proj_zip Proj_image_url Proj_Streetview_url Bldg_count)
  work.Building_geocode_a
    (label="Preservation Catalog, Building-level geocoding info"
     keep=nlihc_id Proj_Name &geo_vars address_id Bldg_x Bldg_y Bldg_lat Bldg_lon Bldg_addre Zip
          image_url Streetview_url ssl_std
     rename=(address_id=Bldg_address_id Zip=Bldg_zip image_url=Bldg_image_url Streetview_url=Bldg_streetview_url
             ssl_std=Ssl));
    
  set DC_info_geocode_mar;
  by nlihc_id;
  
  length Ward2012x $ 1;
  
  Ward2012x = left( Ward2012 );
  
  length
    Proj_addre Bldg_addre $ 160
    Proj_zip $ 5
    Proj_image_url Proj_streetview_url $ 255
    Ssl_std $ 17;
  
  retain Proj_address_id Proj_x Proj_y Proj_lat Proj_lon Proj_addre Proj_zip Proj_image_url Bldg_count;
  
  Ssl_std = left( Ssl );
  
  if first.nlihc_id then do;
    Bldg_count = 0;
    Proj_address_id = .;
    Proj_x = .;
    Proj_y = .;
    Proj_lat = .;
    Proj_lon = .;
    Proj_addre = "";
    Proj_zip = "";
    Proj_image_url = "";
    Proj_streetview_url = "";
  end;
    
  Bldg_count + 1;
  
  Bldg_x = MAR_XCOORD;
  Bldg_y = MAR_YCOORD;
  Bldg_lon = MAR_LONGITUDE;
  Bldg_lat = MAR_LATITUDE;
  Bldg_addre = MAR_MATCHADDRESS;
  
 output work.Building_geocode_a;
  
  if address_id > 0 and missing( Proj_address_id ) then Proj_address_id = address_id;
  if Proj_zip = "" then Proj_zip = Zip;
  
  Proj_x = sum( Proj_x, MAR_XCOORD );
  Proj_y = sum( Proj_y, MAR_YCOORD );
  Proj_lat = sum( Proj_lat, MAR_LATITUDE );
  Proj_lon = sum( Proj_lon, MAR_LONGITUDE );
  
  if image_url ~= "" and Proj_image_url = "" then Proj_image_url = image_url;

  if Streetview_url ~= "" and Proj_streetview_url = "" then Proj_streetview_url = Streetview_url;

  if Bldg_count = 1 then Proj_addre = MAR_MATCHADDRESS;
  else if Bldg_count <= &MAX_PROJ_ADDRE then Proj_addre = trim( Proj_addre ) || "; " || MAR_MATCHADDRESS;
  else if Bldg_count = %eval( &MAX_PROJ_ADDRE + 1 ) then Proj_addre = trim( Proj_addre ) || "; others";
    
  if last.nlihc_id then do;
  
    Proj_x = Proj_x / Bldg_count;
    Proj_y = Proj_y / Bldg_count;
    Proj_lat = Proj_lat / Bldg_count;
    Proj_lon = Proj_lon / Bldg_count;
    
    output work.Project_geocode_a;

  end;
  
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
    Proj_addre = "Project address"
    Proj_address_id = "Project MAR address ID"
    Proj_image_url = "OCTO property image URL"
    Proj_lat = "Project latitude"
    Proj_lon = "Project longitude"
    Proj_streetview_url = "Google Street View URL"
    Proj_x = "Project longitude (MD State Plane Coord., NAD 1983 meters)"
    Proj_y = "Project latitude (MD State Plane Coord., NAD 1983 meters)"
    Proj_zip = "ZIP code (5 digit)"
    Bldg_addre = "Building address"
    Bldg_x = "Building longitude (MD State Plane Coord., NAD 1983 meters)"
    Bldg_y = "Building latitude (MD State Plane Coord., NAD 1983 meters)"
    Bldg_lon = "Building longitude"
    Bldg_lat = "Building latitude"
    Bldg_count = "Number of buildings for project";
  
  format Ward2012x $ward12a.;
  
  rename Ward2012x = Ward2012;
  drop Ward2012;
  
run;

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

**Check to see if any projects or buildings were removed in previous step**;

proc compare base=prescat.project_geocode compare=work.project listall maxprint=(40,32000);
  id nlihc_id;
run;

proc compare base=prescat.building_geocode compare=work.building listall maxprint=(40,32000);
  id Bldg_address_id;
run;

** merge new geocode files onto existing geocode files**;

data Project_geocode;
	set Project Project_geocode_a;
	run;

data Building_geocode;
	set Building Building_geocode_a;
	run;

%Dup_check(
  data=Project_geocode,
  by=nlihc_id,
  id=Proj_Name Proj_addre 
)

**Check for changes in the new geocode files that are not related to the new projects**;

proc sort data=prescat.building_geocode;
 by nlihc_id proj_name Bldg_address_id;
 run;

proc sort data=building_geocode;
 by nlihc_id proj_name Bldg_address_id;
 run;

proc compare base=prescat.project_geocode compare=work.project_geocode listall maxprint=(40,32000);
 id nlihc_id proj_name;
 run;

proc compare base=prescat.building_geocode compare=work.building_geocode listall maxprint=(40,32000);
 id nlihc_id proj_name Bldg_address_id;
 run;

** Macro Register_metadata - Start Definition **/

%macro Register_metadata( revisions= );

proc sort 
 data=Project_geocode 
 out=PresCat.Project_geocode (label="Preservation Catalog, Project-level geocoding info");
 by nlihc_id;
 run;

proc sort 
 data=Building_geocode 
 out=PresCat.Project_geocode (label="Preservation Catalog, Building-level geocoding info");
 by nlihc_id Bldg_address_id;
 run;

%File_info( data=&outlib..Project_geocode, freqvars=Ward2012 Bldg_count )
%File_info( data=&outlib..Building_geocode, freqvars=Ward2012 )

  %if &_remote_batch_submit %then %do;
  
    ** Register metadata **;
    
    %Dc_update_meta_file(
      ds_lib=PresCat,
      ds_name=Building_geocode,
      creator_process=DC_info_geocode.sas,
      restrictions=None,
      revisions=%str(&revisions)
    )
    
    %Dc_update_meta_file(
      ds_lib=PresCat,
      ds_name=Project_geocode,
      creator_process=DC_info_geocode.sas,
      restrictions=None,
      revisions=%str(&revisions)
    )
    
  %end;  
  %else %do;
  
    %warn_mput( msg=Not final batch submit. Files will not be registered with metadata system. )
  
%File_info( data=Project_geocode, freqvars=Ward2012 Bldg_count )
%File_info( data=Building_geocode, freqvars=Ward2012 )

  %end;

%mend Register_metadata;

/** End Macro Definition **/


%Register_metadata( revisions=%str(New file.) )

run;
