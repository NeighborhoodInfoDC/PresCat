/**************************************************************************
 Program:  Update_real_property.sas
 Library:  PresCat
 Project:  NeighborhoodInfo DC
 Author:   P. Tatian
 Created:  02/17/18
 Version:  SAS 9.2
 Environment:  Local Windows session (desktop)
 
 Description:  Autocall macro to update PresCat.Real_property.

 Modifications:
**************************************************************************/

%macro Update_real_property( 
  Parcel = PresCat.Parcel,  /** Preservation Catalog Parcel file **/  
  Revisions =               /** Metadata revisions description **/
  );

  %local fcl_keep_vars;
  
  %if %length( &revisions ) = 0 %then %let revisions = %str(Update with latest &Parcel, ROD.Foreclosure, RealProp.Sales, and DHCD.Rcasd_* data.);

  ** Create format for selecting SSLs of Catalog properties **;

  proc sort data=&Parcel out=Parcel_list (keep=ssl) nodupkey;
    by ssl;

  %Data_to_format(
    FmtLib=work,
    FmtName=$sslsel,
    Desc=,
    Data=Parcel_list,
    Value=ssl,
    Label=ssl,
    OtherLabel="",
    DefaultLen=.,
    MaxLen=.,
    MinLen=.,
    Print=N,
    Contents=N
    )


  ** Compile OTR property transaction data **;

  data Transactions;

    set Realprop.Sales_master (keep=ssl saledate saleprice ownername_full acceptcode acceptcode_new);
    where put( ssl, $sslsel. ) ~= "";

    if saledate = '01jan1901'd then saledate = .u;
    
    %Owner_name_clean( Ownername_full, Ownername_full )
    
    length sale_type_desc $ 80;
    
    if acceptcode_new ~= "" then 
      sale_type_desc = put( acceptcode_new, $accptnw. );
    else if acceptcode ~= "" then 
      sale_type_desc = put( acceptcode, $accept. );
    else 
      sale_type_desc = "";
    
    length RP_type $ 40 RP_desc $ 200;
    
    retain sort_order 1 RP_type "OTR/SALE";
    
    RP_desc = "OTR: Sold";
    
    if Ownername_full ~= "" then
      RP_desc = trim( RP_desc ) || " to " || trim( Ownername_full );
    
    if saleprice > 0 then 
      RP_desc = trim( RP_desc ) || "; price: " || left( put( saleprice, dollar20.0 ) );
      
    if sale_type_desc ~= "" then  
      RP_desc = trim( RP_desc ) || "; sale type: " || sale_type_desc;
      
    RP_desc = trim( RP_desc ) || ".";
      
    drop sale_type_desc;

  run;


  ** Compile ROD foreclosure notice records **;
  
  %let fcl_keep_vars = ssl filingdate ui_instrument documentno grantee grantor verified;

  data Foreclosure_notices;

    set 
      Rod.Foreclosures_1997 (keep=&fcl_keep_vars)
      Rod.Foreclosures_1998 (keep=&fcl_keep_vars)
      Rod.Foreclosures_1999 (keep=&fcl_keep_vars)
      Rod.Foreclosures_2000 (keep=&fcl_keep_vars)
      Rod.Foreclosures_2001 (keep=&fcl_keep_vars)
      Rod.Foreclosures_2002 (keep=&fcl_keep_vars)
      Rod.Foreclosures_2003 (keep=&fcl_keep_vars)
      Rod.Foreclosures_2004 (keep=&fcl_keep_vars)
      Rod.Foreclosures_2005 (keep=&fcl_keep_vars)
      Rod.Foreclosures_2006 (keep=&fcl_keep_vars)
      Rod.Foreclosures_2007 (keep=&fcl_keep_vars)
      Rod.Foreclosures_2008 (keep=&fcl_keep_vars)
      Rod.Foreclosures_2009 (keep=&fcl_keep_vars)
      Rod.Foreclosures_2010 (keep=&fcl_keep_vars)
      Rod.Foreclosures_2011 (keep=&fcl_keep_vars)
      Rod.Foreclosures_2012 (keep=&fcl_keep_vars)
      Rod.Foreclosures_2013 (keep=&fcl_keep_vars)
      Rod.Foreclosures_2014 (keep=&fcl_keep_vars)
      Rod.Foreclosures_2015 (keep=&fcl_keep_vars)
      Rod.Foreclosures_2016 (keep=&fcl_keep_vars)
      Rod.Foreclosures_2017 (keep=&fcl_keep_vars)
    ; 
    
    where put( ssl, $sslsel. ) ~= "";
    
    %Owner_name_clean( grantee, grantee )
    %Owner_name_clean( grantor, grantor )
    
    length verified_desc $ 40;
    
    if not verified then verified_desc = " (UNVERIFIED)";
    else verified_desc = "";
    
    length RP_type $ 40 RP_desc $ 200;
    
    retain sort_order 2 RP_type "ROD/FCLNOT";

    RP_desc = "ROD: " || trim( put( ui_instrument, $uinstr. ) ) || 
      " (" || trim( documentno ) || ")" ||
      /**** "; issued to " || trim( grantee ) || ****/
      "; issued by " || trim( grantor ) || 
      trim( compbl( verified_desc ) );

    RP_desc = trim( RP_desc ) || ".";
    
    fcl_rel_notice = 1;
    
  run;

  proc sort data=Foreclosure_notices;
    by ssl descending filingdate;
  run;


  ** Get foreclosure outcomes from Realprop.Sales_master_forecl **;
  ** Only use foreclosure sale and distressed sale outcomes **;

  data Foreclosure_outcomes;

    set Realprop.Sales_master_forecl;
    
    where put( ssl, $sslsel. ) ~= "";
    
    length RP_type $ 40 RP_desc $ 200;
    
    retain sort_order 3 RP_type "NIDC/FCLOUT";
    
    array a_end{*} episode1_end episode2_end episode3_end episode4_end episode5_end;
    array a_out{*} episode1_outcome2 episode2_outcome2 episode3_outcome2 episode4_outcome2 episode5_outcome2;
    
    do i = 1 to dim( a_end );
    
      if a_end{i} >= 0 and a_out{i} in ( 2, 3, 4, 5 ) then do;

        episode_num = i;
        episode_end = a_end{i};
        episode_outcome2 = a_out{i};
        
        RP_desc = "NIDC: " || trim( put( a_out{i}, outcomii. ) ) || ".";
        
        if a_out{i} in ( 2, 3 ) then fcl_sale = 1;
        else if a_out{i} in ( 4, 5 ) then distr_sale = 1;
        
        output;

      end;
      
    end;
      
    keep ssl episode_num episode_end episode_outcome2 sort_order RP_type RP_desc;
    
  run;


  ** Compile DHCD RCASD notice data **;

  data Rcasd_notices;

    length RP_type $ 40 RP_desc $ 200;
    
    retain sort_order 4 RP_type "DHCD/RCASD";
    
    set 
      Dhcd.Rcasd_2015
      Dhcd.Rcasd_2016
	  Dhcd.Rcasd_2017
	  Dhcd.Rcasd_2018;
    by nidc_rcasd_id;
    
    where put( ssl, $sslsel. ) ~= "";
    
    if first.nidc_rcasd_id;
    
    RP_desc = 'RCASD: ' || put( Notice_type, $rcasd_notice_type. );
    
    if num_units > 0 then 
      RP_desc = trim( RP_desc ) || '; units: ' || left( put( num_units, comma8.0 ) );
    
    if sale_price > 0 then 
      RP_desc = trim( RP_desc ) || '; price: ' || left( put( sale_price, dollar12.0 ) );
    
    RP_desc = trim( RP_desc ) || '.';
    
    rename notice_date=RP_date;
    
    keep ssl notice_date rp_type rp_desc;
    
  run;

  proc sort data=Rcasd_notices nodupkey;
    by ssl descending rp_date rp_type;
  run;


  ** Combine all real property events **;

  data Realproperty_events;

    set 
      Foreclosure_notices 
        (keep=ssl filingdate sort_order RP_type RP_desc ui_instrument 
         rename=(filingdate=RP_date))
      Transactions 
        (keep=ssl saledate sort_order RP_type RP_desc 
         rename=(saledate=RP_date))
      Foreclosure_outcomes
         (rename=(episode_end=RP_date))
      Rcasd_notices;
    
    if missing( RP_date ) then delete;
    
    label
      RP_type = 'Real property event, type'
      RP_desc = 'Real property event, description';
    
    format RP_type $rptype.;
    
    drop episode_: ui_instrument;
    
  run;


  ** Add NLIHC_ID to data (NB: can have multiple parcels) **;

  proc sql noprint;
    create table Real_property (label="Preservation Catalog, Real property events" drop=sort_order) as
    select * from &Parcel (keep=ssl nlihc_id) as Parcel right join Realproperty_events as Tran
    on Parcel.ssl = Tran.ssl
    order by Nlihc_id, RP_date desc, sort_order desc;


  ** Finalize data set **;
  
  %Finalize_data_set(
    data=Real_property,
    out=Real_property,
    outlib=PresCat,
    label="Preservation Catalog, Real property events",
    sortby=nlihc_id descending rp_date rp_type,
    revisions=%str(&revisions),
    archive=y,
    printobs=0,
    freqvars=rp_type 
  )

%mend Update_real_property;

/** End Macro Definition **/

