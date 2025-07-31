/**************************************************************************
 Program:  Create_project_geocode.sas
 Library:  PresCat
 Project:  NeighborhoodInfo DC
 Author:   P. Tatian
 Created:  06/03/17
 Version:  SAS 9.2
 Environment:  Local Windows session (desktop)
 
 Description:  Autocall macro to create Project_geocode data set from
 Building_geocode data set.

 Modifications:
**************************************************************************/

/** Macro Create_project_geocode - Start Definition **/

%macro Create_project_geocode( 
  data=PresCat.Building_geocode, 
  out=Project_geocode, 
  revisions=, 
  compare=Y,
  finalize=Y,
  archive=N 
  );

  %local PROJ_ADDRE_LENGTH PROJ_ADDRE_OVER_LBL geo_vars;

  %let PROJ_ADDRE_LENGTH = 160;

  %let PROJ_ADDRE_OVER_LBL = "; others";

  %let geo_vars = 
    Ward2012 Anc2012 Anc2023 Psa2012 Psa2019 Geo2010 Cluster_tr2000 Cluster_tr2000_name 
    Zip Geo2020 GeoBg2020 GeoBlk2020 Ward2022 cluster2017 voterpre2012;

  proc sort data=&data out=_create_project_geocode;
    by nlihc_id descending bldg_units_mar bldg_addre;
  run;

  data 
    &out 
      (keep=nlihc_id &geo_vars Proj_name Proj_address_id Proj_x Proj_y Proj_lat Proj_lon 
            Proj_addre Proj_zip Proj_image_url Proj_Streetview_url Bldg_count Proj_units_mar);
      
    set _create_project_geocode;
    by nlihc_id;
    
    length
      Proj_addre $ &PROJ_ADDRE_LENGTH
      Proj_zip Zip $ 5
      Proj_image_url Proj_streetview_url $ 255;
    
    retain 
      Proj_address_id Proj_x Proj_y Proj_lat Proj_lon Proj_addre Proj_zip Proj_image_url 
      Proj_streetview_url Bldg_count Proj_units_mar _Proj_addre_count
      _Proj_addre_remaining;
    
    if first.nlihc_id then do;
      Bldg_count = 0;
      _Proj_addre_count = 0;
      _Proj_addre_remaining = &PROJ_ADDRE_LENGTH;
      Proj_address_id = .;
      Proj_x = Bldg_x;
      Proj_y = Bldg_y;
      Proj_lat = Bldg_lat;
      Proj_lon = Bldg_lon;
      Proj_addre = "";
      Proj_zip = "";
      Proj_image_url = "";
      Proj_streetview_url = "";
      Proj_units_mar = .;
    end;
      
    Bldg_count + 1;
    
    if bldg_address_id > 0 and missing( Proj_address_id ) then Proj_address_id = bldg_address_id;
    
    if Proj_zip = "" then Proj_zip = Bldg_Zip;
    Zip = Proj_zip;
    
    Proj_units_mar = sum( Proj_units_mar, Bldg_units_mar );
    
    if Bldg_image_url ~= "" and Proj_image_url = "" then Proj_image_url = Bldg_image_url;

    if Bldg_Streetview_url ~= "" and Proj_streetview_url = "" then Proj_streetview_url = Bldg_Streetview_url;
    
    if not( missing( Bldg_addre ) ) and _Proj_addre_remaining > 0 then do;
    
      if length( Bldg_addre ) < _Proj_addre_remaining - ( length( &PROJ_ADDRE_OVER_LBL ) + 2 ) then do;
    
        _Proj_addre_count + 1;

        if _Proj_addre_count = 1 then Proj_addre = Bldg_addre;        
        else Proj_addre = trim( Proj_addre ) || "; " || Bldg_addre;
        
        _Proj_addre_remaining = &PROJ_ADDRE_LENGTH - length( Proj_addre );
        
      end; 
      else do;
      
        Proj_addre = trim( Proj_addre ) || &PROJ_ADDRE_OVER_LBL;
        
        _Proj_addre_remaining = 0;
        
      end;
    
    end;
    
    if last.nlihc_id then do;
    
      output &out;
      
    end;
    
    label
      Bldg_count = "Number of buildings for project"
      Proj_addre = "Project addresses"
      Proj_address_id = "Project MAR address ID (first address in list)"
      Proj_image_url = "OCTO property image URL"
      Proj_lat = "Project latitude"
      Proj_lon = "Project longitude"
      Proj_streetview_url = "Google Street View URL"
      Proj_x = "Project longitude (MD State Plane Coord., NAD 1983 meters)"
      Proj_y = "Project latitude (MD State Plane Coord., NAD 1983 meters)"
      Proj_zip = "ZIP code (5 digit)"
      Proj_units_mar = "Total housing units at primary addresses (from MAR)"
      Zip = "ZIP code (5 digit)"
    ;
    
    format Zip $zipa.;
    
    drop _Proj_addre_count _Proj_addre_remaining;
    
  run;

  %if %mparam_is_yes( &compare ) %then %do;
  
    proc compare base=PresCat.Project_geocode compare=&out listall maxprint=(40,32000);
      id nlihc_id;
    run;
  
  %end;
    
  ** Finalize data set **;

  %Finalize_data_set(
    finalize=&finalize,
    data=&out,
    out=Project_geocode,
    outlib=PresCat,
    label="Preservation Catalog, Project-level geocoding info",
    sortby=nlihc_id,
    revisions=%str(&revisions),
    archive=&archive,
    printobs=0
  )
    
  ** Clean up temporary files **;
  
  proc datasets library=Work nolist;
    delete _create_project_geocode /memtype=data;
  quit;

%mend Create_project_geocode;

/** End Macro Definition **/

