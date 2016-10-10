/**************************************************************************
 Program:  Delete_catalog_projects.sas
 Library:  PresCat
 Project:  NeighborhoodInfo DC
 Author:   P. Tatian
 Created:  10/09/16
 Version:  SAS 9.2
 Environment:  Local Windows session (desktop)
 
 Description:  Delete one or more projects entirely from the PresCat
 data sets. 

 Modifications:
**************************************************************************/

%macro Delete_catalog_projects( Project_list= );

  %local Archive_pre;

  %if %length( &Project_list ) = 0 %then %do;
    %Err_mput( macro=Delete_catalog_projects, msg=Project_list= parameter cannot be empty. )
    %goto exit;
  %end;
  
  /** Macro Delete_from_one_catalog_ds - Start Definition **/

  %macro Delete_from_one_catalog_ds( data=, label=, sortby=, project_list= );

    data &data._del;
    
      set PresCat.&data;
      where nlihc_id not in ( &Project_list );
      
    run;
    
    proc compare base=PresCat.&data compare=&data._del listall maxprint=(40,32000);
      id &sortby;
    run;
    
    %Finalize_dataset( 
      data=&data._del, 
      out=&data, 
      outlib=PresCat, 
      label=&label, 
      sortby=&sortby, 
      archive=y,
      revisions=%str(Delete projects &project_list..),
      printobs=5
    )
    
    run;

  %mend Delete_from_one_catalog_ds;

  /** End Macro Definition **/


  ** Archive before delete **;
  
  %let Archive_pre = %scan( &_program, 1, . );
  
  %Archive_catalog_data( 
    data=Project Subsidy Parcel Building_geocode Project_category Project_geocode Project_update_history
         Reac_score Real_property Subsidy_notes Subsidy_update_history, 
    zip_pre=&Archive_pre, zip_suf=_pre )
  

  ** Project **;
  
  %Delete_from_one_catalog_ds( 
    data=Project, 
    label="Preservation Catalog, Projects", 
    sortby=nlihc_id, 
    project_list=&project_list 
  )

  ** Subsidy **;
  
  %Delete_from_one_catalog_ds( 
    data=Subsidy, 
    label="Preservation Catalog, Project subsidies", 
    sortby=nlihc_id subsidy_id, 
    project_list=&project_list 
  )

  ** Parcel **;
  
  %Delete_from_one_catalog_ds(
    data=Parcel,
    label="Preservation Catalog, Real property parcels",
    sortby=nlihc_id ssl,
    project_list=&project_list
  )

  ** Building_geocode **;
  
  %Delete_from_one_catalog_ds(
    data=Building_geocode,
    label="Preservation Catalog, Building-level geocoding info",
    sortby=nlihc_id bldg_addre,
    project_list=&project_list
  )

  ** Project_category **;
  
  %Delete_from_one_catalog_ds(
    data=Project_category,
    label="Preservation Catalog, Project category",
    sortby=Proj_name,
    project_list=&project_list
  )

  ** Project_geocode **;
  
  %Delete_from_one_catalog_ds(
    data=Project_geocode,
    label="Preservation Catalog, Project-level geocoding info",
    sortby=nlihc_id,
    project_list=&project_list
  )

  ** Project_update_history **;
  
  %Delete_from_one_catalog_ds(
    data=Project_update_history,
    label="Preservation Catalog, Project update history",
    sortby=nlihc_id descending update_dtm,
    project_list=&project_list
  )

  ** Reac_score **;
  
  %Delete_from_one_catalog_ds(
    data=Reac_score,
    label="Preservation Catalog, REAC scores",
    sortby=nlihc_id descending reac_date,
    project_list=&project_list
  )


  ** Real_property **;
  
  %Delete_from_one_catalog_ds(
    data=Real_property,
    label="Preservation Catalog, Real property events",
    sortby=nlihc_id descending rp_date rp_type,
    project_list=&project_list
  )

  ** Subsidy_notes **;
  
  %Delete_from_one_catalog_ds(
    data=Subsidy_notes,
    label="Preservation Catalog, Subsidy notes",
    sortby=nlihc_id subsidy_id,
    project_list=&project_list
  )

  ** Subsidy_update_history **;
  
  %Delete_from_one_catalog_ds(
    data=Subsidy_update_history,
    label="Preservation Catalog, Subsidy update history",
    sortby=nlihc_id subsidy_id descending update_dtm,
    project_list=&project_list
  )


  %exit:

%mend Delete_catalog_projects;


