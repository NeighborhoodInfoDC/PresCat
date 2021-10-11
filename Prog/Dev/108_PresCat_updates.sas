/**************************************************************************
 Program:  108_PresCat_updates.sas
 Library:  PresCat
 Project:  NeighborhoodInfo DC
 Author:   P. Tatian
 Created:  07/13/17
 Version:  SAS 9.2
 Environment:  Local Windows session (desktop)
 
 Description:  Updates and checks to Preservation Catalog. 
 GitHub issue #108.

 Modifications:
**************************************************************************/

%include "\\sas1\DCdata\SAS\Inc\StdLocal.sas";

** Define libraries **;
%DCData_lib( PresCat )
%DCData_lib( HUD )
%DCData_lib( RealProp )


** Initialize PresCat global macro vars **;

%PresCat_global_mvars()


** Add year built to Project **;

proc sql noprint;
  create table Parcel_yb as
    select a.nlihc_id, coalesce( a.ssl, b.ssl ) as ssl, coalesce( a.ayb, b.ayb ) as ayb, coalesce( a.eyb, b.eyb ) as eyb
    from RealProp.Camarespt_2014_03 as b right join (
      select a.nlihc_id, coalesce( a.ssl, b.ssl ) as ssl, coalesce( a.ayb, b.ayb ) as ayb, coalesce( a.eyb, b.eyb ) as eyb
      from RealProp.camacondopt_2013_08 as b right join (
        select a.nlihc_id, coalesce( a.ssl, b.ssl ) as ssl, b.ayb, b.eyb
        from RealProp.camacommpt_2013_08 as b right join 
        PresCat.Parcel as a
        on a.ssl = b.ssl ) as a 
      on a.ssl = b.ssl ) as a
    on a.ssl = b.ssl
    order by nlihc_id, ssl;
  quit;

data Parcel_yb_2;

  set Parcel_yb;
  
  if ayb < 1900 then ayb = .u;
  if eyb < 1900 then eyb = .u;

run;

proc summary data=Parcel_yb_2;
  by nlihc_id;
  var ayb eyb;
  output out=Project_yb (drop=_type_ _freq_) min=;
run;


** Add earlier start dates for Sec8MF subsidies **;

proc sql noprint;
  create table Subsidy_a as
  select a.*, b.* 
  from (
    select a.*, b.tracs_effective_date as poa_start_orig_new
    from PresCat.Subsidy as a left join Hud.Sec8mf_2003_06_dc as b
    on a.subsidy_info_source = 'HUD/MFA' and a.subsidy_info_source_id = trim( left( put( b.property_id, 16. ) ) ) || "/" || left( b.contract_number )
  ) as a
  left join Project_yb as b
  on a.nlihc_id = b.nlihc_id
  order by nlihc_id, subsidy_id;
quit;

proc print data=Subsidy_a;
  where subsidy_info_source = 'HUD/MFA';
  id nlihc_id subsidy_id;
  var program units_assist poa_start: ayb eyb;
run;

data Subsidy;

  set Subsidy_a;
  
  ** Check original subsidy start date against new version and year property was built **;
  ** Don't use year built before 1/1/1910 (probably not accurate) **;
  
  if max( '01jan1910'd, mdy( 1, 1, ayb ) ) <= Poa_start_orig_new < Poa_start_orig then Poa_start_orig = Poa_start_orig_new;
  
  keep &_pc_subsidy_vars;
  
run;

proc compare base=PresCat.Subsidy compare=Subsidy listall maxprint=(40,32000);
  id nlihc_id subsidy_id;
run;


** Add owner category to Project **;

proc summary data=PresCat.Parcel nway;
  class nlihc_id parcel_owner_type;
  output out=Project_owner;
run;

proc sort data=Project_owner;
  by nlihc_id descending _freq_;
run;

data Project_owner_nodup;

  set Project_owner;
  by nlihc_id;
  
  if first.nlihc_id;

run;

proc print data=Project_owner;
  by nlihc_id;
  id nlihc_id;
run;

proc print data=Project_owner_nodup;
  id nlihc_id;
run;


** Create updated Project table **;

data Project;

  merge
    PresCat.Project 
    Project_yb 
     (keep=nlihc_id ayb eyb
      rename=(ayb=Proj_ayb eyb=Proj_eyb))
    Project_owner_nodup
      (keep=nlihc_id Parcel_owner_type
       rename=(Parcel_owner_type=Proj_owner_type))
  ;
  by nlihc_id;
  
  label
    Proj_ayb = "Project year built (original)"
    Proj_eyb = "Project year built (improvements)"
    Proj_owner_type = "Project owner type (majority of parcels)";
  
  keep &_pc_project_vars;
  
run;
 
proc compare base=PresCat.Project compare=Project listall maxprint=(40,32000);
  id nlihc_id;
run;


** Finalize data sets **;

%Finalize_data_set( 
  /** Finalize data set parameters **/
  data=Project,
  out=Project,
  outlib=PresCat,
  label=&_pc_project_dslb,
  sortby=&_pc_project_sort,
  archive=Y,
  /** Metadata parameters **/
  revisions=%str(Add Proj_ayb, Proj_eyb, Proj_owner_type vars.),
  /** File info parameters **/
  printobs=0,
  freqvars=Proj_owner_type,
  stats=n sum mean stddev min max
)


%Finalize_data_set( 
  /** Finalize data set parameters **/
  data=Subsidy,
  out=Subsidy,
  outlib=PresCat,
  label=&_pc_subsidy_dslb,
  sortby=&_pc_subsidy_sort,
  archive=Y,
  /** Metadata parameters **/
  revisions=%str(Update POA_start_orig with older data for Sec8MF subsidies.),
  /** File info parameters **/
  printobs=0,
  freqvars=,
  stats=n sum mean stddev min max
)


