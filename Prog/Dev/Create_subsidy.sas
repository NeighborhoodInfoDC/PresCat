/**************************************************************************
 Program:  Create_subsidy.sas
 Library:  PresCat
 Project:  NeighborhoodInfo DC
 Author:   P. Tatian
 Created:  08/10/13
 Version:  SAS 9.1
 Environment:  Local Windows session (desktop)
 
 Description:  Create full PresCat.Subsidy data set from Subsidy_mfa
 and Subsidy_other.

 Modifications:
  10/26/13 PAT Add Agency and Portfolio vars.  
  10/18/13 PAT Set subsidies to not active if project is in 
           Lost Rental list (TEMPORARY FIX).
  09/27/14 PAT Updated for SAS1.
  12/31/14 PAT Updated Portfolio variable to use new codes. Conversion
               from Program to Portfolio now uses $progtoportfolio fmt.
  01/08/15 PAT Changed Update_date to Update_dtm (datetime).
  01/16/15 PAT Added label for Compl_end.
  06/18/15 PAT Corrections for Museum Sq One (latest updates). 
  06/27/15 PAT Added POA_start_orig, value of earliest start date 
               recorded. (Values need to be verified against older data.)
**************************************************************************/

%include "L:\SAS\Inc\StdLocal.sas";

** Define libraries **;
%DCData_lib( PresCat, local=n )

/*
proc format;
  value $Portfol
    '202 Direct Loan/Elderly/Pre - 1974' = 'Section 202/811'
    '202/8 Direct Loan/Elderly-Handicapped' = 'Section 202/811'
    '202/811 Capital Advance' = 'Section 202/811'
    '207/223(f) Pur/Refin Hsg.' = 'Other'
    '220 Urban Renewal Hsg.' = 'Other'
    '221(d)(3) BMIR Urban Renewal/Coop Hsg' = 'Section 221(d)(3) below market rate interest (BMIR)'
    '221(d)(3) Mkt. Rate Moderate Inc/Disp Fams' = 'Section 221(d)(3)&(4) with affordability restrictions'
    '221(d)(4) Mkt. Rate Mod Inc/Disp Fams' = 'Section 221(d)(3)&(4) with affordability restrictions'
    '223(a)(7)/207/223(f) Refinanced Insurance' = 'Section 223'
    '223(a)(7)/220 Refi/Urban Renewal' = 'Section 223'
    '223(a)(7)/221(d)(3) MKT Refi/Moderate Income' = 'Section 221(d)(3)&(4) with affordability restrictions'
    '223(a)(7)/221(d)(4) MKT Refi/Moderate Income' = 'Section 221(d)(3)&(4) with affordability restrictions'
    '223(a)(7)/221(d)(4) MKT/244 Refi/Mod Income Co-In' = 'Section 221(d)(3)&(4) with affordability restrictions'
    '223(a)(7)/232 Refi/Nursing Home' = 'Section 223'
    '232 Nursing Homes' = 'Section 232'
    '232/223(f)/Pur/Refin/Nursing Hms' = 'Section 232'
    '236(j)(1)/Lower Income Families' = 'Section 236'
    '241(a)/221-BMIR Improvements & Additions' = 'Other'
    '542(b) QPE Risk Sharing-Recent Comp' = 'Section 542(b)&(c)'
    '542(b) QPE Risk Sharing-Existing' = 'Section 542(b)&(c)'
    '542(c) HFA Risk Sharing-Existing' = 'Section 542(b)&(c)'
    '542(c) HFA Risk Sharing-Recent Comp' = 'Section 542(b)&(c)'
    'CDBG' = 'Community Development Block Grants'
    'DC Housing Production Trust Fund' = 'DC Housing Production Trust Fund'
    'HOME' = 'HOME'
    'Low Income Housing Tax Credit' = 'LIHTC'
    'McKinney Vento Act loan' = 'McKinney Vento Act loan'
    'PRAC 202/811' = 'Project Rental Assistance Contract (PRAC)'
    'Public housing' = 'Public Housing'
    'Sec 202' = 'Section 202/811'
    'Sec 8 loan management' = 'Project-based Section 8'
    'Sec 8 new construction' = 'Project-based Section 8'
    'Sec 8 property disposition' = 'Project-based Section 8'
    'Sec 8 rehabilitation' = 'Project-based Section 8'
    'Sec 8 state agency' = 'Project-based Section 8'
    'Tax exempt bond' = 'Tax exempt bond'
    other = ' ';
run;
*/

proc sort data=PresCat.Subsidy_mfa out=Subsidy_mfa;
  by Nlihc_id mfa_start mfa_end;

proc sort data=PresCat.Subsidy_other out=Subsidy_other;
  by Nlihc_id poa_start poa_end;

** New subsidy records **;

data Subsidy_new;

  length 
    Nlihc_id $ 8
    Units_Assist  8
    POA_start  8
    POA_end  8
    contract_number $ 11
    rent_to_FMR_description $ 40
    Subsidy_Active  3
    Subsidy_Info_Source_ID $ 40
    Subsidy_Info_Source $ 40
    Subsidy_Info_Source_Date  8
    Update_Dtm  8
    Program $ 32
    Agency $ 80;
 
  Nlihc_id = "NL001033";
  Units_Assist = .;
  POA_start = .;
  POA_end = .;
  contract_number = "DC39Q031002";
  rent_to_FMR_description = "";
  Subsidy_Active = .;
  Subsidy_Info_Source_ID = "800219652/DC39Q031002";
  Subsidy_Info_Source = "HUD/MFA";
  Subsidy_Info_Source_Date = .;
  Update_Dtm = .;
  Program = "PRAC/811";
  Agency = "";
  
  output;
  
