/* cap input rows for the captured run */
options obs=100;

/* The following %macro is copied verbatim from Macros/DCInfo_corrections.sas
   in this repo. It applies hand-entered corrections to catalog records
   (reassigning a duplicated NLIHC_ID and fixing a known unit count/category)
   and is meant to be invoked inside a DATA step. The caller in script.sas
   supplies a small set of records covering exactly the rows it corrects. */

/** Macro Corrections - Start Definition **/

%macro DCInfo_corrections(  );

  ** Assign new NLIHC_ID to St. Dennis (duplicate ID with CEMI - Bethune House) **;

  if NLIHC_ID = "NL001007" and upcase( Proj_Name ) = "ST. DENNIS" then
    NLIHC_ID = "NL001030";

  if NLIHC_ID = "NL000046" then do;
    units = 535;
    Category = "1";
  end;

%mend DCInfo_corrections;

/** End Macro Definition **/
