/**************************************************************************
 Program:  Check_APSH_PH_062016.sas
 Library:  PresCat
 Project:  NeighborhoodInfo DC
 Author:   K. Abazajian
 Created:  06/16/2016
 Version:  SAS 9.2
 Environment:  Local Windows session (desktop)
 
 Description:  Read in local APSH dataset and compare to PresCat subsidy data

 Modifications:
**************************************************************************/

%include "L:\SAS\Inc\StdLocal.sas";

** Define libraries **;
%DCData_lib( PresCat, local=n, rreadonly=n )
libname raw "D:\DCData\Libraries\PresCat\Raw";\

%let outlib = %mif_select( &_remote_batch_submit, PresCat, WORK );

/*Flag NLIHC_IDs with Public Housing as program (some receive other subs)*/
data subsidy_pubhsng (keep=Nlihc_id pubhsng);
set PresCat.subsidy;
if program ~= "PUBHSNG " then delete;
pubhsng=1;
run;

/*Merge flag onto all subsidies*/
data all_subsidy_pubhsng;
merge PresCat.subsidy subsidy_pubhsng PresCat.project(keep=nlihc_id proj_name Proj_Addre);
by nlihc_id;
if pubhsng~=1 then delete;
run;

/*Merge one-time data pull [year] APSH data in SAS dataset filetype*/
data hudPicture2015_DC;
set raw.hudPicture2015_DC;
name=propcase(name);
run;

proc sort data=hudPicture2015_DC;by name;run;

proc sort data=all_subsidy_pubhsng; by proj_name;run;

/*First visual check for projects in APSH program=Public Housing, pubhsng~=1*/
data APSH_subsidy_check;
merge all_subsidy_pubhsng(in=a) hudPicture2015_DC(rename=(name=proj_name));
by proj_name;
run;
/*Second visual check for projects in catalog where pubhsng=1, APSH program~=Public Housing*/
data APSH_subsidy_check_2;
set APSH_subsidy_check;
if pubhsng~=1 then delete;
run;


/*VISUAL CHECK of subsidy_check data

2015 APSH Notes 
(projects in APSH as PH, not in catalog): 
1475 Columbia Rd 
Nannie Helen Burroughs 
Edgewood Terrace Seniors Development(Edgewood III is in catalog as PH, not seniors)
Matthews Memorial Terrace Apartments 
Sheridan Station Phase I (Multifamily) 
Victory Square Senior Apartments

(projects in catalog as PH, different in APSH):
Sursum Corda NL000287 in APSH as Section 8


Other discrepancies were updated in DCData\Libraries\PresCat\Prog\Updates\Update_DCHA_Document_2016_04.sas
*/

