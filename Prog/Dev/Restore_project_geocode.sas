/**************************************************************************
 Program:  Restore_project_geocode.sas
 Library:  PresCat
 Project:  NeighborhoodInfo DC
 Author:   P. Tatian
 Created:  01/03/17
 Version:  SAS 9.2
 Environment:  Local Windows session (desktop)
 
 GitHub issue: #85
 
 Description:  Restore Project_geocode file from Building_geocode.
 Reapply geocoding data fixes for NL000093 and NL000319.

 Modifications:
**************************************************************************/

%include "\\sas1\DCdata\SAS\Inc\StdLocal.sas";

** Define libraries **;
%DCData_lib( PresCat )


** Reapply geocoding data fixes for NL000093 and NL000319 **;

%let input_file_pre = Buildings_for_geocoding_fixes;

** MAR address info sheet **;

filename fimport "&_dcdata_r_path\PresCat\Raw\New\&input_file_pre._NL000093_NL000319.csv" lrecl=2000;

data WORK.MAR_ADDRESS    ;

  %let _EFIERR_ = 0; /* set the ERROR detection macro variable */
  infile FIMPORT delimiter = ',' MISSOVER DSD lrecl=32767 firstobs=2 ;
  informat NLIHC_ID $8.;
  informat ADDRESS_ID best32. ;
  informat STATUS $6. ;
  informat FULLADDRESS $40. ;
  informat ADDRNUM $5. ;
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
  informat STREETVIEWURL $200. ;
  informat RES_TYPE $11. ;
  informat WARD_2002 $6. ;
  informat WARD_2012 $6. ;
  informat ANC_2002 $6. ;
  informat ANC_2012 $6. ;
  informat SMD_2002 $8. ;
  informat SMD_2012 $8. ;
  informat MARID best32. ;
  informat IMAGEURL $200. ;
  informat IMAGEDIR best32. ;
  informat IMAGENAME $12. ;
  informat CONFIDENCELEVEL $1. ;

  input
  NLIHC_ID $
  ADDRESS_ID
                   STATUS $
                   FULLADDRESS $
                   ADDRNUM $
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
  
proc sort data=Mar_address;
  by address_id;

** Create Building_Geocode Fix **;

data bldg_mar_address;

  length
    Nlihc_id $ 16
    Bldg_addre $ 160
    Bldg_image_url Bldg_streetview_url $ 255;

  merge 
    Mar_address (rename = (address_id = bldg_address_id Streetviewurl=Bldg_streetview_url XCOORD=Bldg_x
                           YCOORD=Bldg_y LONGITUDE=Bldg_lon LATITUDE=Bldg_lat)
                 in=inA)
    PresCat.Project (keep=nlihc_id proj_name);
  by nlihc_id;
  
  if inA;
  
  format _all_ ;
  informat _all_ ;
  
  ** Fix capatilization for match**;

  street = propcase(stname);
  type = propcase(street_type);
  
  length bldg_addre $ 160;
  bldg_addre = catx (' ',addrnum, street, type, quadrant);
  
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
  
  length Bldg_zip $ 5;
  
  Bldg_zip = put( ZIPCODE, z5.0 );
  
  format Bldg_zip $zipa.;

  ** Cluster names **;
  
  Cluster_tr2000_name = put( Cluster_tr2000, $clus00b. );
  
  ** Image url **;
  
  if imagename ~= "" and imagename ~=: "No_Image_Available" then 
    bldg_image_url = trim( imageurl ) || "/" || trim( left( imagedir ) ) || "/" || imagename;
  
drop street type;

run;

proc sort data=bldg_mar_address; by nlihc_id bldg_addre;
run;

data Building_geocode;

  length
    Nlihc_id $ 16
    Proj_name $ 80
    Bldg_addre $ 160
    Bldg_image_url Bldg_streetview_url $ 255;

  update
    PresCat.Building_geocode (where=(Nlihc_id~='NL000093'))
    bldg_mar_address
      (keep=Anc2012 Bldg_addre Bldg_address_id Bldg_image_url Bldg_lat
            Bldg_lon Bldg_streetview_url Bldg_x Bldg_y Bldg_zip
            Cluster_tr2000 Cluster_tr2000_name Geo2010 Nlihc_id
            Proj_Name Psa2012 Ssl Ward2012)
    updatemode=nomissingcheck;
  by nlihc_id bldg_addre;

run;


** Create updated Project_geocode **;

%let MAX_PROJ_ADDRE = 3;   /** Maximum number of addresses to include in Proj_addre field in PresCat.Project_geo **/

%let geo_vars = Ward2012 Anc2012 Psa2012 Geo2010 Cluster_tr2000 Cluster_tr2000_name Zip;

