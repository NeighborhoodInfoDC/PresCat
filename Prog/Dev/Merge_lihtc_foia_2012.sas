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

  Multiple matching nlihc_id for same dhcd_project_id
    1) NL000202/Mayfair Mansions was originally parcel 5057 0040, PIS=10/10/1988.
         >> Assign records from dhcd_project_id=1.
       Parcel was later split into parcels 5057 0803 and 5057 0804.
       Parcel 5057 0803 is NL001005/Mayfair Mansions Apartments, PIS=07/09/2009.
         >> Assign records from dhcd_project_id=72 to NL001005.
       Parcel 5057 0804 is not yet in Catalog. HUD.Lihtc_2013_dc lists as HUD_ID=DCB2012802.
         >> Create new project.  >>> SEPARATE PROGRAM
    2) NL000237/Hanover Court (Hartford Knox St Apts) should be dhcd_project_id=10
    3) NL000325
    4) NL000102/Faircliff Plaza West should be only these addresses
        1400 - 1404 EUCLID ST NW
        1424 - 1432 CLIFTON ST NW (ADDED TO DHCD LIST)
    5) NL000273/NL000274/Orchard Park (Southview Apts I)
         >> Combine into one project
         [ADDED 3522 22ND ST SE TO DHCD LIST]
    6) NL000997/NL000998/Stanton Park Apts
         >> Divide addresses between two projects as follows
              _Stanton Gainesville_ [NL000998]
              2606 18th St SE
              1811 Gainesville St SE
              1817 Gainesville St SE
              _Stanton Wagner_ [NL000997]
              2446 Wagner St SE
              2440 Wagner St SE
              2436 Wagner St SE
              2422 Wagner St SE

 Modifications:
**************************************************************************/

%include "L:\SAS\Inc\StdLocal.sas";

** Define libraries **;
%DCData_lib( PresCat )
%DCData_lib( DHCD )
%DCData_lib( RealProp )

%let Update_dtm = %sysfunc( datetime() );


**************************************************************************
  Project names 
**************************************************************************;

%Data_to_format(
  FmtLib=work,
  FmtName=$project_name,
  Data=PresCat.Project,
  Value=nlihc_id,
  Label=proj_name,
  OtherLabel="",
  Print=N,
  Contents=N
  )


**************************************************************************
  Edits to DHCD LIHTC data
**************************************************************************;

data Lihtc_foia_11_09_12;

  set dhcd.Lihtc_foia_11_09_12;

  dhcd_project_id_orig = dhcd_project_id; 
  
  ** Combine dhcd_project_id 29 and 30 (same project: Faircliff Plaza East) **;

  if dhcd_project_id = 30 then dhcd_project_id = 29;

  ** Split projects **;

  select ( dhcd_project_id );
    when ( 44 ) do;
      if ssl = '5755    0137' then dhcd_project_id = 44.1;
      else if ssl =: '5315' then dhcd_project_id = 44.2;
      else if ssl in: ( '5409', '5424', '5426', '5440' ) then dhcd_project_id = 44.3;
      else if ssl in ( '5755    0830', '5778    0163' ) then dhcd_project_id = 44.4;
    end;
    when ( 90 ) do;
      if ssl in: ( '5902', '5910', '5911' ) then dhcd_project_id = 90.1;
      else if ssl in: ( '5901', '5903', '5904', '5907' ) then dhcd_project_id = 90.2;
    end;
    when ( 99 ) do;
      if ssl =: '5734' then dhcd_project_id = 99.1;
      else if ssl =: '5835' then dhcd_project_id = 99.2;
    end;
    otherwise /** DO NOTHING **/;
  end;
  
run;

proc sort data=Lihtc_foia_11_09_12;
  by dhcd_project_id;
run;


**************************************************************************
Calculate corrected compliance dates
  From Risha Williams, DCHFA: 
  The "Placed is Service Date" + "15 Years" = the "Compliance Period"
  The "Compliance Period End Date" + 15 Years = the "Extended Use Period"
  (a) Take lastest seg_placed_in_service date for each 
      dhcd_project_id, address_id
  (b) Take earliest date from (a) for each dhcd_project_id
  (c) Add 15 years to (b) to get initial compliance period end,
      add 30 years to (b) to get extended compliance end
**************************************************************************;

