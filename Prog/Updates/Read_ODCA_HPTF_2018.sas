/**************************************************************************
 Program:  Read_ODCA_HPTF_2018.sas
 Library:  PresCat
 Project:  NeighborhoodInfo DC
 Author:   P. Tatian
 Created:  03/21/18
 Version:  SAS 9.2
 Environment:  Local Windows session (desktop)
 
 Description:  Read database of HTPF-Funded Properties from 2001-2016
 published by the DC Office of the Auditor, 3/20/2018. 

 Source: 
 http://www.dcauditor.org/sites/default/files/HPTF-Public-Database.xlsx

 Modifications:
**************************************************************************/

%include "\\sas1\DCdata\SAS\Inc\StdLocal.sas";

** Define libraries **;
%DCData_lib( PresCat )

proc format;
  value $odca_hptf_project_type
    'M' = 'Multifamily'
    'S' = 'Single family'
    'U' = 'Unknown';
run;

filename fimport "&_dcdata_r_path\PresCat\Raw\ODCA\HPTF-Public-Database.csv" lrecl=2000;

data ODCA_HPTF_2018;

  ** Read raw data **;

  infile fimport delimiter = ',' stopover dsd firstobs=7 obs=237;
  
  Odca_record_number + 1;
  
  input 
    _Award_date : $80.
    Borrower_name : $300.
    Project_name : $120.
    _Project_type : $80.
    Award_purpose : $120.
    Award_amount : dollar32.
    Total_expenditures : dollar32.
    Property_type : $24.
    Addresses : $300.
    Ward : $8. 
    _Affordable_units : $80.
    _Units_30_pct_ami : $80.
    _Units_50_pct_ami : $80.
    _Units_80_pct_ami : $80.
	Affordability_period_desc : $80.
    Notes : $300.
  ;
  
  ** Create cleaned/recoded variables **;

  Notes = left( compbl( Notes ) );

  if length( _Award_date ) = 4 then do;
    Award_date = mdy( 1, 1, input( _Award_date, 20. ) );
	Exact_award_date = 0;
  end;
  else do; 
    Award_date = input( _Award_date, mmddyy20. );
	Exact_award_date = 1;
  end;

  if Project_name = '-' then Project_name = '';

  length Project_type $ 1;

  select( _Project_type );
    when ( 'Multi family' ) Project_type = 'M';
    when ( 'Single' ) Project_type = 'S';
    when ( 'Unknown' ) Project_type = 'U';
  end;

  Award_purpose = left( tranwrd( compbl( Award_purpose ), "/ ", "/" ) );

  Property_type = left( tranwrd( compbl( Property_type ), "/ ", "/" ) );

  if Property_type = 'Unknown' then Property_type = 'Not Provided';

  Addresses = left( compbl( Addresses ) );

  if Addresses = "multiple, see Notes" then do; 
    Addresses = Notes;
	Notes = "";
  end;
  else if Addresses = "Not Provided" then Addresses = "";

  if _Units_30_pct_ami =: "Number not provided" then do;
    Notes = trim( Notes ) || " / 0-30% AMI units: " || _Units_30_pct_ami;
	_Units_30_pct_ami = '.u';
  end;

  array a{*} _Affordable_units _Units_: ;

  do i = 1 to dim( a );
    if a{i} = '-' then a{i} = '.u';
  end;

  Affordable_units = input( _Affordable_units, 12. );
  Units_30_pct_ami = input( _Units_30_pct_ami, 12. );
  Units_50_pct_ami = input( _Units_50_pct_ami, 12. );
  Units_80_pct_ami = input( _Units_80_pct_ami, 12. );

  Affordability_period_desc = %capitalize( Affordability_period_desc );
  Affordability_period_desc = left( compbl( Affordability_period_desc ) );

  length buff $ 500;

  buff = tranwrd( upcase( Affordability_period_desc ), "YEARS", "" );

  i = max( index( buff, "FOR OWNERSHIP" ), index( buff, "FOR HOMEOWNERSHIP" ) );

  if i > 0 then Affordability_years_owner = input( scan( substr( buff, 1, i - 1 ), -1, ' ' ), 8. );

  i = index( buff, "FOR RENTAL" );

  if i > 0 then Affordability_years_rental = input( scan( substr( buff, 1, i - 1 ), -1, ' ' ), 8. );

  if missing( Affordability_years_owner ) then do;

    if buff = "NOT PROVIDED" then i = .u;
	else i = input( buff, 8. );

    select ( Property_type );
	  when ( 'Lease-to-own' ) do;
	    Affordability_years_rental = i;
		Affordability_years_owner = i;
	  end;
	  when ( 'Not Provided' ) do;
	    Affordability_years_rental = .u;
		Affordability_years_owner = .u;
	  end;
	  when ( 'Owner' ) do;
	    Affordability_years_rental = .n;
		Affordability_years_owner = i;
	  end;
	  when ( 'Rental' ) do;
	    Affordability_years_rental = i;
		Affordability_years_owner = .n;
	  end;
	  when ( 'Owner/Rental', 'Rental/Owner' ) do;
	    Affordability_years_rental = i;
		Affordability_years_owner = i;
	  end;
	end;

  end;
  
  label
    Odca_record_number = "Project record number in ODCA database"
    Addresses = "Project addresses"
    Affordability_period_desc = "Affordability period (description provided by ODCA)"
    Affordability_years_owner = "Years of affordability, owner units"
    Affordability_years_rental = "Years of affordability, rental units"
    Affordable_units = "Number of affordable units"
    Award_amount = "Award amounts ($)"
    Award_date = "Award date"
    Award_purpose = "Purpose of HPTF award(s)"
    Borrower_name = "Borrower name"
    Exact_award_date = "Exact award date provided (0 = only year provided)"
    Notes = "Notes, if applicable"
    Project_name = "Project name"
    Project_type = "Project type"
    Property_type = "Property type"
    Total_expenditures = "Total expenditures per SOAR ($)"
    Units_30_pct_ami = "Affordable units at 0-30% AMI"
    Units_50_pct_ami = "Affordable units at 31-50% AMI"
    Units_80_pct_ami = "Affordable units at 51-80% AMI"
    Ward = "Ward of project (provided by ODCA)"
   ; 

  format Award_date mmddyy10. Exact_award_date dyesno. Project_type $odca_hptf_project_type.;

  drop i buff _: ;
    
run;

filename fimport clear;

%Finalize_data_set( 
  /** Finalize data set parameters **/
  data=ODCA_HPTF_2018,
  out=ODCA_HPTF_2018,
  outlib=PresCat,
  label="Office of the DC Auditor, HTPF-funded properties from 2001-2016",
  sortby=Odca_record_number,
  /** Metadata parameters **/
  restrictions=None,
  revisions=%str(New file.),
  /** File info parameters **/
  printobs=10,
  freqvars=Project_type Award_purpose Property_type Affordability_period_desc
)


run;

