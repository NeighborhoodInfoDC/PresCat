/**************************************************************************
 Program:  Update_Sec8mf_2014_11.sas
 Library:  PresCat
 Project:  NeighborhoodInfo DC
 Author:   P. Tatian
 Created:  12/24/14
 Version:  SAS 9.2
 Environment:  Local Windows session (desktop)
 
 Description:  Update Preservation Catalog with latest HUD Sec 8 MF
 update file.
 
 UPDATE PRESCAT.PROJECT

 Modifications:
**************************************************************************/

%include "L:\SAS\Inc\StdLocal.sas";

** Define libraries **;
%DCData_lib( PresCat, local=n )
%DCData_lib( HUD, local=n )

%let Update_file = Sec8MF_2014_11;
%let Finalize = N;
%let NO_SUBSIDY_ID = 9999999999;
%let Update_dtm = %sysfunc( datetime() );

%let Subsidy_update_vars = 
    Units_Assist POA_start POA_end contract_number
    rent_to_FMR_description Subsidy_Active Program 
    Subsidy_Info_Source_ID 
    Subsidy_Info_Source_Date Update_Dtm;
    
%let Subsidy_missing_info_vars = 
    contract_number property_name_text address_line1_text program_type_name;
    
%let Project_mfa_update_vars = 
    Hud_Own_Effect_dt Hud_Own_Name Hud_Own_Type Hud_Mgr_Name
    Hud_Mgr_Type;

%let Project_subsidy_update_vars =
    Subsidized Proj_Units_Assist_Min Subsidy_Start_First Subsidy_End_First 
    Proj_Units_Assist_Max Subsidy_Start_Last Subsidy_End_Last;

%let Project_missing_info_vars = 
    contract_number property_name_text address_line1_text program_type_name;

proc sql noprint;
  select Extract_date into :Sec8MF_update_date from Hud.&Update_file._dc;
quit;
 
%put _user_;

proc print data=/***PresCat.Subsidy***/PRESCAT.SUBSIDY_UPDATE_SEC8MF_2014_11;
  where nlihc_id in (
    "NL000035",
    "NL000040",
    "NL000094",
    "NL000105",
    "NL000134",
    "NL000196",
    "NL000229",
    "NL000274",
    "NL000291",
    "NL000307",
    "NL000324",
    "NL000999" );
  **where nlihc_id in (
    "NL000001", 
    "NL000046", 
    "NL000103", 
    "NL000273", 
    "NL000280" );  
  **where Subsidy_Info_Source_ID in (
    "800003675/DC39L000069", 
    "800003741/DC39L000008", 
    "800003780/DC390014006", 
    "800003784/DC390005003", 
    "800003784/DC39L000067", 
    "800003784/DC39L000081", 
    "800218816/DC39M000023" );
  id nlihc_id;
  by nlihc_id;
  var subsidy_id Subsidy_Info_Source Subsidy_Info_Source_ID Subsidy_Info_Source_Date Subsidy_active units_assist poa_end;
  format Subsidy_Info_Source ;
run;


**************************************************************************;
***** Create test version of Project exception file **;

data Project_except_test;

  set PresCat.Project_except_test (keep=nlihc_id &Project_mfa_update_vars);
  
  ** Exception for updated var **;
  nlihc_id = "NL000047";
  Hud_Own_Name = "NEW OWNER!";
  Hud_Own_Effect_dt = .;
  Hud_mgr_name = "";
  Except_date = date();
  Except_init = 'PAT';
  output;
  
  ** Exception for nonupdated var **;
  nlihc_id = "NL000001";
  Hud_Own_Name = "";
  Hud_Own_Effect_dt = '01jan2015'd;
  Hud_mgr_name = "";
  Except_date = date();
  Except_init = 'PAT';
  output;
  
  ** Exception same as updated var **;
  nlihc_id = "NL000102";
  Hud_Own_Name = "Fpw, LP";
  Hud_Own_Effect_dt = .;
  Hud_mgr_name = "";
  Except_date = date();
  Except_init = 'PAT';
  output;
  
  ** Exception for nonupdated obs **;
  nlihc_id = "NL000035";
  Hud_Own_Name = "";
  Hud_Own_Effect_dt = .;
  Hud_mgr_name = "Who's the manager?";
  Except_date = date();
  Except_init = 'PAT';
  output;
  
  format Except_date mmddyy10.;
  
run; 

%File_info( data=Project_except_test, contents=n, stats= )

***** Normalize exception file *****;

options mprint symbolgen mlogic spool;

%Except_norm( data=Project_except_test, by=nlihc_id )

  proc print data=Project_except_test_norm;
    id nlihc_id;
    title2 "File = Project_except_test_norm";
  run;


********************************************************************************;
** Update Project file;

