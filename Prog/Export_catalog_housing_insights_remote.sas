/**************************************************************************
 Program:  Export_catalog_housing_insights_remote.sas
 Library:  PresCat
 Project:  NeighborhoodInfo DC
 Author:   P. Tatian
 Created:  11/15/2017
 Version:  SAS 9.4
 Environment:  Remote Windows session (SAS1)
 
 Description:  Export all PresCat data sets to CSV files, with  
 data dictionary, for Housing Insights.

 Modifications:
**************************************************************************/

%include "F:\DCData\SAS\Inc\StdRemote.sas";

** Define libraries **;
%DCData_lib( PresCat )
%DCData_lib( RealProp )

options msglevel=n;


/** Macro Export - Start Definition **/

%macro Export( data=, out=, desc=, where= );

  %local lib file;
  
  %if %scan( &data, 2, . ) = %then %do;
    %let lib = work;
    %let file = &data;
  %end;
  %else %do;
    %let lib = %scan( &data, 1, . );
    %let file = %scan( &data, 2, . );
  %end;

  %if &out = %then %let out = &file;
  
  %if %length( &desc ) = 0 %then %do;
    proc sql noprint;
      select memlabel into :desc from dictionary.tables
        where upcase(libname)=upcase("&lib") and upcase(memname)=upcase("&file");
      quit;
    run;
  %end;

  filename fexport "&out_folder\&out..csv" lrecl=2000;

  proc export data=&data
  %if %length( &where ) > 0 %then %do;
    (where=(&where))
  %end;
      outfile=fexport
      dbms=csv replace;

  run;
  
  filename fexport clear;

  proc contents data=&data out=_cnt_&out (keep=varnum name label label="&desc") noprint;

  proc sort data=_cnt_&out;
    by varnum;
  run;      
  
  %let file_list = &file_list &out;

%mend Export;

/** End Macro Definition **/


/** Macro Dictionary - Start Definition **/

%macro Dictionary( );

  %local desc;

  ** Start writing to XML workbook **;
    
  ods listing close;

  ods tagsets.excelxp file="&out_folder\Data dictionary.xls" style=Normal 
      options( sheet_interval='Proc' orientation='landscape' );

  ** Write data dictionaries for all files **;

  %local i k;

  %let i = 1;
  %let k = %scan( &file_list, &i, %str( ) );

  %do %until ( &k = );
   
    proc sql noprint;
      select memlabel into :desc from dictionary.tables
        where upcase(libname)="WORK" and upcase(memname)=upcase("_cnt_&k");
      quit;
    run;

    ods tagsets.excelxp 
        options( sheet_name="&k" 
                 embedded_titles='yes' embedded_footnotes='yes' 
                 embed_titles_once='yes' embed_footers_once='yes' );

    proc print data=_cnt_&k label;
      id varnum;
      var name label;
      label 
        varnum = 'Col #'
        name = 'Name'
        label = 'Description';
      title1 bold "Data dictionary for file: &k..csv";
      title2 bold "&desc";
      title3 height=10pt "Prepared by Urban-Greater DC on %left(%qsysfunc(date(),worddate.)).";
      footnote1;
    run;

    %let i = %eval( &i + 1 );
    %let k = %scan( &file_list, &i, %str( ) );

  %end;

  ** Close workbook **;

  ods tagsets.excelxp close;
  ods listing;

  run;
  
%mend Dictionary;

/** End Macro Definition **/


**** Create TOPA outcome data set ****;

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
  create table Project_TOPA_outcomes_full as
  select unique
    TOPA_nlihc_id.id, TOPA_nlihc_id.nlihc_id, Table_dat.*
    from TOPA_nlihc_id 
    left join PresCat.TOPA_table_data as Table_dat
    on TOPA_nlihc_id.id = Table_dat.id
    where Table_dat.u_dedup_notice
    order by TOPA_nlihc_id.nlihc_id, u_notice_date;
quit;

** Create export data set **;

data Project_TOPA_outcomes (label="Preservation Catalog, TOPA outcomes for projects");

  retain
    nlihc_id u_notice_date u_sale_date has_topa_outcome d_cbo_dhcd_received_ta_reg TA_assign_rights d_le_coop d_purch_condo_coop d_other_condo 
    d_lihtc d_dc_hptf d_dc_other d_fed_aff d_rent_control d_affordable d_100pct_afford 
    d_rehab d_cbo_involved;

  set Project_TOPA_outcomes_full;
  by nlihc_id;
  
  if last.nlihc_id;
  
  has_topa_outcome = 1;
  
  if outcome_buyouts = "100%" then d_buyout_100 = 1;
  else d_buyout_100 = 0;
  
  if outcome_buyouts = "Partial/Option" then d_buyout_partial = 1;
  else d_buyout_partial = 0;
  
  format has_topa_outcome d_buyout: dyesno.;
  
  ** Fix irregular value **;
  if TA_assign_rights = "Purchase" then TA_assign_rights = " ";
  
  label
    u_notice_date = "Date of TOPA notice of sale"
    u_sale_date = "Date of property sale (if sold)"
    TA_assign_rights = "Tenant association assigned rights"
    has_topa_outcome = "Has TOPA outcome reported"
    d_buyout_100 = "100% buyout"
    d_buyout_partial = "Partial buyout";
  
  keep 
    nlihc_id u_notice_date u_sale_date has_topa_outcome d_cbo_dhcd_received_ta_reg TA_assign_rights d_le_coop d_purch_condo_coop d_other_condo 
    d_lihtc d_dc_hptf d_dc_other d_fed_aff d_rent_control d_affordable d_100pct_afford 
    d_rehab d_cbo_involved d_buyout_100 d_buyout_partial;
    
run;

proc freq data=Project_TOPA_outcomes;
  tables TA_assign_rights;
  format TA_assign_rights ;
run;

** Export data **;

%global file_list out_folder;

** DO NOT CHANGE - This initializes the file_list macro variable **;
%let file_list = ;

%let dtfolder = %sysfunc( putn( %sysfunc( today() ), yymmdd10. ) );

** Fill in the folder location where the export files should be saved **;
%let out_folder = &_dcdata_default_path\PresCat\Raw\Housing Insights\&dtfolder;

options noxwait;
x "md ""&out_folder""";

** Reformat owner types with shorter labels **;

proc format;
  value $OwnCat
    '010' = 'Homeowner'
    '020' = 'Resident owner'
    '030' = 'Other individuals'
    '040' = 'DC government'
    '050' = 'US government'
    '060' = 'Foreign government'
    '070' = 'Quasi-public'
    '080' = 'Community organization'
    '090' = 'Educational institution'
    '100' = 'Religious organization'
    '110' = 'Corporation/LLC'
    '111' = 'Non-profit'
    '115' = 'For-profit'
    '120' = 'GSE'
    '130' = 'Financial institution'
  ;
	
run;
    

** Export individual data sets **;
%Export( data=PresCat.Project_category_view, out=Project, desc=%str(DC Preservation Catalog, Projects) )
%Export( data=PresCat.Subsidy, where=subsidy_active )
%Export( data=PresCat.Parcel )
%Export( data=PresCat.Reac_score ) 
%Export( data=PresCat.Real_property )
%Export( data=PresCat.Building_geocode )
%Export( data=PresCat.Project_geocode )
%Export( data=Project_TOPA_outcomes )

** Create data dictionary **;
%Dictionary()

run;