proc summary data=Lihtc_foia_11_09_12 nway;
  class dhcd_project_id address_id;
  var seg_placed_in_service;
  output out=Lihtc_pis_addr max=;
run;

proc summary data=Lihtc_pis_addr nway;
  class dhcd_project_id;
  var seg_placed_in_service;
  output out=Lihtc_pis (drop=_freq_ _type_) min=rev_proj_placed_in_service;
run;

** Merge compliance dates with unique project and SSL combos **;

proc sort data=Lihtc_foia_11_09_12 (drop=_:) out=lihtc_proj_ssl nodupkey;
  by dhcd_project_id ssl;
run;


**************************************************************************
  Match LIHTC projects to Catalog IDs by parcel
**************************************************************************;

proc sql noprint;
  create table lihtc_parcel as
  select 
    coalesce( parcel.ssl, lihtc.ssl ) as ssl, lihtc.dhcd_project_id, lihtc.dhcd_project_id_orig, parcel.nlihc_id, 
    input( put(nlihc_id, $lihtc_sel.), 8. ) as cat_lihtc_proj, 
    not( missing( parcel.nlihc_id ) ) as in_cat, not( missing( lihtc.dhcd_project_id ) ) as in_dhcd 
    from lihtc_proj_ssl as lihtc 
    full join PresCat.Parcel as parcel
    on lihtc.ssl = parcel.ssl
  ;
quit;

** Manual corrections to matching **;

data lihtc_parcel_a;

  set lihtc_parcel;

  ** Manual matches **;

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

  ** Correct multiple/ambiguous matches **;

  select ( dhcd_project_id );
    when ( 1 ) nlihc_id = 'NL000202'; /** Mayfair Mansions (Phase I) **/
    when ( 72 ) nlihc_id = 'NL001005'; /** Mayfair Mansions (Phase II) **/
    when ( 6 ) nlihc_id = 'NL000128'; /** Maplewood Court **/
    when ( 10 ) nlihc_id = 'NL000237'; /** Hanover Court (Hartford Knox St Apts) **/
    when ( 44.1 ) nlihc_id = 'NL000316';  /** W Street Apts **/
    when ( 44.2 ) nlihc_id = 'NL000325';  /** WDC I - A **/
    when ( 44.3 ) nlihc_id = 'NL001034';  /** WDC I - B (new) **/
    when ( 44.4 ) nlihc_id = 'NL001035';  /** WDC I - C (new) **/
    when ( 56 ) nlihc_id = 'NL000273'; /** Orchard Park (Formerly Southview Apts I + II) (merged) **/
    when ( 90.1 ) nlihc_id = 'NL000995'; /** Villages of Parklands - Garden Village Apts **/
    when ( 90.2 ) nlihc_id = 'NL000996'; /** Villages of Parklands - Manor Village Apts **/
    when ( 99.1 ) nlihc_id = 'NL000997'; /** Stanton Wagner **/
    when ( 99.2 ) nlihc_id = 'NL000998'; /** Stanton Gainesville **/
    otherwise /** DO NOTHING **/;
  end;
 
  if not missing( dhcd_project_id ) then in_dhcd = 1;

run;

** Check for non-unique matches **;

proc sort data=Lihtc_parcel_a out=Lihtc_parcel_dupchk nodupkey;
  where not( missing( dhcd_project_id ) or missing( nlihc_id ) );
  by dhcd_project_id nlihc_id;
run;

%Dup_check(
  data=Lihtc_parcel_dupchk,
  by=dhcd_project_id,
  id=nlihc_id,
  out=_dup_check,
  listdups=Y,
  count=dup_check_count,
  quiet=N,
  debug=N
)

** Add NLIHC_ID to DHCD LIHTC data **;

%Data_to_format(
  FmtLib=work,
  FmtName=dhcd_to_nlihc,
  Desc=,
  Data=Lihtc_parcel_dupchk,
  Value=dhcd_project_id,
  Label=nlihc_id,
  OtherLabel=" ",
  DefaultLen=.,
  MaxLen=.,
  MinLen=.,
  Print=Y,
  Contents=N
  )