** Get Category IDs from Project dataset **;

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


** Prepare update file **;

data Sec8MF_project_update;

  set Hud.&Update_file._dc;
  where not( program_type_name = "UnasstPrj SCHAP" and assisted_units_count = 0 );

  ** Create update variables **;

  length 
    Hud_Own_Effect_dt  8
    Hud_Own_Name $ 80
    Hud_Own_Type $ 2
    Hud_Mgr_Name $ 80
    Hud_Mgr_Type $ 2
    Subsidy_Info_Source_ID $ 40
    Subsidy_Info_Source_Date 8
    Update_Dtm 8
  ;
 
  Hud_Own_Effect_dt = ownership_effective_date;
  
  if not( missing( owner_organization_name ) ) then do;
    %owner_name_clean( owner_organization_name, Hud_Own_Name )
  end;
  else do;
    %owner_name_clean( owner_individual_full_name, Hud_Own_Name )
  end;

  Hud_Own_Type = owner_company;
  
  if not( missing( mgmt_agent_org_name ) ) then do;
    %owner_name_clean( mgmt_agent_org_name, Hud_Mgr_Name )
  end;
  else do;
    %owner_name_clean( mgmt_agent_full_name, Hud_Mgr_Name )
  end;

  Hud_Mgr_Type = mgmt_agent_company;

  Subsidy_Info_Source_ID = trim( left( put( property_id, 16. ) ) ) || "/" || 
                           left( contract_number );

  Subsidy_Info_Source_Date = extract_date;

  Update_Dtm = &Update_Dtm;

  format Hud_Own_Type $ownmgrtype. Hud_Mgr_Type $ownmgrtype.
         Hud_Own_Effect_dt Subsidy_Info_Source_Date mmddyy10. Update_Dtm datetime16.;
  
  keep &Project_mfa_update_vars &Project_missing_info_vars 
       Subsidy_Info_Source_ID Subsidy_Info_Source_Date Update_Dtm; 

run;

proc sort data=Sec8MF_project_update;
  by Subsidy_Info_Source_ID;
run;

%File_info( data=Sec8MF_project_update, freqvars=Hud_Own_Type Hud_Mgr_Type Subsidy_Info_Source_Date )

title2 'File = Sec8MF_project_update';

%Dup_check(
  data=Sec8MF_project_update,
  by=Subsidy_Info_Source_ID,
  id=contract_number
)

proc print data=Sec8MF_project_update;
  where Subsidy_Info_Source_ID in ( "800003675/DC39L000069", "800003675/DC39M000051" );
  id Subsidy_Info_Source_ID;
  var &Project_mfa_update_vars;
run;

title2;

** Create Project to update source link with Subsidy file **;

proc sort 
    data=/***PresCat.Subsidy***/PRESCAT.SUBSIDY_UPDATE_SEC8MF_2014_11 (where=(Subsidy_Info_Source="HUD/MFA" and not(missing(Subsidy_Info_Source_ID)))) 
    out=Subsidy_sort (keep=nlihc_id Update_Dtm Units_assist Subsidy_Info_Source_Date Subsidy_Info_Source_ID);
  by nlihc_id descending Subsidy_Info_Source_Date descending Units_assist;

data Project_source_link;

  set Subsidy_sort;
  by nlihc_id;
  
  if first.nlihc_id then output;
  
  keep nlihc_id Subsidy_Info_Source_ID;
  
run;

%File_info( data=Project_source_link, contents=n, stats=, printobs=20 )

proc print data=Project_source_link;
  where nlihc_id in ( "NL000046" ) or Subsidy_Info_Source_ID in ( "800003675/DC39L000069", "800003675/DC39M000051" );;
  id nlihc_id;
title2 "File = Project_source_link";
run; 

title2;

** Create subsidy update file **;

%Create_project_subsidy_update( data=/***PresCat.Subsidy***/PRESCAT.SUBSIDY_UPDATE_SEC8MF_2014_11 )

** Prepare Catalog file for update **;

data Project_mfa Project_other; 

  merge PresCat.Project Project_source_link;
  by nlihc_id;
  
  if not( missing( Subsidy_Info_Source_ID ) ) then do;
    %Owner_name_clean( Hud_Own_Name, Hud_Own_Name )
    %Owner_name_clean( Hud_Mgr_Name, Hud_Mgr_Name )
    output Project_mfa;
  end;
  else do;
    output Project_other;
  end;
  
run;

proc sort data=Project_mfa;
  by Subsidy_Info_Source_ID;
run;

proc print data=Project_mfa;
  where nlihc_id in ( "NL000046", "NL000040" ) or Subsidy_Info_Source_ID in ( "800003675/DC39L000069", "800003675/DC39M000051" );;
  id nlihc_id;
  var Subsidy_Info_Source_ID;
  title2 "File = Project_mfa";