data Project_geocode      
       (keep=nlihc_id Proj_Name &geo_vars Proj_address_id Proj_x Proj_y Proj_lat Proj_lon 
             Proj_addre Proj_zip Proj_image_url Proj_Streetview_url Bldg_count);

  length Nlihc_id $ 16;

  set Building_geocode;
  by Nlihc_id;
  
  length
    Proj_addre $ 160
    Proj_zip Zip $ 5
    Proj_image_url Proj_streetview_url $ 255;
  
  retain Proj_address_id Proj_x Proj_y Proj_lat Proj_lon Proj_addre Proj_zip Proj_image_url Bldg_count;
  
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
  
  if bldg_address_id > 0 and missing( Proj_address_id ) then Proj_address_id = bldg_address_id;
  if Proj_zip = "" then Proj_zip = bldg_Zip;
  
  Proj_x = sum( Proj_x, bldg_x );
  Proj_y = sum( Proj_y, bldg_y );
  Proj_lat = sum( Proj_lat, bldg_lat );
  Proj_lon = sum( Proj_lon, bldg_lon );
  
  if bldg_image_url ~= "" and Proj_image_url = "" then Proj_image_url = bldg_image_url;

  if bldg_Streetview_url ~= "" and Proj_streetview_url = "" then Proj_streetview_url = bldg_Streetview_url;

  if Bldg_count = 1 then Proj_addre = bldg_addre;
  else if Bldg_count <= &MAX_PROJ_ADDRE then Proj_addre = trim( Proj_addre ) || "; " || bldg_addre;
  else if Bldg_count = %eval( &MAX_PROJ_ADDRE + 1 ) then Proj_addre = trim( Proj_addre ) || "; others";
    
  if last.nlihc_id then do;
  
    Proj_x = Proj_x / Bldg_count;
    Proj_y = Proj_y / Bldg_count;
    Proj_lat = Proj_lat / Bldg_count;
    Proj_lon = Proj_lon / Bldg_count;
    
    Zip = Proj_zip;
    
    output Project_geocode;
    
  end;
  
  label
    Proj_Name = "Project name"
    NLIHC_ID = "Preservation Catalog project ID"
    Proj_addre = "Project address"
    Proj_address_id = "Project MAR address ID (first address in list)"
    Proj_image_url = "OCTO property image URL"
    Proj_lat = "Project latitude"
    Proj_lon = "Project longitude"
    Proj_streetview_url = "Google Street View URL"
    Proj_x = "Project longitude (MD State Plane Coord., NAD 1983 meters)"
    Proj_y = "Project latitude (MD State Plane Coord., NAD 1983 meters)"
    Proj_zip = "ZIP code (5 digit)"
    zip = "ZIP code (5 digit)"
    Bldg_count = "Number of buildings for project";
  
run;


** Check restored file against earlier version **;

proc compare base=PresCat.Building_geocode compare=Building_geocode listall maxprint=(40,32000);
  id nlihc_id bldg_addre;
run;

proc compare base=PresCat.Project_geocode compare=Project_geocode listall maxprint=(40,32000);
  id nlihc_id;
run;


** Finalize data sets **;

%Finalize_data_set( 
  /** Finalize data set parameters **/
  data=Building_geocode,      /** Input temporary data set (required) **/
  out=Building_geocode,       /** Ouput data set name (required) **/
  outlib=PresCat,    /** Output data set library (required) **/
  label="Preservation Catalog, Building-level geocoding info",     /** Output data set label, in quotes (required) **/
  sortby=nlihc_id bldg_addre,    /** Output data set sorting variables (required) **/
  archive=Y,  /** Add output data set to archive (Y/N) **/
  printobs=0,
  /** Metadata parameters **/
  restrictions=None,          /** Metadata file restrictions **/
  revisions=%str(Replace data set with correct, updated version.)                 /** Metadata file revisions (required) **/
  )

data _null_;
  set Building_geocode (where=(nlihc_id in ('NL000093','NL000319') ));
  file print;
  put / '--------------------';
  put (_all_) (= /);
run;


%Finalize_data_set( 
  /** Finalize data set parameters **/
  data=Project_geocode,      /** Input temporary data set (required) **/
  out=Project_geocode,       /** Ouput data set name (required) **/
  outlib=PresCat,    /** Output data set library (required) **/
  label="Preservation Catalog, Project-level geocoding info",     /** Output data set label, in quotes (required) **/
  sortby=nlihc_id,    /** Output data set sorting variables (required) **/
  archive=Y,  /** Add output data set to archive (Y/N) **/
  printobs=0,
  /** Metadata parameters **/
  restrictions=None,          /** Metadata file restrictions **/
  revisions=%str(Replace data set with correct, updated version.)                 /** Metadata file revisions (required) **/
  )

data _null_;
  set Project_geocode (where=(nlihc_id in ('NL000093','NL000319') ));
  file print;
  put / '--------------------';
  put (_all_) (= /);
run;

