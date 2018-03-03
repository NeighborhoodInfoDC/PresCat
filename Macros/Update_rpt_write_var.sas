/**************************************************************************
 Program:  Update_rpt_write_var.sas
 Library:  PresCat
 Project:  NeighborhoodInfo DC
 Author:   P. Tatian
 Created:  07/19/15
 Version:  SAS 9.2
 Environment:  Local Windows session (desktop)
 
 Description:  Autocall macro to write variable info to update report. 

 Modifications:
**************************************************************************/

/** Macro Update_rpt_write_var - Start Definition **/

%macro Update_rpt_write_var( var=, fmt=comma8.0, lbl=, typ=n, except=y );

  %if &lbl = %then %do;
    Var = "&var";
  %end;
  %else %do;
    Var = &lbl;
  %end;
  
  Old_value = put( &var._Base, &fmt );
  
  %if %upcase( &typ ) = N %then %do;
  
    if missing( &var._Compare ) then New_value = "-";
    else New_value = put( &var._Compare, &fmt );
    
  %end;
  %else %do;
  
    &var._DIF = compress( &var._DIF, '.' );
  
    if missing( &var._Compare ) then New_value = "-";
    else New_value = put( &var._Compare, &fmt );
    
  %end;
  
  %if %upcase( &except ) = Y %then %do;
  
    if missing( &var._EXCEPT ) then Except_value = "-";
    else Except_value = put( &var._EXCEPT, &fmt );
    
    if New_value ~= "-" or Except_value ~= "-" then output;
    
  %end;
  %else %do;
  
    Except_value = "n/a";
    if New_value ~= "-" then output;
    
  %end;

%mend Update_rpt_write_var;

/** End Macro Definition **/

