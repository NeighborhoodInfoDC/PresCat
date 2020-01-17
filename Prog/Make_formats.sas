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
    "6" = "Lost Rental"
    "7" = "Replaced";
  
  value $Categrn
    "1" = "1 - At-Risk or Flagged for Follow-up"
    "2" = "2 - Expiring Subsidy"
    "3" = "3 - Recent Failing REAC Score"
    "4" = "4 - More Info Needed"
    "5" = "5 - Other Subsidized Property"
    "6" = "6 - Lost Rental"
    "7" = "7 - Replaced";
  
  value $Infosrc
    "HUD/MFA" = "HUD/Multifamily Assistance and Section 8 Contracts"
    "HUD/MFIS" = "HUD/Insured Multifamily Mortgages"
    "HUD/LIHTC" = "HUD/Low Income Housing Tax Credits"
    "HUD/PSH" = "HUD/Picture of Subsidized Households"
    "VCU-CNHED/LECOOP" = "VCU-CNHED/Limited equity cooperative database";
    
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
    "OTR/SALE" = "OTR: Property sale"
    "ROD/FCLNOT" = "ROD: Foreclosure notice"
    "NIDC/FCLOUT" = "NIDC: Foreclosure outcome"
    "DHCD/RCASD" = "DHCD: RCASD notice";
  
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
	'S8-MR' = 'PB8'
	'PBV' = 'PBV'
	'HOPEVI' = 'HOPE VI'

    /***
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
    ***/

    /** MFIS mortgage programs (new codes) **/
    "207APTS" = "HUDMORT"
    "207EXCPT" = "HUDMORT"
    "207MBHC" = "HUDMORT"
    "207RENT" = "HUDMORT"
    "207223FC0I" = "HUDMORT"
    "207223FCIC" = "HUDMORT"
    "207223FPRH" = "HUDMORT"
    "207223FEDA" = "HUDMORT"
    "207223FDEL" = "HUDMORT"
    "213MGTCP" = "HUDMORT"
    "213ICNSCP" = "HUDMORT"
    "213SICP" = "HUDMORT"
    "220URBRH" = "HUDMORT"
    "220223EDA" = "HUDMORT"
    "221D3BMIRUC" = "HUDMORT"
    "221D3MRMI" = "HUDMORT"
    "221D4CIC" = "HUDMORT"
    "221D4MSRO" = "HUDMORT"
    "221D4MRMI" = "HUDMORT"
    "221D4MRDA" = "HUDMORT"
    "221D4MRCI" = "HUDMORT"
    "221D4MRD" = "HUDMORT"
    "221HRSP" = "HUDMORT"
    "221HRSDA" = "HUDMORT"
    "223A7R221D3" = "HUDMORT"
    "223A7R221D4" = "HUDMORT"
    "223A7207CIC" = "HUDMORT"
    "223A7REFI" = "HUDMORT"
    "223A7223FCIC" = "HUDMORT"
    "223A7223FREFI" = "HUDMORT"
    "223A7RPRCI" = "HUDMORT"
    "223A7207REXC" = "HUDMORT"
    "223A7213RCP" = "HUDMORT"
    "223A7220RUR" = "HUDMORT"
    "223A7220RDA" = "HUDMORT"
    "223A7221DCIC" = "HUDMORT"
    "223A7221D3MRMI" = "HUDMORT"
    "223A7221D3BMIR" = "HUDMORT"
    "223A7221D4MRMI" = "HUDMORT"
    "223A7221D4MMIC" = "HUDMORT"
    "223A7223DAS" = "HUDMORT"
    "223A7223DHC" = "HUDMORT"
    "223A7231REH" = "HUDMORT"
    "223A7232RAL" = "HUDMORT"
    "223A7232RBC" = "HUDMORT"
    "223A7232RNH" = "HUDMORT"
    "223A7PRAL" = "HUDMORT"
    "223A7PRBC" = "HUDMORT"
    "223A7PRNH" = "HUDMORT"
    "223A7RLIF" = "HUDMORT"
    "223A7232RIA" = "HUDMORT"
    "223A7236RIA" = "HUDMORT"
    "223A7242RIA" = "HUDMORT"
    "223ARIAA" = "HUDMORT"
    "223A7BMIRREL" = "HUDMORT"
    "223A7MRREL" = "HUDMORT"
    "223A7236REL" = "HUDMORT"
    "223A7221BMIRRIA" = "HUDMORT"
    "223A7242RH" = "HUDMORT"
    "223CBMIRAS" = "HUDMORT"
    "223CMRAS" = "HUDMORT"
    "223D2YOL" = "HUDMORT"
    "223DBMIR2YOL" = "HUDMORT"                      
    "223D2YOLAL" = "HUDMORT"
    "223D2YOLBC" = "HUDMORT"
    "223D2YOLNH" = "HUDMORT"
    "223D2YOLLIF" = "HUDMORT"
    "231ELDERLY" = "HUDMORT"
    "232ASSTLVN" = "HUDMORT"
    "232BRDCARE" = "HUDMORT"
    "232NRSNGHM" = "HUDMORT"
    "232NRSNGHMD" = "HUDMORT"
    "232IFS" = "HUDMORT"
    "232PRAL" = "HUDMORT"
    "232PRBC" = "HUDMORT"
    "232PRNH" = "HUDMORT"
    "234DCND" = "HUDMORT"
    "235JRS" = "HUDMORT"
    "236J1EH" = "HUDMORT"
    "236J1LIF" = "HUDMORT"
    "236J1LIFDA" = "HUDMORT"
    "241AIMPADD" = "HUDMORT"
    "241AIAC" = "HUDMORT"
    "241AIAUR" = "HUDMORT"
    "241ABMIRIA" = "HUDMORT"
    "241AMIRIA" = "HUDMORT"
    "241AIAPR" = "HUDMORT"
    "241AIABC" = "HUDMORT"
    "241AIANH" = "HUDMORT"
    "241AIAAL" = "HUDMORT"
    "241AIALIF" = "HUDMORT"
    "241AIAH" = "HUDMORT"
    "241FBMIREL" = "HUDMORT"
    "241FEL" = "HUDMORT"
    "242HSPTLS" = "HUDMORT"
    "242HSPDA" = "HUDMORT"
    "242RP242H" = "HUDMORT"
    "542BQPERSP15" = "HUDMORT"
    "542BQPERSRC" = "HUDMORT"
    "542BQPERSE" = "HUDMORT"
    "542CHFARSE" = "HUDMORT"
    "542CHFARSRC" = "HUDMORT"
    "542BQPERSFFBE" = "HUDMORT"
    "608VETHSG" = "HUDMORT"
    "608PBHSDS" = "HUDMORT"
    "608WH" = "HUDMORT"
    "803ARSH" = "HUDMORT"
    "803MILH" = "HUDMORT"
    "810ARSH" = "HUDMORT"
    "908NTDH" = "HUDMORT"
    "TX1002LD" = "HUDMORT"
    "TXIGRPPR" = "HUDMORT"

    'CDBG' = 'CDBG'
    'DC-HPTF' = 'DC HPTF'
    'HOME' = 'HOME'

    'LIHTC',
    'LIHTC/UNKWN', 
    'LIHTC/4PCT', 
    'LIHTC/9PCT', 
    'LIHTC/4+9PCT', 
    'LIHTC/TCEP' = 'LIHTC'
    
    'MCKINNEY' = 'MCKINNEY'
    'PUBHSNG' = 'PUBHSNG'
    'TEBOND' = 'TEBOND'
	'FHLB' = 'FHLB'
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
	'S8-MR' = 'Sec 8 moderate rehabilitation'
	'PBV' = 'Project-based vouchers'
    '202-DL-E74' = 'Sec 202 direct loan/elderly/pre-1974'
    '202-DL-EH' = 'Sec 202/8 direct loan/elderly-handicapped'
    '202/811-CA' = 'Sec 202/811 capital advance'

    /** MFIS mortgage programs (new codes) **/
    "207APTS" = "Sec 207 Apartments"
    "207EXCPT" = "Sec 207 Exception (Sale of PMM)"
    "207MBHC" = "Sec 207 Mobile Home Courts"
    "207RENT" = "Sec 207 Rental Projects"
    "207223FC0I" = "Sec 207/223(f)/244 Co-Insurance"
    "207223FCIC" = "Sec 207/223(f) Co-Insurance Converted to Full Insurance"
    "207223FPRH" = "Sec 207/223(f) Pur/Refin Hsg."
    "207223FEDA" = "Sec 207/223(f)/223(e) Declining Area"
    "207223FDEL" = "Sec 207/223(f) - Delegated"
    "213MGTCP" = "Sec 213 Management Cooperative"
    "213ICNSCP" = "Sec 213(i) Consumer Cooperative"
    "213SICP" = "Sec 213 Sales and Inv. Cooperative"
    "220URBRH" = "Sec 220 Urban Renewal Hsg."
    "220223EDA" = "Sec 220/223(e) Declin. Area"
    "221D3BMIRUC" = "Sec 221(d)(3) BMIR Urban Renewal/Coop Hsg"
    "221D3MRMI" = "Sec 221(d)(3) Mkt. Rate Moderate Inc/Disp Fams"
    "221D4CIC" = "Sec 221(d)(4) Co-Insurance Converted to Full Insurance"
    "221D4MSRO" = "Sec 221(d)(4) Mkt. Rate - Single Room Occupancy"
    "221D4MRMI" = "Sec 221(d)(4) Mkt. Rate Mod Inc/Disp Fams"
    "221D4MRDA" = "Sec 221(d)(4) Mkt. Rate/223(e)Declin. Area"
    "221D4MRCI" = "Sec 221(d)(4)/244 Mkt. Rate/Co-Insurance"
    "221D4MRD" = "Sec 221(d)(4) Mkt. Rate - Delegated"
    "221HRSP" = "Sec 221(h) Rehab. Sales Project"
    "221HRSDA" = "Sec 221(h) Rehab Sales/223(e) Declin. Area"
    "223A7R221D3" = "Sec 223(a)(7) Refi of 221d3 Market Rate in a 223(e) Declining Area"
    "223A7R221D4" = "Sec 223(a)(7) Refi of 221d4 in a 223(e) Declining Area"
    "223A7207CIC" = "Sec 223(a)(7)/207 Co-Insurance Converted to Full Ins."
    "223A7REFI" = "Sec 223(a)(7)/207 Refinanced Insurance"
    "223A7223FCIC" = "Sec 223(a)(7)/207/223(f) Co-Insurance Converted to Full Ins."
    "223A7223FREFI" = "Sec 223(a)(7)/207/223(f) Refinanced Insurance"
    "223A7RPRCI" = "Sec 223(a)(7)/207/223(f)/244 Refi/Pur/Refin Co-In"
    "223A7207REXC" = "Sec 223(a)(7)/207/Refi/Exception (Sale of PMM)"
    "223A7213RCP" = "Sec 223(a)(7)/213 Refi/Coops"
    "223A7220RUR" = "Sec 223(a)(7)/220 Refi/Urban Renewal"
    "223A7220RDA" = "Sec 223(a)(7)/220/223(e) Refi/Declining Areas"
    "223A7221DCIC" = "Sec 223(a)(7)/221(d)(3) Co-Insurance Converted to Full Ins."
    "223A7221D3MRMI" = "Sec 223(a)(7)/221(d)(3) MKT Refi/Moderate Income"
    "223A7221D3BMIR" = "Sec 223(a)(7)/221(d)(3)BMIR/Urban Renewal/Coop Hsg"
    "223A7221D4MRMI" = "Sec 223(a)(7)/221(d)(4) MKT Refi/Moderate Income"
    "223A7221D4MMIC" = "Sec 223(a)(7)/221(d)(4) MKT/244 Refi/Mod Income Co-In"
    "223A7223DAS" = "Sec 223(a)(7)/223(d)/221 Asset Sales"
    "223A7223DHC" = "Sec 223(a)(7)/223(d)/232 Refi/2 yr Op Loss Loan - Health Care"
    "223A7231REH" = "Sec 223(a)(7)/231 Refi/Elderly Housing"
    "223A7232RAL" = "Sec 223(a)(7)/232 Refi/Assisted Living"
    "223A7232RBC" = "Sec 223(a)(7)/232 Refi/Board and Care"
    "223A7232RNH" = "Sec 223(a)(7)/232 Refi/Nursing Home"
    "223A7PRAL" = "Sec 223(a)(7)/232/223(f)/Pur/Refi/Assisted Living"
    "223A7PRBC" = "Sec 223(a)(7)/232/223(f)/Pur/Refi/Board & Care"
    "223A7PRNH" = "Sec 223(a)(7)/232/223(f)/Pur/Refi/Nursing Home"
    "223A7RLIF" = "Sec 223(a)(7)/236(j)(1) Refi/Lower Inc Families"
    "223A7232RIA" = "Sec 223(a)(7)/241(a)/232 Refi/Improvements & Additions"
    "223A7236RIA" = "Sec 223(a)(7)/241(a)/236 Refi/Improvements & Additions"
    "223A7242RIA" = "Sec 223(a)(7)/241(a)/242 Refi/Improvements & Additions"
    "223ARIAA" = "Sec 223(a)(7)/241(a)/Refi/Impro & Adds - Apts(not 236/BMIR)"
    "223A7BMIRREL" = "Sec 223(a)(7)/241(f)/221 - BMIR Refi/Equity Loan"
    "223A7MRREL" = "Sec 223(a)(7)/241(f)/221 - MR Refi/Equity Loan"
    "223A7236REL" = "Sec 223(a)(7)/241(f)/236 Refi/Equity Loan"
    "223A7221BMIRRIA" = "Sec 223(a)(7)/241/(a)/221-BMIR Refi/Improvements & Add"
    "223A7242RH" = "Sec 223(a)(7)/242 Refi/Hospital"
    "223CBMIRAS" = "Sec 223(c)/221(d)(3) BMIR Asset Sales"
    "223CMRAS" = "Sec 223(c)/221(d)(3) MR Asset Sales"
    "223D2YOL" = "Sec 223(d)/207 Two Yr. Opr. Loss"
    "223DBMIR2YOL" = "Sec 223(d)/221-BMIR Two Yr. Opr. Loss"                      
    "223D2YOLAL" = "Sec 223(d)/232 2yr Op Loss/Assted Lvng"
    "223D2YOLBC" = "Sec 223(d)/232 2yr Op Loss/Brd & Care"
    "223D2YOLNH" = "Sec 223(d)/232 Two Yr. Opr. Loss/Nursing Hm"
    "223D2YOLLIF" = "Sec 223(d)/236 Two Yr. Opr. Loss/Lower Income Families"
    "231ELDERLY" = "Sec 231 Elderly Housing"
    "232ASSTLVN" = "Sec 232 Assisted Living"
    "232BRDCARE" = "Sec 232 Board and Care"
    "232NRSNGHM" = "Sec 232 Nursing Homes"
    "232NRSNGHMD" = "Sec 232 Nursing Homes - Delegated"
    "232IFS" = "Sec 232(i) Fire Safety"
    "232PRAL" = "Sec 232/223(f)/Pur/Refin/Assisted Living"
    "232PRBC" = "Sec 232/223(f)/Pur/Refin/Board & Care"
    "232PRNH" = "Sec 232/223(f)/Pur/Refin/Nursing Hms"
    "234DCND" = "Sec 234(d) Condominium"
    "235JRS" = "Sec 235(j) Rehab. Sales"
    "236J1EH" = "Sec 236(j)(1)/202 Elderly Hsg."
    "236J1LIF" = "Sec 236(j)(1)/Lower Income Families"
    "236J1LIFDA" = "Sec 236(j)(1)/223(e)/Lower Income Families/Declin. Area"
    "241AIMPADD" = "Sec 241(a)/207 Improvements & Additions"
    "241AIAC" = "Sec 241(a)/213 Improvements & Additions /Coops"
    "241AIAUR" = "Sec 241(a)/220 Improvements & Additions /Urban Renewal"
    "241ABMIRIA" = "Sec 241(a)/221-BMIR Improvements & Additions"
    "241AMIRIA" = "Sec 241(a)/221-MIR(d)(3)&(d)(4) Improvements & Additions"
    "241AIAPR" = "Sec 241(a)/223(f) Improvements & Additions/Pur/Refin"
    "241AIABC" = "Sec 241(a)/232 /Improvements & Additions /Board & Care"
    "241AIANH" = "Sec 241(a)/232 /Improvements & Additions /Nursing Homes"
    "241AIAAL" = "Sec 241(a)/232/Improvements & Additions /Assisted Liv"
    "241AIALIF" = "Sec 241(a)/236 /Improvements & Additions/Lower Inc Families"
    "241AIAH" = "Sec 241(a)/242 /Improvements & Additions /Hospitals"
    "241FBMIREL" = "Sec 241(f)/221-BMIR Equity Loan"
    "241FEL" = "Sec 241(f)/236 Equity Loan"
    "242HSPTLS" = "Sec 242 Hospitals"
    "242HSPDA" = "Sec 242/223(e)/Hospitals/Declin. Area"
    "242RP242H" = "Sec 242/223(f)/Refi/Purchase of a 242 Hospital"
    "542BQPERSP15" = "Sec 542(b) QPE Risk Sharing Plus < 15 yr term, no Amtz Balloon"
    "542BQPERSRC" = "Sec 542(b) QPE Risk Sharing-Recent Comp"
    "542BQPERSE" = "Sec 542(b) QPE Risk Sharing-Existing"
    "542CHFARSE" = "Sec 542(c) HFA Risk Sharing-Existing"
    "542CHFARSRC" = "Sec 542(c) HFA Risk Sharing-Recent Comp"
    "542BQPERSFFBE" = "Sec 542(b) QPE Risk Sharing-FFB Existing"
    "608VETHSG" = "Sec 608 Veteran Housing"
    "608PBHSDS" = "Sec 608-610 Pub. Hsg. Disposition"
    "608WH" = "Sec 608 War Housing"
    "803ARSH" = "Sec 803 Armed Services Housing"
    "803MILH" = "Sec 803 Military Housing"
    "810ARSH" = "Sec 810 Armed Services Housing"
    "908NTDH" = "Sec 908 National Defense Housing"
    "TX1002LD" = "Title X 1002 Land Development"
    "TXIGRPPR" = "Title XI Group Practice"
    'LIHTC/UNKWN' = 'Low income housing tax credit: unknown pct'
    'LIHTC/4PCT' = 'Low income housing tax credit 4%'
    'LIHTC/9PCT' = 'Low income housing tax credit 9%'
    'LIHTC/4+9PCT' = 'Low income housing tax credit 4+9%'
    'LIHTC/TCEP' = 'Low income housing tax credit: TCEP only'

    /** Other **/
    'CDBG' = 'Community development block grant'
    'DC-HPTF' = 'DC housing production trust fund'
    'HOME' = 'HOME'
    'MCKINNEY' = 'McKinney Vento Act loan'
    'PUBHSNG' = 'Public housing'
    'TEBOND' = 'Tax exempt bond'
	'HOPEVI' = 'HOPE VI'
	'FHLB' = 'Federal Home Loan Bank'
    'LECOOP' = 'Limited equity cooperative';

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
	'S8-MR' = 'Sec 8 MR'
	'PBV' = 'PBV' 
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
    'LIHTC' = 'LIHTC (old program code)'
    'LIHTC/UNKWN' = 'LIHTC unknown pct'
    'LIHTC/4PCT' = 'LIHTC 4%'
    'LIHTC/9PCT' = 'LIHTC 9%'
    'LIHTC/4+9PCT' = 'LIHTC 4+9%'
    'LIHTC/TCEP' = 'LIHTC TCEP only'
    'MCKINNEY' = 'McKinney Vento'
    'PUBHSNG' = 'Public housing'
    'TEBOND' = 'Tax exempt bond'
	'HOPEVI' = 'HOPE VI'
	'FHLB' = 'FHLB'
    'LECOOP' = 'Limited equity coop';

  value $portfolio
    '202/811' = 'Section 202/811'
    '221-3-4' = 'Section 221(d)(3)&(4)'
    '221-BMIR' = 'Section 221 BMIR'
    '223' = 'Section 223'
    '232' = 'Section 232'
    '236' = 'Section 236'
    '542' = 'Section 542(b)&(c)'
    'HUDMORT' = 'HUD-insured mortgage'
    'CDBG' = 'CDBG'
    'DC HPTF' = 'DC housing production trust fund'
    'HOME' = 'HOME'
    'LIHTC' = 'LIHTC'
    'MCKINNEY' = 'McKinney Vento'
    'OTHER' = 'Other'
    'PB8' = 'Project-based section 8'
    'PRAC' = 'Project rental assistance contract'
    'PUBHSNG' = 'Public housing'
    'TEBOND' = 'Tax exempt bond'
	'PBV' = 'Project-based vouchers'
	'HOPEVI' = 'HOPE VI'
	'FHLB' = 'Federal Home Loan Bank'
    'LECOOP' = 'Limited equity cooperative';

  value lihtc_credit2prog
    . = 'LIHTC/UNKWN'
    1 = 'LIHTC/4PCT'
    2 = 'LIHTC/9PCT'
    3 = 'LIHTC/4+9PCT'
    4 = 'LIHTC/TCEP';
 
  value $odca_hptf_project_type
    'M' = 'Multifamily'
    'S' = 'Single family'
    'U' = 'Unknown';

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
  modify lihtc_credit2prog (desc="HUD LIHTC credit code to program code") / entrytype=format;
  modify odca_hptf_project_type (desc="ODCA HPTF database project type code") / entrytype=formatc;
  contents;
quit;

