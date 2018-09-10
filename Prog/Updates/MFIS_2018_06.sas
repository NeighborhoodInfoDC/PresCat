/**************************************************************************
 Program:  MFIS_2018_06.sas
 Library:  HUD
 Project:  Urban-Greater DC
 Author:   Will Oliver
 Created:  9/10/2018
 Version:  SAS 9.4
 Environment:  Local Windows session (desktop)
 
 Description:  Compile HUD-insured multifamily mortgage data.
 Creates files for DC, MD, VA, and WV.
 
**************************************************************************/

%include "L:\SAS\Inc\StdLocal.sas";

** Define libraries **;
%DCData_lib( HUD )
%DCData_lib( RealProp )


*--- EDIT PARAMETERS BELOW -----------------------------------------;

%MFIS_read_update_file( 
  filedate = '31jul2018'd,  /** Enter date of HUD database as SAS date value, ex: '25nov2014'd **/
  revisions = %str(New file.)
)
  
run;
