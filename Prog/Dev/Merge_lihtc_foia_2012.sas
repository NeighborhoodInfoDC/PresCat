/**************************************************************************
 Program:  Merge_lihtc_foia_2012.sas
 Library:  PresCat
 Project:  NeighborhoodInfo DC
 Author:   P. Tatian
 Created:  12/28/16
 Version:  SAS 9.2
 Environment:  Local Windows session (desktop)
 
 Description:  Final merge of DHCD LIHTC FOIA (11/9/12) with
Preservation Catalog.

 Modifications:
**************************************************************************/

%include "L:\SAS\Inc\StdLocal.sas";

** Define libraries **;
%DCData_lib( PresCat )

%DCData_lib( DHCD )
%DCData_lib( RealProp )


** Edits to DHCD LIHTC data **;

data Lihtc_foia_11_09_12;

  set dhcd.Lihtc_foia_11_09_12;
  
  ** Remove extraneous geo matches from LIHTC FOIA data **;

  if scan( address_std, 1 ) ~= scan( m_addr, 1 ) then _score_ = .n;
  
  if _score_ >= 45;
  
  ** Combine dhcd_project_id 29 and 30 (same project) **;

  if dhcd_project_id = 30 then dhcd_project_id = 29;
  
run;


** Identify tax credit projects in Catalog **;

proc sort data=PresCat.Subsidy out=Subsidy_lihtc nodupkey;
  where portfolio = 'LIHTC';
  by nlihc_id;

%Data_to_format(
  FmtLib=work,
  FmtName=$Lihtc_sel,
  Desc=,
  Data=Subsidy_lihtc,
  Value=nlihc_id,
  Label='1',
  OtherLabel='0',
  DefaultLen=.,
  MaxLen=.,
  MinLen=.,
  Print=N,
  Contents=N
  )


*************************************************************************
Calculate corrected compliance dates
  From Risha Williams, DCHFA: 
  The "Placed is Service Date" + "15 Years" = the "Compliance Period"
  The "Compliance Period End Date" + 15 Years = the "Extended Use Period"
  (a) Take lastest seg_placed_in_service date for each 
      dhcd_project_id, address_id
  (b) Take earliest date from (a) for each dhcd_project_id
  (c) Add 15 years to (b) to get initial compliance period end,
      add 30 years to (b) to get extended compliance end
************************************************************************;

proc summary data=Lihtc_foia_11_09_12 nway;
  class dhcd_project_id address_id;
  var seg_placed_in_service;
  output out=Lihtc_a max=;
run;

proc summary data=Lihtc_a nway;
  class dhcd_project_id;
  var seg_placed_in_service;
  output out=Lihtc_pis (drop=_freq_ _type_) min=rev_proj_placed_in_service;
run;


** Merge compliance dates with unique project and SSL combos **;

proc sort data=Lihtc_foia_11_09_12 (drop=_:) out=lihtc_proj_ssl nodupkey;
  by dhcd_project_id ssl;
run;

data Lihtc;

  merge
    Lihtc_proj_ssl
    Lihtc_pis;
  by dhcd_project_id;
  
  rev_proj_initial_expiration = intnx( 'year', rev_proj_placed_in_service, 15, 'same' );
  rev_proj_extended_expiration = intnx( 'year', rev_proj_placed_in_service, 30, 'same' );

  format rev_proj_placed_in_service rev_proj_initial_expiration rev_proj_extended_expiration mmddyy10.;
  
  label
    rev_proj_placed_in_service = 'Project placed in service date (NIDC revised)'
    rev_proj_initial_expiration = 'Project initial compliance expiration date (NIDC revised)'
    rev_proj_extended_expiration = 'Project extended compliance expiration date (NIDC revised)';
  
  drop proj_initial_expiration proj_extended_expiration dhcd_seg_id seg_placed_in_service;
  
run;


** Match LIHTC projects to Catalog by parcel **;

proc sql noprint;
  create table lihtc_parcel as
  select 
    coalesce( parcel.ssl, lihtc.ssl ) as ssl, lihtc.dhcd_project_id, parcel.nlihc_id, 
    input( put(nlihc_id, $lihtc_sel.), 8. ) as cat_lihtc_proj, 
    not( missing( parcel.nlihc_id ) ) as in_cat, not( missing( lihtc.dhcd_project_id ) ) as in_dhcd 
    from lihtc as lihtc 
    full join PresCat.Parcel as parcel
    on lihtc.ssl = parcel.ssl
  ;
quit;


** Manual corrections to matching **;