data Lihtc_foia_nlihc_id;

  length Nlihc_id $ 16;

  merge 
    Lihtc_foia_11_09_12
    Lihtc_pis;
  by dhcd_project_id;

  Nlihc_id = put( dhcd_project_id, dhcd_to_nlihc. );

  rev_proj_initial_expiration = intnx( 'year', rev_proj_placed_in_service, 15, 'same' );
  rev_proj_extended_expiration = intnx( 'year', rev_proj_placed_in_service, 30, 'same' );

  format rev_proj_placed_in_service rev_proj_initial_expiration rev_proj_extended_expiration mmddyy10.;
  
  label
    rev_proj_placed_in_service = 'Project placed in service date (NIDC revised)'
    rev_proj_initial_expiration = 'Project initial compliance expiration date (NIDC revised)'
    rev_proj_extended_expiration = 'Project extended compliance expiration date (NIDC revised)';
  
  drop proj_initial_expiration proj_extended_expiration seg_placed_in_service;
  
run;


**************************************************************************
  Prepare Subsidy update file: 
  Merge project NL000274 with NL000273 (Orchard Park), remove NL001019
  Remove public housing subsidy from NL000325 (actually HCV)
  Remove previously deleted project NL000375.
**************************************************************************;

data Subsidy_lihtc Subsidy_non_lihtc Subsidy_all;

  retain _subsidy_count;

  set PresCat.Subsidy;
  where nlihc_id not in ( 'NL000375', 'NL001019' );
  by nlihc_id subsidy_id;

  if nlihc_id = 'NL000273' and last.subsidy_id then _subsidy_count = subsidy_id;
  else if nlihc_id = 'NL000274' then do;
    _subsidy_count + 1;
    subsidy_id = _subsidy_count;
    nlihc_id = 'NL000273';
  end;
  else if nlihc_id = 'NL000325' then do;
    if subsidy_id = 1 then delete;
    else subsidy_id = subsidy_id - 1;
  end;

  if portfolio = 'LIHTC' then output Subsidy_lihtc;
  else output Subsidy_non_lihtc;

  output Subsidy_all;

  drop _subsidy_count;

run;

proc print data=PresCat.Subsidy;
  where nlihc_id in ( 'NL000273', 'NL000274' );
  id nlihc_id subsidy_id;
  var program units_assist subsidy_info_:; 
  title2 'Orchard Park: Before Merge';
run;

proc print data=Subsidy_all;
  where nlihc_id in ( 'NL000273', 'NL000274' );
  id nlihc_id subsidy_id;
  var program units_assist subsidy_info_:; 
  title2 'Orchard Park: After Merge';
run;

title2;

** Identify tax credit projects in Catalog **;

proc sort data=Subsidy_lihtc out=Subsidy_lihtc_nodup nodupkey;
  by nlihc_id;
run;

%Data_to_format(
  FmtLib=work,
  FmtName=$Lihtc_sel,
  Desc=,
  Data=Subsidy_lihtc_nodup,
  Value=nlihc_id,
  Label='1',
  OtherLabel='0',
  DefaultLen=.,
  MaxLen=.,
  MinLen=.,
  Print=N,
  Contents=N
  )

** Prepare subsidy file update **;

proc sort data=Lihtc_foia_nlihc_id;
  by nlihc_id;
run;

data Subsidy_update Subsidy_new;

  set Lihtc_foia_nlihc_id;
  where nlihc_id ~= '';
  by nlihc_id;

  length 
    subsidy_active 3
    agency $ 80
    contract_number $ 11
    portfolio $ 16
    program $ 32
    rent_to_fmr_description subsidy_info_source subsidy_info_source_id
    subsidy_info_source_property $ 40;

  if first.nlihc_id;

  subsidy_id = 9999;

    agency = '';
    contract_number = '';
    poa_start = rev_proj_placed_in_service;
    poa_start_orig = rev_proj_placed_in_service;
    compl_end = rev_proj_initial_expiration;
    poa_end = rev_proj_extended_expiration;
    poa_end_actual = .n;
    poa_end_prev = .n;
    portfolio = 'LIHTC';
    program = 'LIHTC';
    rent_to_fmr_description = '';
    subsidy_active = 1;
    subsidy_info_source = 'DHCD/FOIA';
    subsidy_info_source_date = '09nov2012'd;
    subsidy_info_source_id = '';
    subsidy_info_source_property = '';
    units_assist = proj_lihtc_units;
    update_dtm = &Update_dtm;

  ** Adjust unit counts **;

  select ( nlihc_id );
    when ( 'NL000316' ) units_assist = 18;
    when ( 'NL000325' ) units_assist = 18;
    when ( 'NL001034' ) units_assist = 111;
    when ( 'NL001035' ) units_assist = 54;
    when ( 'NL000995' ) units_assist = 230;
    when ( 'NL000996' ) units_assist = 347;
    when ( 'NL000997' ) units_assist = 26;
    when ( 'NL000998' ) units_assist = 36;
    otherwise
      /** DO NOTHING **/;
  end;

  if put( nlihc_id, $lihtc_sel. ) = '1' then do;
    output Subsidy_update;
    if nlihc_id = 'NL000273' then output Subsidy_update;  ** Project has 2 LIHTC records **;
  end;
  else output Subsidy_new;

