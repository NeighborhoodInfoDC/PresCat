/**************************************************************************
 Program:  Subsidy_MFIS_fix.sas
 Library:  PresCat
 Project:  NeighborhoodInfo DC
 Author:   P. Tatian
 Created:  09/19/15
 Version:  SAS 9.2
 Environment:  Local Windows session (desktop)
 
 Description:  Fix coding of MFIS projects in Subsidy data set.

 Modifications:
**************************************************************************/

%include "\\sas1\DCdata\SAS\Inc\StdLocal.sas";

** Define libraries **;
%DCData_lib( PresCat, local=n )
%DCData_lib( HUD, local=n )

** Format to fill in missing mortgage IDs **;

%Data_to_format(
  FmtLib=work,
  FmtName=$nlihcid2subid,
  Desc=,
  Data=prescat.dc_info_07_08_15 (where=(not(missing(id_fha)) and nlihc_id not in ('NL001011', 'NL001012'))),
  Value=nlihc_id,
  Label=id_fha,
  OtherLabel=" ",
  DefaultLen=.,
  MaxLen=.,
  MinLen=.,
  Print=N,
  Contents=N
  )

** Add mortgage IDs for MFIS records **;

data Subsidy;

  set PresCat.Subsidy;
  
  if Subsidy_info_source in (
    "HUD - Insured Mulitfamily Mortgages",
    "HUD - Insured Multifamily Mortgages",
    "HUD - Terminated Multifamily Mortgages",
    "HUD-Insured Mulitfamily Mortgages",
    "HUD-Insured Multifamily Mortgages"
  ) then do;

    Subsidy_info_source = "HUD/MFIS";
    
    select ( nlihc_id );
      when ( 'NL001011' ) Subsidy_info_source_id = '00022004'; /** IDI FACILITIES **/
      when ( 'NL001012' ) Subsidy_info_source_id = '00032034'; /** 1ST AND M **/
	  when ( 'NL000047' ) Subsidy_info_source_id = '00035475'; /** Paul Lawrence Dunbar (Campbell Heights) **/
      otherwise Subsidy_info_source_id = put( nlihc_id, $nlihcid2subid. );
    end;
    
  end;

run;

proc print data=Subsidy n;
  where Subsidy_info_source = "HUD/MFIS";
  id nlihc_id;
  var portfolio program Subsidy_Info_Source_Date Subsidy_Info_Source_ID;
run;

** Add project name and address for comparison **;

data Subsidy_project;

  merge
    Subsidy 
      (keep=nlihc_id Subsidy_info_source Subsidy_info_source_id Subsidy_active
       where=(Subsidy_info_source = "HUD/MFIS") in=in1)
    PresCat.Project (keep=nlihc_id Proj_Name Proj_Addre);
  by nlihc_id;
  
  if in1;
  
run;

proc sort data=Subsidy_project;
  by Subsidy_Info_Source_ID;
run;  

** Should not be any duplicate IDs **;

%Dup_check(
  data=Subsidy_project,
  by=Subsidy_Info_Source_ID,
  id=nlihc_id Proj_Name Proj_Addre
)

** Test merge with MFIS data to check ID accuracy **;

data Test_merge;

  merge
    Subsidy_project (in=in1)
    HUD.MFIS_2015_08_dc 
      (keep=HUD_project_number property_name property_street MFIS_status
       rename=(HUD_project_number=Subsidy_info_source_id));
    by Subsidy_Info_Source_ID;
    
  if in1;
  
run;

filename fexport "&_dcdata_r_path\PresCat\Prog\Dev\Subsidy_MFIS_fix.csv" lrecl=1000;

proc export data=Test_merge
    outfile=fexport
    dbms=csv replace;

run;

filename fexport clear;


** Replace existing subsidy file and update metadata **;

proc datasets library=PresCat memtype=(data) nolist;
  copy in=Work out=PresCat;
  select Subsidy;
  modify Subsidy (label="Preservation Catalog, Project subsidies" sortedby=nlihc_id subsidy_id);
quit;

%File_info( data=PresCat.Subsidy, freqvars=Subsidy_Info_Source, printobs=5 )

%Dc_update_meta_file(
  ds_lib=PresCat,
  ds_name=Subsidy,
  creator_process=Subsidy_MFIS_fix.sas,
  restrictions=None,
  revisions=%str(Add Subsidy_Info_Source_ID values for MFIS records.)
)