data lihtc_parcel;

  set lihtc_parcel;

  select ( nlihc_id );
    when ( 'NL000237' )
      dhcd_project_id = 10;
    when ( 'NL001019' )
      delete;
    when ( 'NL000041' )
      dhcd_project_id = 4;
    when ( 'NL000061' )
      dhcd_project_id = 9;
    when ( 'NL000123' )
      dhcd_project_id = 2;
    when ( 'NL000153' )
      dhcd_project_id = 57;
    when ( 'NL000154' )
      dhcd_project_id = 38;
    when ( 'NL000176' )
      dhcd_project_id = 106;
    when ( 'NL000180' )
      dhcd_project_id = 105;
    when ( 'NL000335' )
      dhcd_project_id = 27;
    when ( 'NL000384' )
      dhcd_project_id = 79;
    when ( 'NL000388' )
      dhcd_project_id = 74;
    when ( 'NL000413' )
      dhcd_project_id = 33;
    otherwise
      /** DO NOTHING **/;
  end;
  
  if not missing( dhcd_project_id ) then in_dhcd = 1;

run;


** Add LIHTC project details to matched data **;

proc sql noprint;
  create table lihtc_parcel_b as
  select 
    coalesce( lihtc_parcel.dhcd_project_id, lihtc.dhcd_project_id ) as dhcd_project_id, lihtc_parcel.*, lihtc.* 
    from lihtc_parcel
    left join lihtc
    on lihtc_parcel.dhcd_project_id = lihtc.dhcd_project_id
	order by lihtc_parcel.dhcd_project_id, lihtc_parcel.nlihc_id
  ;
quit;


** Merge LIHTC/Cat match with Catalog Subsidy and Project data **;

proc sql noprint;
  create table A as
  select
    coalesce( project_parcel.nlihc_id, subsidy.nlihc_id ) as nlihc_id, project_parcel.*, 
    subsidy.poa_start, subsidy.poa_end, subsidy.units_assist from
    ( select 
        coalesce( project.nlihc_id, lihtc_parcel.nlihc_id ) as nlihc_id, lihtc_parcel.*, 
        project.proj_name from 
      lihtc_parcel_b as lihtc_parcel
      left join PresCat.project as project
      on project.nlihc_id = lihtc_parcel.nlihc_id
    ) as project_parcel
    left join PresCat.Subsidy (where=(portfolio = 'LIHTC')) as subsidy
    on project_parcel.nlihc_id = subsidy.nlihc_id
  order by ssl
;
quit;


** Count different match types **;

proc sort data=A out=A_nodup nodupkey;
  by nlihc_id dhcd_project_id;
run;

proc summary data=A_nodup nway;
  where not missing( nlihc_id );
  class nlihc_id;
  var in_dhcd;
  output out=A_nlihcid (drop=_freq_ _type_) sum=dhcd_count;
run;

proc summary data=A_nodup nway;
  where not missing( dhcd_project_id );
  class dhcd_project_id;
  var in_cat;
  output out=A_dhcd (drop=_freq_ _type_) sum=cat_count;
run;

proc sql noprint;
  create table Merge_lihtc_foia_2012 as 
  select AA.*, A_dhcd.* from
  ( select A.*, A_nlihcid.* from
    A left join A_nlihcid 
    on A.nlihc_id = A_nlihcid.nlihc_id
  ) as AA
  left join A_dhcd
  on AA.dhcd_project_id = A_dhcd.dhcd_project_id
  order by nlihc_id, dhcd_project_id, ssl
;
quit;


** A) Single matching nlihc_id LIHTC project and dhcd_project_id (1:1) **;

%let Update_dtm = %sysfunc( datetime() );

proc sort data=Merge_lihtc_foia_2012 out=Merge_lihtc_foia_2012_a nodupkey;
  where not( missing( nlihc_id ) or missing( dhcd_project_id ) ) and cat_count = 1 and dhcd_count = 1 and cat_lihtc_proj = 1;
  by nlihc_id dhcd_project_id;
run;

data Update_a;

  merge 
    PresCat.Subsidy 
      (where=(portfolio = 'LIHTC'))
    PresCat.Project
      (keep=nlihc_id proj_name proj_units_tot)
    Merge_lihtc_foia_2012_a
      (keep=nlihc_id dhcd_project_id cat_count dhcd_count cat_lihtc_proj rev_proj_: proj_lihtc_units
       in=inFoia);
  by nlihc_id;
  
  if inFoia;
  
run;

%Dup_check(
  data=Update_a,
  by=nlihc_id,
  id=subsidy_id POA_start rev_proj_placed_in_service POA_end rev_proj_initial_expiration rev_proj_extended_expiration Units_Assist proj_lihtc_units,
  out=_dup_check,
  listdups=Y,
  count=dup_check_count,
  quiet=N,
  debug=N
)

