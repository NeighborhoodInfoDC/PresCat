/**************************************************************************
 Program:  Update_Sec8mf_2014_11_a.sas
 Library:  PresCat
 Project:  NeighborhoodInfo DC
 Author:   P. Tatian
 Created:  12/24/14
 Version:  SAS 9.2
 Environment:  Local Windows session (desktop)
 
 Description:  Update Preservation Catalog with latest HUD Sec 8 MF
 update file.
 
 UPDATE PRESCAT.SUBSIDY

 Modifications:
**************************************************************************/

%include "L:\SAS\Inc\StdLocal.sas";

** Define libraries **;
%DCData_lib( PresCat, local=n )
%DCData_lib( HUD, local=n )

%let Update_file = Sec8mf_2014_11;
%let Finalize = N;
%let NO_SUBSIDY_ID = 9999999999;
%let Update_dtm = %sysfunc( datetime() );

%let Subsidy_update_vars = 
    Units_Assist POA_start POA_end Compl_end 
    rent_to_FMR_description Subsidy_Active Program 
    ;
    
%let Subsidy_tech_vars = Subsidy_Info_Source_ID Subsidy_Info_Source_Date Update_Dtm;

%let Subsidy_missing_info_vars = 
    contract_number property_name_text address_line1_text program_type_name
    ;
    
%let Project_update_vars = 
    Hud_Own_Effect_dt Hud_Own_Name Hud_Own_Type Hud_Mgr_Name
    Hud_Mgr_Type Update_Dtm;

%let Project_missing_info_vars = ;

proc sql noprint;
  select Extract_date into :Sec8MF_update_date from Hud.&Update_file._dc;
quit;

%put _user_;

**************************************************************************;
***** Create test version of subsidy exception file **;

data Subsidy_except_test;

  set PresCat.Subsidy_except_test;
  
  ** Exception for updated var **;
  nlihc_id = "NL000001";
  Subsidy_id = 3;
  POA_start = '01oct2004'd;
  Except_date = date();
  Except_init = 'PAT';
  output;
  
  ** Exception for nonupdated var **;
  nlihc_id = "NL000021";
  Subsidy_id = 2;
  POA_start = .;
  POA_end = '30nov2024'd;
  Compl_end = .;
  Except_date = date();
  Except_init = 'PAT';
  output;
  
  ** Exception same as updated var **;
  nlihc_id = "NL000023";
  Subsidy_id = 2;
  POA_start = '21dec2011'd;
  POA_end = .;
  Except_date = date();
  Except_init = 'PAT';
  output;
  
  ** Exception for nonupdated obs **;
  nlihc_id = "NL000029";
  Subsidy_id = 2;
  POA_start = .;
  POA_end = '31oct2044'd;
  Except_date = date();
  Except_init = 'PAT';
  output;

  ** Multiple exception records **;
  nlihc_id = "NL000046";
  Subsidy_id = 3;
  POA_start = '28feb2014'd;
  POA_end = '28feb2025'd;
  rent_to_fmr_description = 'Old desc';
  Except_date = '28feb2014'd;
  Except_init = 'PAT';
  output;
  POA_start = .;
  POA_end = '28feb2030'd;
  Units_assist = .u;
  Except_date = date();
  Except_init = 'PAT';
  rent_to_fmr_description = 'New desc';
  output;
    
run; 

%File_info( data=Subsidy_except_test, contents=n, stats= )


***** NORMALIZE EXCEPTION FILE *****;

***options mprint symbolgen mlogic spool;

%Except_norm( data=Subsidy_except_test, by=nlihc_id subsidy_id )

  proc print data=Subsidy_except_test_norm;
    id nlihc_id subsidy_id;
    title2 "File = Subsidy_except_test_norm";
  run;


********************************************************************************;
** Update subsidy file;

** Get Category IDs **;

%Data_to_format(
  FmtLib=work,
  FmtName=$nlihcid2cat,
  Desc=,
  Data=PresCat.Project_category,
  Value=nlihc_id,
  Label=category_code,
  OtherLabel='',
  DefaultLen=1,
  Print=N,
  Contents=N
  )

