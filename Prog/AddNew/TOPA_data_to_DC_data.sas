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

%let dsname="\\sas1\dcdata\Libraries\PresCat\Raw\TOPA\TOPA_DOPA_5+.csv";
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

proc print data=TOPA_database; 
run; 

%Rcasd_address_parse(
	data=TOPA_database,
	out=TOPA_addresses,
	id=ID,
	addr=All_street_addresses,
	keepin=CASD_Report_week_ending_date Offer_of_Sale_date__usually_DHCD
)

proc print data=TOPA_addresses; 
run; 

%DC_mar_geocode(
	data=TOPA_addresses,
	staddr=Address,
	out=TOPA_geocoded, 
	geo_match=yes
)

proc print data=TOPA_geocoded; 
run; 

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
