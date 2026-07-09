/**************************************************************************
 Caller for the repo's %Update_rpt_write_var autocall macro
 (Macros/Update_rpt_write_var.sas). In the catalog update flow, a comparison
 step produces, for each tracked variable, a _Base value (current), a
 _Compare value (proposed), a _DIF flag (0 = unchanged), and an optional
 _EXCEPT override. The macro turns each of those into one report row of
 Var / Old_value / New_value / Except_value, and only outputs a row when
 something actually changed or an exception applies.

 Here we build one project's comparison record with three tracked variables:
   units      - changed (100 -> 120)
   subsidized - unchanged (_DIF = 0, so it is dropped from the report)
   ownercont  - unchanged in the compare, but has an exception override
 and call the macro once per variable to assemble the report table.
**************************************************************************/

data update_report;

  length Var $ 40 Old_value New_value Except_value $ 16;
  keep Var Old_value New_value Except_value;

  /* One project's comparison record. */
  Units_Base = 100;      Units_Compare = 120;  Units_DIF = 20;   Units_EXCEPT = .;
  Subsidized_Base = 80;  Subsidized_Compare = 80;  Subsidized_DIF = 0;  Subsidized_EXCEPT = .;
  Ownercont_Base = 50;   Ownercont_Compare = 50;   Ownercont_DIF = 0;   Ownercont_EXCEPT = 60;

  %Update_rpt_write_var( var=Units, lbl="Total units" )
  %Update_rpt_write_var( var=Subsidized, lbl="Subsidized units" )
  %Update_rpt_write_var( var=Ownercont, lbl="Owner-controlled units" )

run;

proc print data=update_report noobs label;
  var Var Old_value New_value Except_value;
  label Var = "Variable" Old_value = "Old" New_value = "New" Except_value = "Exception";
run;
