/**************************************************************************
 Program:  TOPA_add_subsidies.sas
 Library:  PresCat
 Project:  Urban-Greater DC
 Author:   Elizabeth Burton
 Created:  7/18/2023
 Version:  SAS 9.4
 Environment:  Local Windows session (desktop)
 
 Description:  Add LIHTC, federal project-based subsidies, DC HPTF, and LEC data from PresCat.Subsidy to TOPA notices
 
 Modifications:
**************************************************************************/

%include "\\sas1\DCdata\SAS\Inc\StdLocal.sas";

** Define libraries **;
%DCData_lib( PresCat )

%File_info( data=PresCat.Subsidy, printobs=5 )
%File_info( data=PresCat.TOPA_addresses, printobs=5 )
%File_info( data=PresCat.Building_geocode, printobs=5 )
%File_info( data=PresCat.Topa_notices_sales, printobs=5 )

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

%File_info( data=TOPA_nlihc_id, printobs=10 )

** Add TOPA notice and sale dates to TOPA_nlihc_id **; 
proc sql noprint;
  create table TOPA_nlihc_dates as
  select unique 
  	coalesce( TOPA_nlihc_id.ID, Topa_notices_sales.ID ) as ID, /** Matching variables **/
	TOPA_nlihc_id.u_address_id_ref, TOPA_nlihc_id.FULLADDRESS, TOPA_nlihc_id.Nlihc_id, TOPA_nlihc_id.Bldg_addre, /** Other vars keeping **/
	Topa_notices_sales.u_sale_date, Topa_notices_sales.u_notice_date, Topa_notices_sales.u_sum_units
	from TOPA_nlihc_id left join PresCat.Topa_notices_sales as Topa_notices_sales   /** Left join = only keep obs that are in TOPA_addresses**/ 
  on TOPA_nlihc_id.ID = Topa_notices_sales.ID   /** Matching on address_ID **/
  order by TOPA_nlihc_id.ID;    /** Sorting by notice ID **/
quit; 

%File_info( data=TOPA_nlihc_dates, printobs=10 )

** Match TOPA_nlihc_id with PresCat.Subsidy **;
proc sql noprint; 
  create table TOPA_subsidy_match as
  select unique
    coalesce ( TOPA_nlihc_dates.Nlihc_id, Subsidy.Nlihc_id ) as Nlihc_id, /** Matching variables **/
	TOPA_nlihc_dates.ID, TOPA_nlihc_dates.u_address_id_ref, TOPA_nlihc_dates.FULLADDRESS, /** Other vars keeping **/
	TOPA_nlihc_dates.u_sale_date, TOPA_nlihc_dates.u_notice_date, TOPA_nlihc_dates.u_sum_units,
	Subsidy.POA_end, Subsidy.POA_end_actual, Subsidy.POA_end_prev,
	Subsidy.POA_start, Subsidy.POA_start_orig, Subsidy.Portfolio, 
	Subsidy.Program, Subsidy.Units_Assist, Subsidy.rent_to_fmr_description, Subsidy.Subsidy_id
  from TOPA_nlihc_dates left join PresCat.Subsidy as Subsidy /** Left join = only keep obs that are in TOPA_nlihc_id**/
  on TOPA_nlihc_dates.Nlihc_id = Subsidy.Nlihc_id
  order by TOPA_nlihc_dates.ID; 
quit; 

%File_info( data=TOPA_subsidy_match, printobs=10 )

** Creating all_POA_start, actual_POA_start, and u_days_notice_to_subsidy, filtering out unneeded obs**; 