run;

data PresCat.Subsidy (label="Preservation Catalog, project subsidies");

  length Nlihc_id $ 8 Subsidy_id 8;

  set
    Subsidy_mfa
      (keep=Nlihc_id Subsidy_Active Program Contract_Number mfa_assunits mfa_start mfa_end Subsidy_Info_Source 
            Subsidy_Info_Source_ID Subsidy_Info_Source_Date Update_Dtm Compl_end
            rent_to_FMR_description
       rename=(mfa_assunits=Units_Assist mfa_start=POA_start mfa_end=POA_end))
    Subsidy_other
      (drop=Subsidy_Info_Source_Var)
    Subsidy_new;
  by Nlihc_id poa_start poa_end;

  where Nlihc_id ~= "";
  
  ** Subsidy ID number **;
  
  if first.Nlihc_id then Subsidy_id = 0;
  
  Subsidy_id + 1;
  
  POA_start_orig = POA_start;
  
  format POA_start_orig mmddyy10.;
  
  ** Set subsidies to not active if project is in Lost Rental list **;
  ****** NB: NEED TO REVIEW THESE PROJECTS AND FIX SOURCE INFO ******;
  
  if Nlihc_id in ( "NL000035", "NL000056", "NL000068", "NL000087", "NL000098",
                   "NL000105", "NL000132", "NL000134", "NL000137", "NL000196",
                   "NL000199", "NL000231", "NL000307", "NL000324", "NL000371",
                   "NL000382", "NL000394", "NL000414", "NL000416" ) then Subsidy_Active = 0;
  
  /*
  Program = left( compbl( Program ) );
  
  if Program = '542(b)QPE Risk Sharing-Existing' then Program = '542(b) QPE Risk Sharing-Existing';
  
  Program = tranwrd( Program, '/ ', '/' );
  */
  
  length Agency $ 80;
  
  if Program = "LIHTC" then Agency = "DC Dept of Housing and Community Development; DC Housing Finance Agency";
  else if Subsidy_info_Source =: "DCFHA" then Agency = "DC Housing Finance Agency";
  else if Subsidy_Info_Source =: "DCHA" then Agency = "DC Housing Authority";
  else if Subsidy_Info_Source in ( "Email from KIM DCHA", "Email from Kim Cole DCHA" ) then Agency = "DC Housing Authority";
  else if Subsidy_Info_Source =: "DHCD" then Agency = "DC Dept of Housing and Community Development";
  else if Subsidy_Info_Source =: "DC/" then Agency = "DC";
  else if Subsidy_Info_Source =: "HUD" then Agency = "US Dept of Housing and Urban Development";
  else Agency = "Other";
  
  length Portfolio $ 16;
  
  Portfolio = put( Program, $progtoportfolio. );
  
  **** CORRECTIONS ****;
  
  ** Museum Square One **;
  
  if nlihc_id = "NL000208" and subsidy_id = 1 then do;
    poa_end = '31oct2011'd;
    compl_end = poa_end;
    Subsidy_Active = 0;
  end;

  if nlihc_id = "NL000208" and subsidy_id = 2 then do;
    poa_end = '01oct2015'd;
  end;

  label 
    NLIHC_ID = "Preservation Catalog project ID"
    Subsidy_ID = "Preservation Catalog subsidy ID"
    POA_start = "Period of affordability, current start date"
    POA_start_orig = "Period of affordability, original start date"
    Compl_end = "Compliance period, end date"
    POA_end = "Period of affordability, end date"
    Units_Assist = "Subsidy assisted units"
    Subsidy_Active = "Subsidy is active"
    Subsidy_Info_Source = "Source for latest subsidy update"
    Update_Dtm = "Datetime of last subsidy update"
    Program = "Subsidy program"
    Subsidy_Info_Source_ID = "Project ID number for subsidy info source"
    Subsidy_Info_Source_Date = "Date of last subsidy info source"
    Agency = "Agency responsible for managing subsidy"
    Portfolio = "Subsidy portfolio"
  ;
  
  format Program $progfull. Portfolio $portfolio.;
  
run;

/*
proc sort data=PresCat.Subsidy;
  by NLIHC_ID program contract_number;
*/

%File_info( data=PresCat.Subsidy, freqvars=Program Portfolio Subsidy_Info_Source Agency rent_to_FMR_description )

proc print data=PresCat.Subsidy;
  where Portfolio = "";
  id nlihc_id;
  var Program Portfolio Agency;
  title2 'Subsidies with missing Portfolio info';
run;

title2;

**** Compare with earlier version ****;

libname comp 'D:\DCData\Libraries\PresCat\Data\Old';

proc sort data=PresCat.Subsidy out=Subsidy_new;
  by NLIHC_ID program contract_number;

proc sort data=Comp.Subsidy out=Subsidy_old;
  by NLIHC_ID program contract_number;

proc compare base=Subsidy_old compare=Subsidy_new listall maxprint=(40,32000);
  id NLIHC_ID program contract_number;
run;