run;

** Update existing LIHTC records with DHCD info **;

data Subsidy_lihtc_a;

  merge
    Subsidy_lihtc 
    Subsidy_update 
      (keep=nlihc_id poa_start poa_start_orig compl_end poa_end:  
            units_assist subsidy_info_source subsidy_info_source_date update_dtm
       rename=(units_assist=_units_assist));
  by nlihc_id;

  if _units_assist > 0 then units_assist = _units_assist;

  drop _units_assist;

run;

** Update projects that had no previous LIHTC records **;

data Subsidy;

  retain _subsidy_id_last;

  set
    Subsidy_lihtc_a
    Subsidy_non_lihtc
    Subsidy_new
      (keep=nlihc_id subsidy_id poa_start poa_start_orig compl_end poa_end: 
            subsidy_active portfolio program
            units_assist subsidy_info_source subsidy_info_source_date update_dtm);
  by nlihc_id subsidy_id;

  if first.nlihc_id then _subsidy_id_last = 0;

  if subsidy_id = 9999 or missing( subsidy_id ) then subsidy_id = _subsidy_id_last + 1;

  _subsidy_id_last = subsidy_id;

  drop _subsidy_id_last;

run;

%Dup_check(
  data=Subsidy,
  by=nlihc_id subsidy_id,
  id=program
)

proc compare base=Subsidy_all compare=Subsidy listall maxprint=(140,32000);
  id nlihc_id subsidy_id;
run;

proc print data=Subsidy_lihtc;
  where nlihc_id in ( 'NL000273', 'NL000274' );
  id nlihc_id subsidy_id;
  var program units_assist poa_: compl_:; 
  title2 'Orchard Park: Before Update';
run;

proc print data=Subsidy;
  where nlihc_id in ( 'NL000273', 'NL000274' );
  id nlihc_id subsidy_id;
  var program units_assist poa_: compl_:; 
  title2 'Orchard Park: After Update';
run;

title2; 


**************************************************************************
  Update Subsidy_except
**************************************************************************;

data Subsidy_except;

  set 
    PresCat.Subsidy_except
    Subsidy 
      (keep=nlihc_id subsidy_id poa_start compl_end poa_end units_assist update_dtm
       where=(update_dtm = &Update_dtm)
       in=in2);
  by nlihc_id subsidy_id;

  if in2 then do;
    Except_date = today();
    Except_init = 'PAT';
  end;

  drop update_dtm;

run;

proc compare base=PresCat.Subsidy_except compare=Subsidy_except maxprint=(40,32000);
  id nlihc_id subsidy_id;
run;


**************************************************************************
  Update Building_geocode
**************************************************************************;

filename fimport "L:\Libraries\DHCD\Raw\LIHTC\Read_LIHTC_FOIA_11_09_12_mar_tool_base.csv" lrecl=2000;

proc import out=LIHTC_FOIA_mar_base
    datafile=fimport
    dbms=csv replace;
  datarow=2;
  getnames=yes;
  guessingrows=10000;
run;

filename fimport clear;

** Add NLIHC_ID to geocoding records **;

proc sort data=LIHTC_FOIA_mar_base;
  by dhcd_project_id dhcd_seg_id addr_num;
run;

proc sort data=Lihtc_foia_nlihc_id out=Lihtc_foia_nlihc_id_umx nodupkey;
  by dhcd_project_id_orig dhcd_seg_id nlihc_id;
run;

%Dup_check(
  data=Lihtc_foia_nlihc_id_umx,
  by=dhcd_project_id_orig dhcd_seg_id,
  id=nlihc_id
)

