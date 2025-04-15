/**************************************************************************
 Program:  481_ProjBasedAddresses.sas
 Library:  PresCat
 Project:  Urban-Greater DC
 Author:   P. Tatian
 Created:  04/15/25
 Version:  SAS 9.4
 Environment:  Local Windows session (desktop)
 GitHub issue:  481
 
 Description:  Create list of addresses for project-based
 developments in Preservation Catalog. 

Request from Brian Rohal, Legal Aid DC.

 Modifications:
**************************************************************************/

%include "\\sas1\DCdata\SAS\Inc\StdLocal.sas";

** Define libraries **;
%DCData_lib( PresCat )

** Create merged data **;


proc sql noprint;
  create table ProjBasedAddresses as
  select distinct
    coalesce( Geo.nlihc_id, Sub.nlihc_id ) as Nlihc_id, Geo.bldg_addre, Sub.Portfolio 
    from PresCat.Building_geocode as Geo left join PresCat.Subsidy as Sub
  on Geo.nlihc_id = Sub.nlihc_id
  where Sub.Portfolio in ( '202/811', 'PB8' ) and Sub.Subsidy_active
  order by Geo.nlihc_id, Geo.bldg_addre, Sub.Portfolio;
quit;

%File_info( data=ProjBasedAddresses, stats=, printobs=20 )

%Dup_check(
  data=ProjBasedAddresses,
  by=nlihc_id bldg_addre,
  id=portfolio,
  out=_dup_check,
  listdups=Y,
  count=dup_check_count,
  quiet=N,
  debug=N
)



run;
