/**************************************************************************
 Program:  Lost_rental_review.sas
 Library:  PresCat
 Project:  NeighborhoodInfo DC
 Author:   P. Tatian
 Created:  11/25/14
 Version:  SAS 9.2
 Environment:  Local Windows session (desktop)
 
 Description:  Data for review of lost rental properties.

 Modifications:
**************************************************************************/

%include "L:\SAS\Inc\StdLocal.sas";

** Define libraries **;
%DCData_lib( PresCat )

proc print data=PresCat.Subsidy;
  where nlihc_id in ( 'NL000055', 'NL000096', 'NL000307', 'NL000416', 'NL000196', 'NL000094' );
  id nlihc_id ;
  var contract_number Program;
run;
