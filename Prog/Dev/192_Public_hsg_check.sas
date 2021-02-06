/**************************************************************************
 Program:  192_Public_hsg_check.sas
 Library:  PresCat
 Project:  Urban-Greater DC
 Author:   P. Tatian
 Created:  03/16/19
 Version:  SAS 9.4
 Environment:  Local Windows session (desktop)
 GitHub issue:  192
 
 Description:  Check public housing developments

 Modifications:
**************************************************************************/

%include "\\sas1\DCdata\SAS\Inc\StdLocal.sas";

** Define libraries **;
%DCData_lib( PresCat )
%DCData_lib( HUD )
%DCData_lib( MAR )

%Data_to_format(
  FmtLib=work,
  FmtName=$nlihcid_to_projname,
  Desc=,
  Data=PresCat.Project_category_view,
  Value=nlihc_id,
  Label=nlihc_id || proj_name,
  OtherLabel=,
  DefaultLen=.,
  MaxLen=.,
  MinLen=.,
  Print=N,
  Contents=N
  )


%let list =
"NL000413"
"NL000394"
"NL000410"
"NL000362"
"NL000414"
"NL000393"
"NL000390"
"NL000399"
"NL000010"
"NL000392";

title2 'Projects incorrectly listed as public housing';

proc print data=PresCat.Project_category_view;
  where nlihc_id in ( &list );
  id nlihc_id;
  var status proj_name proj_addre;
run;

proc print data=PresCat.Subsidy;
  where nlihc_id in ( &list );
  by nlihc_id;
  id nlihc_id subsidy_id;
  var program subsidy_info_source subsidy_info_source_date;
run;

proc print data=PresCat.parcel;
  where nlihc_id in ( &list );
  by nlihc_id;
  id nlihc_id ssl;
  var parcel_owner_name;
run;

proc print data=PresCat.real_property;
  where nlihc_id in ( &list );
  by nlihc_id;
  id nlihc_id ssl;
run;

** Remove non PH records **;

data Subsidy;

  set PresCat.Subsidy;
  by nlihc_id subsidy_id;
  
  where program ~= 'PUBHSNG' or nlihc_id not in ( &list );
  
  retain subsidy_id_new;
  
  if first.nlihc_id then do;
    subsidy_id_new = 1;
  end;
  else do;
    subsidy_id_new + 1;
  end;
  
  drop subsidy_id;
  
  rename subsidy_id_new=Subsidy_id;
  
  label Subsidy_id_new = "Preservation Catalog subsidy ID";

run;

title2 'With public housing subsidy removed';

proc print data=Subsidy;
  where nlihc_id in ( &list );
  by nlihc_id;
  id nlihc_id subsidy_id;
  var program subsidy_info_source subsidy_info_source_date;
run;

proc compare base=PresCat.Subsidy compare=Subsidy listall maxprint=(40,32000);
  id Nlihc_id Subsidy_id;
run;

%Data_to_format(
  FmtLib=work,
  FmtName=$nlihcid_to_pubhsg,
  Desc=,
  Data=Subsidy (where=(program='PUBHSNG')),
  Value=nlihc_id,
  Label='1',
  OtherLabel='0',
  DefaultLen=.,
  MaxLen=.,
  MinLen=.,
  Print=N,
  Contents=N
  )

title2;

** Compare Catalog list against APSH **;

data Apsh_pubhsng;

 set HUD.Apsh_project_2018_dc 
   (keep=code name program std_addr std_zip5 total_units where=(program='2'));

run;

title2 'HUD APSH list of public housing developments (2018)';

ods tagsets.excelxp file="&_dcdata_default_path\PresCat\Raw\Dev\Public_hsg_check_apsh_list.xls" style=Normal options(sheet_interval='Proc' embedded_titles='Yes');
ods tagsets.excelxp options( sheet_name="APSH_public_hsng" );

ods listing close;

proc print data=Apsh_pubhsng n='Projects';
  id code;
  var name std_addr total_units;
  sum total_units;
  format total_units comma10.0;
run;

ods listing;
ods tagsets.excelxp close;

title2;

%DC_mar_geocode(
  data=Apsh_pubhsng,
  out=Apsh_pubhsng_geo,
  staddr=std_addr,
  zip=std_zip5,
  id=code,
  listunmatched=Y
)

%File_info( data=Apsh_pubhsng_geo, contents=y, printobs=0 )

proc sql noprint;
  create table Catalog_apsh_match as
  select Apsh.*, Bldg.bldg_address_id, Bldg.Bldg_addre, Bldg.nlihc_id
  from 
    Apsh_pubhsng_geo as Apsh 
  full join 
    PresCat.Building_geocode (where=(put(nlihc_id,$nlihcid_to_pubhsg.)='1')) as Bldg
  on Bldg.bldg_address_id = Apsh.address_id
  order by nlihc_id, bldg_addre, code;
quit;

ods csvall body="&_dcdata_default_path\PresCat\Raw\Dev\Public_hsg_check_apsh_compare.csv";
ods listing close;

proc print data=Catalog_apsh_match;
  by nlihc_id;
  id nlihc_id bldg_addre;
  var code name std_addr;
run;

ods listing;
ods csvall close;

