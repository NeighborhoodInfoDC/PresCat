/**************************************************************************
 Caller for the repo's %Project_name_clean autocall macro
 (Macros/Project_name_clean.sas). The macro rewrites a raw project name
 into title case and then fixes the abbreviations and Roman numerals that
 propcase() would otherwise mangle (NE/NW/SE/SW quadrants, III/II/IV,
 PUD, CHHI, NCBA, ...). Here we run a handful of raw names through it and
 print the before/after so the substitutions are visible.
**************************************************************************/

data raw_names;
  length raw_name $ 60;
  input raw_name $char60.;
  datalines;
IVY CITY SENIOR RESIDENCES III
brookland manor ne
2ND STREET PUD
neighborhood NCBA towers
MLK gateway se
the villages at ivy iv
CHHI senate square sw
NEW BEGINNINGS second nw
;
run;

data cleaned;
  set raw_names;
  length clean_name $ 60;
  %Project_name_clean( raw_name, clean_name )
run;

proc print data=cleaned noobs label;
  var raw_name clean_name;
  label raw_name = "Raw project name" clean_name = "Cleaned project name";
run;
