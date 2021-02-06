/**************************************************************************
 Program:  Project_fix_001.sas
 Library:  PresCat
 Project:  NeighborhoodInfo DC
 Author:   P. Tatian
 Created:  09/29/16
 Version:  SAS 9.2
 Environment:  Local Windows session (desktop)
 
 Description:  Re-sort Building_geocode and replace project addresses
 in Project. 
 
 ONE-TIME FIX PROGRAM.

 Modifications:
**************************************************************************/

%include "\\sas1\DCdata\SAS\Inc\StdLocal.sas";

** Define libraries **;
%DCData_lib( PresCat )

%let MAX_PROJ_ADDRE = 3;   /** Maximum number of addresses to include in Proj_addre field in PresCat.Project_geo **/

proc sort data=PresCat.Building_geocode out=Building_geocode_sort;
 by nlihc_id Bldg_addre;

run;

data Proj_addre_new;

  set Building_geocode_sort;
  by nlihc_id;
  
  length
    Proj_addre $ 160;
    
  retain Proj_addre Bldg_count;
 
  if first.nlihc_id then do;
    Bldg_count = 0;
    Proj_addre = "";
  end;
    
  Bldg_count + 1;
  
  if Bldg_count = 1 then Proj_addre = Bldg_addre;
  else if Bldg_count <= &MAX_PROJ_ADDRE then Proj_addre = trim( Proj_addre ) || "; " || Bldg_addre;
  else if Bldg_count = %eval( &MAX_PROJ_ADDRE + 1 ) then Proj_addre = trim( Proj_addre ) || "; others";
    
  if last.nlihc_id then do;
  
    output Proj_addre_new;

  end;
  
  label
      Proj_addre = "Project address(es)"
      Bldg_count = "Number of buildings for project";
  
  keep nlihc_id Proj_addre Bldg_count;
  
run;


** Finalize files **;

data Project_new;

  merge 
    PresCat.Project (drop=Proj_addre Bldg_count in=inProject)
    Proj_addre_new;
  by nlihc_id;
  
run;


proc compare base=PresCat.Project compare=Project_new listall maxprint=(40,32000);
  id nlihc_id;
run;

proc sort data=Project_new out=PresCat.Project (label="Preservation Catalog, Projects");
  by nlihc_id;
run;

%File_info( data=PresCat.Project )

%Dc_update_meta_file(
  ds_lib=PresCat,
  ds_name=Project,
  creator_process=Project_fix_001.sas,
  restrictions=None,
  revisions=%str(Replace Proj_addre and Bldg_count vars based on resorted PresCat.Building_geocode.)
)


proc sort data=Building_geocode_sort out=PresCat.Building_geocode (label="Preservation Catalog, Building-level geocoding info");
 by nlihc_id Bldg_addre;
run;

%File_info( data=PresCat.Building_geocode )

%Dc_update_meta_file(
  ds_lib=PresCat,
  ds_name=Building_geocode,
  creator_process=Project_fix_001.sas,
  restrictions=None,
  revisions=%str(Resort by nlihc_id and bldg_addre.)
)


%Archive_catalog_data( data=Project Building_geocode, zip_pre=Project_fix_001, zip_suf=,
  overwrite=y, quiet=y )