run;
title2;

** Perform update **;

data Project_mfa_update_a;

  update 
    Project_mfa (in=in_Project)
    Sec8MF_project_update 
      (keep=&Project_mfa_update_vars &Project_missing_info_vars 
            Subsidy_Info_Source_ID Subsidy_Info_Source_Date Update_Dtm);
  by Subsidy_Info_Source_ID;
  
  if in_Project;
  
run;

proc sort data=Project_mfa_update_a;
  by Nlihc_id;
run;

data Project_mfa_update_b;

  update 
    Project_mfa_update_a (in=in_Project)
    Project_subsidy_update
      (keep=nlihc_id &Project_subsidy_update_vars);
  by Nlihc_id;
  
  if in_Project;
  
run;
    
proc print data=Project_mfa_update_b;
  where nlihc_id in ( "NL000046", "NL000040" ) or Subsidy_Info_Source_ID in ( "800003675/DC39L000069", "800003675/DC39M000051" );
  id nlihc_id;
  by nlihc_id;
  var Subsidy_Info_Source_ID Subsidy_Info_Source_Date;
  title2 "File = Project_mfa_update_b / NLIHC_ID=NL000046";
run;

proc print data=Project_mfa_update_b;
  where missing( Subsidy_Info_Source_Date );
  id nlihc_id;
  var Subsidy_Info_Source_ID &Project_mfa_update_vars;
  title2 "File = Project_mfa_update_b / Missing Subsidy_Info_Source_Date";
run;
title2;

***** Summarize update changes *****;

%file_info( data=Project_mfa_update_b, freqvars=Subsidy_Info_Source_Date Update_Dtm )

proc sort data=Project_mfa;
  by nlihc_id;

proc compare base=Project_mfa compare=Project_mfa_update_b 
    listall /*outnoequal*/ outbase outcomp outdif maxprint=(40,32000)
    out=Update_project_result (rename=(_type_=comp_type));
  id nlihc_id Subsidy_Info_Source_ID;
  var &Project_mfa_update_vars &Project_subsidy_update_vars;
run;

proc print data=Update_project_result (obs=20) noobs;
  id nlihc_id;
  title2 'File = Update_project_result';
run;

title2;

** Formatted compare output **;

%Super_transpose(  
  data=Update_project_result,
  out=Update_project_result_tr,
  var=&Project_mfa_update_vars &Project_subsidy_update_vars,
  id=comp_type,
  by=nlihc_id Subsidy_Info_Source_ID,
  mprint=N
)

%file_info( data=Update_project_result_tr, printobs=10, stats= )


******** Apply exception file ************;

proc sort data=Project_except_test_norm;
  by nlihc_id;

data Project_mfa_except;

  update Project_mfa_update_b (in=in1) Project_except_test_norm;
  by nlihc_id;
  
  if in1;
  
run;

%File_info( data=Project_mfa_except, printobs=10, stats= )

/*
proc print data=Project_mfa_except;
  where nlihc_id in ( 'NL000001' );
  id nlihc_id subsidy_id;
  title2 "File = Project_mfa_except";
run;
title2;
*/

data Project_except_test_b;

  set Project_except_test_norm;
  
  retain comp_type 'EXCEPT';
  
run;

proc print data=Project_except_test_b (obs=10) noobs;
  id nlihc_id;
  title2 'File = Project_except_test_b';
run;

title2;

** Formatted compare output **;

%Super_transpose(  
  data=Project_except_test_b,
  out=Update_project_except_tr,
  var=&Project_mfa_update_vars,
  id=comp_type,
  by=nlihc_id,
  mprint=N
)

%file_info( data=Update_project_except_tr, printobs=10, stats= )

** Combine update and exception changes **;

data Update_project_result_except_tr;

  merge Update_project_result_tr Update_project_except_tr;
  by nlihc_id;
  
  ** Add category codes for report **;
  
  length Category_code $ 1;
  
  Category_code = put( nlihc_id, $nlihcid2cat. );
  
  format Category_code $categry.;
  
run;

proc print data=Update_project_result_except_tr;
  where nlihc_id in ( 'NL000029' );
  id nlihc_id;
  title2 "File = Update_project_result_except_tr";
run;
title2;


** Recombine with other subsidy data, project category file **;

data Project_Update_all;

  set
    Project_mfa_except
    Project_other;
  by nlihc_id;
  
  where not( missing( nlihc_id ) );
  
  drop Subsidy_Info_Source_ID contract_number
       program_type_name property_name_text address_line1_text
       Subsidy_Info_Source_Date; 
  
run;

** Update project categories **;

proc sort data=PresCat.Project_category out=Project_category;
  by nlihc_id;
