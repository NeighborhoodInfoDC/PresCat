/**************************************************************************
 Program:  Test_lihtc_foia_2012_match.sas
 Library:  PresCat
 Project:  NeighborhoodInfo DC
 Author:   P. Tatian
 Created:  12/14/16
 Version:  SAS 9.2
 Environment:  Local Windows session (desktop)
 
 Description:  Test matching DHCD FOIA (11/9/12) list of LIHTC projects 
 with Preservation Catalog.

 Modifications:
**************************************************************************/

%include "L:\SAS\Inc\StdLocal.sas";

** Define libraries **;
%DCData_lib( PresCat )
%DCData_lib( DHCD )
%DCData_lib( RealProp )


** Remove extraneous geo matches from LIHTC FOIA data **;

data Lihtc_foia_11_09_12;

  set dhcd.Lihtc_foia_11_09_12;
  
  if scan( address_std, 1 ) ~= scan( m_addr, 1 ) then _score_ = .n;
  
  if _score_ >= 45;
  
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


** Merge LIHTC with Catalog Parcel, Subsidy, and Project data **;

proc sql noprint;
  create table A as
  select
    coalesce( project_parcel.nlihc_id, subsidy.nlihc_id ) as nlihc_id, project_parcel.*, 
    subsidy.poa_start, subsidy.poa_end, subsidy.units_assist from
    ( select 
        coalesce( project.nlihc_id, lihtc_parcel.nlihc_id ) as nlihc_id, lihtc_parcel.*, 
        project.proj_name, project.proj_addre from 
        (  select 
             coalesce( parcel.ssl, lihtc.ssl ) as ssl, lihtc.*, parcel.nlihc_id, 
             input( put(nlihc_id, $lihtc_sel.), 8. ) as cat_lihtc_proj, 
             not( missing( parcel.nlihc_id ) ) as in_cat, not( missing( lihtc.dhcd_project_id ) ) as in_dhcd 
             from lihtc as lihtc 
             full join PresCat.Parcel as parcel
             on lihtc.ssl = parcel.ssl
        ) as lihtc_parcel 
      left join PresCat.project as project
      on project.nlihc_id = lihtc_parcel.nlihc_id
    ) as project_parcel
    left join PresCat.Subsidy (where=(portfolio = 'LIHTC')) as subsidy
    on project_parcel.nlihc_id = subsidy.nlihc_id
  order by ssl
;


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

***proc print data=A_nlihcid;

proc summary data=A_nodup nway;
  where not missing( dhcd_project_id );
  class dhcd_project_id;
  var in_cat;
  output out=A_dhcd (drop=_freq_ _type_) sum=cat_count;
run;

***proc print data=A_dhcd;

proc sql noprint;
  create table B as 
  select AA.*, A_dhcd.* from
  ( select A.*, A_nlihcid.* from
    A left join A_nlihcid 
    on A.nlihc_id = A_nlihcid.nlihc_id
  ) as AA
  left join A_dhcd
  on AA.dhcd_project_id = A_dhcd.dhcd_project_id
;


** Export project matching lists for review **;

ods listing close;
ods tagsets.excelxp file="D:\DCData\Libraries\PresCat\Prog\Dev\Test_lihtc_foia_2012_match_A.xls" style=Analysis options(sheet_interval='Proc' );


title2 '** Full listing **';

ods tagsets.excelxp options( sheet_name="Full" );

proc print data=A;
  id ssl;
  var nlihc_id dhcd_project_id proj_name project proj_addre m_addr ssl in_: cat_lihtc_proj poa_start rev_proj_placed_in_service 
      poa_end rev_proj_initial_expiration rev_proj_extended_expiration units_assist proj_lihtc_units;
run;


title2 '** Single matching nlihc_id LIHTC project and dhcd_project_id (1:1) **';

ods tagsets.excelxp options( sheet_name="1-1-LIHTC" );

