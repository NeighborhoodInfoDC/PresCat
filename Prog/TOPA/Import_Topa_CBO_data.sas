/**************************************************************************
 Program:  Import_Topa_CBO_data.sas
 Library:  Prescat
 Project:  Urban-Greater DC
 Author:   P. Tatian
 Created:  07/18/23
 Version:  SAS 9.4
 Environment:  Local Windows session (desktop)
 GitHub issue:  388
 
 Description:  Import TOPA data from CBOs.

 Modifications:
**************************************************************************/

%include "\\sas1\DCdata\SAS\Inc\StdLocal.sas";

** Define libraries **;
%DCData_lib( Prescat )

/** Macro Read_data - Start Definition **/

%macro Read_data( file_suffix= );

  %local file_base;
  %let file_base = Topa_CBO_sheet 4.28.23_with_var_names;

  ** Download and read TOPA dataset into SAS dataset**;
  %let dsname="&_dcdata_r_path\PresCat\Raw\TOPA\&file_base._&file_suffix..csv";
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

  proc import out=Topa_CBO_sheet_&file_suffix
      datafile=fixed
      dbms=csv replace;
    datarow=3;
    getnames=yes;
    guessingrows=max;
  run;

  filename fixed clear;

  data Topa_CBO_sheet_&file_suffix;

    set Topa_CBO_sheet_&file_suffix;
    where not( missing( id ) );

    id_num = input( id, 12.0 );
    
    drop id;
    rename id_num=id;
    
    u_notice_date_num = input( u_notice_date, anydtdte20. );
    
    drop u_notice_date;
    rename u_notice_date_num=u_notice_date;
    
    %if %lowcase( &file_suffix ) = without_sales %then %do;
    
      length cbo_unit_count_char $ 7;
    
      cbo_unit_count_char = left( put( cbo_unit_count, 7.0 ) );
      
      drop cbo_unit_count;
      rename cbo_unit_count_char=cbo_unit_count;
      
    %end;
   
    format _all_ ;
    informat _all_ ;
    
    format u_sale_date u_notice_date_num mmddyy10.;
    
    drop VAR: drop: ;
    /*rename id_num=id u_notice_date_num=u_notice_date;*/

  run;
  
  proc sort data=Topa_CBO_sheet_&file_suffix;
    by id;
  run;
  
  %File_info( data=Topa_CBO_sheet_&file_suffix, printobs=5 )

%mend Read_data;

/** End Macro Definition **/


%Read_data( file_suffix=with_sales )

%Read_data( file_suffix=without_sales )

%Read_data( file_suffix=sales_2021_2022 )


** Combine data sets **;

data Topa_CBO_sheet;

  length cbo_complete $ 40 r_ta_provider r_ta_lawyer $ 80 add_notes data_notes $ 600;

  set 
    Topa_CBO_sheet_with_sales (in=in1)
    Topa_CBO_sheet_without_sales (in=in2)
    Topa_CBO_sheet_sales_2021_2022;
  by id;
  
  length Source_sheet $ 24;
  
  if in1 then Source_sheet = "WITH SALES";
  else if in2 then Source_sheet = "WITHOUT SALES";
  else Source_sheet = "SALES IN 2021 AND 2022";
   
run;

%File_info( data=Topa_CBO_sheet, printobs=0, freqvars=Source_sheet )

proc print data=Topa_CBO_sheet;
  where missing( u_notice_date );
  id id;
  var source_sheet all_street_addresses property_name;
run;
