/**************************************************************************
 Program:  Create_subsidy_other.sas
 Library:  PresCat
 Project:  NeighborhoodInfo DC
 Author:   P. Tatian
 Created:  07/25/13
 Version:  SAS 9.1
 Environment:  Local Windows session (desktop)
 
 Description:  Create initial Subsidy data set.
 Other subsidies.

 Modifications:
  09/27/14 PAT Updated for SAS1.
  10/19/14 PAT Changed informat for reading source date to ANYDTDTE.
               Updated DC_info file.
  12/31/14 PAT Updated Program var to use new codes.
  01/08/15 PAT Changed Update_date to Update_dtm (datetime).
  01/18/15 PAT Added calculated Compl_end and Poa_end for LIHTC projects.
**************************************************************************/

%include "L:\SAS\Inc\StdLocal.sas";

** Define libraries **;
%DCData_lib( PresCat, local=n )

** Format for translating old program descriptions to new codes **;

proc format;
  value $oldcattoprog
    '202 Direct Loan/ Elderly/ Pre - 1974' = '202-DL-E74'
    '202/8 Direct Loan/ Elderly-Handicapped' = '202-DL-EH'
    '202/811 Capital Advance' = '202/811-CA'
    '207/ 223(f) Pur/ Refin Hsg.' = '207/223-PR'
    '220 Urban Renewal Hsg.' = '220-URH'
    '221(d)(3) BMIR Urban Renewal/ Coop Hsg' = '221-3-BMIR-URC'
    '221(d)(3) Mkt. Rate Moderate Inc/ Disp Fams' = '221-3-MRMI'
    '221(d)(4) Mkt. Rate Mod Inc/ Disp Fams' = '221-4-MRMI'
    '223(a)(7)/207/223(f) Refinanced Insurance' = '223/207/223-RI'
    '223(a)(7)/220 Refi/ Urban Renewal' = '223/220-RUR'
    '223(a)(7)/221(d)(3) MKT Refi/ Moderate Income' = '223/221-3-MRMI'
    '223(a)(7)/221(d)(4) MKT  Refi/ Moderate Income' = '223/221-4-MRMI'
    '223(a)(7)/221(d)(4) MKT/244 Refi/Mod Income Co-In' = '223/221/244-MRMI'
    '223(a)(7)/232 Refi/ Nursing Home' = '223/232-RNH'
    '232 Nursing Homes' = '232-NH'
    '232/ 223(f)/Pur/Refin/ Nursing Hms' = '232/223-PRNH'
    '236(j)(1)/ Lower Income Families' = '236-LIF'
    '241(a)/ 221-BMIR Improvements & Additions' = '241/221-BMIRIA'
    '542(b) QPE Risk Sharing-Recent Comp' = '542-QPE-RC'
    '542(b)QPE Risk Sharing-Existing' = '542-QPE-E'
    '542(c) HFA Risk Sharing-Existing' = '542-HFA-E'
    '542(c) HFA Risk Sharing-Recent Comp' = '542-HFA-RC'
    'CDBG' = 'CDBG'
    'DC Housing Production Trust Fund' = 'DC-HPTF'
    'HOME' = 'HOME'
    'Low Income Housing Tax Credit' = 'LIHTC'
    'McKinney Vento Act loan' = 'MCKINNEY'
    'Public housing' = 'PUBHSNG'
    'Tax exempt bond' = 'TEBOND'
    other = ' ';

** Fix problem with date for V202 **;

data DC_Info;

  set PresCat.DC_Info_10_19_14;
  
  ** Apply standard corrections **;
  
  %DCInfo_corrections()
  
  v202_start_n = input( v202_start, mmddyy12. );
  
  format v202_start_n mmddyy10.;
  
  rename v202_start_n=v202_start v202_start=v202_start_xxx;
  
run;

/** Macro print_subsidy - Start Definition **/

%macro print_subsidy( subsidy );

  proc print data=DC_Info;
    where &subsidy._source ~= "";
    var &subsidy._: ;
  run;

%mend print_subsidy;

/** End Macro Definition **/


/*
%print_subsidy( cdbg )
%print_subsidy( dcha )
%print_subsidy( fha )
%print_subsidy( home )
%print_subsidy( hptf )
%print_subsidy( lihtc )
%print_subsidy( mckin )
%print_subsidy( tebond )
%print_subsidy( v202 )
%print_subsidy( v236 )
*/

%global sub_list;

%let sub_list = ;

/** Macro compile_subsidy - Start Definition **/

