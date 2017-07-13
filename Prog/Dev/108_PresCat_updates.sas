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

%include "L:\SAS\Inc\StdLocal.sas";

** Define libraries **;
%DCData_lib( PresCat )
%DCData_lib( HUD )
%DCData_lib( RealProp )

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
  
  if ayb = 0 then ayb = .;
  if eyb = 0 then eyb = .;

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


** Check projects with subsidies from "HUD - Active 202/811 Loans (10/08/10)" **;

proc format;
  value $sel_source
    "HUD - Active 202/811 Loans" = "*"
    "HUD/MFA" = "HUD/MFA"
    other = " ";
run;

proc print data=Subsidy_a;
  where subsidy_info_source = "HUD - Active 202/811 Loans";
  id nlihc_id subsidy_id;
  var subsidy_info_source_date program units_assist poa_: ;
run;

proc sql noprint;
  create table Has_HUD_active_202 as
  select a.nlihc_id, b.* from Subsidy_a (where=(subsidy_info_source = "HUD - Active 202/811 Loans")) as a left join Subsidy_a as b
  on a.nlihc_id = b.nlihc_id
  order by nlihc_id, subsidy_id;
quit;

proc print data=Has_HUD_active_202;
  id nlihc_id subsidy_id;
  by nlihc_id;
  var subsidy_info_source program units_assist poa_start_orig poa_start_orig_new poa_start ayb eyb;
  format subsidy_info_source $sel_source.;
run;


run;