proc print data=Update_a label;
  where abs( poa_start - rev_proj_placed_in_service ) > 365 or abs( units_assist - proj_lihtc_units ) > 0;
  id nlihc_id proj_name subsidy_id;
  var POA_start rev_proj_placed_in_service proj_units_tot Units_Assist proj_lihtc_units;
  title2 'A) Nonmatching compliance start dates or assisted unit counts';
  label
    POA_start = 'Placed in service (CATALOG)'
    rev_proj_placed_in_service = 'Placed in service (DHCD)'
    proj_units_tot = 'Total project units (CATALOG)'
    Units_Assist = 'LIHTC units (CATALOG)'
    proj_lihtc_units = 'LIHTC units (DHCD)';
run;

title2;


** B) Single matching nlihc_id non-LIHTC project and dhcd_project_id (1:1) **;

proc sort data=Merge_lihtc_foia_2012 out=Merge_lihtc_foia_2012_b nodupkey;
  where not( missing( nlihc_id ) or missing( dhcd_project_id ) ) and cat_count = 1 and dhcd_count = 1 and cat_lihtc_proj = 0;
  by nlihc_id dhcd_project_id;
run;

data Update_b;

  merge 
    PresCat.Subsidy
    Merge_lihtc_foia_2012_b
      (keep=nlihc_id dhcd_project_id cat_count dhcd_count cat_lihtc_proj rev_proj_: proj_lihtc_units
       in=inFoia);
  by nlihc_id;
  
  if inFoia;
  
  if last.nlihc_id then do;
  
    subsidy_id = subsidy_id + 1;
    
    agency = '';
    contract_number = '';
    poa_end_actual = .n;
    poa_end_prev = .n;
    poa_start_orig = rev_proj_placed_in_service;
    portfolio = 'LIHTC';
    program = 'LIHTC';
    rent_to_fmr_description = '';
    subsidy_active = 1;
	subsidy_info_source = '';
	subsidy_info_source_date = .n;
	subsidy_info_source_id = '';
	subsidy_info_source_property = '';
    
    output;
    
  end;

run;



** Update Subsidy file with new records **;

data Update_all;

  set
    Update_a
    Update_b;
  by nlihc_id subsidy_id;

  if not missing( rev_proj_initial_expiration ) then compl_end = rev_proj_initial_expiration;
  if not missing( rev_proj_extended_expiration ) then poa_end = rev_proj_extended_expiration;
  if not missing( rev_proj_placed_in_service ) then poa_start = rev_proj_placed_in_service;
  if not missing( proj_lihtc_units ) then units_assist = proj_lihtc_units;
  Update_Dtm = &Update_Dtm;

  Except_date = today();

  length Except_init $ 8;
  Except_init = 'PAT';

  keep agency compl_end contract_number nlihc_id poa_end
poa_end_actual poa_end_prev poa_start poa_start_orig
portfolio program rent_to_fmr_description subsidy_active
subsidy_id subsidy_info_source subsidy_info_source_date
subsidy_info_source_id subsidy_info_source_property
units_assist update_dtm Except_: dhcd_project_id;

run;


** Update Subsidy records **;

data Subsidy;

  update 
    PresCat.Subsidy
	Update_all (drop=Except_: dhcd_project_id)
    updatemode=nomissingcheck;
  by nlihc_id subsidy_id;

run;

proc compare base=PresCat.Subsidy compare=Subsidy listall maxprint=(400,32000);
  id nlihc_id subsidy_id;
  title2 'Update Subsidy records: results';
run;
title2;


** Add new info to Subsidy_except to prevent overwriting by HUD data updates **;

data Subsidy_except;

  update 
    PresCat.Subsidy_except
	Update_all (keep=nlihc_id subsidy_id poa_start compl_end poa_end units_assist Except_:);
  by nlihc_id subsidy_id;

run;


** Import geocoded building addresses from MAR Geocoder **;

filename fimport "&_dcdata_r_path\PresCat\Raw\Lihtc_foia_2012_geocode main.csv" lrecl=2000;

proc import out=Geocode_main
    datafile=fimport
    dbms=csv replace;
  datarow=2;
  getnames=yes;
  guessingrows=1000;

run;

filename fimport clear;

filename fimport "&_dcdata_r_path\PresCat\Raw\Lihtc_foia_2012_geocode mar_address.csv" lrecl=2000;

proc import out=Geocode_mar_address
    datafile=fimport
    dbms=csv replace;
  datarow=2;
  getnames=yes;
  guessingrows=1000;

run;

filename fimport clear;

proc sort data=Geocode_main;
  by marid;
  
proc sort data=Geocode_mar_address nodupkey;
  by address_id;
  
