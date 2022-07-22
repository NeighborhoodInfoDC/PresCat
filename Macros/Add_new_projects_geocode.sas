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
  input_path=  /** Location of input files **/
  );

  %local geo_vars;
  
  ** Import geocoded project data **;

  ** Main sheet info **;

  filename fimport "&input_path\&input_file_pre._main.csv" lrecl=2000;

  proc import out=New_Proj_Geocode_main
      datafile=fimport
      dbms=csv replace;
    datarow=2;
    getnames=yes;
    guessingrows=500;

  run;

  filename fimport clear;

  ** MAR Address sheet info **;

  filename fimport "&input_path\&input_file_pre._mar_address.csv" lrecl=2000;

  data WORK.NEW_PROJ_GEOCODE_MAR_ADDRESS    ;
    %let _EFIERR_ = 0; /* set the ERROR detection macro variable */
    infile FIMPORT delimiter = ',' MISSOVER DSD lrecl=32767 firstobs=2 ;
       informat ADDRESS_ID best32. ;
       informat MARID best32. ;
       informat STATUS $6. ;
       informat FULLADDRESS $36. ;
       informat ADDRNUM best32. ;
       informat ADDRNUMSUFFIX $1. ;
       informat STNAME $21. ;
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
       informat ROC $17. ;
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
	   informat WARD_2022 $6. ;
       informat ANC_2002 $6. ;
       informat ANC_2012 $6. ;
       informat SMD_2002 $8. ;
       informat SMD_2012 $8. ;
       informat IMAGEURL $38. ;
       informat IMAGEDIR $8. ;
       informat IMAGENAME $22. ;
       informat CONFIDENCELEVEL $1. ;
       format ADDRESS_ID best12. ;
       format MARID best12. ;
       format STATUS $6. ;
       format FULLADDRESS $36. ;
       format ADDRNUM best12. ;
       format ADDRNUMSUFFIX $1. ;
       format STNAME $21. ;
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
       format ROC $17. ;
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
	   format WARD_2022 $6. ;
       format ANC_2002 $6. ;
       format ANC_2012 $6. ;
       format SMD_2002 $8. ;
       format SMD_2012 $8. ;
       format IMAGEURL $38. ;
       format IMAGEDIR $8. ;
       format IMAGENAME $22. ;
       format CONFIDENCELEVEL $1. ;
    input
                ADDRESS_ID
                MARID
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
				WARD_2022 $
                ANC_2002 $
                ANC_2012 $
                SMD_2002 $
                SMD_2012 $
                IMAGEURL $
                IMAGEDIR $
                IMAGENAME $
                CONFIDENCELEVEL $
    ;
    if _ERROR_ then call symputx('_EFIERR_',1);  /* set ERROR detection macro variable */
  run;

  filename fimport clear;

  ** Combine geocoding information **;

  proc sort data=New_Proj_Geocode_main;
    by marid;
  run;

  proc sort data=New_Proj_Geocode_mar_address;
    by marid;
  run;

  data New_Proj_Geocode;

    merge 
      New_Proj_Geocode_main
      New_Proj_Geocode_mar_address;
    by marid;

    length Streetview_url Image_url $ 255;

    Streetview_url = left( STREETVIEWURL );

    if imagename ~= "" and upcase( imagename ) ~=: "NO_IMAGE_AVAILABLE" then 
      Image_url = trim( imageurl ) || "/" || trim( left( imagedir ) ) || "/" || imagename;

    keep 
      Proj_Name Bldg_City Bldg_ST Bldg_Zip Bldg_Addre
      MAR_MATCHADDRESS MAR_XCOORD MAR_YCOORD MAR_LATITUDE
      MAR_LONGITUDE MAR_WARD MAR_CENSUS_TRACT MAR_ZIPCODE MARID
      MAR_ERROR MAR_SCORE MAR_SOURCEOPERATION MAR_IGNORE
      SSL Ward_2012 Ward_2022 ANC_2012 PSA Census_tract Cluster_
      Streetview_url Image_url;

  run;

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
      nlihc_id = cats ('NL', put(nlihc_hold,z6.));
      drop firstproj nlihc_num nlihc_sans nlihc_hold lastid _drop_constant;
  run;

  **Merge project info and address info for new projects**;

  data DC_info_geocode_mar;
  
    set New_Proj_Geocode;
    
    format _all_ ;
    informat _all_ ;
    
    ** Reformat addresses **;

    %address_clean( MAR_MATCHADDRESS, MAR_rMATCHADDRESS );
    
    ** Standard geos **;
    
    length Ward2012 $ 1;
    
    Ward2012 = substr( Ward_2012, 6, 1 );
    
    format Ward2012 $ward12a.;

    length Ward2022 $ 1;
    
    Ward2022 = substr( Ward_2022, 6, 1 );
    
    format Ward2022 $ward22a.;

    length Anc2012 $ 2;
    
    Anc2012 = substr( Anc_2012, 5, 2 );
    
    format Anc2012 $anc12a.;
    
    length Psa2012 $ 3;
    
    Psa2012 = substr( Psa, 21, 3 ); 
    
    format Psa2012 $psa12a.;
    
    length Geo2010 $ 11;
    
    if Census_tract ~= . then Geo2010 = "11001" || put( Census_tract, z6. );
    
    format Geo2010 $geo10a.;

    length Geo2020 $ 11;
    
    if Census_tract ~= . then Geo2020 = "11001" || put( Census_tract, z6. );
    
    format Geo2020 $geo20a.;

    ** Note: This is not technically the right way to create the 2000 clusters, 
    **       but we will soon switch to new clusters so this will be obsolete; 
    
    length Cluster_tr2000 $ 2 Cluster_tr2000_name $ 80;
        
    if Cluster_ ~= "" then Cluster_tr2000 = put( 1 * substr( Cluster_, 9, 2 ), z2. );
    
    format Cluster_tr2000 $clus00a.;
    
    length Zip $ 5;
    
    if not( missing( MAR_ZIPCODE ) ) then Zip = put( MAR_ZIPCODE, z5.0 );
    else Zip = put( Bldg_zip, z5.0 );
    
    format Zip $zipa.;

    ** Cluster names **;
    
    Cluster_tr2000_name = put( Cluster_tr2000, $clus00b. );

    drop Ward_2012 Ward_2022 ANC_2012 PSA Census_tract Cluster_;
    
  run;

  proc sort data=DC_info_geocode_mar;
    by nlihc_id MAR_rMATCHADDRESS;
  run;

  ** Create project and building geocode data sets for new projects **;

  %let geo_vars = Ward2012 Ward 2022 Anc2012 Psa2012 Geo2010 GeoBg2020 GeoBlk2020 Cluster_2017 Cluster_tr2000 Cluster_tr2000_name Zip;

  data 
    work.Building_geocode_a
      (keep=nlihc_id Proj_Name &geo_vars marid Bldg_x Bldg_y Bldg_lat Bldg_lon Bldg_addre zip
            image_url Streetview_url ssl_std
       rename=(marid=Bldg_address_id Zip=Bldg_zip image_url=Bldg_image_url Streetview_url=Bldg_streetview_url
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
	  Ward2022 = "Ward (2022)"
      Ssl_std = "Property identification number (square/suffix/lot)"
      Proj_Name = "Project name"
      NLIHC_ID = "Preservation Catalog project ID"
      marid = "MAR address ID"
      streetview_url = "Google Street View URL"
      Anc2012 = "Advisory Neighborhood Commission (2012)"
      Psa2012 = "Police Service Area (2012)"
      Geo2010 = "Full census tract ID (2010): ssccctttttt"
	  Geo2020 = "Full census tract ID (2020): ssccctttttt"
	  GeoBg2020 = 'Full census block group ID (2020): sscccttttttb'
	  GeoBlk2020 = 'Full census block ID (2020): sscccttttttbbbb'
      Cluster_tr2000 = "Neighborhood cluster (tract-based, 2000)"
      Cluster_tr2000_name = "Neighborhood cluster names (tract-based, 2000)"
	  Cluster_2017 = 'Neighborhood cluster (tract-based, 2017)'
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
  
  ** Find related parcels by using property owner names **;

  proc sql noprint;

    create table Ssl_by_owner as
    select coalesce( Parcel.Ownername, Owners.Ownername ) as Ownername, Owners.Nlihc_id, 
      Owners.Bldg_address_id, Owners.Proj_name, Parcel.ssl, Parcel.In_last_ownerpt, Parcel.ui_proptype as Parcel_type,
      Parcel.ownerpt_extractdat_last as Parcel_info_source_date, Parcel.saledate as Parcel_owner_date, 
      Parcel.ownercat as Parcel_owner_type, 
      Parcel.ownername_full as Parcel_owner_name, Parcel.x_coord as Parcel_x, Parcel.y_coord as Parcel_y
    from (
      /** Parcel characteristics **/
      select Parcel_base.*, Who_owns.ssl, Who_owns.ownercat, Who_owns.ownername_full,
        Geo.ssl, Geo.x_coord, Geo.y_coord
      from
      RealProp.Parcel_base as Parcel_base
      left join
      RealProp.Parcel_base_who_owns as Who_owns
      on Parcel_base.ssl = Who_owns.ssl
      left join
      Realprop.Parcel_geo as Geo
      on Parcel_base.ssl = Geo.ssl
    ) as Parcel 
    left join (
      /** List of property owners **/
      select Bldg.Nlihc_id, coalesce( Bldg.SSL, Parcel.SSL ) as SSL, Bldg.Bldg_address_id, 
        Bldg.Proj_name, Parcel.Ownername
      from Building_geocode_a as Bldg
      left join
      Realprop.Parcel_base as Parcel
      on Bldg.SSL = Parcel.SSL ) as Owners
    on upcase( Parcel.Ownername ) = upcase( Owners.Ownername )
    where not( missing( Owners.Nlihc_id ) ) and not ( missing( Owners.Ownername ) ) and
      Parcel.ownercat not in ( '040', '045', '050', '060', '070', '080', '090', '100', '120', '130' )
    order by nlihc_id, ssl;
   
  quit;
  
  /*
  title2 'SSL_BY_OWNER';

  proc print data=ssl_by_owner;
    by nlihc_id;
    id nlihc_id ssl;
    var ownername Parcel_owner_type;
  run;
  
  title2;
  */
  
  ** Find additional addresses using updated parcel list **;
  
  proc sql noprint;
    create table Building_geocode_b as
    select coopfulla.*, parcel.ssl, parcel.in_last_ownerpt, parcel.ownername
    from (
      select distinct bldgaddr.nlihc_id, bldgaddr.Proj_name, coalesce( bldgaddr.address_id, addr.address_id ) as Bldg_address_id, 
        addr.fulladdress as Bldg_addre, addr.ssl, addr.active_res_occupancy_count,
        anc2012, cluster_tr2000, geo2010, Geo2020, GeoBg2020, GeoBlk2020, psa2012, ward2012, ward2022, latitude as Bldg_lat, longitude as Bldg_lon, 
        x as Bldg_x, y as Bldg_y, zip as Bldg_zip
      from (  
        select Ssl_by_owner.nlihc_id, Ssl_by_owner.Proj_name, xref.address_id, coalesce( Ssl_by_owner.ssl, xref.ssl ) as ssl 
        from Ssl_by_owner 
        full join
        Mar.Address_ssl_xref as xref
        on xref.ssl = Ssl_by_owner.ssl
        where not( missing( Ssl_by_owner.nlihc_id ) or missing( xref.address_id ) ) ) as bldgaddr
      left join
      Mar.Address_points_view as addr
      on bldgaddr.address_id = addr.address_id ) as coopfulla
    left join
    RealProp.Parcel_base as parcel
    on coopfulla.ssl = parcel.ssl
    order by nlihc_id, Bldg_address_id;
    
  quit;

  /*
  title2 'BUILDING_GEOCODE_B';

  proc print data=building_geocode_b;
    by nlihc_id;
    id nlihc_id Bldg_address_id;
    var Bldg_addre;
  run;
  
  title2;
  */
  
  data Building_geocode_c;
  
    merge Building_geocode_a Building_geocode_b;
    by nlihc_id Bldg_address_id;
    
  run;
  
  ** Check new projects for pre-existing addresses in Catalog **;
  
  proc sort data=Building_geocode_c out=Building_geocode_c1;
    by bldg_address_id nlihc_id;
  run;

  proc sort data=PresCat.Building_geocode out=Building_geocode_c2;
    by bldg_address_id nlihc_id;
  run;

  proc compare base=Building_geocode_c1 compare=Building_geocode_c2 noprint outbase outcomp out=Building_geocode_comp;
    id bldg_address_id;
    var nlihc_id proj_name bldg_addre;
  run;

  proc sort data=Building_geocode_comp;
    by bldg_address_id _type_ nlihc_id;
  run;

  data Building_geocode_comp_rpt;

    retain _hold_bldg_address_id .a;

    set Building_geocode_comp;
    by bldg_address_id;

    if _type_ = 'BASE' then do;
      _hold_bldg_address_id = bldg_address_id;
    end;
    else if _hold_bldg_address_id = bldg_address_id then do;
      %warn_put( macro=Add_new_projects_geocode, 
                 msg="Possible existing Catalog project. " bldg_address_id= 
                     " See output for details." )
      output;
    end;
    else do;
      _hold_bldg_address_id = .a;
    end;

    drop _hold_bldg_address_id;

  run;

  title2 '********************************************************************************************';
  title3 '** Addresses in new projects that match those in existing Catalog projects';
  title4 '** Check to make sure these projects are not already in Catalog';

  proc print data=Building_geocode_comp_rpt noobs label;
    by bldg_address_id;
    id nlihc_id;
    var proj_name bldg_addre;
  run;
  
  title2; 
  

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

  proc compare base=prescat.project_geocode compare=work.project maxprint=(40,32000);
    id nlihc_id;
  run;

  title2 '********************************************************************************************';
  title3 '** 2/ Check to see if any buildings were removed in previous step';

  proc compare base=prescat.building_geocode compare=work.building maxprint=(40,32000);
    id nlihc_id Bldg_addre;
  run;

  title2;

  ** merge new geocode files onto existing geocode files**;
  
  proc sort data=Building_geocode_c;
    by nlihc_id Bldg_addre;
  run;

  data Building_geocode;
    set Building Building_geocode_c;
    by nlihc_id Bldg_addre;
    drop ACTIVE_RES_OCCUPANCY_COUNT in_last_ownerpt OWNERNAME;
  run;

  title2 '********************************************************************************************';
  title3 '** 3/ Check for changes in the new Building geocode file that is not related to the new projects';

  proc compare base=prescat.building_geocode compare=work.building_geocode listbasevar listcompvar maxprint=(40,32000);
   id nlihc_id proj_name Bldg_addre;
   run;
   
  title2;
   
  %Create_project_geocode(
    data=Building_geocode, 
    revisions=%str(Add new projects from &input_file_pre._*.csv.),
    compare=N,
    archive=N
  )

  ** Create file with list of new NLIHC_IDs **;

  proc sql;

     create table New_nlihc_id as
     select nlihc_id, proj_name
     from project_geocode
     where nlihc_id not in (select distinct nlihc_id from prescat.project)
     ;

  quit;
  
  %Data_to_format(
    FmtLib=work,
    FmtName=$New_nlihc_id,
    Data=New_nlihc_id,
    Value=Nlihc_id,
    Label=Nlihc_id,
    OtherLabel="",
    Print=N,
    Contents=N
    )

  %Finalize_data_set( 
    /** Finalize data set parameters **/
    data=Building_geocode,
    out=Building_geocode,
    outlib=PresCat,
    label="Preservation Catalog, Building-level geocoding info",
    sortby=Nlihc_id Bldg_addre,
    archive=N,
    /** Metadata parameters **/
    revisions=%str(Add new projects from &input_file_pre._*.csv.),
    /** File info parameters **/
    printobs=0
  )
  
  title2 'Building_geocode: New records';

  proc print data=Building_geocode;
    where put( nlihc_id, $New_nlihc_id. ) ~= "";
    by nlihc_id;
    id nlihc_id;
    var bldg_addre;
  run;
  
  title2 'Project_geocode: New records';

  proc print data=Project_geocode n;
    where put( nlihc_id, $New_nlihc_id. ) ~= "";
    id nlihc_id;
    var bldg_count proj_addre;
  run;

  title2;


  title2 '********************************************************************************************';
  title3 '** Project_geocode: Check for duplicate project IDs';

  %Dup_check(
    data=Project_geocode,
    by=nlihc_id,
    id=Proj_Name Proj_addre 
  )

  run;

  title2 '********************************************************************************************';
  title3 '** Building_geocode_c: Check for duplicate addresses in projects being added';

  %Dup_check(
    data=Building_geocode_c,
    by=Bldg_address_id,
    id=nlihc_id Proj_name Bldg_addre 
  )

  run;

  title2;
  
  ** Parcel **;
  
  data Parcel;
  
    set
      PresCat.Parcel
      Ssl_by_owner
        (keep=nlihc_id ssl in_last_ownerpt bldg_address_id parcel_info_source_date
              parcel_owner_date parcel_owner_name parcel_owner_type parcel_type
              parcel_x parcel_y
         rename=(bldg_address_id=parcel_address_id));
    by nlihc_id ssl;
    
    informat _all_ ;
    
  run;
  
  %Finalize_data_set( 
    /** Finalize data set parameters **/
    data=Parcel,
    out=Parcel,
    outlib=PresCat,
    label="Preservation Catalog, Real property parcels",
    sortby=nlihc_id ssl,
    archive=N,
    /** Metadata parameters **/
    revisions=%str(Add new projects from &input_file_pre._*.csv.),
    /** File info parameters **/
    printobs=0
  )

  proc compare base=prescat.Parcel compare=Parcel listbasevar listcompvar maxprint=(40,32000);
   id nlihc_id ssl;
  run;
  
  title2 'Parcel: New records';

  proc print data=Parcel;
    where put( nlihc_id, $New_nlihc_id. ) ~= "";
    by nlihc_id;
    id nlihc_id ssl;
    var parcel_owner_name;
  run;
  
  title2;

%mend Add_new_projects_geocode;

/** End Macro Definition **/

