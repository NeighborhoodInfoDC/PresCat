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

%File_info( data=TOPA_subsidy_match, printobs=100 )

** Creating all_POA_start, actual_POA_start, and u_days_notice_to_subsidy, filtering out unneeded obs**; 

data TOPA_subsidy; 
  set TOPA_subsidy_match; 
  format all_POA_start MMDDYY10.;
  format actual_POA_start DYESNO.;
  format date_LEC_form MMDDYY10.;
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
  label u_days_notice_to_subsidy='Number of days from notice of sale to start of subsidy (Urban created var)';
  if not(missing(all_POA_start)); ** delete missing subsidy start dates **; 
  if portfolio in ("LIHTC", "202/811", "PB8", "PRAC", "DC HPTF", "LECOOP"); ** only include LIHTC, federal project-based subsidies, DC HPTF, and LEC **;
  if portfolio = "LIHTC" and u_days_notice_to_subsidy < 0 then before_LIHTC_aff_units=Units_Assist;
  if portfolio = "LIHTC" and 0 <= u_days_notice_to_subsidy <= 365 then after_LIHTC_aff_units=Units_Assist;
  if portfolio in ( "202/811", "PB8", "PRAC" ) and u_days_notice_to_subsidy < 0 then before_fed_aff_units=Units_Assist;
  if portfolio in ( "202/811", "PB8", "PRAC" ) and 0 <= u_days_notice_to_subsidy <= 365 then after_fed_aff_units=Units_Assist;
  if portfolio = "DC HPTF" and u_days_notice_to_subsidy < 0 then before_DC_HPTF_aff_units=Units_Assist;
  if portfolio = "DC HPTF" and 0 <= u_days_notice_to_subsidy <= 365 then after_DC_HPTF_aff_units=Units_Assist;
  if portfolio = "LECOOP" and u_days_notice_to_subsidy < 0 then before_LEC_aff_units=Units_Assist;
  if portfolio = "LECOOP" and 0 <= u_days_notice_to_subsidy <= 365 then after_LEC_aff_units=Units_Assist;
run;

%File_info( data=TOPA_subsidy, printobs=10 )

proc sort data=TOPA_subsidy;
  by id POA_start_orig;
run;

** To do on data step: 
	1) Add if not(missing(poa_end_actual)) and u_sale_date-poa_end_actual < 365 then delete
	2) Retain all prev ids across subsidies that aren't last.id and add them to total IDs, ex. ID 318 where fed subsidy before LIHTC subsidy
	3) Join data by ID for one obs per ID **;

data TOPA_test; 
  set TOPA_subsidy; 
  by id POA_start_orig;
  if first.ID then do;
	prev_LIHTC_units=.; prev_fed_units=.; prev_DC_HPTF_units=.; prev_LEC_units=.; 
  end;
  if first.ID and ID=ID then do;
	prev_LIHTC_units=before_LIHTC_aff_units; prev_fed_units=before_fed_aff_units; prev_DC_HPTF_units=before_DC_HPTF_aff_units;
	prev_LEC_units=before_LEC_aff_units; 
  end; 
  retain prev_LIHTC_units;
  retain prev_fed_units;
  retain prev_DC_HPTF_units;
  retain prev_LEC_units;

  if last.id and portfolio="LIHTC" then
	if not(missing(after_LIHTC_aff_units)) and not(missing(prev_LIHTC_units)) then total_LIHTC_aff_units=prev_LIHTC_units+after_LIHTC_aff_units;
	else if missing(after_LIHTC_aff_units) then total_LIHTC_aff_units=prev_LIHTC_units;
	else total_LIHTC_aff_units=after_LIHTC_aff_units;
  
  if last.id and portfolio in ( "202/811", "PB8", "PRAC" ) then
    if not(missing(after_fed_aff_units)) and not(missing(prev_fed_units)) then total_fed_aff_units=prev_fed_units+after_fed_aff_units;
	else if missing(after_fed_aff_units) then total_fed_aff_units=prev_fed_units;
    else total_fed_aff_units=after_fed_aff_units;

  if last.id and portfolio = "DC HPTF" then
    if not(missing(after_DC_HPTF_aff_units)) and not(missing(prev_DC_HPTF_units)) then total_DC_HPTF_aff_units=prev_DC_HPTF_units+after_DC_HPTF_aff_units;
	else if missing(after_DC_HPTF_aff_units) then total_DC_HPTF_aff_units=prev_DC_HPTF_units;
    else total_DC_HPTF_aff_units=after_DC_HPTF_aff_units;

  if last.id and portfolio = "LECOOP" then
    if not(missing(after_LEC_aff_units)) and not(missing(prev_LEC_units)) then total_LEC_aff_units=prev_LEC_units+after_fed_aff_units;
	else if missing(after_LEC_aff_units) then total_LEC_aff_units=prev_LEC_units;
  	else total_LEC_aff_units=after_LEC_aff_units;
run; 

%File_info( data=TOPA_test, printobs=193 )

proc sql;
  create table TOPA_test2 as
  select ID, 
            sum(before_LIHTC_aff_units) as before_LIHTC_aff_units,
            sum(after_LIHTC_aff_units) as after_LIHTC_aff_units,
            sum(before_fed_aff_units) as before_fed_aff_units,
            sum(after_fed_aff_units) as after_fed_aff_units,
            sum(before_DC_HPTF_aff_units) as before_DC_HPTF_aff_units,
            sum(after_DC_HPTF_aff_units) as after_DC_HPTF_aff_units,
            sum(before_LEC_aff_units) as before_LEC_aff_units,
            sum(after_LEC_aff_units) as after_LEC_aff_units
  from   TOPA_subsidy
  group by ID;
quit;

%File_info( data=TOPA_test2, printobs=138 )


%Finalize_data_set( 
/** Finalize data set parameters **/
  data=,
  out=,
  outlib=PresCat,
  label="",
  sortby=ID,
  /** Metadata parameters **/
  revisions=%str,
  /** File info parameters **/
  printobs=10,
  freqvars=
)

