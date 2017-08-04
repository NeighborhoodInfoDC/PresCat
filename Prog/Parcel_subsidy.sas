/**************************************************************************
 Program:  Parcel_subsidy.sas
 Library:  PresCat
 Project:  NeighborhoodInfo DC
 Author:   P. Tatian
 Created:  09/27/14
 Version:  SAS 9.2
 Environment:  Local Windows session (desktop)
 
 Description:  Create parcel-level data set that flags active
 subsidies in Preservation Catalog.

 Modifications:
  10/12/14 PAT Added final code for summarizing to parcel level.
**************************************************************************/

%include "L:\SAS\Inc\StdLocal.sas";

** Define libraries **;
%DCData_lib( PresCat, local=n )
%DCData_lib( RealProp, local=n )

%let PROJECT_CHECK = 'NL000137';

** Merge Pres Catalog parcel list with Parcel_base **;

proc sort data=PresCat.Parcel out=Parcel_by_ssl;
  by ssl;
run;

data PresCat_parcel;

  merge
    RealProp.Parcel_base 
      (keep=ssl ui_proptype in_last_ownerpt
       in=_in_Parcel_base)
    Parcel_by_ssl
      (keep=ssl nlihc_id
       in=_in_PresCat);
  by ssl;
  
  if _in_PresCat;
  
  in_Parcel_base = _in_Parcel_base;
  in_PresCat = _in_PresCat;
  
run;

** Sort by project code, listing active and residential parcels first **;

proc sort data=PresCat_parcel;
  by nlihc_id descending in_last_ownerpt ui_proptype;
run;

/* 
proc print data=PresCat_parcel;
  where nlihc_id = &PROJECT_CHECK;
  id nlihc_id;
run;
 */

** Add assisted units by project and by subsidy type **;

data Subsidy;

  set PresCat.Subsidy
    (keep=nlihc_id Portfolio Subsidy_Active Units_assist
     where=(Subsidy_Active));
  
  Sub_all_proj = 1;
  Sub_all_units = Units_assist;
  
  select ( Portfolio );
    when ( "CDBG" ) do; 
      Sub_CDBG_proj = 1;
      Sub_CDBG_units = Units_assist;
    end;

    when ( "DC HPTF" ) do; 
      Sub_HPTF_proj = 1;
      Sub_HPTF_units = Units_assist;
    end;

    when ( "HOME" ) do; 
      Sub_HOME_proj = 1;
      Sub_HOME_units = Units_assist;
    end;

    when ( "LIHTC" ) do; 
      Sub_LIHTC_proj = 1;
      Sub_LIHTC_units = Units_assist;
    end;

    when ( "MCKINNEY" ) do; 
      Sub_McKinney_proj = 1;
      Sub_McKinney_units = Units_assist;
    end;

    when ( "PBV", "HUDMORT", "HOPE VI", "FHLB" ) do; 
      Sub_Other_proj = 1;
      Sub_Other_units = Units_assist;
    end;

    when ( "PRAC" ) do; 
      Sub_ProjectBased_proj = 1;
      Sub_ProjectBased_units = Units_assist;
    end;

    when ( "PB8" ) do;
      Sub_ProjectBased_proj = 1;
      Sub_ProjectBased_units = Units_assist;
    end;

    when ( "PUBHSNG" ) do; 
      Sub_PublicHsng_proj = 1;
      Sub_PublicHsng_units = Units_assist;
      end;

    when ( "202/811" ) do;
      Sub_ProjectBased_proj = 1;
      Sub_ProjectBased_units = Units_assist;
    end;

    when ( "TEBOND" ) do; 
      Sub_TEBond_proj = 1;
      Sub_TEBond_units = Units_assist;
      end;

    otherwise do;
      %err_put( msg='Subsidy not found: ' Nlihc_id= Portfolio= )
    end;
    
  end;

  array Sub{*} Sub_: ;
  
  do i = 1 to dim( Sub );
    if Sub{i} = . then Sub{i} = 0;
  end;
  
  label
    Sub_all_proj = 'Any assisted project'
    Sub_CDBG_proj = 'CDBG project'
    Sub_HOME_proj = 'HOME project'
    Sub_HPTF_proj = 'DC Housing Production Trust Fund project'
    Sub_LIHTC_proj = 'Low-Income Housing Tax Credit project'
    Sub_McKinney_proj = 'McKinney Vento loan project'
    Sub_Other_proj = 'Other subsidy project'
    Sub_ProjectBased_proj = 'Federal project-based assistance project'
    Sub_PublicHsng_proj = 'Public housing project'
    Sub_TEBond_proj = 'Tax-exempt bond project'
    Sub_all_units = 'All assisted units'
    Sub_CDBG_units = 'CDBG assisted units'
    Sub_HOME_units = 'HOME assisted units'
    Sub_HPTF_units = 'DC Housing Production Trust Fund assisted units'
    Sub_LIHTC_units = 'Low-Income Housing Tax Credit assisted units'
    Sub_McKinney_units = 'McKinney Vento loan assisted units'
    Sub_Other_units = 'Other subsidy assisted units'
    Sub_ProjectBased_units = 'Federal project-based assistance assisted units'
    Sub_PublicHsng_units = 'Public housing assisted units'
    Sub_TEBond_units = 'Tax-exempt bond units';
  
  drop i;
  