data Sec8MF_subsidy_update;

  set Hud.&Update_file._dc;
  where not( program_type_name = "UnasstPrj SCHAP" and assisted_units_count = 0 );

  ** Create update variables **;

  length 
    Units_Assist POA_start POA_end Compl_end 8
    Subsidy_Active 3
    Subsidy_Info_Source $ 40
    Subsidy_Info_Source_ID $ 40
    Subsidy_Info_Source_Date 8
    Update_Dtm 8
  ;
  
  retain Subsidy_Info_Source "HUD/MFA";
 
  Subsidy_Info_Source_ID = trim( left( put( property_id, 16. ) ) ) || "/" || 
                           left( contract_number );
  
  if assisted_units_count > 0 then Units_Assist = assisted_units_count;

  POA_start = tracs_effective_date;
  
  POA_end = tracs_overall_expiration_date;
  
  Compl_end = POA_end;

  if tracs_status in ( 'T' ) then Subsidy_Active = 0;
  else Subsidy_Active = 1;

  Subsidy_Info_Source_Date = extract_date;

  Update_Dtm = &Update_Dtm;

  ** Program code **;
  
  length Program $ 32;
  
  Program = put( program_type_name, $mfatoprog. );
  
  if missing( Program ) then do;
    %warn_put( msg="Missing program type: " _n_= property_id= contract_number= assisted_units_count= program_type_name= )
  end;
  
  /********** SKIP FOR NOW ************
  length Agency $ 80;
  
  if Program = "Low Income Housing Tax Credit" then Agency = "DC Dept of Housing and Community Development; DC Housing Finance Agency";
  else if Subsidy_info_Source =: "DCFHA" then Agency = "DC Housing Finance Agency";
  else if Subsidy_Info_Source =: "DCHA" then Agency = "DC Housing Authority";
  else if Subsidy_Info_Source in ( "Email from KIM DCHA", "Email from Kim Cole DCHA" ) then Agency = "DC Housing Authority";
  else if Subsidy_Info_Source =: "DHCD" then Agency = "DC Dept of Housing and Community Development";
  else if Subsidy_Info_Source =: "DC/" then Agency = "DC";
  else if Subsidy_Info_Source =: "HUD" then Agency = "US Dept of Housing and Urban Development";
  else Agency = "Other";
  **********************************/

  format POA_start POA_end Compl_end Subsidy_Info_Source_Date mmddyy10. Update_Dtm datetime16.;
  
  keep
    Units_Assist POA_start POA_end Compl_end
    contract_number rent_to_FMR_description Subsidy_Active
    Subsidy_Info_Source 
    Subsidy_Info_Source_ID Subsidy_Info_Source_Date Update_Dtm 
    Program
    property_name_text address_line1_text program_type_name
    ownership_effective_date
    owner_organization_name owner_individual_full_name
    owner_organization_name owner_individual_full_name
    mgmt_agent_org_name mgmt_agent_full_name
    mgmt_agent_org_name mgmt_agent_full_name;

run;

proc sort data=Sec8MF_subsidy_update;
  by Subsidy_Info_Source_ID;
run;

%File_info( data=Sec8MF_subsidy_update, freqvars=Program Subsidy_Info_Source_Date )

title2 'File = Sec8MF_subsidy_update';

%Dup_check(
  data=Sec8MF_subsidy_update,
  by=Subsidy_Info_Source_ID,
  id=contract_number,
  out=_dup_check,
  listdups=Y,
  count=dup_check_count,
  quiet=N,
  debug=N
)

title2 'File = PresCat.Subsidy (where=(Subsidy_Info_Source="HUD/MFA"))';

%Dup_check(
  data=PresCat.Subsidy (where=(Subsidy_Info_Source="HUD/MFA")),
  by=Subsidy_Info_Source_ID,
  id=nlihc_id contract_number Subsidy_Info_Source portfolio,
  out=_dup_check,
  listdups=Y,
  count=dup_check_count,
  quiet=N,
  debug=N
)

title2;

***** Update subsidy file *****;

** Prepare Catalog file for update **;

data Subsidy_mfa Subsidy_other; 

  set PresCat.Subsidy;
  
  if Subsidy_Info_Source="HUD/MFA" then output Subsidy_mfa;
  else output Subsidy_other;
  
run;

proc sort data=Subsidy_mfa;
  by Subsidy_Info_Source_ID;
run;

** Perform update **;

data Subsidy_mfa_update_a;

  update 
    Subsidy_mfa Sec8MF_subsidy_update (keep=&Subsidy_update_vars &Subsidy_tech_vars &Subsidy_missing_info_vars);
  by Subsidy_Info_Source_ID;
  
  if missing( Subsidy_id ) then Subsidy_id = &NO_SUBSIDY_ID;
  
