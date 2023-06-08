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

%let dsname="\\sas1\dcdata\Libraries\PresCat\Raw\TOPA\draft-combined pipeline 5+ - Combined.csv";

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
	 datarow=3;  /** Skip first 2 rows which have variable names and labels **/
	guessingrows=max;

run;

data DC_Pipeline_2022_07; 
	set DC_Pipeline;
	_30__Unit_Sizes_Complete = input(_30__Unit_Sizes_Complete_, 8.);
	_30_AMI_LRSP = input(_30__AMI___LRSP, 8.);
/*	drop _30__Unit_Sizes_Complete_ _30__AMI___LRSP; putting variables together to drop*/ 
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
	label Project_name = 'Project Name'
		Address = 'Address'
		SSL = 'SSL'
		Developer = 'Developer'
		FRPP_loan_amount = 'First Right Purchase Program (FRPP) Loan Amount'
		FRPP_loan_covenant_terms = 'First Right Purchase Program (FRPP) Loan Covenant Terms'
		SAFI_loan_amount = 'SIte Acquisition Funding Initiative (SAFI) Loan Amount'
		SAFI_loan_covenant_terms = 'Site Acquisition Funding Initiative (SAFI) Loan Covenant Terms'
		HPF_loan_amount = 'Housing Preservation Fund (HPF) Loan Amount'
		HPF_loan_covenant_terms = 'Housing Preservation Fund (HPF) Loan Covenant Terms'
		application_fiscal_year = 'Consolidated RFP/NOFA App Fiscal Year'
		selection_fiscal_year = 'Selection Fiscal Year'
		selection_date = 'Selection Date'
		application_type = 'Application Type'
		In_TOPA_spreadsheet = 'In TOPA spreadsheet?'
		TOPA_notice_date = 'TOPA Notice Date(s)'
		TA_registration_date = 'TA Registration Date'
		Limited_equity_coop = 'Limited Equity Coop?'
		LEC_year_formed = 'If LEC, Year Formed'
		LEC_dev_consultant = 'If LEC, Dev. Consultant'
		PADD_project = 'PADD project'
		DMPED_project = 'DMPED Project'
		Tenure = 'Tenure'
		Project_type_or_scope = 'Project Type/Scope'
		New_construction_or_preservation = 'New Construction or Preservation'
		deed_verified = 'Deed Verified'
		complete_unit_count = 'Complete Unit Count'
		repl_30_AMI_units = 'Replacement 30% AMI Units'
		units_0_to_30 = '0-30% AMI Units'
		units_31_to_50 = '31-50% AMI Units'
		units_51_to_60 = '51-60% AMI Units'
		units_61_to_80 = '61-80% AMI Units'
		units_81_to_market_rate = '81%+ AMI / Market Rate'
		psh_units = 'PSH Units'
		affordable_units = 'Affordable Units'
		total_units = 'Total Units'
		LRSP_units_new = 'LRSP Units (New)'
		existing_rental_assistance = 'Existing Rental Assistance In Project'
		Existing_RA_Type = 'Type of Existing Rental Assistance'
		LRSP_Contract_Status = 'LRSP Contract Status'
		LRSP_Contr_Council_Sub_Date = 'LRSP Contract Council Submit Date'
		LRSP_Contract_LIMS_Link = 'LRSP Contract LIMS Link'
		LRSP_Contract_Amount = 'LRSP Contract Amount'
		LRSP_per_unit = 'LRSP/Unit'
		Source_for_LRSP_Information = 'Source for LRSP Information'
		LRSP_30_percent_units = '30% AMI - LRSP'
		Average_AMI = 'Average AMI'
		Total_Development_Costs_(TDC) = 'Total Development Costs (TDC)'
		TDC_per_unit = 'TDC/Unit'
		loan_amount_to_TDC_ratio = 'Loan Amount / TDC'
		HPTF_amount = 'HPTF'
		TCE_Amount = 'TCE'
		HOPWA_Amount = 'Housing Opportunities for Persons With AIDS (HOPWA)'
		CIP_Amount = 'Community Investment Program'
		NSP_Amount = 'Neighborhood Stabilization Program'
		CDBG_Amount = 'Community Development Block Grant (CDBG)'
		HUD_HOME_Amount = 'HOME funds from HUD'
		Dept_of_Behavioral_Health_Amount = 'Department of Behavorial Health (DBH)'
		National_HTF_Amount = 'National Housing Trust Fund (HTF)'
		Loan_or_Grant_Amount = 'Loan/Grant Amount'
		Loan_Amount_Per_Affordable_Unit = 'Loan Amount Per Affordable Unit'
		Council_Submission = 'Council Submission'
		LIHTC_Annual_Allocation = 'LIHTC Annual Allocation'
		LIHTC_Type = 'LIHTC Type'
		Construction_Status = 'Construction Status'
		Loan_Status = 'Loan Status'
		Proj_or_Act_Loan_Closing_Date = 'Projected or Actual Loan Closing Date'
		Proj_or_Act_Closing_FY = 'Projected or Actual Closing Fiscal Year'
		App_to_Closing = 'App to Closing'
		HPTF_30_AMI_Unit_Cost = 'HPTF 30% AMI Unit Cost'
		Proportional_HPTF_30_AMI = 'Proportional HPTF 30% AMI'
		DHCD_HPTF_30_AMI = 'DHCD HPTF 30% AMI'
		DHCD_HPTF_30_AMI_Illustrative = 'DHCD HPTF 30% AMI Illustrative'
		DHCD_HPTF_30_AMI_Method2 = 'DHCD HPTF 30% AMI Method2'
		Previously_Funded = 'Prevously Funded?'
		Previous_Funding_Date = 'Previous Funding Date'
		Previous_Funding_Amount = 'Previous Funding Amount'
		Previous_Funding_Type = 'Previous Funding Type'
		Previous_Funding_Source = 'Previous Funding Source'
		Thirty_perc_unit_sizes_compl = '30% Unit Sizes Complete?'
		Singles_Units = 'Singles Units'
		Family_Units = 'Family Units'
		Share_Family_Units = 'Share Family Units'
		Sum_of_Unit_Detail = 'Sum of Unit Detail'
		Complete_Unit_Detail = 'Complete Unit Detail?'
		Address_for_MAR = 'Address for MAR'
		MAR_MATCHADDRESS = 'MAR_MATCHADDRESS'
		MAR_WARD = 'MAR_WARD'
		MAR_LATITUDE = 'MAR_LATITUDE'
		MAR_LONGITUDE = 'MAR_LONGITUDE'
		MAR_TRACT = 'MAR_TRACT'
		MAR_ID = 'MAR_ID'
		Notes = 'Notes'

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
