/**************************************************************************
 Program:  Register_all_metadata.sas
 Library:  PresCat
 Project:  NeighborhoodInfo DC
 Author:   P. Tatian
 Created:  09/03/15
 Version:  SAS 9.2
 Environment:  Local Windows session (desktop)
 
 Description:  Register metadata for all initial Preservation Catalog
 data sets.

 Modifications:
**************************************************************************/

%include "\\sas1\DCdata\SAS\Inc\StdLocal.sas";

** Define libraries **;
%DCData_lib( PresCat )

%Dc_update_meta_file(
  ds_lib=PresCat,
  ds_name=Parcel,
  creator_process=Create_parcel.sas,
  restrictions=None,
  revisions=%str(New file.)
)

%Dc_update_meta_file(
  ds_lib=PresCat,
  ds_name=Project,
  creator_process=Create_project.sas,
  restrictions=None,
  revisions=%str(New file.)
)

%Dc_update_meta_file(
  ds_lib=PresCat,
  ds_name=Project_category,
  creator_process=Create_project_category.sas,
  restrictions=None,
  revisions=%str(New file.)
)

/** EMPTY FILES WON'T REGISTER
%Dc_update_meta_file(
  ds_lib=PresCat,
  ds_name=Project_except,
  creator_process=Create_project_except.sas,
  restrictions=None,
  revisions=%str(New file.)
)

%Dc_update_meta_file(
  ds_lib=PresCat,
  ds_name=Project_update_history,
  creator_process=Create_project_update_history.sas,
  restrictions=None,
  revisions=%str(New file.)
)
*/

%Dc_update_meta_file(
  ds_lib=PresCat,
  ds_name=REAC_score,
  creator_process=Create_REAC_score.sas,
  restrictions=None,
  revisions=%str(New file.)
)

%Dc_update_meta_file(
  ds_lib=PresCat,
  ds_name=Real_property,
  creator_process=Create_real_property.sas,
  restrictions=None,
  revisions=%str(New file.)
)

%Dc_update_meta_file(
  ds_lib=PresCat,
  ds_name=Subsidy,
  creator_process=Create_subsidy.sas,
  restrictions=None,
  revisions=%str(New file.)
)

%Dc_update_meta_file(
  ds_lib=PresCat,
  ds_name=Subsidy_notes,
  creator_process=Create_subsidy.sas,
  restrictions=None,
  revisions=%str(New file.)
)

/** EMPTY FILES WON'T REGISTER
%Dc_update_meta_file(
  ds_lib=PresCat,
  ds_name=Subsidy_except,
  creator_process=Create_subsidy_except.sas,
  restrictions=None,
  revisions=%str(New file.)
)

%Dc_update_meta_file(
  ds_lib=PresCat,
  ds_name=Subsidy_update_history,
  creator_process=Create_subsidy_update_history.sas,
  restrictions=None,
  revisions=%str(New file.)
)
*/

/** FILES WITH NO NUMERIC VARS WON'T REGISTER
%Dc_update_meta_file(
  ds_lib=PresCat,
  ds_name=TA_notes,
  creator_process=Create_TA_notes.sas,
  restrictions=None,
  revisions=%str(New file.)
)
*/

run;