run;

/* 
proc print data=Subsidy;
  where nlihc_id = &PROJECT_CHECK;
  id nlihc_id;
run;
 */

proc summary data=Subsidy nway;
  class nlihc_id;
  var 
    Sub_all_proj
    Sub_CDBG_proj Sub_HOME_proj Sub_HPTF_proj Sub_LIHTC_proj
    Sub_McKinney_proj Sub_Other_proj Sub_ProjectBased_proj
    Sub_PublicHsng_proj Sub_TEBond_proj
    Sub_all_units
    Sub_CDBG_units Sub_HOME_units Sub_HPTF_units Sub_LIHTC_units
    Sub_McKinney_units Sub_Other_units Sub_ProjectBased_units
    Sub_PublicHsng_units Sub_TEBond_units;
  output out=Subsidy_agg 
    max( 
      Sub_all_proj
      Sub_CDBG_proj Sub_HOME_proj Sub_HPTF_proj Sub_LIHTC_proj
      Sub_McKinney_proj Sub_Other_proj Sub_ProjectBased_proj
      Sub_PublicHsng_proj Sub_TEBond_proj
      Sub_all_units
      Sub_CDBG_units Sub_HOME_units Sub_HPTF_units Sub_LIHTC_units
      Sub_McKinney_units Sub_Other_units Sub_ProjectBased_units
      Sub_PublicHsng_units Sub_TEBond_units 
    )=
    ;
run;

/* 
proc print data=Subsidy_agg;
  where nlihc_id = &PROJECT_CHECK;
  id nlihc_id;
run;
 */

/* %File_info( data=Subsidy_agg ) */

** Merge with parcel data to assign subsidies to parcels **;

data PresCat_parcel_subsidy;

  retain Saved;

  merge 
    PresCat_parcel
    Subsidy_agg (in=in_Subsidy);
  by NLIHC_ID;
  
  if in_Subsidy;
  
  ** Save only one parcel per project **;
  
  if first.Nlihc_id then do;
    Saved = 0;
  end;
  
  if Saved = 0 and ( ui_proptype =: "1" or last.Nlihc_id ) then do;
    Saved = 1;
    Output;
  end;
  
  label
    _freq_ = "Number of subsidy records for parcel";
  
  drop Saved in_Parcel_base in_PresCat _type_;
  
  rename _freq_ = Num_subsidy_recs;

run;

** Summarize to parcel level **;

proc summary data=PresCat_parcel_subsidy nway;
  class ssl;
  var 
    Sub_all_proj
    Sub_CDBG_proj Sub_HOME_proj Sub_HPTF_proj Sub_LIHTC_proj
    Sub_McKinney_proj Sub_Other_proj Sub_ProjectBased_proj
    Sub_PublicHsng_proj Sub_TEBond_proj
    Sub_all_units
    Sub_CDBG_units Sub_HOME_units Sub_HPTF_units Sub_LIHTC_units
    Sub_McKinney_units Sub_Other_units Sub_ProjectBased_units
    Sub_PublicHsng_units Sub_TEBond_units;
  output 
    out=PresCat.Parcel_subsidy 
      (label="Assisted projects and units by real property parcel"
       drop=_type_ _freq_)
    sum= ;
run;

%File_info( data=PresCat.Parcel_subsidy, freqvars=Sub_all_proj )


**** CHECKS ****;

title2 '---Projects without any parcel assigned---';

proc print data=PresCat_parcel_subsidy;
  where ssl = '';
  var Nlihc_id;
run;

title2 '---Multiple projects in same SSL---';

%Dup_check(
  data=PresCat_parcel_subsidy (where=(ssl~="")),
  by=ssl,
  id=nlihc_id ui_proptype,
  out=_dup_check,
  listdups=Y,
  count=dup_check_count,
  quiet=N,
  debug=N
)

title2 '---Projects assigned to nonresidential parcels---';

proc print data=PresCat_parcel_subsidy;
  where ui_proptype ~=: '1';
  id nlihc_id;
  var ssl in_last_ownerpt ui_proptype 
    Sub_all_units
    Sub_CDBG_units Sub_HOME_units Sub_HPTF_units Sub_LIHTC_units
    Sub_McKinney_units Sub_Other_units Sub_ProjectBased_units
    Sub_PublicHsng_units Sub_TEBond_units
  ;
  sum 
    Sub_all_units
    Sub_CDBG_units Sub_HOME_units Sub_HPTF_units Sub_LIHTC_units
    Sub_McKinney_units Sub_Other_units Sub_ProjectBased_units
    Sub_PublicHsng_units Sub_TEBond_units
  ;
run;

title2;
