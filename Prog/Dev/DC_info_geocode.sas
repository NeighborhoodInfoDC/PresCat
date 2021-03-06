/**************************************************************************
 Program:  DC_info_geocode.sas
 Library:  PresCat
 Project:  NeighborhoodInfo DC
 Author:   P. Tatian
 Created:  08/10/13
 Version:  SAS 9.1
 Environment:  Local Windows session (desktop)
 
 Description:  Import geocoded DC_Info database and create data sets
 PresCat.Project_geocode and PresCat.Building_geocode.

 Modifications:
  10/26/13 PAT Added Address_id, Image_url and Streetview_url variables 
               to Project_geocode and Building_geocode data sets.
  09/27/14 PAT Updated for SAS1.
               Added SSL to Building_geocode.
  11/11/14 PAT Added additional addresses for Brookland Manor (NL000046).
  12/18/14 PAT Fill in missing geos for TAP PROGRAM - RIDGE RD (NL000338).
  01/31/15 PAT Added new project 54th Street Housing (NL001033).
  02/09/15 PAT Added variable labels. 
  02/14/15 PAT Added new addresses.
**************************************************************************/

%include "\\sas1\DCdata\SAS\Inc\StdLocal.sas";

** Define libraries **;
%DCData_lib( PresCat )


%let MAX_PROJ_ADDRE = 3;   /** Maximum number of addresses to include in Proj_addre field in PresCat.Project_geo **/


%let outlib = %mif_select( &_remote_batch_submit, PresCat, WORK );


** Import geocoded building addresses from MAR Geocoder **;

** Main sheet info **;

filename fimport "&_dcdata_r_path\PresCat\Raw\DC_Info_02_08_13_buildings_for_geocoding (2013-10-13) main.csv" lrecl=2000;

proc import out=DC_info_geocode_a
    datafile=fimport
    dbms=csv replace;
  datarow=2;
  getnames=yes;
  guessingrows=500;

run;

filename fimport clear;

filename fimport "&_dcdata_r_path\PresCat\Raw\DC_Info_02_08_13_buildings_for_geocoding (2014-11-11) main.csv" lrecl=2000;

proc import out=DC_info_geocode_b
    datafile=fimport
    dbms=csv replace;
  datarow=2;
  getnames=yes;
  guessingrows=500;

run;

filename fimport clear;

filename fimport "&_dcdata_r_path\PresCat\Raw\Buildings for geocoding (2015-01-31) main.csv" lrecl=2000;

proc import out=DC_info_geocode_c
    datafile=fimport
    dbms=csv replace;
  datarow=2;
  getnames=yes;
  guessingrows=500;

run;

filename fimport clear;

filename fimport "&_dcdata_r_path\PresCat\Raw\Buildings for geocoding (2015-02-14) main.csv" lrecl=2000;

proc import out=DC_info_geocode_d
    datafile=fimport
    dbms=csv replace;
  datarow=2;
  getnames=yes;
  guessingrows=500;

run;

filename fimport clear;

data DC_info_geocode;
  set DC_info_geocode_a DC_info_geocode_b DC_info_geocode_c DC_info_geocode_d;
run;

title2 "File = DC_info_geocode";

%Dup_check(
  data=DC_info_geocode,
  by=marid,
  id=nlihc_id Bldg_Addre_new,
  out=_dup_check,
  listdups=Y,
  count=dup_check_count,
  quiet=N,
  debug=N
)

title2;

** MAR address info sheet **;

filename fimport "&_dcdata_r_path\PresCat\Raw\DC_Info_02_08_13_buildings_for_geocoding (2013-10-13) mar_address.csv" lrecl=2000;

proc import out=Mar_address_a
    datafile=fimport
    dbms=csv replace;
  datarow=2;
  getnames=yes;
  guessingrows=500;

run;

filename fimport clear;

filename fimport "&_dcdata_r_path\PresCat\Raw\DC_Info_02_08_13_buildings_for_geocoding (2014-11-11) mar_address.csv" lrecl=2000;

proc import out=Mar_address_b
    datafile=fimport
    dbms=csv replace;
  datarow=2;
  getnames=yes;
  guessingrows=500;

run;

filename fimport clear;

filename fimport "&_dcdata_r_path\PresCat\Raw\Buildings for geocoding (2015-01-31) mar_address.csv" lrecl=2000;

proc import out=Mar_address_c
    datafile=fimport
    dbms=csv replace;
  datarow=2;
  getnames=yes;
  guessingrows=500;

run;

filename fimport clear;

filename fimport "&_dcdata_r_path\PresCat\Raw\Buildings for geocoding (2015-02-14) mar_address.csv" lrecl=2000;

proc import out=Mar_address_d
    datafile=fimport
    dbms=csv replace;
  datarow=2;
  getnames=yes;
  guessingrows=500;

run;

filename fimport clear;



data Mar_address;
  length ROC $ 2;
  set Mar_address_a Mar_address_b Mar_address_c Mar_address_d;