%macro compile_subsidy( sub, units=_assunits, poa=y );

  %local program;

  %let sub = %lowcase( &sub );
  %let poa = %lowcase( &poa );
  
  %let sub_list = &sub_list Subsidy_&sub;

  /*
  proc freq data=PresCat.DC_Info_10_19_14;
    tables &sub._source;
  run;

  proc freq data=PresCat.DC_Info_10_19_14;
    tables &sub._prog;
  run;
  */

  data Subsidy_&sub;
  
    set DC_Info;
    where &sub._source ~= "";
    
    length Program $ 32;
    
    %if &sub = cdbg %then %do;
       program = "CDBG";
    %end;
    %else %if &sub = dcha %then %do;
       program = "PUBHSNG";
    %end;
    %else %if &sub = home %then %do;
       program = "HOME";
    %end;
    %else %if &sub = mckin %then %do;
       program = "MCKINNEY";
    %end;
    %else %if &sub = hptf %then %do;
       program = "DC-HPTF";
    %end;
    %else %if &sub = lihtc %then %do;
       program = "LIHTC";
    %end;
    %else %if &sub = tebond %then %do;
       program = "TEBOND";
    %end;
    %else %do;
       program = put( &sub._prog, $oldcattoprog. );
    %end;    
        
    Units_assist = &sub.&units;
    
    %if &poa = y %then %do;
      
      POA_start = &sub._start;
      POA_end = &sub._end;
  
      format POA_start POA_end mmddyy10.;
    
    %end;
    %else %do;
    
      POA_start = .;
      POA_end = .;
      
    %end;
    
    length 
      Subsidy_Active 3
      Subsidy_Info_Source_ID $ 40
      Subsidy_Info_Source_Var $ 32
      Subsidy_Info_Source $ /*16*/ 40
      Subsidy_Info_Source_Date 8
      Update_Dtm 8
    ;
    
    Subsidy_Active = 1;
    
    if &sub._source =: "Housing Data Report" then Subsidy_Info_Source = "DC/HSNGDAT";
    else if &sub._source =: "Affordable Housing Pipeline" then Subsidy_Info_Source = "DC/AFFPIPELINE";
    else if &sub._source =: "DCHFA Pipeline" then Subsidy_Info_Source = "DC/HFAPIPELINE";
    else if &sub._source =: "HUD - Office of Community Planning and Development" then Subsidy_Info_Source = "HUD/OCPD";
    else if &sub._source =: "HUD - LIHTC Database" then Subsidy_Info_Source = "HUD/LIHTC";
    else if &sub._source =: "HUD LIHTC Database" then Subsidy_Info_Source = "HUD/LIHTC";
    else do;
      ** TEMPORARY CODING **;
      Subsidy_Info_Source = scan( &sub._source, 1, '(' );
    end;
    /*
    else do;
      %err_put( msg="Data source not recognized. " _n_= nlihc_id= &sub._source= )
    end;
    */

  if indexc( &sub._source, '(' ) > 0 then do;

    Subsidy_Info_Source_Date = 
      input( 
        substr( &sub._source, 
                indexc( &sub._source, '(' ) + 1, 
                indexc( &sub._source, ')' ) - ( indexc( &sub._source, '(' ) + 1 ) ),
        anydtdte12. );
    
  end;
  else do;
  
    Subsidy_Info_Source_Date = .u;
    
  end;
  

    Subsidy_Info_Source_ID = "";
    Subsidy_Info_Source_Var = "";

    Update_Dtm = datetime();
    
    format Subsidy_Active dyesno. Subsidy_Info_Source_Date mmddyy10. Update_Dtm datetime16.;
    
    keep NLIHC_ID Program Units_assist POA_start POA_end Subsidy_: Update_Dtm;
  
  run;
  
  /*%File_info( data=Subsidy_&sub., freqvars=Program Subsidy_Info_Source, printobs=0 )*/
  
%mend compile_subsidy;

/** End Macro Definition **/

%compile_subsidy( cdbg )
%compile_subsidy( dcha, units=_units, poa=n )
%compile_subsidy( fha, units=_units )
%compile_subsidy( home )
%compile_subsidy( hptf )
%compile_subsidy( lihtc )
%compile_subsidy( mckin )
%compile_subsidy( tebond )
%compile_subsidy( v202, units=_units )
%compile_subsidy( v236, units=_units )

data PresCat.Subsidy_other;

  set &sub_list;
  
  ** Correct compliance and affordability end dates for LIHTC projects **;
  
  if program = "LIHTC" and not( missing( poa_start ) ) then do;
    Compl_end = intnx( 'year', poa_start, 15, 'same' );
    Poa_end = intnx( 'year', poa_start, 30, 'same' );
  end;
  else if program ~= "LIHTC" then do;
    Compl_end = poa_end;
  end;
  
  format Compl_end mmddyy10.;
  
run;

proc sort data=PresCat.Subsidy_other;
  by nlihc_id program;
run;

%File_info( data=PresCat.Subsidy_other, freqvars=Program Subsidy_Info_Source, printobs=10 )

**** Compare with earlier version ****;

libname comp 'D:\DCData\Libraries\PresCat\Data\Old';

proc sort data=Comp.Subsidy_other out=Subsidy_other;
  by nlihc_id program;
run;

proc compare base=Subsidy_other compare=PresCat.Subsidy_other maxprint=(40,32000);
  id nlihc_id program;
run;