data LIHTC_FOIA_mar_base_nlihc_id;

  merge
    LIHTC_FOIA_mar_base
    Lihtc_foia_nlihc_id_umx 
      (keep=dhcd_project_id_orig dhcd_seg_id nlihc_id
       rename=(dhcd_project_id_orig=dhcd_project_id));
  by dhcd_project_id dhcd_seg_id;

run;

filename fimport "L:\Libraries\DHCD\Raw\LIHTC\Read_LIHTC_FOIA_11_09_12_mar_tool_mar_address.csv" lrecl=2000;

data Lihtc_foia_mar_address;

%let _EFIERR_ = 0; /* set the ERROR detection macro variable */
infile FIMPORT delimiter = ',' MISSOVER DSD lrecl=32767 firstobs=2 ;
informat ADDRESS_ID best32. ;
informat MARID best32. ;
informat STATUS $6. ;
informat FULLADDRESS $160. ;
informat ADDRNUM best32. ;
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
informat STREETVIEWURL $255. ;
informat RES_TYPE $11. ;
informat WARD_2002 $6. ;
informat WARD_2012 $6. ;
informat ANC_2002 $6. ;
informat ANC_2012 $6. ;
informat SMD_2002 $8. ;
informat SMD_2012 $8. ;
informat IMAGEURL $160. ;
informat IMAGEDIR $160. ;
informat IMAGENAME $160. ;
informat CONFIDENCELEVEL $1. ;


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

proc sort data=Lihtc_foia_mar_address;
  by address_id;
run;

proc sort data=LIHTC_FOIA_mar_base_nlihc_id nodupkey;
  by marid;
run;

data LIHTC_FOIA_mar_final;

  merge
    LIHTC_FOIA_mar_base_nlihc_id
      (keep=marid nlihc_id MAR_MATCHADDRESS mar_zipcode mar_latitude mar_longitude mar_xcoord mar_ycoord
       rename=(marid=address_id))
    Lihtc_foia_mar_address;
  by address_id;

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
  
  if not( missing( mar_zipcode ) ) then Zip = put( mar_zipcode, z5.0 );
  else Zip = "";
    
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
  
run;

** Create project and building geocode update data sets **;

%let geo_vars = Ward2012 Anc2012 Psa2012 Geo2010 Cluster_tr2000 Cluster_tr2000_name Zip;
%let MAX_PROJ_ADDRE = 3;   /** Maximum number of addresses to include in Proj_addre field in PresCat.Project_geo **/

proc sort data=Lihtc_foia_mar_final;
  by nlihc_id;
run;

data 
  Project_geocode_update 
    (keep=nlihc_id &geo_vars Proj_address_id Proj_x Proj_y Proj_lat Proj_lon 
          Proj_addre Proj_zip Proj_image_url Proj_Streetview_url Bldg_count)
  Building_geocode_update
    (keep=nlihc_id &geo_vars address_id Bldg_x Bldg_y Bldg_lat Bldg_lon Bldg_addre Zip
          image_url Streetview_url ssl_std
     rename=(address_id=Bldg_address_id Zip=Bldg_zip image_url=Bldg_image_url Streetview_url=Bldg_streetview_url
             ssl_std=Ssl));
    
  set Lihtc_foia_mar_final (where=(not(missing(nlihc_id))));
  by nlihc_id;
  
  format Streetview_url address_id ;
  informat _all_ ;

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

** Create new version of geocode data sets **;

%Data_to_format(
  FmtLib=work,
  FmtName=$Project_geocode_update,
  Data=Project_geocode_update,
  Value=nlihc_id,
  Label=nlihc_id,
  OtherLabel="",
  Print=N
  )

proc sort data=Building_geocode_update;
  by nlihc_id bldg_addre;
run;

data Building_geocode;

  set
    PresCat.Building_geocode (where=(put(nlihc_id,$Project_geocode_update.)=""))
    Building_geocode_update;
  by nlihc_id bldg_addre;

  select ( nlihc_id );

    when ( 'NL001034' ) do;
      proj_name = "WDC I - B";
    end;

    when ( 'NL001035' ) do;
      proj_name = "WDC I - C";
    end;

    otherwise do;
      if put( nlihc_id, $project_name. ) ~= "" then 
        Proj_name = put( nlihc_id, $project_name. );
      else
        delete;
    end;

  end;

run;

proc compare base=PresCat.Building_geocode compare=Building_geocode maxprint=(40,32000);
  id nlihc_id bldg_addre;
run;

