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
  select coalesce( Addr.Nlihc_id, Proj.Nlihc_id ) as Nlihc_id, Proj.Proj_name, Addr.Bldg_addre, Addr.Portfolio
    from
    (
      select distinct
        coalesce( Geo.nlihc_id, Sub.nlihc_id ) as Nlihc_id, Geo.bldg_addre, Sub.Portfolio 
        from PresCat.Building_geocode as Geo left join PresCat.Subsidy as Sub
      on Geo.nlihc_id = Sub.nlihc_id
      where Sub.Portfolio in ( '202/811', 'PB8' ) and Sub.Subsidy_active
    ) as Addr
    left join
    Prescat.Project_category_view as Proj
  on Addr.Nlihc_id = Proj.Nlihc_id
  order by Addr.nlihc_id, Addr.bldg_addre, Addr.Portfolio;
quit;

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


data ProjBasedAddresses_unq;

  set ProjBasedAddresses;
  by nlihc_id Bldg_addre;
  
  length Portfolio_agg $ 400;
  retain Portfolio_agg;
  
  if first.bldg_addre then Portfolio_agg = '';
  
  Portfolio_agg = catx( '; ', Portfolio_agg, put( Portfolio, $portfolio. ) );
  
  if last.bldg_addre then output;
  
  drop Portfolio;

run;


%File_info( data=ProjBasedAddresses_unq, stats=, printobs=40 )

** Check on projects with multiple subsidies **;
proc print data=ProjBasedAddresses_unq;
  where nlihc_id in ( 'NL000120', 'NL000297' );
  id nlihc_id;
run;

