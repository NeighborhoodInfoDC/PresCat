/**************************************************************************
 Program:  Update_LIHTC_2020.sas
 Library:  PresCat
 Project:  NeighborhoodInfo DC
 Author:   D. Harvey
 Created:  07/22/22
 Version:  SAS 9.2
 Environment:  Local Windows session (desktop)
 
 Description:  Update Preservation Catalog with HUD LIHTC data.

 Modifications:
**************************************************************************/

%include "\\sas1\DCdata\SAS\Inc\StdLocal.sas";

** Define libraries **;
%DCData_lib( PresCat )
%DCData_lib( HUD )
%DCData_lib( MAR )


%Update_LIHTC( Update_file=Lihtc_2020, quiet=y,
  manual_subsidy_match=
  ,
  address_correct=
   
)

