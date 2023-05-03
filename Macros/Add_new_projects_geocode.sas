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
  input_path=,  /** Location of input files **/
  address_data_edits=, /** Address data manual edits **/
  parcel_data_edits= /** Parcel data manual edits **/
  );

  %local geo_vars a_obs_count;
  
  ** Import geocoded project data **;

  ** Main sheet info **;

  filename fimport "&input_path\&input_file_pre..csv" lrecl=2000;

  proc import out=New_Proj_projects
      datafile=fimport
      dbms=csv replace;
    datarow=2;
    getnames=yes;
    guessingrows=500;

  run;

  filename fimport clear;
  
  ** Convert ZIP code to char var for geocoding **;
  
  data New_Proj_projects;
  
    set New_Proj_projects;
    where id > 0;
    
    length Bldg_zip_char $ 5;
    
    Bldg_zip_char = left( put( Bldg_zip, z5.0 ) );
    
    rename Bldg_zip_char=Bldg_zip;
    drop Bldg_zip;
    
    ** Remove unnecessary formats and informats **;
    format _all_ ;
    informat _all_ ;

  run;

  title2 '********************************************************************************************';
  title3 "** Rows in &input_path\&input_file_pre..csv with duplicate values of ID.";
  title4 '** Each project should have a unique value of ID. Fix in input data.';

  %Dup_check(
    data=New_Proj_projects,
    by=id,
    id=proj_name Bldg_addre
  )

  title2;

  title2 '********************************************************************************************';
  title3 "** New project data read from &input_path\&input_file_pre..csv";

  proc print data=New_Proj_projects noobs n;
    id id;
  run;
  
  title2;

  ** Geocode new project addresses **;

  %DC_mar_geocode(
    geo_match=Y,
    data=New_Proj_projects,
    out=New_Proj_projects_geocode,
    staddr=Bldg_addre,
    zip=Bldg_zip,
    id=ID,
	keep_geo=address_id anc2012 latitude longitude cluster2017 cluster_tr2000 
	         geo2010 geo2020 geobg2020 geoblk2020 ward2012 ward2022,
    ds_label=,
    match_score_min=71,            /** Minimum score for a match **/
    listunmatched=Y
  )

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

  proc sort data = New_Proj_projects_geocode;
    by id;
    run;

  data New_Proj_projects_geocode;
    set New_Proj_projects_geocode;
    by id;
    firstproj = first.id;
    run;

  *** Current format of nlihc_id is $16. Test with the new format***;
  data New_Proj_projects_geoc_nlihc_id;
    retain proj_name nlihc_id;
    set Nlihc_id New_Proj_projects_geocode;
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
  Data=New_Proj_projects_geoc_nlihc_id,
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
      select distinct New.nlihc_id, New.Proj_name, New.Bldg_addre, coalesce( New.address_id, xref.address_id ) as address_id, xref.lot_type, xref.ssl as xref_ssl from 
  	  New_Proj_projects_geoc_nlihc_id as New left join
  	  Mar.Address_ssl_xref as xref
  	  on New.address_id = xref.address_id
  	  where New.M_exactmatch
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
  
  proc sql noprint;
    select count( nlihc_id ) into :a_obs_count separated by ' ' from A;
  quit;
  
  %if &a_obs_count = 0 %then %do;
    %err_mput( macro=Add_new_project_geocode, msg=No valid street addresses in geocoded data. )
    %let _macro_fatal_error = 1;
    %goto exit_macro;
  %end;

  ** Create project and building geocode data sets for new projects **;

  %let geo_vars = Anc2012 Cluster2017 Cluster_tr2000 Cluster_tr2000_name Geo2010  
                  Geo2020 GeoBg2020 GeoBlk2020 Psa2012 ssl Ward2012 Ward2022;

  proc sort data=all_addresses nodupkey;
    by address_id nlihc_id;
  run;

  proc sort data=New_Proj_projects_geoc_nlihc_id out=New_proj_geocode_addr_srt;
    by address_id;
  run;

  data 
    work.Building_geocode_a
      (keep=nlihc_id address_id Proj_Name &geo_vars Bldg_x Bldg_y Bldg_lat Bldg_lon Bldg_addre bldg_zip
            bldg_units_mar ssl
       rename=(address_id=Bldg_address_id));
      
    merge 
      all_addresses (in=in1)
      Mar.Address_points_view 
       (rename=(
          fulladdress=bldg_addre latitude=bldg_lat longitude=bldg_lon active_res_occupancy_count=bldg_units_mar
		  x=bldg_x y=bldg_y zip=bldg_zip 
          ))
    ;
    by address_id;

    if in1;
    
    ** Address manual edits **;
    
    &Address_data_edits;

    length Proj_name $ 80;

    Proj_name = left( put( nlihc_id, $nlihc_id_to_proj_name. ) );

    ** Cluster names **;
    
    length Cluster_tr2000_name $ 120;
	    
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
      in_catalog = 0;
      output;
    end;
    else if _hold_bldg_address_id = bldg_address_id then do;
      %warn_put( macro=Add_new_projects_geocode, 
                 msg="Possible existing Catalog project. " bldg_address_id= 
                     " See output for details." )
      in_catalog = 1;
      output;
    end;
    else do;
      _hold_bldg_address_id = .a;
    end;
    
    format in_catalog dyesno.;

    drop _hold_bldg_address_id;

  run;

  title2 '********************************************************************************************';
  title3 '** Addresses in new projects that match existing Catalog projects OR';
  title4 '** New projects with common addresses';
  title4 '** Check to make sure these projects are not already in Catalog or dedulicate in input data';

  %Dup_check(
    data=Building_geocode_comp_rpt,
    by=bldg_address_id,
    id=nlihc_id in_catalog proj_name bldg_addre,
    out=_dup_check,
    listdups=Y,
    quiet=Y
  )

  title2; 

  **remove projects from geocode datasets that are no longer in project dataset**;

  proc sql;

     create table project_geocode_b as
     select *
     from prescat.project_geocode
     where nlihc_id in (select distinct nlihc_id from prescat.project)
     ;

  quit;

  proc sql;

     create table building_geocode_b as
     select *
     from prescat.building_geocode
     where nlihc_id in (select distinct nlihc_id from prescat.project)
     ;

  quit;

  title2 '********************************************************************************************';
  title3 '** 1/ Check to see if any projects were removed in previous step';

  proc compare base=prescat.project_geocode compare=work.project_geocode_b listbaseobs nosummary;
    id nlihc_id;
  run;

  title2 '********************************************************************************************';
  title3 '** 2/ Check to see if any buildings were removed in previous step';

  proc compare base=prescat.building_geocode compare=work.building_geocode_b listbaseobs nosummary;
    id nlihc_id Bldg_addre;
  run;

  title2;

  ** merge new geocode files onto existing geocode files**;
  
  proc sort data=Building_geocode_a;
    by nlihc_id Bldg_addre;
  run;

  data Building_geocode;
    length Cluster_tr2000_name $ 120;
    set Building_geocode_b Building_geocode_a;
    by nlihc_id Bldg_addre;
    
  run;

  title2 '********************************************************************************************';
  title3 '** 3/ Check for changes in the new Building geocode file that are not related to the new projects';

  proc compare base=prescat.building_geocode compare=work.building_geocode nosummary listbasevar listcompvar maxprint=(40,32000);
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
    var bldg_units_mar bldg_addre;
  run;
  
  title2 'Project_geocode: New records';

  proc print data=Project_geocode n;
    where put( nlihc_id, $New_nlihc_id. ) ~= "";
    id nlihc_id;
    var bldg_count proj_units_mar proj_addre;
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
  
  %Owner_name_clean( Parcel_owner_name, Parcel_owner_name )

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
    
    ** Parcel data manual edits **;
    
    &Parcel_data_edits;
    
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

  title2 '********************************************************************************************';
  title3 '** 4/ Check for changes in the new Parcel file that are not related to the new projects';

  proc compare base=prescat.Parcel compare=Parcel nosummary listbasevar listcompvar maxprint=(40,32000);
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
  
  %exit_macro: 

%mend Add_new_projects_geocode;

/** End Macro Definition **/

