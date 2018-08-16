/**************************************************************************
 Program:  Read_ODCA_HPTFdatabase.sas
 Library:  PRESCAT
 Project:  NeighborhoodInfo DC
 Author:   M. Cohen
 Created:  8/13/18
 Version:  SAS 9.2
 Environment:  Local Windows session (desktop)
 
 Description:  Read data from ODCA Housing Production Trust Fund Database.

 Modifications:
**************************************************************************/

%include "L:\SAS\Inc\StdLocal.sas";

** Define libraries **;
%DCData_lib( PRESCAT )
%DCData_lib( MAR )

data 
    ODCA_HPTF;
 infile "L:\Libraries\PresCat\Raw\ODCA\HPTF-Public-Database.csv" dsd stopover lrecl=2000 firstobs=7;
input
Date : $10.
Borrower_name : $40.
Project_name : $40.
Single_multiple : $20.
Project_type : $40.
Award_amount : dollar10.
Exp_per_soar : dollar10.
Property_type : $20.
Address : $60.
Ward : 1.
Num_units : 3.
Ami_0_30 : 3.
Ami_31_50 : 3.
Ami_51_80 : 3.
Aff_z : $50.
Notes : $200.;

start_date = input(date,MMDDYY10.);
aff_x = compress(aff_z, ,"a s");
if aff_x = "" then aff_x = .;
if aff_x = "1540" then notes = "Also a 2016 construction loan. Of the 14 units, 10 units are reserved for DBH consumers. 
The 2016 agreement reduced the units from the 2008 agreement, which stipulated 214 affordable units for 60% AMI. 
15 year affordability for ownership, 40 for rental";
if aff_x = "4015" then notes = "15 year affordability for ownership, 40 for rental";
if aff_x = "4015" or aff_x = "1540" then aff_x = "40";

format start_date mmddyy10.
exp_per_soar dollar10.0
award_amount dollar10.0;
per_afford = input (aff_x, 3.);


label
date = "Unformatted date"
Start_date = "Award date"
Borrower_name = "Name of borrower"
Project_name ="Project name"
Single_multiple ="Single or multifamily project"
Project_type ="Purpose of the award"
Award_amount ="Award amount"
Exp_per_soar ="Total expenditures per SOAR"
Property_type ="Type of property"
Address ="Project address"
Ward ="Ward"
Num_units = "Number of affordable units"
Ami_0_30 = "Number of affordable units at 0-30% AMI"
Ami_31_50 = "Number of affordable units at 31-50% AMI"
Ami_51_80 = "Number of affordable units at 51-80% AMI"
Per_afford= "Period of Affordability"
Notes = "Notes"
;

drop aff_:;

run;


** Geocode **;

 %DC_mar_geocode(
  data = odca_hptf,
  staddr = address,
  zip=,
  out = odca_hptf_mar,
  geo_match = Y,
  streetalt_file=,
  debug = Y,
  mprint = Y
);