data TOPA_subsidy; 
  set TOPA_subsidy_match; 
  format all_POA_start MMDDYY10.;
  format actual_POA_start DYESNO.;
  if not(missing(POA_start_orig)) then do;
	all_POA_start=POA_start_orig;
	actual_POA_start=1;
		end;
  else if (missing(POA_start_orig)) then do; 
    all_POA_start=POA_start_orig;
	actual_POA_start=0;
		end;
  label all_POA_start='Period of affordability, original start date or if original date missing, period of affordability, current start date';
  label actual_POA_start='Original start date used';
  u_days_notice_to_subsidy = all_POA_start - u_sale_date;
  label u_days_notice_to_subsidy='Number of days from property sale date to start of subsidy (Urban created var)';
  if not(missing(all_POA_start)); ** delete missing subsidy start dates **; 
  if portfolio in ("LIHTC", "202/811", "PB8", "PRAC", "DC HPTF", "LECOOP"); ** only include LIHTC, federal project-based subsidies, DC HPTF, and LEC **;
  if portfolio = "LIHTC" and u_days_notice_to_subsidy < 0 then before_LIHTC_aff_units=Units_Assist;
  if portfolio in ( "202/811", "PB8", "PRAC" ) and u_days_notice_to_subsidy < 0 then before_fed_aff_units=Units_Assist;
  if portfolio = "DC HPTF" and u_days_notice_to_subsidy < 0 then before_DC_HPTF_aff_units=Units_Assist;
  if portfolio = "LECOOP" and u_days_notice_to_subsidy < 0 then before_LEC_aff_units=Units_Assist;
run;

%File_info( data=TOPA_subsidy, printobs=10 )

data TOPA_subsidy_after; 
  set TOPA_subsidy;
  if portfolio = "LIHTC" then 
	if missing(poa_end_actual) and 0 <= u_days_notice_to_subsidy <= 730 and not(missing(before_LIHTC_aff_units)) then after_LIHTC_aff_units=Units_Assist+before_LIHTC_aff_units;
	else if missing(poa_end_actual) and 0 <= u_days_notice_to_subsidy <= 730 and missing(before_LIHTC_aff_units) then after_LIHTC_aff_units=Units_Assist;
	else if missing(poa_end_actual) and u_days_notice_to_subsidy <0 or u_days_notice_to_subsidy > 0 then after_LIHTC_aff_units=before_LIHTC_aff_units;
	else if not(missing(poa_end_actual)) and poa_end_actual-u_sale_date <= 365 then after_LIHTC_aff_units=.;
	else after_LIHTC_aff_units=Units_Assist;

  if portfolio in ( "202/811", "PB8", "PRAC" ) then 
	if missing(poa_end_actual) and 0 <= u_days_notice_to_subsidy <= 730 and not(missing(before_fed_aff_units)) then after_fed_aff_units=Units_Assist+before_fed_aff_units;
	else if missing(poa_end_actual) and 0 <= u_days_notice_to_subsidy <= 730 and missing(before_fed_aff_units) then after_fed_aff_units=Units_Assist;
	else if missing(poa_end_actual) and u_days_notice_to_subsidy <0 or u_days_notice_to_subsidy > 0 then after_fed_aff_units=before_fed_aff_units;
	else if not(missing(poa_end_actual)) and poa_end_actual-u_sale_date <= 365 then after_fed_aff_units=.;
	else after_fed_aff_units=Units_Assist;

  if portfolio = "DC HPTF" then 
	if missing(poa_end_actual) and 0 <= u_days_notice_to_subsidy <= 730 and not(missing(before_DC_HPTF_aff_units)) then after_DC_HPTF_aff_units=Units_Assist+before_DC_HPTF_aff_units;
	else if missing(poa_end_actual) and 0 <= u_days_notice_to_subsidy <= 730 and missing(before_DC_HPTF_aff_units) then after_DC_HPTF_aff_units=Units_Assist;
	else if missing(poa_end_actual) and u_days_notice_to_subsidy <0 or u_days_notice_to_subsidy > 0 then after_DC_HPTF_aff_units=before_DC_HPTF_aff_units;
	else if not(missing(poa_end_actual)) and poa_end_actual-u_sale_date <= 365 then after_DC_HPTF_aff_units=.;
	else after_DC_HPTF_aff_units=Units_Assist;

  if portfolio = "LECOOP" then 
	if missing(poa_end_actual) and 0 <= u_days_notice_to_subsidy <= 730 and not(missing(before_LEC_aff_units)) then after_LEC_aff_units=Units_Assist+before_LEC_aff_units;
	else if missing(poa_end_actual) and 0 <= u_days_notice_to_subsidy <= 730 and missing(before_LEC_aff_units) then after_LEC_aff_units=Units_Assist;
	else if missing(poa_end_actual) and u_days_notice_to_subsidy <0 or u_days_notice_to_subsidy > 0 then after_LEC_aff_units=before_LEC_aff_units;
	else if not(missing(poa_end_actual)) and poa_end_actual-u_sale_date <= 365 then after_LEC_aff_units=.;
	else after_LEC_aff_units=Units_Assist;
