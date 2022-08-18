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
      SSL Ward_2012 ANC_2012 PSA Census_tract Cluster_
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

  ** Create project name format **;

  %Data_to_format(
  FmtLib=work,
  FmtName=$nlihc_id_to_proj_name,
  Data=New_Proj_Geocode,
  Value=nlihc_id,
  Label=proj_name,
  OtherLabel="",
  Print=N,
  Contents=N
  )

  ** Compile full lists of addresses and parcels for each project **;

  proc sql noprint;

    /** Match geocoded address IDs with MAR address-parcel crosswalk **/
    create table A as 
      select distinct New.nlihc_id, New.Proj_name, New.Bldg_addre, coalesce( New.Marid, xref.address_id ) as address_id, xref.lot_type, xref.ssl as xref_ssl from 
  	  New_proj_geocode as New left join
  	  Mar.Address_ssl_xref as xref
  	  on New.Marid = xref.address_id
  	  where New.Mar_score > 90
  	  order by nlihc_id, address_id, xref_ssl;

    /** Add property owner name and category **/ 
    create table B as
      select A.*, Who.ssl as Who_ssl, Who.ownername_full, Who.ownercat from
  	A left join
  	Realprop.Parcel_base_who_owns as Who
  	on Xref_ssl = Who.ssl
  	order by nlihc_id, address_id, Xref_ssl;

    /** Add parcels with same owner names **/
    create table C as
      select B.*, Who.ssl as Who_ssl2, Who.ownername_full from 
  	B left join
  	Realprop.Parcel_base_who_owns as Who
  	on B.ownername_full = Who.ownername_full
  	where B.ownername_full ~= "" and B.ownercat in ( '010', '020', '030', '111', '115' )
  	order by nlihc_id, Address_id, Who.ssl;

    /** Compile full list of parcel **/
    create table all_parcels as
      select C.nlihc_id, C.who_ssl2 as ssl from C
      union
      select A.nlihc_id, A.xref_ssl as ssl from A
  	order by nlihc_id, ssl;

    /** Match full parcel list with address-parcel crosswalk to get address IDs **/
    create table D as
      select distinct all_parcels.nlihc_id, coalesce( all_parcels.ssl, xref.ssl ) as ssl, xref.address_id from
  	all_parcels left join
  	Mar.Address_ssl_xref as xref
  	on all_parcels.ssl = xref.ssl
  	where not( missing( all_parcels.ssl ) or missing( xref.ssl ) )
  	order by nlihc_id, ssl, address_id;

    /** Compile full list of address IDs **/
    create table all_addresses as
      select D.nlihc_id, D.address_id from D
      union
      select A.nlihc_id, A.address_id from A
  	where not( missing( address_id ) )
  	order by nlihc_id, address_id;

  quit;

  ** Create project and building geocode data sets for new projects **;

  %let geo_vars = Anc2012 Cluster2017 Cluster_tr2000 Cluster_tr2000_name Geo2010 GeoBg2010 GeoBlk2010 
                  Geo2020 GeoBg2020 GeoBlk2020 Psa2012 ssl Ward2012 Ward2022 Zip;

  proc sort data=all_addresses nodupkey;
    by address_id nlihc_id;
  run;

  proc sort data=New_proj_geocode out=New_proj_geocode_addr_srt;
    by marid;
  run;

  data 
    work.Building_geocode_a
      (keep=nlihc_id address_id Proj_Name &geo_vars marid Bldg_x Bldg_y Bldg_lat Bldg_lon Bldg_addre zip
            bldg_units_mar bldg_image_url bldg_Streetview_url ssl
       rename=(address_id=Bldg_address_id));
      
    merge 
      all_addresses (in=in1)
      Mar.Address_points_view 
       (rename=(
          fulladdress=bldg_addre latitude=bldg_lat longitude=bldg_lon active_res_occupancy_count=bldg_units_mar
		  x=bldg_x y=bldg_y zip=bldg_zip 
          ))
      New_proj_geocode_addr_srt 
        (keep=marid image_url streetview_url 
         rename=(marid=address_id image_url=bldg_image_url streetview_url=bldg_streetview_url))
    ;
    by address_id;

	if in1;

	length Proj_name $ 80;

	Proj_name = left( put( nlihc_id, $nlihc_id_to_proj_name. ) );

    ** Cluster names **;
    
    length Cluster_tr2000_name $ 80;
	    
    Cluster_tr2000_name = left( put( Cluster_tr2000, $clus00b. ) );

	format _all_ ;
	informat _all_ ;
    
  run;
  
  ** Check new projects for pre-existing addresses in Catalog **;
  
  proc sort data=Building_geocode_a out=Building_geocode_c1;
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
  
  proc sort data=Building_geocode_a;
    by nlihc_id Bldg_addre;
  run;

  data Building_geocode;
    set Building Building_geocode_a;
    by nlihc_id Bldg_addre;
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
  title3 '** Building_geocode_a: Check for duplicate addresses in projects being added';

  %Dup_check(
    data=Building_geocode_a,
    by=Bldg_address_id,
    id=nlihc_id Proj_name Bldg_addre 
  )

  run;

  title2;
  

  ** Parcel **;

  proc sort data=all_parcels out=all_parcels_sorted nodupkey;
    by ssl nlihc_id;
  run;

  proc sort data=Mar.Address_ssl_xref (where=(not(missing(address_id)))) out=Address_ssl_xref_nodup nodupkey;
    by ssl;
  run;

data Parcel_a;

  merge
    all_parcels_sorted
      (in=in1)
    RealProp.Parcel_base 
      (keep=ssl ui_proptype saledate in_last_ownerpt ownerpt_extractdat_last
       rename=(ui_proptype=Parcel_type saledate=Parcel_owner_date ownerpt_extractdat_last=Parcel_Info_Source_Date)
       in=in_Parcel_base)
    RealProp.Parcel_geo 
      (keep=ssl x_coord y_coord
       rename=(x_coord=Parcel_x y_coord=Parcel_y))
    RealProp.Parcel_base_who_owns
      (keep=ssl Ownername_full Ownercat
       rename=(ownername_full=Parcel_owner_name Ownercat=Parcel_owner_type))
    Address_ssl_xref_nodup (keep=ssl address_id rename=(address_id=parcel_address_id));
  by ssl;
  
  if in1;
  
  if Parcel_x = 0 then Parcel_x = .u;
  if Parcel_y = 0 then Parcel_y = .u;
  
  if not in_Parcel_base then do;
    %warn_put( msg="SSL not found in Parcel_base; will not be saved. " nlihc_id= ssl= )
    delete;
  end;

  format nlihc_id ;
  informat _all_ ;

run;

proc sort data=Parcel_a;
  by nlihc_id ssl;
run;

  data Parcel;
  
    set
      PresCat.Parcel
      Parcel_a;
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