proc print data=B;
  where not( missing( nlihc_id ) or missing( dhcd_project_id ) ) and cat_count = 1 and dhcd_count = 1 and cat_lihtc_proj = 1;
  id nlihc_id dhcd_project_id;
  var cat_count dhcd_count proj_name project proj_addre m_addr ssl cat_lihtc_proj poa_start rev_proj_placed_in_service poa_end rev_proj_initial_expiration rev_proj_extended_expiration units_assist proj_lihtc_units;
run;


title2 '** Single matching nlihc_id non-LIHTC project and dhcd_project_id (1:1) **';

ods tagsets.excelxp options( sheet_name="1-1-NON" );

proc print data=B;
  where not( missing( nlihc_id ) or missing( dhcd_project_id ) ) and cat_count = 1 and dhcd_count = 1 and cat_lihtc_proj = 0;
  id nlihc_id dhcd_project_id;
  var cat_count dhcd_count proj_name project proj_addre m_addr ssl cat_lihtc_proj poa_start rev_proj_placed_in_service poa_end rev_proj_initial_expiration rev_proj_extended_expiration units_assist proj_lihtc_units;
run;


title2 '** Multiple matching nlihc_id for same dhcd_project_id **';

ods tagsets.excelxp options( sheet_name="Mult NLIHC_ID" );

proc print data=B;
  where not( missing( nlihc_id ) or missing( dhcd_project_id ) ) and cat_count > 1 and dhcd_count > 0;
  id nlihc_id dhcd_project_id;
  var cat_count dhcd_count proj_name project proj_addre m_addr ssl cat_lihtc_proj poa_start rev_proj_placed_in_service 
      poa_end rev_proj_initial_expiration rev_proj_extended_expiration units_assist proj_lihtc_units;
run;


title2 '** Multiple matching dhcd_project_id for same nlihc_id **';

ods tagsets.excelxp options( sheet_name="Mult DHCD_PROJECT_ID" );

proc print data=B;
  where not( missing( nlihc_id ) or missing( dhcd_project_id ) ) and cat_count > 0 and dhcd_count > 1;
  id nlihc_id dhcd_project_id;
  var cat_count dhcd_count proj_name project proj_addre m_addr ssl cat_lihtc_proj poa_start rev_proj_placed_in_service 
      poa_end rev_proj_initial_expiration rev_proj_extended_expiration units_assist proj_lihtc_units;
run;


title2 '** nlihc_id LIHTC project without matching dhcd_project_id **';

ods tagsets.excelxp options( sheet_name="No DHCD_PROJECT_ID" );

proc print data=B;
  where not( missing( nlihc_id ) ) and dhcd_count in ( 0, . ) and cat_lihtc_proj = 1;
  id nlihc_id;
  var dhcd_project_id cat_count dhcd_count proj_name project proj_addre m_addr ssl cat_lihtc_proj poa_start rev_proj_placed_in_service 
      poa_end rev_proj_initial_expiration rev_proj_extended_expiration units_assist proj_lihtc_units;
run;

title2 '** dhcd_project_id without matching nlihc_id **';

ods tagsets.excelxp options( sheet_name="No NLIHC_ID" );

proc print data=B;
  where not( missing( dhcd_project_id ) ) and cat_count in ( 0, . );
  id dhcd_project_id;
  var nlihc_id cat_count dhcd_count proj_name project proj_addre m_addr ssl cat_lihtc_proj poa_start rev_proj_placed_in_service 
      poa_end rev_proj_initial_expiration rev_proj_extended_expiration units_assist proj_lihtc_units;
run;


title2;

ods tagsets.excelxp close;
ods listing;


** Export building addresses for geocoding through MAR geocoding tool **;

data Geo_export;

  set Lihtc_foia_11_09_12;
  
  keep dhcd_project_id dhcd_seg_id addr_num address_std;
  
run;

filename fexport "L:\Libraries\PresCat\Raw\Lihtc_foia_2012_geocode.csv" lrecl=2000;

proc export data=Geo_export
    outfile=fexport
    dbms=csv replace;

run;

filename fexport clear;