data Project_geocode;

  set
    PresCat.Project_geocode (where=(put(nlihc_id,$Project_geocode_update.)=""))
    Project_geocode_update;
  by nlihc_id;

  select ( nlihc_id );

    when ( 'NL001034' ) do;
      proj_name = "WDC I - B";
    end;

    when ( 'NL001035' ) do;
      proj_name = "WDC I - C";
    end;

    otherwise do;
      if put( nlihc_id, $project_name. ) ~= "" then 
        Proj_name = put( nlihc_id, $project_name. );
      else
        delete;
    end;

  end;

run;

proc compare base=PresCat.Project_geocode compare=Project_geocode listall maxprint=(40,32000);
  id nlihc_id;
run;


**************************************************************************
  Update Project
**************************************************************************;

%Create_project_subsidy_update( data=Subsidy, out=Project_subsidy_update )

data Project_a;

  update
    PresCat.Project
    Project_subsidy_update
      updatemode=nomissingcheck;
  by nlihc_id;

  if put( nlihc_id, $Project_geocode_update. ) ~= "" then update_dtm = &Update_dtm;

run;

data Project;

  update
    Project_a
    Project_geocode_update
      updatemode=missingcheck;
  by nlihc_id;

  select ( nlihc_id );

    when ( 'NL001034' ) do;
      proj_name = "WDC I - B";
      status = 'A';
      category_code = '5';
      Cat_at_risk = 0;
      Cat_expiring = 0;
      Cat_failing_insp = 0;
      Cat_more_info = 0;
      Cat_lost = 0;
      Cat_replaced = 0;
      Proj_city = 'Washington';
      Proj_st = 'DC';
      Proj_units_tot = 111;
      PBCA = 0;
    end;

    when ( 'NL001035' ) do;
      proj_name = "WDC I - C";
      status = 'A';
      category_code = '5';
      Cat_at_risk = 0;
      Cat_expiring = 0;
      Cat_failing_insp = 0;
      Cat_more_info = 0;
      Cat_lost = 0;
      Cat_replaced = 0;
      Proj_city = 'Washington';
      Proj_st = 'DC';
      Proj_units_tot = 54;
      PBCA = 0;
    end;

    when ( 'NL000325' ) do;
      Proj_units_tot = 18;
    end;

    otherwise
      /** DO NOTHING **/;

  end;

run;

proc compare base=PresCat.Project compare=Project listall maxprint=(40,32000);
  id nlihc_id;
run;


**************************************************************************
  Apply updates
**************************************************************************;

%Finalize_data_set( 
  /** Finalize data set parameters **/
  data=Subsidy,
  out=Subsidy,
  outlib=PresCat,
  label="Preservation Catalog, Project subsidies",
  sortby=nlihcd_id subsidy_id,
  archive=Y,
  /** Metadata parameters **/
  revisions=%str(Update LIHTC projects with DHCD FOIA, 11-09-12.),
  /** File info parameters **/
  printobs=10
)

%Finalize_data_set( 
  /** Finalize data set parameters **/
  data=Project,
  out=Project,
  outlib=PresCat,
  label="Preservation Catalog, Projects",
  sortby=nlihcd_id,
  archive=Y,
  /** Metadata parameters **/
  revisions=%str(Update LIHTC projects with DHCD FOIA, 11-09-12.),
  /** File info parameters **/
  printobs=10
)

%Finalize_data_set( 
  /** Finalize data set parameters **/
  data=Subsidy_except,
  out=Subsidy_except,
  outlib=PresCat,
  label="Preservation Catalog, ",
  sortby=nlihcd_id subsidy_id except_date,
  archive=Y,
  /** Metadata parameters **/
  revisions=%str(Update LIHTC projects with DHCD FOIA, 11-09-12.),
  /** File info parameters **/
  printobs=10
)

%Finalize_data_set( 
  /** Finalize data set parameters **/
  data=Building_geocode,
  out=Building_geocode,
  outlib=PresCat,
  label="Preservation Catalog, Building-level geocoding info",
  sortby=nlihcd_id bldg_addre,
  archive=Y,
  /** Metadata parameters **/
  revisions=%str(Update LIHTC projects with DHCD FOIA, 11-09-12.),
  /** File info parameters **/
  printobs=10
)

