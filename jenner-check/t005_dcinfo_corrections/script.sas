/**************************************************************************
 Caller for the repo's %DCInfo_corrections autocall macro
 (Macros/DCInfo_corrections.sas). The macro carries two hand-entered fixes:
 St. Dennis carries the duplicate ID NL001007 (shared with Bethune House) and
 is reassigned to NL001030, and NL000046's unit count and category are set to
 their known-correct values (535 units, category 1).

 We feed it four records: the two rows it targets, a lookalike that shares
 NL001007 but is NOT St. Dennis (must be left alone), and an unrelated row.
 The before/after print shows only the intended rows change.
**************************************************************************/

data catalog_raw;
  length NLIHC_ID $ 16 Proj_Name $ 40 Category $ 1 units 8;
  input NLIHC_ID $ Proj_Name $char40. Category $ units;
  datalines;
NL001007 St. Dennis                              5 40
NL001007 Bethune House                           5 60
NL000046 Edgewood Terrace                        4 500
NL000093 Brookland Manor                         2 535
;
run;

data catalog_corrected;
  set catalog_raw;
  %DCInfo_corrections()
run;

proc print data=catalog_raw noobs label;
  var NLIHC_ID Proj_Name Category units;
  label NLIHC_ID = "ID (before)" Proj_Name = "Project";
  title "Before corrections";
run;

proc print data=catalog_corrected noobs label;
  var NLIHC_ID Proj_Name Category units;
  label NLIHC_ID = "ID (after)" Proj_Name = "Project";
  title "After corrections";
run;
title;
