/**************************************************************************
 Program:  Create_subsidy_mfa.sas
 Library:  PresCat
 Project:  NeighborhoodInfo DC
 Author:   P. Tatian
 Created:  07/25/13
 Version:  SAS 9.1
 Environment:  Local Windows session (desktop)
 
 Description:  Create initial Subsidy data set.

 Modifications:
  09/27/14 PAT Updated for SAS1.
  10/16/14 PAT Added subsidy correction for NL000046.
  10/19/14 PAT Updated DC_info and Sec8MF files.
               Removed subsidy correction for NL000046.
               Added updates to ID_MFA, MFA_START, MFA_END, MFA_ASSUNITS.
  12/24/14 PAT Changed Subsidy_Info_Source_ID to property_id/contract_number.
               Mark projects with tracs_status='T' or missing from MFA 
               update as inactive.
  12/31/14 PAT Revised Program variable to use new codes. 
  01/08/15 PAT Changed Update_date to Update_dtm (datetime).
  01/18/15 PAT Added Compl_end.
  01/29/15 PAT Added property_id for Sayles Place/NL000262.
**************************************************************************/

%include "L:\SAS\Inc\StdLocal.sas";

** Define libraries **;
%DCData_lib( PresCat, local=n )
%DCData_lib( HUD, local=n )

/*
%File_info( data=HUD.sec8mf_2014_10_dc, printobs=5 )

title2 'HUD.sec8mf_2014_10_dc';

data _null_;
  set HUD.sec8mf_2014_10_dc;
  where property_id = 800003675;
  file print;
  put / '--------------------';
  put (_all_) (= /);
run;
*/

proc freq data=HUD.sec8mf_2014_10_dc;
  tables program_type_group_code * program_type_name / list missing nocum nopercent;
run;

title2;

data DC_Info;

  set PresCat.DC_Info_10_19_14;
  
  property_id = 1 * ID_MFA;
  
  ** Apply standard corrections **;
  
  %DCInfo_corrections()
  
  ** Tentative fixes for property_id - to be confirmed with Pres Network **;
  
  select ( NLIHC_ID );
    when ( 'NL000137' )  /** 21 K TER NW **/
      property_id = 800003730;
    when ( 'NL000303' )  /** 222 W ST NW **/
      property_id = 800003805;
    when ( 'NL000098' )  /** 1312 EUCLID ST NW **/
      property_id = 800003808;
    when ( 'NL000999' )  /** 1350 Clifton St NW **/
      property_id = 800003695;
    when ( 'NL000234' )  /** 2701 ROBINSON PLACE SE **/
      property_id = 800214527;
    when ( 'NL000262' )  /** Sayles Place **/
      property_id = 800003779;
    otherwise
      /** Do nothing **/;
  end;
  
  if not missing( property_id );

run;

proc sort data=DC_Info;
  by property_id;
  
proc sort data=HUD.sec8mf_2014_10_dc out=sec8mf_dc_a;
  by property_id;

** Need data for two older projects no longer in current HUD database **;
proc sort data=Hud.Sec8mf_2007_12_dc (where=(property_id in ( 800003695, 800003708 ))) out=sec8mf_dc_b;
  by property_id;

data Sec8mf_dc;

  set sec8mf_dc_a sec8mf_dc_b (in=inb);
  by property_id;
  
  if inb then tracs_status = 'T';

run;

%Dup_check(
  data=Sec8mf_dc,
  by=property_id contract_number,
  id=
)
 
proc format;
  value $progfl
    "Other S8 New" = "Sec 8 new construction"
    "Other S8 Rehab" = "Sec 8 rehabilitation"
    "PRAC 202/811" = "PRAC 202/811"
    "S8 Loan Mgmt" = "Sec 8 loan management"
    "S8 Prop. Disp." = "Sec 8 property disposition"
    "S8 State Agency" = "Sec 8 state agency"
    "Sec. 202" = "Sec 202";
  value $oldcattoprog
    'Sec. 202' = '202/8'
    'S8 State Agency' = 'HFDA/8'
    'S8 Loan Mgmt' = 'LMSA'
    'S8 Prop. Disp.' = 'PD/8'
    'PRAC 202/811' = 'PRAC/202/811'
    'Other S8 New' = 'S8-NC'
    'Other S8 Rehab' = 'S8-SR'
    other = ' ';
run;

title2 'Dup_check: DC_Info';

