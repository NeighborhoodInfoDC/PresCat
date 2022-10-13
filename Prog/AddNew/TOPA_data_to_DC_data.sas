/**************************************************************************
 Program:  DC_data_to_TOPA_data.sas
 Library:  PresCat
 Project:  Urban-Greater DC
 Author:   Elizabeth Burton
 Created:  9/29/2022
 Version:  SAS 9.4
 Environment:  Local Windows session (desktop)
 
 Description:  Match TOPA database from CNHED to DCData data sets to add characteristics. 
 
 Modifications:
**************************************************************************/

%include "\\sas1\DCdata\SAS\Inc\StdLocal.sas";

** Define libraries **;
%DCData_lib( PresCat )
%DCData_lib( DHCD )
%DCData_lib( MAR )
%DCData_lib( RealProp )

%let dsname="&_dcdata_r_path\PresCat\Raw\TOPA\TOPA_DOPA_5+.csv";
filename fixed temp;
/** Remove carriage return and line feed characters within quoted strings **/
/*'0D'x is the hexadecimal representation of CR and
/*'0A'x is the hexadecimal representation of LF.*/
/* Replace carriage return and linefeed characters inside */
/* double quotes with a specified character.  */
/* CR/LFs not in double quotes will not be replaced. */
%let repA=' || '; /* replacement character LF */
%let repD=' || '; /* replacement character CR */
 data _null_;
 /* RECFM=N reads the file in binary format. The file consists */
 /* of a stream of bytes with no record boundaries. SHAREBUFFERS */
 /* specifies that the FILE statement and the INFILE statement */
 /* share the same buffer. */
 infile &dsname recfm=n sharebuffers;
 file fixed recfm=n;
 /* OPEN is a flag variable used to determine if the CR/LF is within */
 /* double quotes or not. Retain this value. */
 retain open 0;
 input a $char1.;
 /* If the character is a double quote, set OPEN to its opposite value. */
 if a = '"' then open = ^(open);
 /* If the CR or LF is after an open double quote, replace the byte with */
 /* the appropriate value. */
 if open then do;
 if a = '0D'x then put &repD;
 else if a = '0A'x then put &repA;
 else put a $char1.;
 end;
 else put a $char1.;
run;

proc import datafile=fixed
            dbms=csv
            out=TOPA_database
            replace;
		
     getnames=yes;
	 guessingrows=max;
run;

proc print data=TOPA_database (obs=5); 
run; 

%Rcasd_address_parse(
	data=TOPA_database,
	out=TOPA_addresses,
	id=ID,
	addr=All_street_addresses,
	keepin=CASD_Report_week_ending_date Offer_of_Sale_date__usually_DHCD,
	keepout=CASD_Report_week_ending_date Offer_of_Sale_date__usually_DHCD
)

%File_info( data=TOPA_addresses, printobs=40 )

%DC_mar_geocode(
	data=TOPA_addresses,
	staddr=Address,
	out=TOPA_geocoded, 
	geo_match=yes
)

%File_info( data=TOPA_geocoded, printobs=5 )

proc sql noprint;
  create table TOPA_SSL as   /** Name of output data set to be created (Parcel_a) **/
  select
    coalesce( TOPA_geocoded.ADDRESS_ID, Xref.address_id ) as address_id,    /** Matching variables **/
    TOPA_geocoded.ID, /** Other vars you want to keep from the two data sets, separated by commas **/
	TOPA_geocoded.CASD_Report_week_ending_date, TOPA_geocoded.Offer_of_Sale_date__usually_DHCD,
	TOPA_geocoded.Anc2012, TOPA_geocoded.cluster2017, TOPA_geocoded.Geo2020, 
	TOPA_geocoded.GeoBg2020, TOPA_geocoded.GeoBlk2020, TOPA_geocoded.Psa2012,
	TOPA_geocoded.VoterPre2012, TOPA_geocoded.Ward2022, 
    Xref.ssl
    from TOPA_geocoded (where=(not(missing(ADDRESS_ID)))) as TOPA_geocoded
      left join Mar.Address_ssl_xref as xref    /** Left join = only keep obs that are in TOPA_geocoded **/
  on TOPA_geocoded.ADDRESS_ID = Xref.address_id   /** This is the condition you are matching on **/
  order by TOPA_geocoded.ID, Xref.ssl;    /** Optional: sorts the output data set **/
quit;

%File_info( data=TOPA_SSL, printobs=5 )

/*  %Finalize_data_set( */
/*    /** Finalize data set parameters **/*/
/*    data=TOPA_database,*/
/*    out=TOPA_database,*/
/*    outlib=PresCat,*/
/*    label="Preservation Catalog, new DC TOPA dataset",*/
/*    sortby=CHANGE w unique identifier,*/
/*    /** Metadata parameters **/*/
/*    revisions=%str(New data set.),*/
/*    /** File info parameters **/*/
/*    printobs=10 */
/*  )*/