run;

proc sort data=Subsidy_mfa_update_a;
  by Nlihc_id Subsidy_id poa_start poa_end;
run;

** Add subsidy ID to new subsidy records **;

data Subsidy_mfa_update_b;

  set Subsidy_mfa_update_a (in=in1) Subsidy_other;
  by nlihc_id Subsidy_id;
  
  retain Subsidy_id_ret;
  
  if first.nlihc_id then Subsidy_id_ret = 0;
  
  if Subsidy_id = &NO_SUBSIDY_ID then Subsidy_id = Subsidy_id_ret + 1;
  
  Subsidy_id_ret = Subsidy_id;
  
  if in1 then output;
  
  drop Subsidy_id_ret &Subsidy_missing_info_vars;
  
run;

/*
proc compare base=Subsidy_mfa_update_a compare=Subsidy_mfa_update_b maxprint=(40,32000);
run;
*/


***** Summarize update changes *****;

%file_info( data=Subsidy_mfa_update_b, freqvars=Subsidy_Info_Source_Date Update_Dtm )

proc sort data=Subsidy_mfa;
  by nlihc_id Subsidy_ID;

proc sort data=Subsidy_mfa_update_b;
  by nlihc_id Subsidy_ID;

proc compare base=Subsidy_mfa compare=Subsidy_mfa_update_b 
    listall /*outnoequal*/ outbase outcomp outdif maxprint=(40,32000)
    out=Update_subsidy_result (rename=(_type_=comp_type));
  id nlihc_id Subsidy_ID Subsidy_Info_Source_ID;
  var Units_Assist POA_start POA_end Compl_end
    rent_to_FMR_description Subsidy_Active
    Program;
run;

proc print data=Update_subsidy_result (obs=20) noobs;
  id nlihc_id Subsidy_ID;
  title2 'File = Update_subsidy_result';
run;

title2;

** Formatted compare output **;

%Super_transpose(  
  data=Update_subsidy_result,
  out=Update_subsidy_result_tr,
  var=Units_Assist POA_start POA_end Compl_end
    rent_to_FMR_description Subsidy_Active
    Program,
  id=comp_type,
  by=nlihc_id Subsidy_ID Subsidy_Info_Source_ID,
  mprint=N
)

%file_info( data=Update_subsidy_result_tr, printobs=10, stats= )


******** Apply exception file ************;

data Subsidy_mfa_except;

  update Subsidy_mfa_update_b (in=in1) Subsidy_except_test_norm /*(drop=Except_:)*/;
  by nlihc_id Subsidy_ID;
  
  if in1;
  
run;

%File_info( data=Subsidy_mfa_except, printobs=10, stats= )

/*
proc print data=Subsidy_mfa_except;
  where nlihc_id in ( 'NL000001' );
  id nlihc_id subsidy_id;
  title2 "File = Subsidy_mfa_except";
run;
title2;
*/

/*
proc compare base=Subsidy_mfa_update_b compare=Subsidy_mfa_except 
    listall outnoequal outbase outcomp outdif maxprint=(40,32000)
    out=Update_except (rename=(_type_=comp_type));
  id nlihc_id Subsidy_ID;
  var Units_Assist POA_start POA_end Compl_end
    rent_to_FMR_description Subsidy_Active
    Program;
run;
*/

data Subsidy_except_test_b;

  set Subsidy_except_test_norm;
  
  retain comp_type 'EXCEPT';
  
run;

proc print data=Subsidy_except_test_b (obs=10) noobs;
  id nlihc_id Subsidy_ID;
  title2 'File = Subsidy_except_test_b';
run;

title2;

** Formatted compare output **;

%Super_transpose(  
  data=Subsidy_except_test_b,
  out=Update_except_tr,
  var=Units_Assist POA_start POA_end Compl_end
    rent_to_FMR_description Subsidy_Active
    Program,
  id=comp_type,
  by=nlihc_id Subsidy_ID /*Subsidy_Info_Source_ID*/,
  mprint=N
)

%file_info( data=Update_except_tr, printobs=10, stats= )

** Combine update and exception changes **;