%Dup_check(
  data=DC_Info,
  by=property_id,
  id=nlihc_id id_mfa 
)

title2 'Dup_check: Sec8mf_dc';

%Dup_check(
  data=Sec8mf_dc,
  by=property_id,
  id=contract_number
)

title2;

data PresCat.Subsidy_mfa;

  length MFA_ASSUNITS 8;

  merge 
    DC_Info 
      (keep=NLIHC_ID Category ID_MFA MFA_SOURCE MFA_PROG MFA_START MFA_END MFA_ASSUNITS MFA_NOTES
            property_id Proj_name Proj_Addre
       in=in1)
    sec8mf_dc
      (keep=contract_number property_id tracs_effective_date tracs_current_expiration_date 
            tracs_overall_expiration_date tracs_status program_type_name assisted_units_count 
            address_line1_text rent_to_FMR_description extract_date
       where=(not(program_type_name = "UnasstPrj SCHAP" and assisted_units_count = 0))
       in=in2);
  by property_id;

  in_DC_Info = in1;
  in_MFA = in2;
  
  ** Clean project names **;
  
  %Project_name_clean( Proj_name, Proj_name )
  
  ** Fix data problem **;
  
  if mfa_source  =: "HUD - Multifamily AssisHUD" then 
    mfa_source = substr( mfa_source, 24 );
  
  ** Create standardized variables **;
  
  length 
    Subsidy_Active 3
    Subsidy_Info_Source_ID $ 40
    Subsidy_Info_Source_Var $ 32
    Subsidy_Info_Source $ /*16*/ 40
    Subsidy_Info_Source_Date 8
    Update_Dtm 8
  ;
  
  if tracs_status in ( 'T' ) or not in_MFA then Subsidy_Active = 0;
  else Subsidy_Active = 1;
  
  Subsidy_Info_Source = "HUD/MFA";

  Subsidy_Info_Source_ID = trim( left( put( property_id, 16. ) ) ) || "/" || 
                           left( contract_number );
  
  Subsidy_Info_Source_Var = "property_id/contract_number";
  
  if in_MFA then do;
  
    Subsidy_Info_Source_Date = extract_date;
    
  end;
  else if mfa_source  =: "HUD - Multifamily Assistance and Section 8 Contracts" then do;
  
      Subsidy_Info_Source_Date = 
        input( 
          substr( mfa_source, 
                  indexc( mfa_source, '(' ) + 1, 
                  indexc( mfa_source, ')' ) - ( indexc( mfa_source, '(' ) + 1 ) ),
          mmddyy8. );
    
  end;
  else do;
  
    Subsidy_Info_Source_Date = .u;
    
  end;
  
  ** Program code **;
  
  length Program $ 32;
  
  Program = put( program_type_name, $mfatoprog. );
  
  if Program = "" then Program = put( mfa_prog, $oldcattoprog. );
  
  /*
  if mfa_prog ~= "" then Program = mfa_prog;
  else do;
  
    select ( program_type_name );
      when ( "HFDA/8 SR" ) Program = "Other S8 Rehab";
      when ( "LMSA" ) Program = "S8 Loan Mgmt";
      when ( "PD/8 MR" ) Program = "S8 Prop. Disp.";
      when ( "Sec 8 SR" ) Program = "S8 Prop. Disp.";
      when ( "PRAC/811" ) Program = "PRAC 202/811";
      otherwise do;
        %warn_put( msg="Unknown program type: " nlihc_id= property_id= program_type_name= mfa_source= )
      end;
    end;
  
  end;
  
  Program = put( Program, $progfl. );
  */
  
  ** Update subsidy info **;
  
  ID_MFA = property_id;
  if not missing( tracs_effective_date ) and missing( MFA_START ) then MFA_START = tracs_effective_date;
  if not missing( tracs_overall_expiration_date ) then MFA_END = tracs_overall_expiration_date;
  if assisted_units_count > 0 then MFA_ASSUNITS = assisted_units_count;
  
  **** TEMPORARY CORRECTIONS TO SUBSIDY INFO ****;
  /*
  if Nlihc_id = "NL000046" then do;
    if contract_number = "DC39L000069" then do;
      mfa_start = '01oct2010'd;
      mfa_end = '30sep2015'd;
      mfa_assunits = 40;
    end;
    else if contract_number = "DC39M000051" then do;
      mfa_start = '01nov2012'd;
      mfa_end = '31oct2015'd;
      mfa_assunits = 333;
    end;
  end;
  */
  
  ** Eliminate entries not in MFA database and with no subsidy info in Catalog **;
  
  if not in_MFA and missing( mfa_assunits) and missing( mfa_source ) and missing( mfa_prog ) 
  and missing( mfa_start ) and missing( mfa_end ) and missing( mfa_notes ) then delete;
  
  ** Compliance period end date (same as subsidy end date) **;
  
  Compl_end = mfa_end;
  
  ** Stamp with today's datetime **;
  
  Update_dtm = datetime();
  
  format 
    Subsidy_Active dyesno.
    Subsidy_Info_Source $infosrc.
    Subsidy_Info_Source_Date mmddyy10.
    Update_Dtm datetime16.;
    
