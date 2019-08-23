/**************************************************************************
 Program:  Public_hsg_parcels.sas
 Library:  PresCat
 Project:  Urban-Greater DC
 Author:   P. Tatian
 Created:  03/23/19
 Version:  SAS 9.4
 Environment:  Local Windows session (desktop)
 GitHub issue:  192
 
 Description:  Identify public housing parcels owned by DCHA.

 Modifications:
**************************************************************************/

%include "L:\SAS\Inc\StdLocal.sas";

** Define libraries **;
%DCData_lib( PresCat )
%DCData_lib( RealProp )

%Data_to_format(
  FmtLib=work,
  FmtName=$nlihcid_to_projname,
  Desc=,
  Data=PresCat.Project_category_view,
  Value=nlihc_id,
  Label=proj_name,
  OtherLabel=,
  DefaultLen=.,
  MaxLen=.,
  MinLen=.,
  Print=N,
  Contents=N
  )

%Data_to_format(
  FmtLib=work,
  FmtName=$nlihcid_to_pubhsg,
  Desc=,
  Data=PresCat.Subsidy (where=(program='PUBHSNG')),
  Value=nlihc_id,
  Label='1',
  OtherLabel='0',
  DefaultLen=.,
  MaxLen=.,
  MinLen=.,
  Print=N,
  Contents=N
  )

proc sql noprint;
  create table Public_hsg_parcels as
  select coalesce( Cat.ssl, Own.ssl ) as ssl, Cat.nlihc_id, put( Cat.nlihc_id, $nlihcid_to_projname. ) as Projname, 
      Own.*
      /*Own.Ownercat, Own.ui_proptype, Own.Ownername_full, Own.premiseadd, Own.in_last_ownerpt*/
    from PresCat.Parcel as Cat
    full join (
      select coalesce( a.ssl, b.ssl, c.ssl ) as ssl, a.in_last_ownerpt, a.ui_proptype, a.premiseadd, b.x_coord, b.y_coord, 
        c.Ownercat, c.Ownername_full
      from RealProp.Parcel_base as a
      left join
      RealProp.Parcel_geo as b
      on a.ssl = b.ssl
      left join
      Realprop.Parcel_base_who_owns as c
      on b.ssl = c.ssl
    ) as Own
    on Cat.ssl = Own.ssl
    where put( Cat.nlihc_id, $nlihcid_to_pubhsg. ) = '1' or Own.Ownercat = '045'
    order by nlihc_id, ssl;
  quit;
  
run;

** Split data sets by matching status **;

data
  Public_hsg_parcels_matches
  Public_hsg_parcels_notincat
  Public_hsg_parcels_notdcha;
  
  set Public_hsg_parcels;
  
  if not( missing( nlihc_id ) ) and ownercat = '045' and in_last_ownerpt then output Public_hsg_parcels_matches; 
  else if missing( nlihc_id ) and in_last_ownerpt then output Public_hsg_parcels_notincat;
  else if not( missing( nlihc_id ) ) and ownercat ~= '045' then output Public_hsg_parcels_notdcha;

run;

ods tagsets.excelxp file="D:\DCData\Libraries\PresCat\Prog\Dev\Public_hsg_parcels.xls" style=Normal options(sheet_interval='Proc' );
ods listing close;

ods tagsets.excelxp options( sheet_name="Matches" );

*ods csvall body="D:\DCData\Libraries\PresCat\Prog\Dev\Public_hsg_parcels_matches.csv";

proc print data=Public_hsg_parcels_matches;
  *where not( missing( nlihc_id ) ) and ownercat = '045' and in_last_ownerpt;
  by nlihc_id;
  id nlihc_id;
  var Projname ssl premiseadd ui_proptype ownercat ownername_full in_last_ownerpt x_coord y_coord;
run;

*ods csvall close;

ods tagsets.excelxp options( sheet_name="Not in catalog" );

*ods csvall body="D:\DCData\Libraries\PresCat\Prog\Dev\Public_hsg_parcels_notincat.csv";

proc print data=Public_hsg_parcels_notincat;
  *where missing( nlihc_id ) and in_last_ownerpt;
  id ssl;
  var premiseadd ui_proptype ownercat ownername_full in_last_ownerpt x_coord y_coord;
run;

*ods csvall close;

ods tagsets.excelxp options( sheet_name="Not owned by DCHA" );

*ods csvall body="D:\DCData\Libraries\PresCat\Prog\Dev\Public_hsg_parcels_notdcha.csv";

proc print data=Public_hsg_parcels_notdcha;
  *where not( missing( nlihc_id ) ) and ownercat ~= '045';
  by nlihc_id;
  id nlihc_id;
  var Projname ssl premiseadd in_last_ownerpt ui_proptype ownercat ownername_full in_last_ownerpt x_coord y_coord;
run;

*ods csvall close;

ods tagsets.excelxp close;
ods listing;


** Create mapping files **;

filename fexport "D:\DCData\Libraries\PresCat\Prog\Dev\Public_hsg_parcels_matches.csv" lrecl=1000;

proc export data=Public_hsg_parcels_matches
    outfile=fexport
    dbms=csv replace;
run;

filename fexport clear;

filename fexport "D:\DCData\Libraries\PresCat\Prog\Dev\Public_hsg_parcels_notincat.csv" lrecl=1000;

proc export data=Public_hsg_parcels_notincat
    outfile=fexport
    dbms=csv replace;
run;

filename fexport clear;

filename fexport "D:\DCData\Libraries\PresCat\Prog\Dev\Public_hsg_parcels_notdcha.csv" lrecl=1000;

proc export data=Public_hsg_parcels_notdcha
    outfile=fexport
    dbms=csv replace;
run;

filename fexport clear;