run;

title2 "File = Mar_address";

%Dup_check(
  data=Mar_address,
  by=address_id,
  id=fulladdress status,
  out=_dup_check,
  listdups=Y,
  count=dup_check_count,
  quiet=N,
  debug=N
)

title2;

** MAR intersection info sheet **;

filename fimport "&_dcdata_r_path\PresCat\Raw\DC_Info_02_08_13_buildings_for_geocoding (2013-10-13) mar_intersection.csv" lrecl=2000;

proc import out=Mar_intersection
    datafile=fimport
    dbms=csv replace;
  datarow=2;
  getnames=yes;
  guessingrows=500;

run;

filename fimport clear;

** Combine building address information **;

proc sort data=DC_info_geocode;
  by marid;
  
proc sort data=Mar_address;
  by address_id;
  
proc sort data=Mar_intersection;
  by marid;
  
data DC_info_geocode_mar;

  merge DC_info_geocode (rename=(marid=address_id) in=in1) Mar_address Mar_intersection (rename=(marid=address_id));
  by address_id;
  
  if in1;
  
  format _all_ ;
  informat _all_ ;
  
  ** Apply standard corrections **;
  
  %DCInfo_corrections()
  
  ** Standard geos **
  
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

  ** Fill in missing geos **;
  
  if nlihc_id = 'NL000338' then do; 
  
    ** TAP PROGRAM - RIDGE RD **;
    Ward2012 = '7';
    Zip = '20019';
    cluster_tr2000 = '32';
    Psa2012 = '603';
    Anc2012 = '7F';
    Geo2010 = '11001007703';
    
  end;
  
  ** Cluster names **;
  
  Cluster_tr2000_name = put( Cluster_tr2000, $clus00b. );
  
  ** Image url **
  
  length Image_url $ 255;
  
  if imagename ~= "" and imagename ~=: "No_Image_Available" then 
    Image_url = trim( imageurl ) || "/" || trim( imagedir ) || "/" || imagename;
    
  rename Streetviewurl=Streetview_url;
  
  ** Reformat addresses **;
  
  %address_clean( MAR_MATCHADDRESS, MAR_MATCHADDRESS );
  
  ** Corrections: Congress Heights PUD **;
  
  if nlihc_id = 'NL001032' then do;
    ssl = 'PAR 02290160';
    address_id = .u;
    Image_url = "";
    Streetviewurl = "";
    MAR_MATCHADDRESS = "Alabama Avenue SE";
  end;
  
run;

proc sort data=DC_info_geocode_mar;
/*  by nlihc_id Proj_Name bldg_ssl;*/
  by nlihc_id bldg_ssl MAR_MATCHADDRESS;
  
%File_info( data=DC_info_geocode_mar, freqvars=Ward2012 )

** Create project and building geocode data sets **;

%let geo_vars = Ward2012 Anc2012 Psa2012 Geo2010 Cluster_tr2000 Cluster_tr2000_name Zip;

data 
  &outlib..Project_geocode 
    (label="Preservation Catalog, Project-level geocoding info"
     keep=nlihc_id Proj_Name &geo_vars Proj_address_id Proj_x Proj_y Proj_lat Proj_lon 
          Proj_addre Proj_zip Proj_image_url Proj_Streetview_url Bldg_count)
  &outlib..Building_geocode
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
  
  output &outlib..Building_geocode;
  
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
    
    output &outlib..Project_geocode;
    
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

%File_info( data=&outlib..Project_geocode, freqvars=Ward2012 Bldg_count )
%File_info( data=&outlib..Building_geocode, freqvars=Ward2012 )

%Dup_check(
  data=&outlib..Project_geocode,
  by=nlihc_id,
  id=Proj_Name Proj_addre 
)

proc print data=&outlib..Project_geocode;
  where Ward2012 = '';
  id nlihc_id;
  title2 "&outlib..Project_geocode / Missing Ward";
run;

proc print data=&outlib..Building_geocode;
  where Ward2012 = '';
  id nlihc_id;
  title2 "&outlib..Building_geocode / Missing Ward";
run;
  
proc print data=&outlib..Building_geocode noobs;
  id nlihc_id;
  var ssl Ward2012 Bldg_address_id bldg_addre;
  title2;
run;

data _null_;
  set &outlib..Building_geocode (where=(nlihc_id='NL001032'));
  file print;
  put / "---&outlib..Building_geocode-----------------";
  put (_all_) (= /);
run;

data _null_;
  set &outlib..Project_geocode (where=(nlihc_id='NL001032'));
  file print;
  put / "---&outlib..Project_geocode-----------------";
  put (_all_) (= /);
run;


/** Macro Register_metadata - Start Definition **/

%macro Register_metadata( revisions= );

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
    
  %end;

%mend Register_metadata;

/** End Macro Definition **/


%Register_metadata( revisions=%str(New file.) )

run;

