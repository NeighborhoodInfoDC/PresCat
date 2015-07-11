/**************************************************************************
 Program:  Create_subsidy_except.sas
 Library:  PresCat
 Project:  NeighborhoodInfo DC
 Author:   P. Tatian
 Created:  01/09/15
 Version:  SAS 9.2
 Environment:  Local Windows session (desktop)
 
 Description:  Create initial subsidy exception data set (blank).

 Modifications:
**************************************************************************/

%include "L:\SAS\Inc\StdLocal.sas";

** Define libraries **;
%DCData_lib( PresCat, local=n )

data PresCat.Subsidy_except (label="Preservation Catalog, project subsidies exception file");

  set PresCat.Subsidy (obs=0);
  
  length Except_date 8 Except_init $ 8;
  
  label 
    Except_date = "Date exception added"
    Except_init = "Initials of person entering exception";
  
  format Except_date mmddyy10.;
  
  drop Subsidy_Info_Source Subsidy_Info_Source_Date Subsidy_Info_Source_ID Portfolio Update_dtm;

run;

%File_info( data=PresCat.Subsidy_except, stats= )

