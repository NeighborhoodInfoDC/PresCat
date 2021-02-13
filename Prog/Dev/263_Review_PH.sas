/**************************************************************************
 Program:  263_Review_PH.sas
 Library:  PresCat
 Project:  Urban-Greater DC
 Author:   P. Tatian
 Created:  02/13/21
 Version:  SAS 9.4
 Environment:  Local Windows session (desktop)
 GitHub issue:  263
 
 Description:  Review public housing projects in Catalog.

 Modifications:
**************************************************************************/

%include "\\sas1\DCdata\SAS\Inc\StdLocal.sas";

** Define libraries **;
%DCData_lib( PresCat )
%DCData_lib( RealProp )
%DCData_lib( HUD )

%let Update_dtm = %sysfunc( datetime() );

%let revisions = ;

  
** Compile data sources on public housing **;

** PresCat.Subsidy + HUD APSH **;

proc sql noprint;
  create table PH_Subsidy_a as
  select Subsidy1.*, APSH18.code as APSH18_code, n(APSH18.code) as APSH18_in,
      APSH18.std_addr as APSH18_std_addr, APSH18.total_units as APSH18_total_units,
      APSH18.name as APSH18_name
    from (
    select Subsidy.*, APSH20.code as APSH20_code, n(APSH20.code) as APSH20_in,
        APSH20.std_addr as APSH20_std_addr, APSH20.total_units as APSH20_total_units,
        APSH20.name as APSH20_name
      from 
      PresCat.Subsidy (where=(program = 'PUBHSNG')) as Subsidy 
      left join 
      HUD.APSH_project_2020_dc (where=(program='2')) as APSH20
      on subsidy_info_source_id = APSH20.code and subsidy_info_source = 'HUD/PSH'
      group by nlihc_id, subsidy_id
    ) as Subsidy1
    left join
    HUD.APSH_project_2018_dc (where=(program='2')) as APSH18
    on subsidy_info_source_id = APSH18.code and subsidy_info_source = 'HUD/PSH'
    group by nlihc_id, subsidy_id
    order by nlihc_id, subsidy_id;
quit;

proc print data=PH_subsidy_a n;
  id nlihc_id;
  var subsidy_active /*subsidy_info_source subsidy_info_source_id*/ apsh18_: apsh20_:;
run;

%Dup_check(
  data=PH_subsidy_a,
  by=nlihc_id,
  id=subsidy_id subsidy_active units_assist apsh18_in apsh20_in apsh18_name apsh20_name subsidy_info_source_id,
  listdups=Y
)

proc summary data=PH_subsidy_a;
  var units_assist subsidy_active update_dtm apsh18_in apsh20_in APSH18_total_units APSH20_total_units;
  by nlihc_id;
  id APSH18_name APSH20_name;
  output out=PH_Subsidy_b 
    max(subsidy_active update_dtm apsh18_in apsh20_in)= 
    sum(units_assist APSH18_total_units APSH20_total_units)=;
run;

data PH_Subsidy;

  length xAPSH18_std_addr xAPSH20_std_addr $ 160;
  retain xAPSH18_std_addr xAPSH20_std_addr;
  
  merge 
    PH_Subsidy_a (keep=nlihc_id APSH18_std_addr APSH20_std_addr)
    PH_Subsidy_b;
  by nlihc_id;
  
  if first.nlihc_id then xAPSH18_std_addr = left( APSH18_std_addr );
  else xAPSH18_std_addr = trim( xAPSH18_std_addr ) || '; ' || left( APSH18_std_addr );
  
  if first.nlihc_id then xAPSH20_std_addr = left( APSH20_std_addr );
  else xAPSH20_std_addr = trim( xAPSH20_std_addr ) || '; ' || left( APSH20_std_addr );
  
  if last.nlihc_id then output;
  
  drop APSH18_std_addr APSH20_std_addr;
  rename xAPSH18_std_addr=APSH18_std_addr xAPSH20_std_addr=APSH20_std_addr;
  
run;


** Parcel data **;

proc summary data=PresCat.Parcel nway; 
  class nlihc_id parcel_owner_name;
  output out=Parcel_owners_a;
run;

proc sort data=Parcel_owners_a;
  by nlihc_id descending _freq_;
run;

data Parcel_owners;

  length Owners $ 160;
  retain Owners;
  
  set Parcel_owners_a;
  by nlihc_id;
  
  if first.nlihc_id then Owners = left( parcel_owner_name );
  else Owners = trim( Owners ) || '; ' || left( parcel_owner_name );
  
  if last.nlihc_id then output;
  
run;

data PH_Subsidy_Proj;

  merge 
    PH_Subsidy (in=in_subsidy)
    PresCat.Project_category_view 
      (keep=nlihc_id ward2012 bldg_count category_code proj_addre proj_name proj_owner_type proj_units_tot status)
    Parcel_owners;
  by nlihc_id;
  
  if in_subsidy;
  
run;

ods tagsets.excelxp file="&_dcdata_default_path\PresCat\Prog\Dev\263_Review_PH.xls" style=Normal options(sheet_interval='Proc' );
ods listing close;

%fdate()

options nodate nonumber;

footnote1 height=9pt "Prepared by Urban-Greater DC (greaterdc.urban.org), &fdate..";
footnote2 height=9pt j=r '{Page}\~{\field{\*\fldinst{\pard\b\i0\chcbpat8\qc\f1\fs19\cf1{PAGE }\cf0\chcbpat0}}}';

ods tagsets.excelxp options( sheet_name="ACTIVE" );

title2 '** Updated Catalog list of ACTIVE public housing **';

proc print data=PH_Subsidy_Proj n label;
  where subsidy_active;
  id nlihc_id proj_name;
  var proj_addre ward2012 units_assist status category_code proj_owner_type owners
    apsh18_in apsh18_name apsh18_std_addr apsh20_in apsh20_name apsh20_std_addr ;
  sum units_assist;
  format units_assist comma10. apsh18_in apsh20_in dyesno. category_code ;
  label 
    nlihc_id = "ID"
    owners = "OTR property owners"
    apsh18_in = "APSH18: Match"
    apsh18_name = "APSH18: Name"
    apsh18_std_addr = "APSH18: Address"
    apsh20_in = "APSH20: Match"
    apsh20_name = "APSH20: Name"
    apsh20_std_addr = "APSH20: Address";
run;

ods tagsets.excelxp options( sheet_name="INACTIVE" );

title2 '** Updated Catalog list of INACTIVE public housing **';

proc print data=PH_Subsidy_Proj n label;
  where not( subsidy_active );
  id nlihc_id proj_name;
  var proj_addre ward2012 units_assist status category_code proj_owner_type owners
    apsh18_in apsh18_name apsh18_std_addr apsh20_in apsh20_name apsh20_std_addr ;
  sum units_assist;
  format units_assist comma10. apsh18_in apsh20_in dyesno. category_code ;
  label 
    nlihc_id = "ID"
    owners = "OTR property owners"
    apsh18_in = "APSH18: Match"
    apsh18_name = "APSH18: Name"
    apsh18_std_addr = "APSH18: Address"
    apsh20_in = "APSH20: Match"
    apsh20_name = "APSH20: Name"
    apsh20_std_addr = "APSH20: Address";
run;

ods tagsets.excelxp close;

title2;
footnote1;

