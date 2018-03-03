/**************************************************************************
 Program:  Update_LIHTC_2013.sas
 Library:  PresCat
 Project:  NeighborhoodInfo DC
 Author:   P. Tatian
 Created:  05/31/17
 Version:  SAS 9.2
 Environment:  Local Windows session (desktop)
 
 Description:  Update Preservation Catalog with HUD LIHTC data.

 Modifications:
**************************************************************************/

%include "L:\SAS\Inc\StdLocal.sas";

** Define libraries **;
%DCData_lib( PresCat )
%DCData_lib( HUD )
%DCData_lib( MAR )


%Update_LIHTC( Update_file=Lihtc_2013, quiet=n,
  manual_subsidy_match=
    if nlihc_id = 'NL001005' and subsidy_id = 5 then do;
      subsidy_info_source_id = 'DCB2009020';
      subsidy_info_source = 'HUD/LIHTC';
    end;
  ,
  address_correct=
    if proj_add = "3400 C J BARNEY DR NE" then proj_add = "3400 CJ BARNEY DR NE";
)

