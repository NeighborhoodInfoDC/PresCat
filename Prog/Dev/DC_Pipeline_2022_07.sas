/**************************************************************************
 Program:  DC_Pipeline_2022_07.sas
 Library:  PresCat
 Project:  Urban Greater DC
 Author:   Elizabeth Burton
 Created:  07/26/2022
 Version:  SAS 9.4
 Environment:  Local Windows session (desktop)
 
 Description:  combined pipeline 5+ dataset in PresCat library (TOPA study)

 Modifications:
**************************************************************************/

%include "\\sas1\DCdata\SAS\Inc\StdLocal.sas";

** Define libraries **;
%DCData_lib( PresCat )

%let dsname="\\sas1\dcdata\Libraries\PresCat\Raw\TOPA\combined_pipeline_5.csv";

filename fixed temp;
/** Remove carriage return and line feed characters within quoted strings **/
/*'0D'x is the hexadecimal representation of CR and
/*'0A'x is the hexadecimal representation of LF.*/
/* Replace carriage return and linefeed characters inside */
/* double quotes with a specified character.  */
/* CR/LFs not in double quotes will not be replaced. */
%let repA=' || '; /* replacement character LF */
%let repD=' || '; /* replacement character CR */
 data _null_;
 /* RECFM=N reads the file in binary format. The file consists */
 /* of a stream of bytes with no record boundaries. SHAREBUFFERS */
 /* specifies that the FILE statement and the INFILE statement */
 /* share the same buffer. */
 infile &dsname recfm=n sharebuffers;
 file fixed recfm=n;
 /* OPEN is a flag variable used to determine if the CR/LF is within */
 /* double quotes or not. Retain this value. */
 retain open 0;
 input a $char1.;
 /* If the character is a double quote, set OPEN to its opposite value. */
 if a = '"' then open = ^(open);
 /* If the CR or LF is after an open double quote, replace the byte with */
 /* the appropriate value. */
 if open then do;
 if a = '0D'x then put &repD;
 else if a = '0A'x then put &repA;
 else put a $char1.;
 end;
 else put a $char1.;
run;

proc import datafile=fixed
            dbms=csv
            out=DC_Pipeline
            replace;
		
     getnames=yes;
	 guessingrows=max;

run;

data DC_Pipeline_2022_07; 
	set DC_Pipeline;
	_30__Unit_Sizes_Complete = input(_30__Unit_Sizes_Complete_, 8.);
	_30_AMI_LRSP = input(_30__AMI___LRSP, 8.);
/*	drop _30__Unit_Sizes_Complete_ _30__AMI___LRSP;*/
	TDC_ = input(TDC, comma10.);
/*	drop TDC;*/
	TDCUnit = input(TDC_Unit, comma10.);
/*	drop TDC_Unit;*/
	TCE_ = input(TCE, comma10.);
/*	drop TCE;*/
/*	SumofUnit_Detail = input(Sum_of_Unit_Detail, 8.);*/
/*	drop Sum_of_Unit_Detail;*/
/*	Proportional_HPTF_30_AMI = input(Proportional_HPTF_30__AMI, comma10.);*/
/*	drop Proportional_HPTF_30__AMI;*/
/*	Previous_FundingAmount = input(Previous_Funding_Amount, comma10.);*/
/*	drop Previous_Funding_Amount;*/
/*	PADD_ = input(PADD, 8.);*/
/*	drop PADD;*/
/*	NSP_ = input(NSP, 8.);*/
/*	drop NSP;*/
/*	MARTRACT = input(MAR_TRACT, 8.);*/
/*	drop MAR_TRACT;*/
/*	Loan_GrantAmount = input(Loan_Grant_Amount, 8.);*/
/*	drop Loan_Grant_Amount;*/
/*	Loan_Amount_Per_AffordableUnit = input(Loan_Amount_Per_Affordable_Unit, comma10.);*/
/*	drop Loan_Amount_Per_Affordable_Unit;*/
/*	LRSP_ContractAmount = input(LRSP_Contract_Amount, comma10.);*/
/*	drop LRSP_Contract_Amount;*/
	format TOPA_Notice_Date_s_ TA_Registration_Date Selection_Date Projected_or_Actual_Loan_Closing Previous_Funding_Date LRSP_Contract_Council_Submit_Dat mmddyy10.;
run; 


proc print data=DC_Pipeline_2022_07;
run;

  %Finalize_data_set( 
    /** Finalize data set parameters **/
    data=DC_Pipeline_2022_07,
    out=DC_Pipeline_2022_07,
    outlib=PresCat,
    label="Preservation Catalog, new DC pipeline dataset (TOPA)",
    sortby=Project_Name,
    /** Metadata parameters **/
    revisions=%str(New data set.),
    /** File info parameters **/
    printobs=10,
	freqvars=
  )

  ***convert to numeric:
  Share_Family_Units (percent?)
  Selection_Fiscal_Year (year?)
  Proportional_HPTF_30__AMI
  Projected_or_Actual_Closing_Fisc (year?)
  Prevously_Funded_ -> change Y to 1/o
  Loan_Amount___TDC (percent?)
  LRSP_Units__New_
  LRSP_Unit
  LIHTC_Allocation
  LIHTC_Type (percent?)
  If_LEC__Year_Formed (year?) num now
  HPTF_30__AMI_Unit_Cost
  HPTF
  HOPWA
  HOME
  Family_Units
  Existing_Rental_Assistance_In_Pr
  Deed_Verified
  DMPED
  DHCD_HPTF_30__AMI
  DHCD_HPTF_30__AMI_Illustrative
  DHCD_HPTF_30__AMI_Method2 
  DBH
  Complete_Unit_Detail_
  CIP
  CDBG
  Average_AMI (percent?)
  App_to_Closing
  App_Fiscal_Year (year?)