data Update_subsidy_result_except_tr;

  merge Update_subsidy_result_tr Update_except_tr;
  by nlihc_id subsidy_id;
  
  ** Convert DIF for char vars to missing if no differences **;
  
  array charvars{*} rent_to_FMR_description_DIF Program_DIF;
  
  do i = 1 to dim( charvars );
    charvars{i} = compress( charvars{i}, '.' );
  end;
  
  ** Add category codes for report **;
  
  length Category_code $ 1;
  
  Category_code = put( nlihc_id, $nlihcid2cat. );
  
  format Category_code $categry.;
  
run;

proc print data=Update_subsidy_result_except_tr;
  where nlihc_id in ( 'NL000001' );
  id nlihc_id subsidy_id;
  title2 "File = Update_subsidy_result_except_tr";
run;
title2;


** Recombine with other subsidy data **;

data /**TEMP LIB**/PRESCAT.Subsidy_Update_&Update_file;

  set Subsidy_mfa_except Subsidy_other;
  by nlihc_id Subsidy_id;
  
  where not( missing( nlihc_id ) );
  
  ** Subsidy portfolio **;
  
  length Portfolio $ 16;
  
  Portfolio = put( Program, $progtoportfolio. );
  
  if missing( Portfolio ) then do;
    %warn_put( msg="Missing subsidy portfolio: " _n_= nlihc_id= subsidy_id= Program= )
  end;

run;

%File_info( data=/**TEMP LIB**/PRESCAT.Subsidy_Update_&Update_file )

proc print data=/**TEMP LIB**/PRESCAT.Subsidy_Update_&Update_file;
  where nlihc_id in ( "NL001030", "NL001031", "NL001032", "NL001033" );
  by nlihc_id;
  id subsidy_id;
  title2 "File = Subsidy_Update_&Update_file";
run;
title2;

proc compare base=PresCat.Subsidy compare=/**TEMP LIB**/PRESCAT.Subsidy_Update_&Update_file maxprint=(40,32000) listall;
  id nlihc_id subsidy_id;
  /*
  var Units_Assist POA_start POA_end
    rent_to_FMR_description Subsidy_Active
    Program;
  */
run;


***** Write final file *****;

** Archive past Catalog datasets before updating **;


***options mprint symbolgen mlogic;

%Archive_catalog_data( data=Project Subsidy Update_history, zip_pre=Update_&Update_file, zip_suf= )

***options mprint nosymbolgen nomlogic;

/* proc copy */


***** Add record to Update_history  *****;

data Update_history_rec;

  set Sec8MF_subsidy_update (obs=1 keep=Subsidy_Info_Source Subsidy_Info_Source_Date Update_Dtm);
  
  rename
    Subsidy_Info_Source=Info_Source
    Subsidy_Info_Source_Date=Info_Source_Date;
  
run;

proc sort data=PresCat.Update_history out=Update_history;
  by Info_source Info_source_date;
  
data Update_history_new (label="Preservation Catalog, update history");

  update Update_history Update_history_rec;
  by Info_source Info_source_date;
  
run;

%File_info( data=Update_history_new, stats= )


***** Add record to Update_subsidy_history *****;

data Update_subsidy_history_rec;

  set Update_subsidy_result_except_tr;
  
  %let Dif_list = %ListChangeDelim( &Subsidy_update_vars, new_delim=%str( ), suffix=_DIF );
  
  ********* THIS IS NOT RIGHT BECAUSE _DIF FOR NUM VARS = 0 WHEN NO DIFFERENCES ***********;
  
  if cmiss( of &Dif_list ) < %sysfunc( countw( &Dif_list ) );
  
  drop i Category_code &Dif_list;
  
run;

%File_info( data=Update_subsidy_history_rec, stats= )


***** Create update report *****;

/** Macro Write_var - Start Definition **/

%macro Write_var( var=, fmt=, lbl=, typ=n );

  %if &lbl = %then %do;
    Var = "&var";
  %end;
  %else %do;
    Var = &lbl;
  %end;
  
  Old_value = put( &var._Base, &fmt );
  
  %if %upcase( &typ ) = N %then %do;
  
    if missing( &var._Compare ) or not( abs( &var._DIF ) > 0 ) then New_value = "-";
    else New_value = put( &var._Compare, &fmt );
    
  %end;
  %else %do;
  
    &var._DIF = compress( &var._DIF, '.' );
  
    if missing( &var._Compare ) or missing( &var._DIF ) then New_value = "-";
    else New_value = put( &var._Compare, &fmt );
    
  %end;
  
  if missing( &var._EXCEPT ) then Except_value = "-";
  else Except_value = put( &var._EXCEPT, &fmt );
  
  if New_value ~= "-" or Except_value ~= "-" then output;