run;

proc sort data=PresCat.Subsidy_mfa;
  by property_id contract_number;
run;

%File_info( data=PresCat.Subsidy_mfa, printobs=10, 
            freqvars=tracs_status mfa_prog mfa_source 
                     Subsidy_Active Subsidy_Info_Source_Var Subsidy_Info_Source subsidy_info_source_date program 
                     rent_to_FMR_description )

proc freq data=PresCat.Subsidy_mfa;
  tables in_DC_Info * in_MFA / list missing;
  tables program_type_name * mfa_prog * program / list missing nocum nopercent;
  format program_type_name mfa_prog program ;
run;

proc print data=PresCat.Subsidy_mfa;
  where program = "";
  id Nlihc_id;
  var in_mfa in_dc_info property_id Proj_Addre mfa_: ;
  title2 'No program info';
run;

proc print data=PresCat.Subsidy_mfa;
  where in_MFA and not in_DC_Info;
  id property_id;
  var in_mfa in_dc_info NLIHC_ID address_line1_text contract_number program_type_name assisted_units_count tracs_: ;
  title2 'Not in DC_Info';
run;

proc print data=PresCat.Subsidy_mfa;
  where not in_MFA and in_DC_Info;
  id property_id;
  var in_mfa in_dc_info NLIHC_ID Proj_Addre mfa_: ;
  title2 'Not in HUD MFA';
run;

title2 'PresCat.Subsidy_mfa: Duplicates for Subsidy_Info_Source_ID';

%Dup_check(
  data=PresCat.Subsidy_mfa,
  by=Subsidy_Info_Source_ID,
  id=NLIHC_ID property_id contract_number mfa_prog program_type_name assisted_units_count tracs_status,
  out=_dup_check,
  listdups=Y,
  count=dup_check_count,
  quiet=N,
  debug=N
)

run;

title2;

/*
proc freq data=PresCat.Subsidy_mfa;
  where property_id not in ( 800003675, 800003741, 800003784, 800218816 );
  tables mfa_prog * program_type_name / list missing;
run;
*/

** Export all records for review **;

ods listing close;

ods tagsets.excelxp file="&_dcdata_r_path\PresCat\Data\Subsidy.xls" style=/*Minimal*/Normal 
    options( sheet_interval='Proc' orientation='landscape' );

proc print data=PresCat.Subsidy_mfa;
  id property_id;
  var NLIHC_ID proj_name in_: contract_number 
      Proj_Addre address_line1_text 
      mfa_prog program_type_name 
      MFA_ASSUNITS assisted_units_count 
      mfa_start tracs_effective_date 
      mfa_end tracs_current_expiration_date tracs_overall_expiration_date tracs_status
      mfa_source mfa_notes
      ;
run;

ods tagsets.excelxp close;
ods listing;

** Print differences in MFA and Catalog info **;

proc print data=PresCat.Subsidy_mfa;
  where mfa_prog ~= put( program_type_name, $prgh2oc. );
  id property_id;
  by property_id;
  var NLIHC_ID proj_name contract_number 
      mfa_prog program_type_name 
      ;
  title2 'Program mismatch';
run;

proc print data=PresCat.Subsidy_mfa;
  where mfa_assunits ~= assisted_units_count;
  id property_id;
  by property_id;
  var NLIHC_ID proj_name contract_number 
      MFA_ASSUNITS assisted_units_count 
      ;
  title2 'Assisted units mismatch';
run;

title2; 

**** Compare with earlier version ****;

libname comp 'D:\DCData\Libraries\PresCat\Data\Old';

proc compare base=Comp.Subsidy_mfa compare=PresCat.Subsidy_mfa maxprint=(40,32000);
  id property_id contract_number;
run;
