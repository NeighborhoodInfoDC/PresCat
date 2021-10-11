/**************************************************************************
 Program:  Contents_dc_info.sas
 Library:  PresCat
 Project:  NeighborhoodInfo DC
 Author:   P. Tatian
 Created:  10/19/14
 Version:  SAS 9.2
 Environment:  Local Windows session (desktop)
 
 Description:  Contents of DC_info data set.

 Modifications:
**************************************************************************/

%include "\\sas1\DCdata\SAS\Inc\StdLocal.sas";

** Define libraries **;
%DCData_lib( PresCat, local=n )

%File_info( data=PresCat.DC_info, freqvars=category mfa_prog fha_prog v202_PROG v236_PROG)

proc print data=PresCat.DC_info_10_19_14;
  where nlihc_id = '';
  title2 'Missing NLIHC_ID';
run;

proc print data=PresCat.DC_info_10_19_14;
  where not( missing( ID_MFA ) );
  id nlihc_id;
  var Proj_Name ID_MFA MFA_PROG MFA_START MFA_END MFA_ASSUNITS;
  title2 'MFA data';
run;

proc sort data=PresCat.DC_info out=DC_info;
  by nlihc_id;

proc sort data=PresCat.DC_info_10_19_14 out=DC_info_10_19_14;
  by nlihc_id;

proc compare base=DC_info compare=DC_Info_10_19_14 maxprint=(40,32000) listcompobs;
  id nlihc_id;
run;