%mend Write_var;

/** End Macro Definition **/

proc sort data=Update_subsidy_result_except_tr;
  by Category_code nlihc_id subsidy_id;
run;

data Update_subsidy_result_report;

  set Update_subsidy_result_except_tr;
  
  length Subsidy_desc $ 400;
  
  if not missing( Program_Compare ) then Subsidy_desc = put( Program_Compare, $progshrt. );
  else Subsidy_desc = put( Program_Base, $progshrt. );
  
  if not missing( Subsidy_Info_Source_ID ) then 
    Subsidy_desc = trim( Subsidy_desc ) || ' [' || trim( Subsidy_Info_Source_ID ) || ']';
  
  length Var $ 32 Old_value New_value Except_value $ 80;
  
  %Write_var( var=Subsidy_active, fmt=dyesno., lbl="Subsidy active" )
  %Write_var( var=POA_start, fmt=mmddyy10., lbl="Affordability start" )
  %Write_var( var=POA_end, fmt=mmddyy10., lbl="Affordability end" )
  %Write_var( var=Units_assist, fmt=comma10., lbl="Assisted units" )
  %Write_var( var=rent_to_FMR_description, fmt=$80., lbl="Rent level", typ=c )
  %Write_var( var=Program, fmt=$80., lbl=, typ=c )
  
  keep category_code nlihc_id Subsidy_ID Subsidy_desc Program_Compare Subsidy_Info_Source_ID 
       Var Old_value New_value Except_value;
  
run;

%Data_to_format(
  FmtLib=work,
  FmtName=$nlihcid_proj,
  Desc=,
  Data=PresCat.Project (where=(not(missing(nlihc_id)))),
  Value=nlihc_id,
  Label=trim(nlihc_id)||' / '||left(proj_name),
  OtherLabel='** Unidentified project **',
  DefaultLen=.,
  MaxLen=.,
  MinLen=.,
  Print=N,
  Contents=N
  )

proc format;
  value $except_tl
    "-" = 'white'
    other = 'yellow';
run;

ods listing close;
ods pdf file="&_dcdata_r_path\PresCat\Prog\Updates\Update_&Update_file._subsidy.pdf" 
  style=Styles.Rtf_arial_9pt pdftoc=2 bookmarklist=hide uniform;

proc report data=Update_subsidy_result_report nowd;
  by category_code ;
  column nlihc_id Subsidy_id Subsidy_desc Var Old_value New_value Except_value;
  define nlihc_id / order noprint;
  define Subsidy_id / display "ID" style=[textalign=center];
  define Subsidy_desc / display "Subsidy [source ID]" style=[textalign=left];
  define Var / display "Var" style=[textalign=left];
  define Old_value / display "Old value" style=[textalign=left];
  define New_value / display "New value" style=[textalign=left];
  define Except_value / display "Exception" style(column)=[background=$except_tl. textalign=left];
  break before nlihc_id / ;
  compute before nlihc_id / style=[textalign=left fontweight=bold];
    line nlihc_id $nlihcid_proj.;
  endcomp;
  label category_code = 'Category';
  title2 " ";
  title3 "PresCat.Subsidy - Updated variables";
run;
 
/***
proc print data=Update_subsidy_result_report label;
  by category_code nlihc_id;
  id Subsidy_id Subsidy_desc;
  var Var Old_value New_value;
  var Except_value / style(data) = [background=$except_tl.];
  label
    category_code = "Category"
    nlihc_id = "Project"
    Subsidy_ID = "ID"
    Subsidy_desc = "Subsidy [source ID]"
    Var = "Var"
    Old_value = "Old value"
    New_value = "Update"
    Except_value = "Exception";
  format nlihc_id $nlihcid_proj. Program_Compare $progshrt.;
  title2 " ";
  title3 "PresCat.Subsidy - Updated variables";
run;
***/

** Non-matching records **;

proc print data=Subsidy_mfa_update_a label;
  where missing( nlihc_id );
  id Subsidy_Info_Source_ID;
  var property_name_text address_line1_text program_type_name Subsidy_active Units_assist poa_start poa_end;
  label 
    address_line1_text = "Address"
    program_type_name = "Program";
  title3 "PresCat.Subsidy - Unmatched subsidy records in update file";
run;

title2;
  
ods pdf close;
ods listing;
