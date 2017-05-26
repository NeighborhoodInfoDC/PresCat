/**************************************************************************
 Program:  Change_len_nlihc_id.sas
 Library:  PresCat
 Project:  NeighborhoodInfo DC
 Author:   P. Tatian
 Created:  12/28/16
 Version:  SAS 9.2
 Environment:  Local Windows session (desktop)
 
 Description:  Change the length of the Preservation Catalog 
 Nlihc_id var from 8 to 16 chars.

 Modifications:
**************************************************************************/

%include "L:\SAS\Inc\StdLocal.sas";

** Define libraries **;
%DCData_lib( PresCat )

/** Macro Change_len - Start Definition **/

%macro Change_len( ds=, label=, sortby=nlihc_id );

  data &ds;
  
    length Nlihc_id $ 16;
  
    set PresCat.&ds;
    
  run;
  
  %Finalize_data_set( 
    data=&ds, 
    out=&ds, 
    outlib=PresCat, 
    label=&label, 
    sortby=&sortby, 
    revisions=%str(Change length of Nlihc_id to 16.), 
    stats=,
    printobs=0
  )
  
  run;

%mend Change_len;

/** End Macro Definition **/

%Change_len( ds=Building_geocode, label="Preservation Catalog, Building-level geocoding info", sortby=nlihc_id bldg_addre )
%Change_len( ds=Parcel, label="Preservation Catalog, Real property parcels", sortby=nlihc_id ssl )
%Change_len( ds=Project, label="Preservation Catalog, Projects", sortby=nlihc_id )
%Change_len( ds=Project_category, label="Preservation Catalog, project category" )
%Change_len( ds=Project_geocode, label="Preservation Catalog, Project-level geocoding info" )
%Change_len( ds=Project_update_history, label="Preservation Catalog, Project update history", sortby=nlihc_id update_dtm )
%Change_len( ds=Reac_score, label="Preservation Catalog, REAC scores", sortby=nlihc_id descending REAC_date )
%Change_len( ds=Real_property, label="Preservation Catalog, Real property events", sortby=nlihc_id descending rp_date rp_type )
%Change_len( ds=Subsidy, label="Preservation Catalog, Project subsidies", sortby=nlihc_id subsidy_id )
%Change_len( ds=Subsidy_notes, label="Preservation Catalog, Subsidy notes", sortby=nlihc_id subsidy_id )
%Change_len( ds=Subsidy_update_history, label="Preservation Catalog, Subsidy update history", sortby=nlihc_id subsidy_id update_dtm )

run;
