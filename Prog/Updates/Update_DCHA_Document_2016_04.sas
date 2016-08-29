/**************************************************************************
 Program:  Update_DCHA_Document_2016_04.sas
 Library:  PresCat
 Project:  NeighborhoodInfo DC
 Author:   K. Abazajian
 Created:  08/29/2016
 Version:  SAS 9.2
 Environment:  Local Windows session (desktop)
 
 Description:  Make manual adjustments to projects with edits from DCHA (04/16)

 Modifications:
**************************************************************************/

%include "L:\SAS\Inc\StdLocal.sas";

** Define libraries **;
%DCData_lib( PresCat, local=n, rreadonly=n )

data prescat.subsidy;
set prescat.subsidy; 
*Capitol Gateway Senior Estates;
if Nlihc_id= "NL001000" & Portfolio="PUBHSNG" then delete;
*Capitol Gateway Townhomes part of single family;
if nlihc_id = "NL000375" then delete;
*Fort lincoln no LIHTC all pub housing;
if nlihc_id = "NL000110" & program="LIHTC" then delete; 
*Capper Senior duplicate;
if nlihc_id = "NL001019" then delete;
*Added new subsidy row(subsidy_id=5) for PUBHSNG Glenncrest, 61 units;
*Henson UFAs;
if nlihc_id = "NL000388" & Subsidy_id=3 then Units_Assist=22 ;
*Added new subsidy row (subsidy_id=5) for PUBHSNG Gibson Plaza, 53 units;
*Added new subsidy rows (subsidy_id=3,4) for PUBHSNG and LIHTC Phyllis Wheatley, 76 and 6 units resp.;
*Pollin memorial;
if nlihc_id="NL000353" & subsidy_id=1 then do;
	Program="PUBHSNG";
	Subsidy_Info_Source = "DCHA Document";
end;
*Added new subsidy rows (subsidy_id=4) for PUBHSNG St. Martin's, 50 out of 178 total units;
*The Avenue;
if nlihc_id = "NL000225" then Units_Assist=27;
*Added new subsidy row (subsidy_id=2) for LIHTC The Avenue, 83 units;
*Triangle View;
if nlihc_id="NL000419" then Units_Assist=25;
*Williston; 
if nlihc_id="NL000303" & subsidy_id=2 then do; 
 Subsidy_Info_Source="DCHA Document";
 Program="PUBHSNG";
 end;

*FROM APSH;
if Nlihc_id="NL000034" then do;Units_Assist=439;Subsidy_Info_Source="APSH";end;*previous source-DCHA website;
if nlihc_id="NL000043" then do;Units_Assist=284;Subsidy_Info_Source="APSH";end;

run;
data prescat.project;
set prescat.project;
/*Parkway Overlook ownership*/
if Nlihc_id= "NL000234" then Hud_Own_Name="Parkway Overlook, LP (DCHA affiliate)";
*Capitol Gateway Townhomes part of single family;
if nlihc_id = "NL000375" then delete;
*Capper Senior duplicate;
if nlihc_id = "NL001019" then delete;
*Glenncrest;
if nlihc_id = "NL000085" then Proj_Units_Tot=61;
*Henson UFAs;
if nlihc_id = "NL000388" then Proj_Units_Assist_Max=22 ;
if nlihc_id = "NL000388" then Hud_Mgr_Name="Edgewood Management Corporation";
*Highland Dwellings;
if nlihc_id = "NL000157" then Hud_Mgr_Name="CIH Properties, Inc." & Hud_Own_Name="Highland Dwellings Residential, LP";
*Phyllis Wheatley - note HPTF subsidy says it covers 117 units, left in subsidy file;
if nlihc_id="NL000242" then Proj_Units_Tot=84;
if nlihc_id="NL000242" then Proj_Units_Assist_Min = 6; 
*St. Martin;
if nlihc_id = "NL000384" then Proj_Units_Assist_Min=50;
*The Avenue;
if nlihc_id = "NL000225" then Proj_Units_Assist_Min=27;
if nlihc_id = "NL000225" then Proj_Units_assist_Max=83;
*Triangle View;
if nlihc_id="NL000419" then Proj_Units_Tot=100;
if nlihc_id="NL000419" then Proj_Units_Assist_Min=25;
*Williston;
if nlihc_id="NL000303" then do;
	Proj_Units_Tot=28;
	Proj_Units_Assist_Min=28;
	Proj_Units_Assist_Max=28;
end;

run;
*To add to catalog: 
1475 Columbia Rd , Public Housing
Nannie Helen Burroughs, Public Housing
Matthews Memorial Terrace Apartments, Public Housing
Sheridan Station Phase I (Multifamily), PH
Victory Square Senior Apartments , PH
