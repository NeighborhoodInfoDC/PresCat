/**************************************************************************
 Program:  192_Fix_public_hsg_data.sas
 Library:  PresCat
 Project:  Urban-Greater DC
 Author:   P. Tatian
 Created:  09/20/19
 Version:  SAS 9.4
 Environment:  Local Windows session (desktop)
 GitHub issue:  192
 
 Description:  Correct Catalog address and parcel data for public housing.

 Modifications:
**************************************************************************/

%include "L:\SAS\Inc\StdLocal.sas";

** Define libraries **;
%DCData_lib( PresCat )
%DCData_lib( RealProp )
%DCData_lib( MAR )

%let revisions = Update public housing records (GitHub issue #192).;

%let Update_dtm = %sysfunc( datetime() );


***********************************************************************************
** Update project name for NL000387 to "CAPITOL QUARTER I & II (public housing)" **;

data Project_category;

  set Prescat.Project_category;
  
  if nlihc_id = 'NL000387' then proj_name = "Capitol Quarter I & II (public housing)";
  
run;

%Finalize_data_set( 
  /** Finalize data set parameters **/
  data=Project_category,
  out=Project_category,
  outlib=PresCat,
  label="Preservation Catalog, Project category",
  sortby=nlihc_id,
  archive=Y,
  /** Metadata parameters **/
  revisions=%str(&revisions),
  /** File info parameters **/
  contents=Y,
  printobs=0,
  freqvars=,
  stats=
)

%Data_to_format(
  FmtLib=work,
  FmtName=$nlihcid_to_projname,
  Data=Project_category,
  Value=nlihc_id,
  Label=proj_name,
  OtherLabel=,
  Print=N,
  Contents=N
)


***********************************************************************************
** Create updated parcel data set **;

** Read in parcel corrections **;

filename fimport "&_dcdata_default_path\PresCat\Raw\Dev\Public_hsg_parcels_notincat_corr.csv" lrecl=1000;

proc import out=Notincat_corr
    datafile=fimport
    dbms=csv replace;
  datarow=2;
  getnames=yes;
  guessingrows=max;
run;

filename fimport clear;

proc sort data=Notincat_corr;
  by ssl;
run;

%File_info( data=Notincat_corr, printobs=0, stats=, freqvars=nlihc_id )

filename fimport "&_dcdata_default_path\PresCat\Raw\Dev\Public_hsg_parcels_notincat_oth_corr.csv" lrecl=1000;

proc import out=Notincat_oth_corr
    datafile=fimport
    dbms=csv replace;
  datarow=2;
  getnames=yes;
  guessingrows=max;
run;

filename fimport clear;

%File_info( data=Notincat_oth_corr, printobs=0, stats=, freqvars=nlihc_id )

data Parcel_add;

  set
    Notincat_corr
    Notincat_oth_corr;
  by ssl;
  
  where nlihc_id =: "NL";

  informat _all_ ;
  format _all_ ;
  
  keep ssl nlihc_id;
  
run;

%Dup_check(
  data=Parcel_add,
  by=ssl,
  id=nlihc_id
)

proc summary data=Mar.Address_ssl_xref nway;
  class ssl;
  var address_id;
  output out=ssl_addressid (drop=_type_ _freq_) min=;
run;

data Parcel_add_wchar;

  merge
    Parcel_add 
      (in=in_Parcel)
    RealProp.Parcel_base 
      (keep=ssl ui_proptype saledate in_last_ownerpt ownerpt_extractdat_last
       in=in_Parcel_base)
    RealProp.Parcel_geo 
      (keep=ssl x_coord y_coord)
    RealProp.Parcel_base_who_owns
      (keep=ssl Ownername_full Ownercat)
    ssl_addressid
      (keep=ssl address_id);
  by ssl;
  
  if in_Parcel;
  
  ** Remove duplicate SSL record **;
  if nlihc_id = 'NL000174' and address_id = 156176 then delete; 
  
  if x_coord = 0 then x_coord = .u;
  if y_coord = 0 then y_coord = .u;
  
  if not in_Parcel_base then do;
    %warn_put( msg="SSL not found in Parcel_base; will not be saved. " nlihc_id= ssl= )
    delete;
  end;
  
  informat _all_ ;

  label
    address_id = "Parcel MAR address ID"
    NLIHC_ID = "Preservation Catalog project ID";

  rename 
    ui_proptype=Parcel_type ownername_full=Parcel_owner_name saledate=Parcel_owner_date 
    ownerpt_extractdat_last=Parcel_Info_Source_Date
    address_id=Parcel_address_id
    x_coord=Parcel_x y_coord=Parcel_y Ownercat=Parcel_owner_type;
  
run;

title2 '--Parcel_add_wchar--';
%Dup_check(
  data=Parcel_add_wchar,
  by=nlihc_id ssl,
  id=in_last_ownerpt Parcel_x parcel_owner_name parcel_address_id parcel_type
)
title2;
    
proc sort data=Parcel_add_wchar;
  by nlihc_id ssl;
run;

data Parcel Parcel_del;

  set
    PresCat.Parcel
    Parcel_add_wchar;
  by nlihc_id ssl;

  ** Remove non-public housing parcels: 
  ** output to separate data set to use for deleting corresponding addresses;
  
  if nlihc_id = 'NL000387' and upcase( Parcel_owner_name ) ~= 'DISTRICT OF COLUMBIA HOUSING AUTHORITY' 
    then output Parcel_del;
  else if nlihc_id = 'NL000121' and compbl( ssl ) = '5422 0017' then output Parcel_del;
  else if nlihc_id = 'NL000353' and compbl( ssl ) = '5058 0008' then output Parcel_del;
  else output Parcel;
  
run;

%Finalize_data_set( 
  /** Finalize data set parameters **/
  data=Parcel,
  out=Parcel,
  outlib=PresCat,
  label="Preservation Catalog, Real property parcels",
  sortby=nlihc_id ssl,
  archive=Y,
  /** Metadata parameters **/
  restrictions=None,
  revisions=%str(&revisions),
  /** File info parameters **/
  printobs=0,
  freqvars=Parcel_type Parcel_owner_type
)

** Check for duplicate obs **;

title2 '--Parcel--';
%Dup_check(
  data=Parcel,
  by=nlihc_id ssl,
  id=parcel_owner_name parcel_address_id parcel_type
)
title2;

proc compare base=PresCat.Parcel compare=Parcel maxprint=(40,32000) listvar;
  id nlihc_id ssl;
run;

title2 '--Verify parcels for selected projects--';

proc print data=Parcel;
  where nlihc_id in ( 'NL000387', 'NL000121', 'NL000353', 'NL000333' );
  by nlihc_id;
  id nlihc_id ssl;
  var parcel_owner_type Parcel_owner_name;
run;

title2;


***********************************************************************************
** Create updated address data sets **;

** Addresses to add **;

proc sql noprint;
  create table Address_add as
  select Parcel.ssl, Parcel.nlihc_id, Mar.* 
  from Parcel_add_wchar as Parcel 
  left join ( 
    select xref.ssl, xref.address_id, pt.address_id, 
      pt.fulladdress as bldg_addre, 
      pt.x as Bldg_x, 
      pt.y as Bldg_y,
      pt.latitude as Bldg_lat,
      pt.longitude as Bldg_lon,
      pt.zip as Bldg_zip,
      pt.anc2012, pt.cluster_tr2000, pt.geo2010, pt.psa2012, pt.ward2012
    from Mar.Address_ssl_xref as xref left join Mar.Address_points_view as pt
    on xref.address_id = pt.address_id
  ) as Mar
  on mar.ssl = Parcel.ssl
  where not missing( address_id )
  order by Nlihc_id, bldg_addre;
quit;

proc sort data=Address_add nodupkey;
  by Nlihc_id bldg_addre;
run;

%File_info( data=Address_add, printobs=10 )

title2 '--Address_add--';

%Dup_check(
  data=Address_add,
  by=nlihc_id address_id,
  id=bldg_addre
)

proc print data=Address_add;
  where bldg_addre = '';
  id nlihc_id ssl;
  var bldg_addre address_id;
run;

title2;

** Export new addresses for geocoding **;

filename fexport "&_dcdata_default_path\PresCat\Raw\Dev\192_Address_add.csv" lrecl=256;

proc export data=Address_add (keep=nlihc_id bldg_addre)
    outfile=fexport
    dbms=csv replace;

run;

filename fexport clear;


***********************************************************************************
***********************************************************************************
  At this point, geocoded 192_Address_add.csv addresses
  in OCTO MAR Geocoder Tool to get DC Atlas and Google
  Streetview links.
***********************************************************************************
***********************************************************************************
  

** Read geocoding results **;

filename fimport "&_dcdata_default_path\PresCat\Raw\Dev\192_Address_add_geocoded1.csv" lrecl=1000;

proc import out=Address_add_geocoded1
    datafile=fimport
    dbms=csv replace;
  datarow=2;
  getnames=yes;
  guessingrows=max;
run;

filename fimport clear;

filename fimport "&_dcdata_default_path\PresCat\Raw\Dev\192_Address_add_geocoded2.csv" lrecl=1000;

proc import out=Address_add_geocoded2
    datafile=fimport
    dbms=csv replace;
  datarow=2;
  getnames=yes;
  guessingrows=max;
run;

filename fimport clear;

%File_info( data=Address_add_geocoded1, printobs=0 )
%File_info( data=Address_add_geocoded2, printobs=0 )

proc sql noprint;
  create table Address_add_w_links as
  select Address_add.*, Links.*
  from
  Address_add (drop=address_id)
  left join
  (
    select coalesce( Geo1.marid, Geo2.address_id ) as address_id, Geo1.nlihc_id, Geo1.bldg_addre,
           Geo2.imageurl, Geo2.imagedir, Geo2.imagename, Geo2.streetviewurl
    from Address_add_geocoded1 as Geo1 left join Address_add_geocoded2 as Geo2
    on Geo1.marid = Geo2.address_id
    where not( missing( Geo1.marid ) )
  ) as Links
  on Address_add.nlihc_id = Links.nlihc_id and Address_add.bldg_addre = Links.bldg_addre
  where not( missing( Address_add.bldg_addre ) )
  order by nlihc_id, bldg_addre;
quit;

%File_info( data=Address_add_w_links, printobs=5 )

** Addresses to remove **;

proc sql noprint;
  create table Address_del as
  select coalesce( Mar.ssl, Parcel.ssl ) as ssl, Parcel.nlihc_id, Mar.address_id
  from Parcel_del as Parcel 
  left join
  Mar.Address_ssl_xref as Mar
  on mar.ssl = Parcel.ssl
  where not missing( address_id )
  order by Nlihc_id, address_id;
quit;

%File_info( data=Address_del, contents=n, stats=, printobs=100 )

%Data_to_format(
  FmtLib=work,
  FmtName=$Address_del,
  Desc=,
  Data=Address_del,
  Value=trim( nlihc_id ) || left( put( address_id, z10. ) ),
  Label='X',
  OtherLabel=' ',
  Print=N,
  Contents=N
  )

** Correct duplicate address IDs **;

data 
  Building_geocode_a 
  Building_geocode_b 
    (drop=bldg_address_id bldg_x bldg_y bldg_lat bldg_lon anc: psa: geo: cluster: ward:);

  set Prescat.Building_geocode;
  
  if ( nlihc_id = 'NL001038' and bldg_address_id = 277581 ) or
     ( nlihc_id = 'NL001044' and bldg_address_id = 253199 ) then 
    output Building_geocode_b;
  else 
    output Building_geocode_a;

run;

%File_info( data=Building_geocode_a, printobs=0 )

%DC_mar_geocode(
  data=Building_geocode_b,
  out=Building_geocode_b_geo,
  staddr=bldg_addre,
  zip=bldg_zip,
  id=nlihc_id,
  keep_geo=address_id latitude longitude anc2012 cluster_tr2000 geo2010 psa2012 ward2012,
  listunmatched=Y
)

proc sort data=Building_geocode_b_geo;
  by nlihc_id bldg_addre;
run;

%File_info( data=Building_geocode_b_geo, printobs=0 )

data Building_geocode;

  set
    Building_geocode_a
    Building_geocode_b_geo
      (drop=m_: _: bldg_addre_std
       rename=(address_id=bldg_address_id x=Bldg_x y=Bldg_y latitude=Bldg_lat longitude=Bldg_lon))
    Address_add_w_links (rename=(address_id=bldg_address_id) in=in_add);
  by nlihc_id bldg_addre;
    
  if put( trim( nlihc_id ) || left( put( bldg_address_id, z10. ) ), $Address_del. ) = 'X' then delete;
  
  %Address_clean( bldg_addre, bldg_addre )
  
  if cluster_tr2000_name = '' then cluster_tr2000_name = left( put( cluster_tr2000, clus00b. ) );
  
  proj_name = left( put( nlihc_id, $nlihcid_to_projname. ) );
  
  if in_add then do;

    Bldg_streetview_url = left( streetviewurl );

    if imagename ~= "" and upcase( imagename ) ~=: "NO_IMAGE_AVAILABLE" then 
      Bldg_image_url = trim( imageurl ) || "/" || trim( left( imagedir ) ) || "/" || imagename;
      
  end;

  drop imagename imageurl imagedir streetviewurl;
  
run;

%Finalize_data_set( 
  /** Finalize data set parameters **/
  data=Building_geocode,
  out=Building_geocode,
  outlib=PresCat,
  label="Preservation Catalog, Building-level geocoding info",
  sortby=nlihc_id bldg_addre,
  archive=Y,
  /** Metadata parameters **/
  restrictions=None,
  revisions=%str(&revisions),
  /** File info parameters **/
  printobs=0,
  freqvars=Ward2012
)

** Check for duplicate obs **;

title2 '--Building_geocode--';
%Dup_check(
  data=Building_geocode,
  by=nlihc_id bldg_address_id,
  id=bldg_addre
)
title2;

proc compare base=PresCat.Building_geocode compare=Building_geocode maxprint=(40,32000) listvar method=relative;
  id nlihc_id bldg_addre;
run;

title2 '-- Verify addresses and unit counts for selected projects --';

proc sql noprint;
  create table Building_geocode_check as
  select Building_geocode.*, Addr.Address_id, Addr.active_res_occupancy_count 
  from Building_geocode 
  left join Mar.Address_points_view as Addr
  on Building_geocode.bldg_address_id = Addr.Address_id
  where nlihc_id in ( 'NL000387', 'NL000121', 'NL000353', 'NL000145', 'NL000146', 'NL000333', 'NL000191', 
                      'NL000193', 'NL000194', 'NL000244', 'NL000245', 'NL000268', 'NL000282', 'NL000419',
                      'NL000121', 'NL000301', 'NL000317', 'NL000387' )
  order by nlihc_id, bldg_addre;
quit;

proc print data=Building_geocode_check;
  by nlihc_id;
  id nlihc_id;
  var bldg_addre bldg_address_id active_res_occupancy_count;
  sum active_res_occupancy_count;
run;

title2;

** Create updated Project_geocode data set **;

%Create_project_geocode( data=Building_geocode, revisions=%str(&revisions), compare=n )

proc compare base=PresCat.Project_geocode compare=Project_geocode maxprint=(400,32000) listvar listall method=relative criterion=0.01;
  id nlihc_id;
run;


***********************************************************************************
** Update Subsidy data set with APSH IDs **;

** Adjustments needed to NL000327 & NL000387. Print original records for reference **;

title2 '-- PresCat.Subsidy --';
proc print data=PresCat.Subsidy;
  where nlihc_id in ( 'NL000327', 'NL000387' );
  by nlihc_id; 
  id nlihc_id subsidy_id;
  var program portfolio units_assist Subsidy_info_source_id;
run;
title2;

** NL000327 has two records in APSH so add a 2nd PH record **;

data Subsidy_a;

  set PresCat.Subsidy;
  
  if nlihc_id = 'NL000327' then do;
  
    if subsidy_id = 1 then do;
      output;
      subsidy_id = 2;
    end;
    else do;
      subsidy_id = subsidy_id + 1;
    end;
    
  end;
  
  output;
  
run;

** Read in HUD PSH ID crosswalk **;

filename fimport "&_dcdata_default_path\PresCat\Raw\Dev\Public_hsg_check_apsh_list.csv" lrecl=1000;

proc import out=Public_hsg_check_apsh_list
    datafile=fimport
    dbms=csv replace;
  datarow=5;
  getnames=no;
  guessingrows=max;
run;

filename fimport clear;

%File_info( data=Public_hsg_check_apsh_list, printobs=10, stats= )

data Public_hsg_check_apsh_list_b;

  set Public_hsg_check_apsh_list;
  
  length Nlihc_id $ 16 Subsidy_info_source_id Subsidy_info_source $ 40 Portfolio $16 Program $ 32;
  
  retain Subsidy_info_source 'HUD/PSH' Subsidy_info_source_date '01jan2018'd Update_dtm &Update_dtm;
  
  Subsidy_info_source_id = left( var1 );
  
  i = 1;
  
  Nlihc_id = left( scan( var9, i, ' ,(' ) );
  
  if Nlihc_id = 'NL000387' then do;
    Subsidy_id = 4;
    Subsidy_active = 1;
    Portfolio = 'PUBHSNG';
    Program = 'PUBHSNG';
  end;
  
  Units_assist = var4;
  
  do while ( Nlihc_id ~= '' );
  
    if Nlihc_id =: 'NL' then output;
    
    i + 1;
    
    Nlihc_id = left( scan( var9, i, ' ,(' ) );
    
  end;
  
  format subsidy_info_source_date mmddyy10. Update_dtm datetime.;
  
  keep Nlihc_id Units_assist Program Portfolio Subsidy_: Update_dtm;
    
run;

proc sort data=Public_hsg_check_apsh_list_b;
  by nlihc_id Subsidy_info_source_id;
run;

** Add subsidy_id values for matching **;

data Public_hsg_check_apsh_list_c;

  merge
    Public_hsg_check_apsh_list_b
    Subsidy_a (where=(portfolio = 'PUBHSNG') keep=nlihc_id subsidy_id portfolio);
  by nlihc_id;
  
run;

%File_info( data=Public_hsg_check_apsh_list_c, printobs=100, stats= )

%Dup_check(
  data=Public_hsg_check_apsh_list_c,
  by=nlihc_id,
  id=subsidy_id Units_assist subsidy_info_source_id
)

data Subsidy_b;

  update
    Subsidy_a
    Public_hsg_check_apsh_list_c;
  by nlihc_id subsidy_id;
  
run;

** Export assisted unit differences for review **;

ods listing close;
ods csvall body="&_dcdata_default_path\PresCat\Raw\Dev\192_Units_assist_compare.csv";

proc compare base=PresCat.Subsidy compare=Subsidy_b noprint 
    out=Units_assist_compare outnoequal outbase outcomp outdif;
  id nlihc_id subsidy_id;
  var units_assist;
run;

proc print data=Units_assist_compare;
  by nlihc_id subsidy_id;
  id nlihc_id subsidy_id;
  var _type_ units_assist;
run;

ods csvall close;
ods listing;


***********************************************************************************
***********************************************************************************
  At this point, conducted manual review of assisted unit count differences. 
  Results in Raw\Dev\192_Units_assist_compare.xlsx.
  Code that follows makes adjustments to unit counts based on review.
***********************************************************************************
***********************************************************************************


** Update subsidy exceptions file **;

title2 '-- Prescat.Subsidy_except --';
proc print data=Prescat.Subsidy_except;
  where nlihc_id in ( 'NL000327', 'NL000387' );
  by nlihc_id; 
  id nlihc_id subsidy_id;
  var program units_assist Subsidy_active;
run;
title2;

** New exception records based on manual review of assisted units **;

data Subsidy_except_new;

  set Subsidy_b (keep=nlihc_id subsidy_id program);
  
  where program = 'PUBHSNG';
  
  length Except_init $ 8;
  
  retain Except_init 'PAT' Except_date %sysfunc( today() );
  
  select ( nlihc_id );
    when ( 'NL000058' ) units_assist = 60;
    when ( 'NL000121' ) units_assist = 149;
    when ( 'NL000145' ) units_assist = 235;
    when ( 'NL000146' ) units_assist = 215;
    when ( 'NL000154' ) units_assist = 124;
    when ( 'NL000193' ) units_assist = 440;
    when ( 'NL000194' ) units_assist = 20;
    when ( 'NL000244' ) units_assist = 208;
    when ( 'NL000245' ) units_assist = 144;
    when ( 'NL000282' ) units_assist = 133;
    when ( 'NL000317' ) units_assist = 12;
    when ( 'NL000333' ) units_assist = 234;
    when ( 'NL000419' ) units_assist = 114;
    otherwise
      delete;
  end;
  
  format Except_date mmddyy10.;
  
  drop program;
  
run;

%File_info( data=Subsidy_except_new, stats=, printobs=100 )

data Subsidy_except;

  set 
    Prescat.Subsidy_except (where=(not( missing( nlihc_id ) or missing( subsidy_id ) ) ) )
    Subsidy_except_new;
  by nlihc_id subsidy_id except_date;
  
  ** Adjust prior exception records **;
  
  if nlihc_id = 'NL000327' and subsidy_id = 4 then subsidy_id = 5;
  
run;

data Subsidy;

  update
    Subsidy_b
    Subsidy_except (where=(Except_date=today()));
  by Nlihc_id Subsidy_id;

  drop Except_: ;
  
run;

%Finalize_data_set( 
  /** Finalize data set parameters **/
  data=Subsidy,
  out=Subsidy,
  outlib=PresCat,
  label="Preservation Catalog, Project subsidies",
  sortby=nlihc_id Subsidy_id,
  archive=Y,
  /** Metadata parameters **/
  restrictions=None,
  revisions=%str(&revisions),
  /** File info parameters **/
  printobs=0,
  freqvars=
)

title2 '-- Subsidy (updated) --';
proc print data=Subsidy;
  where nlihc_id in ( 'NL000327', 'NL000387' );
  by nlihc_id; 
  id nlihc_id subsidy_id;
  var program portfolio units_assist Subsidy_info_source_id;
run;

%Dup_check(
  data=Subsidy,
  by=nlihc_id subsidy_id,
  id=program units_assist update_dtm,
  out=_dup_check,
  listdups=Y,
  count=dup_check_count,
  quiet=N,
  debug=N
)
title2;

proc compare base=PresCat.Subsidy compare=Subsidy maxprint=(400,32000) listvar listall;
  id nlihc_id subsidy_id;
run;

%Finalize_data_set( 
  /** Finalize data set parameters **/
  data=Subsidy_except,
  out=Subsidy_except,
  outlib=PresCat,
  label="Preservation Catalog, Subsidy exception file",
  sortby=nlihc_id Subsidy_id except_date,
  archive=Y,
  /** Metadata parameters **/
  restrictions=None,
  revisions=%str(&revisions),
  /** File info parameters **/
  printobs=0,
  freqvars=
)

proc compare base=PresCat.Subsidy_except compare=Subsidy_except maxprint=(400,32000) listvar listall;
  id nlihc_id subsidy_id except_date;
run;


***********************************************************************************
** Update Project data set **;

%Create_project_subsidy_update( data=Subsidy, out=Project_subsidy_update, project_file=PresCat.Project )

data Project_a;

  update
    PresCat.Project
    Project_subsidy_update;
  by nlihc_id;
  
run;

data Project;

  update
    Project_a
    Project_geocode;
  by nlihc_id;
  
  ** Update project unit totals based on manual review **;
  
  select ( nlihc_id );
    when ( 'NL000387' ) proj_units_tot = 91;
    when ( 'NL000419' ) proj_units_tot = 114;
    otherwise /** DO NOTHING **/;
  end;
  
run;

%Finalize_data_set( 
  /** Finalize data set parameters **/
  data=Project,
  out=Project,
  outlib=PresCat,
  label="Preservation Catalog, Projects",
  sortby=nlihc_id,
  archive=Y,
  /** Metadata parameters **/
  restrictions=None,
  revisions=%str(&revisions),
  /** File info parameters **/
  printobs=0,
  freqvars=
)

proc compare base=PresCat.Project compare=Project maxprint=(400,32000) listvar listall;
  id nlihc_id;
run;

