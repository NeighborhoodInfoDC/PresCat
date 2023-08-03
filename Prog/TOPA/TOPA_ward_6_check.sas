/**************************************************************************
 Program:  TOPA_ward_6_check.sas
 Library:  Prescat
 Project:  Urban-Greater DC
 Author:   P. Tatian
 Created:  08/03/23
 Version:  SAS 9.4
 Environment:  Local Windows session (desktop)
 GitHub issue:  
 
 Description:  Check ward 6 properties in years with large unit
counts.

 Modifications:
**************************************************************************/

%include "\\sas1\DCdata\SAS\Inc\StdLocal.sas";

** Define libraries **;
%DCData_lib( Prescat )

data TOPA_table_data;
  
  merge 
    PresCat.TOPA_notices_sales (in=in1)
    PresCat.TOPA_CBO_sheet (keep=id cbo_dhcd_received_ta_reg ta_assign_rights u_has_cbo_outcome outcome_:)
    PresCat.topa_subsidies (keep=id before_: after_:)
    PresCat.topa_database (keep=id All_street_addresses Property_name); 
  by id;
  
run;

*************************************************************************
** Export Ward 6 projects **;
ods tagsets.excelxp   /** Open the excelxp destination **/
  file="&_dcdata_default_path\PresCat\Prog\TOPA\TOPA_Ward6_2012-14.xls"  /** This is where the output will go **/
  style=Normal    /** This is the ODS style that will be used in the workbook **/
  options( sheet_interval='proc' )   /** This creates a new worksheet for every proc print in the output **/
;

ods listing close;  /** Close the regular listing destination **/

ods tagsets.excelxp options(sheet_name="2012");
proc print label data=TOPA_table_data n;
  id id;
  var FULLADDRESS u_final_units u_notice_date u_dedup_notice u_notice_with_sale ;
  sum u_final_units;
  where u_dedup_notice=1 and (Ward2022="6") and (u_notice_date between '01Jan2012'd and '31dec2012'd);
run;

ods tagsets.excelxp options(sheet_name="2013");
proc print label data=TOPA_table_data n;
  id id;
  var FULLADDRESS u_final_units u_notice_date u_dedup_notice u_notice_with_sale ;
  sum u_final_units;
  where u_dedup_notice=1 and (Ward2022="6") and (u_notice_date between '01Jan2013'd and '31dec2013'd);
run;

ods tagsets.excelxp options(sheet_name="2014");
proc print label data=TOPA_table_data n;
  id id;
  var FULLADDRESS u_final_units u_notice_date u_dedup_notice u_notice_with_sale ;
  sum u_final_units;
  where u_dedup_notice=1 and (Ward2022="6") and (u_notice_date between '01Jan2014'd and '31dec2014'd);
run;

ods tagsets.excelxp close;  /** Close the excelxp destination **/
ods listing;   /** Reopen the listing destination **/

run;
