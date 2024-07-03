/**************************************************************************
 Program:  Project_TOPA_outcomes.sas
 Library:  PresCat
 Project:  Urban-Greater DC
 Author:   P. Tatian
 Created:  07/03/24
 Version:  SAS 9.4
 Environment:  Local Windows session (desktop)
 GitHub issue:  451
 
 Description:  Match TOPA outcome variables to PresCat projects.

 Modifications:
**************************************************************************/

%include "\\sas1\DCdata\SAS\Inc\StdLocal.sas";

** Define libraries **;
%DCData_lib( PresCat )

** Crosswalk to match TOPA notices addresses with Nlihc_id **;
proc sql noprint;
  create table TOPA_nlihc_id as
  select unique 
  	coalesce( TOPA_addresses.address_id, Building_geocode.Bldg_address_id ) as u_address_id_ref label="DC MAR address ID", /** Matching variables **/
	TOPA_addresses.FULLADDRESS,TOPA_addresses.ID,  /** Other vars keeping **/
	Building_geocode.Nlihc_id, Building_geocode.Bldg_addre
	from PresCat.TOPA_addresses as TOPA_addresses
      left join PresCat.Building_geocode as Building_geocode   /** Left join = only keep obs that are in TOPA_addresses**/ 
  on TOPA_addresses.address_id = Building_geocode.Bldg_address_id   /** Matching on address_ID **/
  where not( missing(Building_geocode.Nlihc_id))
  order by TOPA_addresses.ID;    /** Sorting by notice ID **/
quit; 

** Remove redundant matches **;
proc sort data=Topa_nlihc_id nodupkey;
  by id nlihc_id;
run;


** Merge with TOPA outcome data **;

proc sql noprint;
  create table Project_TOPA_outcomes as
  select unique
    TOPA_nlihc_id.id, TOPA_nlihc_id.nlihc_id, Table_dat.*
    from TOPA_nlihc_id 
    left join PresCat.TOPA_table_data as Table_dat
    on TOPA_nlihc_id.id = Table_dat.id
    where Table_dat.u_dedup_notice
    order by TOPA_nlihc_id.nlihc_id, u_notice_date;
quit;

run;


** Finalize data set **;

%Finalize_data_set( 
  /** Finalize data set parameters **/
  data=Project_TOPA_outcomes,
  out=Project_TOPA_outcomes,
  outlib=PresCat,
  label="Preservation Catalog, TOPA outcomes for projects",
  sortby=nlihc_id u_notice_date,
  /** Metadata parameters **/
  restrictions=None,
  revisions=%str(New file.),
  /** File info parameters **/
  printobs=0,
  freqvars=outcome_buyouts
)