run;

data Project_Update_&Update_file;

  update 
    Project_Update_all (in=in1)
    Project_category
      updatemode=nomissingcheck;
  by nlihc_id;
  
  if in1;
  
run;

%File_info( data=Project_Update_&Update_file, freqvars=Category_code )

/*
proc print data=Project_Update_&Update_file;
  where nlihc_id in ( "NL001030", "NL001031", "NL001032", "NL001033" );
  id nlihc_id;
  title2 "File = Project_Update_&Update_file";
run;
title2;
*/

proc compare base=PresCat.Project compare=Project_Update_&Update_file maxprint=(40,32000) listall;
  id nlihc_id;
run;


***** Write final file *****;

***** Add record to Update_history  *****;


***** Create update report *****;

/** Macro Write_var - Start Definition **/

%macro Write_var( var=, fmt=comma8.0, lbl=, typ=n, except=y );

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
  
  %if %upcase( &except ) = Y %then %do;
  
    if missing( &var._EXCEPT ) then Except_value = "-";
    else Except_value = put( &var._EXCEPT, &fmt );
    
    if New_value ~= "-" or Except_value ~= "-" then output;
    
  %end;
  %else %do;
  
    Except_value = "n/a";
    if New_value ~= "-" then output;
    
  %end;

%mend Write_var;

/** End Macro Definition **/

proc sort data=Update_project_result_except_tr;
  by Category_code nlihc_id;
run;

proc print data=Update_project_result_except_tr;
  where nlihc_id in ( "NL000046" );
  var Hud_Own_Name: ;
  id nlihc_id;
run;

data Update_project_result_report;

  set Update_project_result_except_tr;

    ****WHERE NLIHC_ID IN ( "NL000046" );

  length Var $ 32 Old_value New_value Except_value $ 80;
  
  %Write_var( var=Hud_Own_Effect_dt, fmt=mmddyy10., lbl="Date owner acquired property" )
  %Write_var( var=Hud_Own_Name, fmt=$80., lbl="Owner name", typ=c )
  %Write_var( var=Hud_Own_Type, fmt=$ownmgrtype., lbl="Owner type", typ=c )
  %Write_var( var=Hud_Mgr_Name, fmt=$80., lbl="Manager name", typ=c )
  %Write_var( var=Hud_Mgr_Type, fmt=$ownmgrtype., lbl="Manager type", typ=c )
  %Write_var( var=Subsidized, lbl="Subsidized", except=n ) 
  %Write_var( var=Proj_Units_Assist_Min, lbl="Assisted units (min)", except=n ) 
  %Write_var( var=Proj_Units_Assist_Max, lbl="Assisted units (max)", except=n ) 
  %Write_var( var=Subsidy_Start_First, fmt=mmddyy10., lbl="Subsidy start (first)", except=n ) 
  %Write_var( var=Subsidy_Start_Last, fmt=mmddyy10., lbl="Subsidy start (last)", except=n )
  %Write_var( var=Subsidy_End_First, fmt=mmddyy10., lbl="Subsidy end (first)", except=n )
  %Write_var( var=Subsidy_End_Last, fmt=mmddyy10., lbl="Subsidy end (last)", except=n )
  
  keep category_code nlihc_id 
       Var Old_value New_value Except_value;
  
run;

/***%File_info( data=Update_project_result_report, printobs=200, contents=n, stats= )***/

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
    "-", "n/a" = 'white'
    other = 'yellow';
run;

ods listing close;
ods pdf file="&_dcdata_r_path\PresCat\Prog\Updates\Update_&Update_file._project.pdf" 
  style=Styles.Rtf_arial_9pt pdftoc=2 bookmarklist=hide uniform;


proc report data=Update_project_result_report nowd;
  by category_code ;
  column nlihc_id Var Old_value New_value Except_value;
  define nlihc_id / order noprint;
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
  title3 "PresCat.Project - Updated variables";
run;
 

/***
proc print data=Update_project_result_report label noobs;
  by category_code nlihc_id;
  var Var Old_value New_value;
  var Except_value / style(data) = [background=$except_tl.];
  label
    category_code = "Category"
    nlihc_id = "Project"
    Var = "Var"
    Old_value = "Old value"
    New_value = "Update"
    Except_value = "Exception";
  format nlihc_id $nlihcid_proj.;
  title2 " ";
  title3 "PresCat.Project - Updated variables";
run;
***/

** Non-matching records **;

proc print data=Project_mfa_update_b label noobs;
  where missing( nlihc_id );
  var &Project_missing_info_vars;
  label 
    address_line1_text = "Address";
  title3 "PresCat.Project - Unmatched project records in update file";
run;

title2;
  
ods pdf close;
ods listing;
