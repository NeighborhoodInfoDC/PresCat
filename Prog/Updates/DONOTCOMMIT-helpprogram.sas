*subsidy delete;

/*Units to be deleted*/
*Capitol Gateway Senior Estates;
if Nlihc_id= "NL001000" & Portfolio="PUBHSNG" then delete;
*Capitol Gateway Townhomes part of single family;
if nlihc_id = "NL000375" then delete;
*Fort lincoln no LIHTC all pub housing;
if nlihc_id = "NL000110" & program="LIHTC" then delete; 
*Capper Senior duplicate;
if nlihc_id = "NL001019" then delete;
*Glenncrest;
if nlihc_id = "NL000085" & program="HPTF" then delete;
  
*project delete;
/*Units to be deleted*/
*Capitol Gateway Townhomes part of single family;
if nlihc_id = "NL000375" then delete;
*Capper Senior duplicate;
if nlihc_id = "NL001019" then delete;


/***************************************************************************/
/**UPDATE PROJECT DATA**/

data update_project;
set prescat.project;
/*Parkway Overlook ownership*/
if Nlihc_id= "NL000234" then Hud_Own_Name="Parkway Overlook, LP (DCHA affiliate)";

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