%Finalize_data_set( 
  /** Finalize data set parameters **/
  data=Project_geocode,
  out=Project_geocode,
  outlib=PresCat,
  label="Preservation Catalog, Project-level geocoding info",
  sortby=nlihcd_id,
  archive=Y,
  /** Metadata parameters **/
  revisions=%str(Update LIHTC projects with DHCD FOIA, 11-09-12.),
  /** File info parameters **/
  printobs=10
)


**************************************************************************
  Export data for new projects not currently in Catalog
**************************************************************************;

** Identify nonmatching projects **;

proc summary data=Lihtc_parcel_a nway;
  class dhcd_project_id_orig;
  var in_cat;
  output out=Lihtc_parcel_in_cat max=;
run;

%Data_to_format(
  FmtLib=work,
  FmtName=Dhcd_proj_id_in_cat,
  Desc=,
  Data=Lihtc_parcel_in_cat,
  Value=dhcd_project_id_orig,
  Label=put( in_cat, $1. ),
  OtherLabel=" ",
  Print=N,
  Contents=N
  )

data Lihtc_foia_nomatch;

  merge 
    Lihtc_foia_11_09_12
    Lihtc_pis;
  by dhcd_project_id;

  if put( dhcd_project_id, Dhcd_proj_id_in_cat. ) = '0';

  rev_proj_initial_expiration = intnx( 'year', rev_proj_placed_in_service, 15, 'same' );
  rev_proj_extended_expiration = intnx( 'year', rev_proj_placed_in_service, 30, 'same' );

  format rev_proj_placed_in_service rev_proj_initial_expiration rev_proj_extended_expiration mmddyy10.;
  
  label
    rev_proj_placed_in_service = 'Project placed in service date (NIDC revised)'
    rev_proj_initial_expiration = 'Project initial compliance expiration date (NIDC revised)'
    rev_proj_extended_expiration = 'Project extended compliance expiration date (NIDC revised)';
  
  drop proj_initial_expiration proj_extended_expiration seg_placed_in_service;
  
run;

proc sort data=Lihtc_foia_nomatch nodupkey;
  by dhcd_project_id address_id;
run;

data Buildings_for_geocoding_subsidy;

  length  
    MARID 8 Units_assist 8 Current_Affordability_Start 8
    Affordability_End 8 Fair_Market_Rent_Ratio $ 250
    Subsidy_Info_Source_ID $ 250 Subsidy_Info_Source $ 250
    Subsidy_Info_Source_Date 8 Update_Date_Time 8 Program $ 250
    Compliance_End_Date 8 Previous_Affordability_end 8 Agency $ 250
    Portfolio $ 250 Date_Affordability_Ended 8;

  set Lihtc_foia_nomatch;
  by dhcd_project_id;

  if first.dhcd_project_id;

  MARID = address_id;
  Units_assist = proj_lihtc_units;
  Current_Affordability_Start = rev_proj_placed_in_service;
  Affordability_End = rev_proj_extended_expiration;
  Fair_Market_Rent_Ratio = '';
  Subsidy_Info_Source_ID = '';
  Subsidy_Info_Source = 'DHCD/FOIA';
  Subsidy_Info_Source_Date = '09nov2012'd;
  Update_Date_Time = &Update_dtm;
  Program = 'LIHTC';
  Compliance_End_Date = rev_proj_initial_expiration;
  Previous_Affordability_end = .;
  Agency = 'DC Dept of Housing and Community Development; DC Housing Finance Agency';
  Portfolio = 'LIHTC';
  Date_Affordability_Ended = .;

  format 
    Current_Affordability_Start
    Affordability_End Subsidy_Info_Source_Date 
    Compliance_End_Date Previous_Affordability_end 
    Date_Affordability_Ended mmddyy10.
    Update_Date_Time datetime16.;

  keep
    MARID Units_assist Current_Affordability_Start
    Affordability_End Fair_Market_Rent_Ratio
    Subsidy_Info_Source_ID Subsidy_Info_Source
    Subsidy_Info_Source_Date Update_Date_Time Program
    Compliance_End_Date Previous_Affordability_end Agency
    Portfolio Date_Affordability_Ended;

run;


/*[START HERE]*/

/** 
Next steps: 
x Update subsidy exception file
x Update building_geocode
x Update project_geocde
x Update project
x Apply updates
- Output new projects to add to Catalog
- Update Parcel --> Update_parcel.sas
- Update real_property --> Update_real_property.sas
SKIP Update subsidy_update_history
**/


