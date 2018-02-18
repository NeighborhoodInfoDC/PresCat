/**************************************************************************
 Program:  Add_new_projects_geocode.sas
 Library:  PresCat
 Project:  NeighborhoodInfo DC
 Author:   P. Tatian
 Created:  02/17/18
 Version:  SAS 9.2
 Environment:  Local Windows session (desktop)
 
 Description:  Autocall macro to add new projects to Preservation
 Catalog. 

 Macro updates:
   PresCat.Buiding_geocode
   PresCat.Project_geocode

 Modifications:
**************************************************************************/

%macro Add_new_projects_geocode( 
  input_file_pre=, /** First part of input file names **/ 
  streetalt_file= /** File containing street name spelling corrections (if omitted, default file is used) **/
  );
  
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

  proc sort data=New_Proj_Geocode;
    by marid;
  run;
   
  options spool;

  %DC_mar_geocode(
    data = New_Proj_Geocode,
    staddr = bldg_addre,
    zip = bldg_zip,
    streetalt_file = &streetalt_file,
    out = New_Proj_Geocode,
    geo_match = Y,
    debug = N,
    mprint = Y
  );

  **Merge project info and address info for new projects**;

  data DC_info_geocode_mar;

  
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

    set New_Proj_Geocode;
    
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
    printobs=0
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

%mend Add_new_projects_geocode;

/** End Macro Definition **/

