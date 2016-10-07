/**************************************************************************
 Program:  Fix NL000093 and NL000319.sas
 Library:  PresCat
 Project:  NeighborhoodInfo DC
 Author:   M. Cohen
 Created:  10/4/2016
 Version:  SAS 9.1
 Environment:  Local Windows session (desktop)
 
 Description:  Fixes geocoding data for NL000093 and NL000319. *One Time Fix*.

 Modifications:

**************************************************************************/

%include "L:\SAS\Inc\StdLocal.sas";

** Define libraries **;
%DCData_lib( PresCat )

%let input_file_pre = Buildings_for_geocoding_fixes;

  ** MAR address info sheet **;

filename fimport "&_dcdata_r_path\PresCat\Raw\New\&input_file_pre._NL000093_NL000319.csv" lrecl=2000;

data WORK.MAR_ADDRESS    ;
%let _EFIERR_ = 0; /* set the ERROR detection macro variable */
infile FIMPORT delimiter = ',' MISSOVER DSD lrecl=32767 firstobs=2 ;
informat NLIHC_ID $8.;
informat ADDRESS_ID best32. ;
informat STATUS $6. ;
informat FULLADDRESS $19. ;
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
informat STREETVIEWURL $104. ;
informat RES_TYPE $11. ;
informat WARD_2002 $6. ;
informat WARD_2012 $6. ;
informat ANC_2002 $6. ;
informat ANC_2012 $6. ;
informat SMD_2002 $8. ;
informat SMD_2012 $8. ;
informat MARID best32. ;
informat IMAGEURL $160. ;
informat IMAGEDIR best32. ;
informat IMAGENAME $12. ;
informat CONFIDENCELEVEL $1. ;
format NLIHC_ID $8.;
format ADDRESS_ID best12. ;
format STATUS $6. ;
format FULLADDRESS $19. ;
format ADDRNUM $5. ;
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
format IMAGEURL $160. ;
format IMAGEDIR best12. ;
format IMAGENAME $12. ;
format CONFIDENCELEVEL $1. ;
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

**Create Building_Geocode Fix**;

data bldg_mar_address;

  set Mar_address (rename = (address_id = bldg_address_id Streetviewurl=Bldg_streetview_url XCOORD=Bldg_x
YCOORD=Bldg_y LONGITUDE=Bldg_lon LATITUDE=Bldg_lat));
  
  format _all_ ;
  informat _all_ ;
  
  ** Fix capatilization for match**;

  street = propcase(stname);
  type = propcase(street_type);
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
  
  length Zip $ 5;
  
  Zip = put( ZIPCODE, z5.0 );
  
  format Zip $zipa.;

  ** Cluster names **;
  
  Cluster_tr2000_name = put( Cluster_tr2000, $clus00b. );
  
  ** Image url **;
  
  if imagename ~= "" and imagename ~=: "No_Image_Available" then 
    bldg_image_url = trim( imageurl ) || "/" || trim( left( imagedir ) ) || "/" || imagename;
  
drop street type;

run;

data Building_Geocode;
set prescat.Building_Geocode;
run;

data Building_Geocode;
modify Building_Geocode bldg_mar_address;
by nlihc_ID;
run;


proc sort data=building_geocode;
 by nlihc_id Bldg_addre;
 run;

title2 '********************************************************************************************';
title3 '** 1/ Check for changes in building_geocode file unrelated to fixes for NL000093 and NL000319';

proc compare base=prescat.building_geocode compare=building_geocode listall maxprint=(40,32000);
 id nlihc_id bldg_addre;
 run;

 **use this to check NL000093 (obs 174), since the bldg_addre has changed**;
proc compare base=building_geocode1 compare=building_geocode listall maxprint=(40,32000);
run;

**Create Project_Geocode Fix**;

data proj_mar_address;

  set Mar_address (rename = (address_id = proj_address_id Streetviewurl=proj_streetview_url XCOORD=proj_x
YCOORD=proj_y LONGITUDE=proj_lon LATITUDE=proj_lat));
  
  format _all_ ;
  informat _all_ ;
  
 ** Fix capatilization for match**;

  street = propcase(stname);
  type = propcase(street_type);
  proj_addre = catx (' ',addrnum, street, type, quadrant);
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
  
  Zip = put( ZIPCODE, z5.0 );
  
  format Zip $zipa.;

  ** Cluster names **;
  
  Cluster_tr2000_name = put( Cluster_tr2000, $clus00b. );
  
  ** Image url **;
  
  if imagename ~= "" and imagename ~=: "No_Image_Available" then 
    proj_image_url = trim( imageurl ) || "/" || trim( left( imagedir ) ) || "/" || imagename;
	
	drop street type;

run;


data Project_Geocode;
set prescat.Project_Geocode;
run;

data Project_Geocode;
modify Project_Geocode proj_mar_address;
by nlihc_ID;
run;


proc sort data=project_geocode;
 by nlihc_id;
 run;

title2 '********************************************************************************************';
title3 '** 2/ Check for changes in project_geocode file unrelated to fixes for NL000093 and NL000319';

proc compare base=prescat.project_geocode compare=project_geocode listall maxprint=(40,32000);
 id nlihc_id;
 run;

**Create Project Fix**;

data project;
set prescat.project;
run;

data project_fix;
set project_geocode;
if nlihc_id in ('NL000093', 'NL000319');
drop proj_name;
run;

data Project;
modify Project project_fix;
by nlihc_ID;
run;

title2 '********************************************************************************************';
title3 '** 3/ Check for changes in project file unrelated to fixes for NL000093 and NL000319';

proc compare base=prescat.project compare=project listall maxprint=(40,32000);
 id nlihc_id;
 run;

** Macro Register_metadata - Start Definition **;

%macro Register_metadata( revisions= );

  %if &_remote_batch_submit %then %do;
  
    ** Create permanent data sets **;
  
    proc sort 
     data=Project_geocode 
     out=PresCat.Project_geocode (label="Preservation Catalog, Project-level geocoding info");
     by nlihc_id;
     run;

    proc sort 
     data=Building_geocode 
     out=PresCat.Project_geocode (label="Preservation Catalog, Building-level geocoding info");
     by nlihc_id Bldg_addre;
     run;

    proc sort 
     data=Project
     out=PresCat.Project (label="Preservation Catalog, Project info");
     by nlihc_id;
     run;

    %File_info( data=&outlib..Project_geocode, freqvars=Ward2012 Bldg_count )
    %File_info( data=&outlib..Building_geocode, freqvars=Ward2012 ) 
	%File_info( data=&outlib..Project, freqvars=Ward2012 ) 

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
    
	%Dc_update_meta_file(
      ds_lib=PresCat,
      ds_name=Project,
      creator_process=DC_info_geocode.sas,
      restrictions=None,
      revisions=%str(&revisions)
    )
    
  %end;  
  %else %do;
  
    %warn_mput( msg=Not final batch submit. Files will not be registered with metadata system. )
  
    %File_info( data=Project_geocode, freqvars=Ward2012 Bldg_count )
    %File_info( data=Building_geocode, freqvars=Ward2012 )
	%File_info( data=Project, freqvars=Ward2012 )
  %end;

%mend Register_metadata;

** End Macro Definition **;


%Register_metadata( revisions=%str(New file.) )

run;