run; 

%File_info( data=TOPA_subsidy_after, printobs=10 )


proc sort data=Topa_subsidy_after;
  by u_address_id_ref u_notice_date;
run;

title2 '** Only units before **';
proc print data=Topa_subsidy_after (obs=50);
  where portfolio = 'LIHTC' and before_LIHTC_aff_units > 0 and after_LIHTC_aff_units in ( 0, . );
  by u_address_id_ref;
  id id;
  var u_notice_date u_sale_date u_days_notice_to_subsidy portfolio poa_start_orig poa_start poa_end_actual units_assist before_LIHTC_aff_units after_LIHTC_aff_units;
  format portfolio ;
run;
title2 '** Only units after **';
proc print data=Topa_subsidy_after (obs=50);
  where portfolio = 'LIHTC' and before_LIHTC_aff_units in ( 0, . ) and after_LIHTC_aff_units > 0;
  by u_address_id_ref;
  id id;
  var u_notice_date u_sale_date u_days_notice_to_subsidy portfolio poa_start_orig poa_start poa_end_actual units_assist before_LIHTC_aff_units after_LIHTC_aff_units;
  format portfolio ;
run;
title2 '** Units before & after **';
proc print data=Topa_subsidy_after (obs=50);
  where portfolio = 'LIHTC' and before_LIHTC_aff_units > 0 and after_LIHTC_aff_units > 0;
  by u_address_id_ref;
  id id;
  var u_notice_date u_sale_date u_days_notice_to_subsidy portfolio poa_start_orig poa_start poa_end_actual units_assist before_LIHTC_aff_units after_LIHTC_aff_units;
  format portfolio ;
run;
title2 '** LIHTC with missing u_days_notice_to_subsidy **';
proc print data=Topa_subsidy_after (obs=50);
  where portfolio = 'LIHTC' and missing( u_days_notice_to_subsidy );
  by u_address_id_ref;
  id id;
  var u_notice_date u_sale_date u_days_notice_to_subsidy portfolio poa_start_orig poa_start poa_end_actual units_assist before_LIHTC_aff_units after_LIHTC_aff_units;
  format portfolio ;
run;

**Aggregating the data across rows with the same ID **;

proc summary data=TOPA_subsidy_after nway
 noprint;
 var before_LIHTC_aff_units after_LIHTC_aff_units before_fed_aff_units after_fed_aff_units before_DC_HPTF_aff_units 
	after_DC_HPTF_aff_units before_LEC_aff_units after_LEC_aff_units;
 class id;
 output out=TOPA_sum_rows
	sum=;
 label before_LIHTC_aff_units='Subsidy assisted units from the Low Income Housing Tax Credit before property sale date (Urban created var)';
 label after_LIHTC_aff_units='Subsidy assisted units from the Low Income Housing Tax Credit after property sale date (Urban created var)';
 label before_fed_aff_units='Federal subsidy assisted units (Project based vouchers, Section 202/811, project rental assistance contract) before property sale date (Urban created var)';
 label after_fed_aff_units='Federal subsidy assisted units (Project based vouchers, Section 202/811, project rental assistance contract) after property sale date (Urban created var)';
 label before_DC_HPTF_aff_units='Subsidy assisted units from the DC Housing Production Trust Fund before property sale date (Urban created var)';
 label after_DC_HPTF_aff_units='Subsidy assisted units from the DC Housing Production Trust Fund after property sale date (Urban created var)';
 label before_LEC_aff_units='Affordable units formed from Limited-Equity Cooperatives before property sale date (Urban created var)';
 label after_LEC_aff_units='Affordable units formed from Limited-Equity Cooperatives after property sale date (Urban created var)';
 label ID='CNHED database unique notice ID';
run;

%File_info( data=TOPA_sum_rows, printobs=50)


%Finalize_data_set( 
/** Finalize data set parameters **/
  data=TOPA_sum_rows,
  out=TOPA_subsidies,
  outlib=PresCat,
  label="Preservation Catalog, Project Subsidies for TOPA notices",
  sortby=ID,
  /** Metadata parameters **/
  revisions=%str(&revisions),
  /** File info parameters **/
  printobs=10
)

