/**************************************************************************
 Program:  Subsidy_fix_002.sas
 Library:  PresCat
 Project:  NeighborhoodInfo DC
 Author:   P. Tatian
 Created:  10/01/15
 Version:  SAS 9.2
 Environment:  Local Windows session (desktop)
 
 Description:  Add Subsidy_info_source_property and POA_end_actual to
 PresCat.Subsidy.

 Modifications:
**************************************************************************/

/*%include "L:\SAS\Inc\StdLocal.sas";*/
%include "C:\DCData\SAS\Inc\StdLocal.sas";

** Define libraries **;
%DCData_lib( PresCat, local=n )
%DCData_lib( HUD, local=n )

%Data_to_format(
  FmtLib=work,
  FmtName=$Hud_project_number2Premise_id,
  Desc=,
  Data=HUD.MFIS_2015_08_DC (where=(not(missing(Premise_id)))),
  Value=Hud_project_number,
  Label=Premise_id,
  OtherLabel=" ",
  DefaultLen=.,
  MaxLen=.,
  MinLen=.,
  Print=N,
  Contents=N
  )

data Subsidy;

  set PresCat.Subsidy;
  
  length Subsidy_info_source_property $40.;    
  
  if Subsidy_Info_Source = "HUD/MFA" then do;
    Subsidy_info_source_property = left( scan( subsidy_info_source_id, 1, '/' ) );
  end;
  else if Subsidy_Info_Source = "HUD/MFIS" then do;
    Subsidy_info_source_property = left( put( Subsidy_Info_Source_ID, $Hud_project_number2Premise_id. ) );
  end;
    
  if Subsidy_Active then POA_end_actual = .n;
  else POA_end_actual = .u;
  
  label
    Subsidy_info_source_property = "Unique property identifier for subsidy info source"
    POA_end_actual = "Actual date when subsidy ended";
    
  format POA_end_actual mmddyy10.;

run;

** Replace existing subsidy file and update metadata **;

proc datasets library=PresCat memtype=(data) nolist;
  copy in=Work out=PresCat;
  select Subsidy;
  modify Subsidy (label="Preservation Catalog, Project subsidies" sortedby=nlihc_id subsidy_id);
quit;

%File_info( data=PresCat.Subsidy, printobs=5 )

%Dc_update_meta_file(
  ds_lib=PresCat,
  ds_name=Subsidy,
  creator_process=Subsidy_fix_002.sas,
  restrictions=None,
  revisions=%str(Add Subsidy_info_source_property and POA_end_actual vars.)
)

