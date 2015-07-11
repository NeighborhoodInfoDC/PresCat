/**************************************************************************
 Program:  Make_formats.sas
 Library:  PresCat
 Project:  NeighborhoodInfo DC
 Author:   P. Tatian
 Created:  07/25/13
 Version:  SAS 9.1
 Environment:  Local Windows session (desktop)
 
 Description:  Make formats for Preservation Catalog.

 Modifications:
  09/27/14 PAT Updated for SAS1.
  12/30/14 PAT Added $mfatoprog.
  12/31/14 PAT Added $progtoportfolio, $progfull, $progshrt, $portfolio.
**************************************************************************/

%include "L:\SAS\Inc\StdLocal.sas";

** Define libraries **;
%DCData_lib( PresCat, local=n )

proc format library=PresCat;
  
  value $Status
    "A" = "Active"
    "I" = "Inactive";
  
  value $Categry
    "1" = "At-Risk or Flagged for Follow-up"
    "2" = "Expiring Subsidy"
    "3" = "Recent Failing REAC Score"
    "4" = "More Info Needed"
    "5" = "Other Subsidized Property"
    "6" = "Lost Rental";
  
  value $Categrn
    "1" = "1 - At-Risk or Flagged for Follow-up"
    "2" = "2 - Expiring Subsidy"
    "3" = "3 - Recent Failing REAC Score"
    "4" = "4 - More Info Needed"
    "5" = "5 - Other Subsidized Property"
    "6" = "6 - Lost Rental";
  
  value $Infosrc
    "HUD/MFA" = "HUD - Multifamily Assistance and Section 8 Contracts";
    
  value $mfatoprog
    '202/8 NC' = '202/8-NC'
    '202/8 SR' = '202/8-SR'
    'HFDA/8 NC' = 'HFDA/8-NC'
    'HFDA/8 SR' = 'HFDA/8-SR'
    'LMSA' = 'LMSA'
    'PD/8 Existing' = 'PD/8-EXIST'
    'PD/8 MR' = 'PD/8-MR'
    'PD/8 SR' = 'PD/8-SR'
    'PRAC/202' = 'PRAC/202'
    'PRAC/811' = 'PRAC/811'
    'Sec 8 NC  ' = 'S8-NC'
    'Sec 8 SR ' = 'S8-SR';
    
  value $prgh2oc
    '202/8 NC' = 'Sec. 202'
    '202/8 SR' = 'Sec. 202'
    'HFDA/8 NC' = 'S8 State Agency'
    /*'HFDA/8 SR' = 'Other S8 Rehab'*/
    'HFDA/8 SR' = 'S8 State Agency'
    /*'LMSA' = 'Other S8 Rehab'*/
    'LMSA' = 'S8 Loan Mgmt'
    'PD/8 Existing' = 'S8 Prop. Disp.'
    'PD/8 MR' = 'S8 Prop. Disp.'
    'PD/8 SR' = 'S8 Prop. Disp.'
    'PRAC/202' = 'PRAC 202/811'
    'PRAC/811' = 'PRAC 202/811'
    'Sec 8 NC' = 'Other S8 New'
    'Sec 8 SR' = 'Other S8 Rehab'
    /*'Sec 8 SR' = 'S8 State Agency'*/
  ;
  
  value $rptype
    "SALE" = "Property sale"
    "FCLNOT" = "Foreclosure notice"
    "FCLOUT" = "Foreclosure outcome";
  
  value $ownmgrtype
    "LD" = "Limited dividend"
    "NP" = "Non-profit"
    "NC" = "Non-profit controlled"
    "OT" = "Other"
    "HA" = "Public housing authority"
    "PM" = "Profit motivated"
    "IN" = "Individual";
    
  value $progtoportfolio
    '202/8-NC' = '202/811'
    '202/8-SR' = '202/811'
    '202/8' = '202/811'
    'HFDA/8-NC' = 'PB8'
    'HFDA/8-SR' = 'PB8'
    'HFDA/8' = 'PB8'
    'LMSA' = 'PB8'
    'PD/8-EXIST' = 'PB8'
    'PD/8-MR' = 'PB8'
    'PD/8-SR' = 'PB8'
    'PD/8' = 'PB8'
    'PRAC/202' = 'PRAC'
    'PRAC/811' = 'PRAC'
    'PRAC/202/811' = 'PRAC'
    'S8-NC' = 'PB8'
    'S8-SR' = 'PB8'
    '202-DL-E74' = '202/811'
    '202-DL-EH' = '202/811'
    '202/811-CA' = '202/811'
    '207/223-PR' = 'OTHER'
    '220-URH' = 'OTHER'
    '221-3-BMIR-URC' = '221-BMIR'
    '221-3-MRMI' = '221-3-4'
    '221-4-MRMI' = '221-3-4'
    '223/207/223-RI' = '223'
    '223/220-RUR' = '223'
    '223/221-3-MRMI' = '221-3-4'
    '223/221-4-MRMI' = '221-3-4'
    '223/221/244-MRMI' = '221-3-4'
    '223/232-RNH' = '223'
    '232-NH' = '232'
    '232/223-PRNH' = '232'
    '236-LIF' = '236'
    '241/221-BMIRIA' = 'OTHER'
    '542-QPE-RC' = '542'
    '542-QPE-E' = '542'
    '542-HFA-E' = '542'
    '542-HFA-RC' = '542'
    'CDBG' = 'CDBG'
    'DC-HPTF' = 'DC HPTF'
    'HOME' = 'HOME'
    'LIHTC' = 'LIHTC'
    'MCKINNEY' = 'MCKINNEY'
    'PUBHSNG' = 'PUBHSNG'
    'TEBOND' = 'TEBOND'
    other = ' ';

  value $progfull
    '202/8-NC' = 'Sec 202 new construction'
    '202/8-SR' = 'Sec 202 substantial rehabilitation'
    '202/8' = 'Sec 202 (unspecified)'
    'HFDA/8-NC' = 'Sec 8 housing finance agency new construction'
    'HFDA/8-SR' = 'Sec 8 housing finance agency substantial rehabilitation'
    'HFDA/8' = 'Sec 8 housing finance agency (unspecified)'
    'LMSA' = 'Sec 8 loan management set-aside'
    'PD/8-EXIST' = 'Sec 8 property disposition existing'
    'PD/8-MR' = 'Sec 8 property disposition moderate rehabilitation'
    'PD/8-SR' = 'Sec 8 property disposition substantial rehabilitation'
    'PD/8' = 'Sec 8 property disposition (unspecified)'
    'PRAC/202' = 'Sec 202 project rental assistance contract'
    'PRAC/811' = 'Sec 811 project rental assistance contract'
    'PRAC/202/811' = 'Sec 202/811 project rental assistance contract'
    'S8-NC' = 'Sec 8 new construction'
    'S8-SR' = 'Sec 8 substantial rehabilitation'
    '202-DL-E74' = 'Sec 202 direct loan/elderly/pre-1974'
    '202-DL-EH' = 'Sec 202/8 direct loan/elderly-handicapped'
    '202/811-CA' = 'Sec 202/811 capital advance'
    '207/223-PR' = 'Sec 207/223(f) purchase/refinance housing'
    '220-URH' = 'Sec 220 urban renewal housing'
    '221-3-BMIR-URC' = 'Sec 221(d)(3) below market rate interest urban renewal/coop housing'
    '221-3-MRMI' = 'Sec 221(d)(3) market rate moderate income/displaced families'
    '221-4-MRMI' = 'Sec 221(d)(4) market rate moderate income/displaced families'
    '223/207/223-RI' = 'Sec 223(a)(7)/207/223(f) refinanced insurance'
    '223/220-RUR' = 'Sec 223(a)(7)/220 refinance/urban renewal'
    '223/221-3-MRMI' = 'Sec 223(a)(7)/221(d)(3) market refinance/moderate income'
    '223/221-4-MRMI' = 'Sec 223(a)(7)/221(d)(4) market refinance/moderate income'
    '223/221/244-MRMI' = 'Sec 223(a)(7)/221(d)(4) market/244 refinance/moderate income co-in'
    '223/232-RNH' = 'Sec 223(a)(7)/232 refinance nursing homes'
    '232-NH' = 'Sec 232 nursing homes'
    '232/223-PRNH' = 'Sec 232/223(f) purchase/refinance nursing homes'
    '236-LIF' = 'Sec 236(j)(1) lower income families'
    '241/221-BMIRIA' = 'Sec 241(a)/221 below market rate interest improvements & additions'
    '542-QPE-RC' = 'Sec 542(b) qualified participating entities risk sharing recent completions'
    '542-QPE-E' = 'Sec 542(b) qualified participating entities risk sharing existing'
    '542-HFA-E' = 'Sec 542(c) housing finance agency risk sharing existing'
    '542-HFA-RC' = 'Sec 542(c) housing finance agency risk sharing recent completions'
    'CDBG' = 'Community development block grant'
    'DC-HPTF' = 'DC housing production trust fund'
    'HOME' = 'HOME'
    'LIHTC' = 'Low income housing tax credit'
    'MCKINNEY' = 'McKinney Vento Act loan'
    'PUBHSNG' = 'Public housing'
    'TEBOND' = 'Tax exempt bond';

  value $progshrt
    '202/8-NC' = 'Sec 202 NC/SR'
    '202/8-SR' = 'Sec 202 NC/SR'
    '202/8' = 'Sec 202 NC/SR'
    'HFDA/8-NC' = 'Sec 8 HFA'
    'HFDA/8-SR' = 'Sec 8 HFA'
    'HFDA/8' = 'Sec 8 HFA'
    'LMSA' = 'Sec 8 LMSA'
    'PD/8-EXIST' = 'Sec 8 PD'
    'PD/8-MR' = 'Sec 8 PD'
    'PD/8-SR' = 'Sec 8 PD'
    'PD/8' = 'Sec 8 PD'
    'PRAC/202' = 'Sec 202 PRAC'
    'PRAC/811' = 'Sec 811 PRAC'
    'PRAC/202/811' = 'Sec 202/811 PRAC'
    'S8-NC' = 'Sec 8 NC/SR'
    'S8-SR' = 'Sec 8 NC/SR'
    '202-DL-E74' = 'Sec 202 direct loan pre-1974'
    '202-DL-EH' = 'Sec 202/8 direct loan'
    '202/811-CA' = 'Sec 202/811 capital advance'
    '207/223-PR' = 'Sec 207/223(f)'
    '220-URH' = 'Sec 220 urban renewal'
    '221-3-BMIR-URC' = 'Sec 221(d)(3) BMIR'
    '221-3-MRMI' = 'Sec 221(d)(3) moderate income'
    '221-4-MRMI' = 'Sec 221(d)(4) moderate income'
    '223/207/223-RI' = 'Sec 223(a)(7)/207/223(f) refi insurance'
    '223/220-RUR' = 'Sec 223(a)(7)/220 refi'
    '223/221-3-MRMI' = 'Sec 223(a)(7)/221(d)(3) market refi'
    '223/221-4-MRMI' = 'Sec 223(a)(7)/221(d)(4) market refi'
    '223/221/244-MRMI' = 'Sec 223(a)(7)/221(d)(4)/244'
    '223/232-RNH' = 'Sec 223(a)(7)/232 refi'
    '232-NH' = 'Sec 232'
    '232/223-PRNH' = 'Sec 232/223(f) purchase/refi'
    '236-LIF' = 'Sec 236(j)(1)'
    '241/221-BMIRIA' = 'Sec 241(a)/221 BMIR'
    '542-QPE-RC' = 'Sec 542(b) QPE recent'
    '542-QPE-E' = 'Sec 542(b) QPE existing'
    '542-HFA-E' = 'Sec 542(c) HFA existing'
    '542-HFA-RC' = 'Sec 542(c) HFA recent '
    'CDBG' = 'CDBG'
    'DC-HPTF' = 'DC HPTF'
    'HOME' = 'HOME'
    'LIHTC' = 'LIHTC'
    'MCKINNEY' = 'McKinney Vento'
    'PUBHSNG' = 'Public housing'
    'TEBOND' = 'Tax exempt bond';

  value $portfolio
    '202/811' = 'Section 202/811'
    '221-3-4' = 'Section 221(d)(3)&(4)'
    '221-BMIR' = 'Section 221 BMIR'
    '223' = 'Section 223'
    '232' = 'Section 232'
    '236' = 'Section 236'
    '542' = 'Section 542(b)&(c)'
    'CDBG' = 'CDBG'
    'DC HPTF' = 'DC housing production trust fund'
    'HOME' = 'HOME'
    'LIHTC' = 'LIHTC'
    'MCKINNEY' = 'McKinney Vento'
    'OTHER' = 'Other'
    'PB8' = 'Project-based section 8'
    'PRAC' = 'Project rental assistance contract'
    'PUBHSNG' = 'Public housing'
    'TEBOND' = 'Tax exempt bond';

run;

proc catalog catalog=PresCat.Formats;
  modify Status (desc="Pres Cat project active status") / entrytype=formatc;
  modify Categry (desc="Pres Cat project category") / entrytype=formatc;
  modify Categrn (desc="Pres Cat project category w/number") / entrytype=formatc;
  modify Infosrc (desc="Data source for subsidy update") / entrytype=formatc;
  modify mfatoprog (desc="HUD MFA programs to Catalog program code") / entrytype=formatc;
  modify prgh2oc (desc="HUD MFA to old catalog program xwalk") / entrytype=formatc;
  modify rptype (desc="Pres Cat real property event type") / entrytype=formatc;
  modify ownmgrtype (desc="HUD owner/manager types") / entrytype=formatc;
  modify progtoportfolio (desc="Cat program code to portfolio") / entrytype=formatc;
  modify progfull (desc="Catalog program full description") / entrytype=formatc;
  modify progshrt (desc="Catalog program short description") / entrytype=formatc;
  modify portfolio (desc="Catalog subsidy portfolio description") / entrytype=formatc;
  contents;
quit;