data Lihtc_foia_2012_geocode;

  merge 
    Geocode_main (rename=(marid=address_id ssl=ssl1) in=in1) 
    Geocode_mar_address;
  by address_id;
  
  if in1;
  
  format _all_ ;
  informat _all_ ;
  
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
  
  Zip = put( MAR_ZIPCODE, z5.0 );
  
  format Zip $zipa.;

  ** Cluster names **;
  
  Cluster_tr2000_name = put( Cluster_tr2000, $clus00b. );
  
  ** Image url **
  
  length Image_url $ 255;
  
  if imagename ~= "" and imagename ~=: "No_Image_Available" then 
    Image_url = trim( imageurl ) || "/" || trim( imagedir ) || "/" || imagename;
    
  rename Streetviewurl=Streetview_url;
  
  ** Reformat addresses **;
  
  %address_clean( MAR_MATCHADDRESS, MAR_MATCHADDRESS );

  ** Check SSL against earlier geocode **;

  if compbl( ssl1 ) ~= compbl( ssl ) then do;
    %warn_put( msg="SSLs not the same. " _n_= ssl1= ssl= dhcd_project_id= dhcd_seg_id= address_std= mar_matchaddress= )
  end;
  
  drop ssl1;

run;


** Update Building_geocode **;

proc sort data=Update_all out=Dhcd_project_id_to_nlihc_id nodupkey;
  by nlihc_id dhcd_project_id;
run;

%Data_to_format(
  FmtLib=work,
  FmtName=dhcd_project_id_to_nlihc_id,
  Desc=,
  Data=Dhcd_project_id_to_nlihc_id,
  Value=dhcd_project_id,
  Label=nlihc_id,
  OtherLabel=' ',
  Print=N
)

%Data_to_format(
  FmtLib=work,
  FmtName=$Update_nlihc_id_list,
  Desc=,
  Data=Dhcd_project_id_to_nlihc_id,
  Value=nlihc_id,
  Label=nlihc_id,
  OtherLabel=' ',
  Print=N
)

data Lihtc_foia_2012_geocode_nlihc_id;

  set Lihtc_foia_2012_geocode;

  Nlihc_id = put( dhcd_project_id, dhcd_project_id_to_nlihc_id. );
  
  if missing( Nlihc_id ) then delete;
  
run;

proc sort data=Lihtc_foia_2012_geocode_nlihc_id nodupkey;
  by nlihc_id address_id;
run;

proc sort data=Lihtc_foia_2012_geocode_nlihc_id;
  by nlihc_id address_std;
run;

%let MAX_PROJ_ADDRE = 3;   /** Maximum number of addresses to include in Proj_addre field in PresCat.Project_geo **/

%let geo_vars = Ward2012 Anc2012 Psa2012 Geo2010 Cluster_tr2000 Cluster_tr2000_name Zip;

data
  Project_geocode_update 
    (keep=nlihc_id &geo_vars Proj_address_id Proj_x Proj_y Proj_lat Proj_lon 
          Proj_addre Proj_zip Proj_image_url Proj_Streetview_url Bldg_count)
  Building_geocode_update
    (keep=nlihc_id &geo_vars address_id Bldg_x Bldg_y Bldg_lat Bldg_lon Bldg_addre Zip
          image_url Streetview_url ssl_std
     rename=(address_id=Bldg_address_id Zip=Bldg_zip image_url=Bldg_image_url Streetview_url=Bldg_streetview_url
             ssl_std=Ssl));

  length Nlihc_id $ 16;

  set Lihtc_foia_2012_geocode_nlihc_id;
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
  
  output Building_geocode_update;
  
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
    
    output Project_geocode_update;
    
  end;
  
  label
    Ward2012x = "Ward (2012)"
    Ssl_std = "Property identification number (square/suffix/lot)"
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

title4 '**** SHOULD NOT BE ANY DUPLICATES REPORTED ****';

%Dup_check(
  data=Building_geocode_update,
  by=nlihc_id Bldg_address_id,
  id=Bldg_addre
)

%Dup_check(
  data=Project_geocode_update,
  by=nlihc_id,
  id=Proj_addre 
)
 
run;
title2;


** Update Building_geocode **;

data Building_geocode;

  set 
    PresCat.Building_geocode
      (where=(put(nlihc_id,$Update_nlihc_id_list.)=' ') drop=proj_name)
    Building_geocode_update;
  by Nlihc_id Bldg_addre;

run;

proc compare base=PresCat.Building_geocode compare=Building_geocode listall maxprint=(400,32000);
  id Nlihc_id Bldg_addre;
run;


** Update Project_geocode **;

data Project_geocode;

  set 
    PresCat.Project_geocode
      (where=(put(nlihc_id,$Update_nlihc_id_list.)=' ') drop=proj_name)
    Project_geocode_update;
  by Nlihc_id;

run;

proc compare base=PresCat.Project_geocode compare=Project_geocode listall maxprint=(400,32000);
  id Nlihc_id;
run;
