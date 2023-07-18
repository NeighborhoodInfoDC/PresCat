/**************************************************************************
 Program:  Topa_manual_edits_export.sas
 Library:  Prescat
 Project:  Urban-Greater DC
 Author:   P. Tatian
 Created:  07/15/23
 Version:  SAS 9.4
 Environment:  Local Windows session (desktop)
 GitHub issue:  375
 
 Description:  Export workbook for TOPA manual edits.

 Modifications:
**************************************************************************/

%include "\\sas1\DCdata\SAS\Inc\StdLocal.sas";

** Define libraries **;
%DCData_lib( Prescat )
%DCData_lib( Realprop )

data Topa_manual_edits_export;

  set Prescat.Topa_notices_sales;
  
run;

proc sort data=Topa_manual_edits_export;
  by u_address_id_ref u_notice_date;
run;

ods listing close;

  
ods tagsets.excelxp file="&_dcdata_default_path\PresCat\Prog\TOPA\Topa_manual_edits_export.xls" style=Normal options(sheet_interval='None' );

ods tagsets.excelxp options( sheet_name="Edits" );

proc print data=Topa_manual_edits_export label;
  id u_address_id_ref u_notice_date;
  var id fulladdress 	u_sum_units u_dedup_notice u_notice_with_sale u_sale_date u_saleprice u_ownername u_proptype;
run;

ods tagsets.excelxp close;

ods listing;


