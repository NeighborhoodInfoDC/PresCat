/**************************************************************************
 Program:  Update_LIHTC_2024_remote.sas
 Library:  PresCat
 Project:  Urban-Greater DC
 Author:   P. Tatian
 Created:  09/03/2026
 Version:  SAS 9.4
 Environment:  Remote session (SAS1)
 
 Description:  Update Preservation Catalog with HUD LIHTC data.

 Modifications:
**************************************************************************/

%include "F:\DCData\SAS\Inc\StdRemote.sas";

** Define libraries **;
%DCData_lib( PresCat )
%DCData_lib( HUD )
%DCData_lib( MAR )


%Update_LIHTC( Update_file=Lihtc_2024, quiet=y,
  manual_subsidy_match=
  ,
  address_correct=
   
)

