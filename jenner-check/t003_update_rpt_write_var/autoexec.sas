/* cap input rows for the captured run */
options obs=100;

/* The following %macro is copied verbatim from Macros/Update_rpt_write_var.sas
   in this repo. It emits the assignment/output statements that build one row
   of a catalog "update report" for a single variable, comparing the base
   value against the compare value and any exception override. The caller in
   script.sas invokes it once per variable inside a DATA step. */

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

    if missing( &var._Compare ) or &var._DIF = 0 then New_value = "-";
    else New_value = put( &var._Compare, &fmt );

  %end;
  %else %do;

    &var._DIF = compress( &var._DIF, '.' );

    if missing( &var._Compare ) or missing( &var._DIF ) then New_value = "-";
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
