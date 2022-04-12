/**************************************************************************
 Program:  Add_new_projects_project.sas
 Library:  PresCat
 Project:  NeighborhoodInfo DC
 Author:   P. Tatian
 Created:  02/17/18
 Version:  SAS 9.2
 Environment:  Local Windows session (desktop)
 
 Description:  Autocall macro to add new projects to Preservation
 Catalog. 

 Macro updates:
   PresCat.Project
   PresCat.Project_category

 Modifications:
**************************************************************************/

%macro Add_new_projects_project(  );
  
  ** Create subsidy update data set **;

  %Create_project_subsidy_update( data=Subsidy ) 

  ** Add year built to Project **;

  proc sql noprint;
    create table Parcel_yb as
      select a.nlihc_id, coalesce( a.ssl, b.ssl ) as ssl, coalesce( a.ayb, b.ayb ) as ayb, coalesce( a.eyb, b.eyb ) as eyb
      from RealProp.Camarespt_2014_03 as b right join (
        select a.nlihc_id, coalesce( a.ssl, b.ssl ) as ssl, coalesce( a.ayb, b.ayb ) as ayb, coalesce( a.eyb, b.eyb ) as eyb
        from RealProp.camacondopt_2013_08 as b right join (
          select a.nlihc_id, coalesce( a.ssl, b.ssl ) as ssl, b.ayb, b.eyb
          from RealProp.camacommpt_2013_08 as b right join 
          Parcel as a   
          on a.ssl = b.ssl ) as a 
        on a.ssl = b.ssl ) as a
      on a.ssl = b.ssl
      order by nlihc_id, ssl;
    quit;

  data Parcel_yb_2;

    set Parcel_yb;
    
    if ayb < 1900 then ayb = .u;
    if eyb < 1900 then eyb = .u;

    label
      ayb = "Project year built (original)"
      eyb = "Project year built (improvements)";

    keep nlihc_id ayb eyb; 

    rename ayb=Proj_ayb eyb=Proj_eyb;

  run;

  proc summary data=Parcel_yb_2;
    by nlihc_id;
    var Proj_ayb Proj_eyb;
    output out=Project_yb (drop=_type_ _freq_) min=;
  run;

  ** Add owner category to Project **;

  proc summary data=Parcel nway; 
    class nlihc_id parcel_owner_type;
    output out=Project_owner;
  run;

  proc sort data=Project_owner;
    by nlihc_id descending _freq_;
  run;

  data Project_owner_nodup;

    set Project_owner;
    by nlihc_id;
    
    if first.nlihc_id;

    label
      Parcel_owner_type = "Project owner type (majority of parcels)";

    keep nlihc_id Parcel_owner_type; 

    rename Parcel_owner_type=Proj_owner_type;

  run;

  ** Total units from subsidy input file **;

  proc summary data=Subsidy_a;
    by nlihc_id;
    var Units_tot;
    output out=Project_units_tot (drop=_type_ _freq_) max=;
  run;

  data Project_a /*(label="Preservation Catalog, projects update")*/;

    merge 
    New_nlihc_id (keep=nlihc_id in=isNew)
    Project_units_tot (rename=(Units_tot=Proj_units_tot))
  	Project_geocode /*Status*/
  	Project_Subsidy_update /*(keep=Nlihc_id Proj_Units_Assist_: Subsidy_Start_: Subsidy_End_: Subsidized)*/
    Project_yb
    Project_owner_nodup;
  	
    by Nlihc_id;

    if isNew;
    
    ** Set Categories (default as 'other subsidized property') **;

    length Category_code $ 1 Cat_at_risk Cat_expiring Cat_failing_insp Cat_lost Cat_more_info Cat_replaced 3;

    cat_at_risk = 0;
    cat_failing_insp = 0;
    cat_more_info = 0;
    cat_lost = 0;
    cat_replaced = 0;

    category_code = "5";
    
    status = "A";

    ** Mark projects with subsidy less than one year away as expiring **;
    
    if -100 < intck( 'year', Subsidy_End_First, date() ) < 1 then Cat_Expiring = 1;
    if cat_expiring = . then cat_expiring = 0;

    ** Label City and State **;
    Proj_City = "Washington";
    Proj_St = "DC";

    length PBCA 3;

    PBCA = 0;
    
    Update_Dtm = datetime();
    
    label
      NLIHC_ID = "Preservation Catalog project ID"
      Status = "Project is active"
      Subsidized = "Project is subsidized"
      Category_code = "Preservation Catalog project category"
      Cat_At_Risk = "Project at risk"
      Cat_Expiring = "Project has upcoming expiring subsidy"
      Cat_Failing_Insp = "Project has failed recent REAC inspection"
      Cat_More_Info = "Project flagged for gathering more information"
      Cat_Lost = "Lost affordable housing"
      Cat_Replaced = "Replaced affordable housing"
      Proj_Name = "Project name"
      Proj_Addre = "Project main address"
      Proj_City = "Project city"
      Proj_ST = "Project state"
      Proj_Zip = "Project ZIP code"
      Proj_Units_Tot = "Total housing units in project"
      Proj_Units_Assist_Min = "Total assisted housing units in project (minimum)"
      Proj_Units_Assist_Max = "Total assisted housing units in project (maximum)"
      Subsidy_Start_First = "First subsidy start date"
      Subsidy_Start_Last = "Last subsidy start date"
      Subsidy_End_First = "First subsidy end date"
      Subsidy_End_Last = "Last subsidy end date"
      Ward2012 = 'Ward (2012)'
      Anc2012 = 'Advisory Neighborhood Commission (2012)'
      Psa2012 = 'Police Service Area (2012)'
      Geo2010 = 'Full census tract ID (2010): ssccctttttt'
      Cluster_tr2000 = 'Neighborhood cluster (tract-based, 2000)'
      Cluster_tr2000_name = 'Neighborhood cluster names (tract-based, 2000)'
      Zip = 'ZIP code (5 digit)'
      Proj_image_url = 'OCTO property image URL'
      Proj_streetview_url = 'Google Street View URL'
      Proj_address_id = 'Project MAR address ID'
      Proj_x = 'Project longitude (MD State Plane Coord., NAD 1983 meters)'
      Proj_y = 'Project latitude (MD State Plane Coord., NAD 1983 meters)'
      Proj_lat = 'Project latitude'
      Proj_lon = 'Project longitude'
      Bldg_count = 'Number of buildings for project'
      Update_Dtm = "Datetime of last project update"
      PBCA = "Performance-Based Contract Administrator Program property"
    ;

    format Status $Status. Category_code $Categry. 
      Subsidized Cat_At_Risk Cat_Expiring Cat_Failing_Insp Cat_More_Info Cat_Lost Cat_Replaced PBCA dyesno.
      Update_Dtm datetime16.
    ;

    format Proj_name ;
    informat Proj_name ;
   
  run;

  data Project;
    	set Prescat.project project_a;
  	by nlihc_id;
  run;

  **** Compare with earlier version ****;

  proc compare base=Prescat.project compare=Project listbasevar listcompvar maxprint=(40,32000);
    id nlihc_id;
  run;

  %Finalize_data_set( 
    /** Finalize data set parameters **/
    data=Project,
    out=Project,
    outlib=PresCat,
    label="Preservation Catalog, Projects",
    sortby=Nlihc_id,
    archive=N,
    /** Metadata parameters **/
    revisions=%str(Add new projects from &input_file_pre._*.csv.),
    /** File info parameters **/
    printobs=0
  )

  title2 'Project: New records';

  proc print data=Project n;
    where put( nlihc_id, $New_nlihc_id. ) ~= "";
    id nlihc_id;
    var Proj_name; 
  run;

  title2 'File = PresCat.Project / DUPLICATE NLIHC_IDs';

  %Dup_check(
    data=Project,
    by=nlihc_id,
    id=Proj_name Proj_addre
  )
  title2;

  proc print data=Project;
    where missing( Nlihc_id );
    var status Proj_name Proj_addre Proj_zip Ward2012;
    title2 '---MISSING NLIHC_ID---';
  run;
  title2;

  proc print data=Project;
    where missing( Ward2012 );
    id nlihc_id;
    var status Proj_name Proj_addre Proj_zip Ward2012;
    title2 '---MISSING WARD---';
  run;
  title2;


  **** Update PresCat.Project_category ****;

  data Project_category;

    set
      PresCat.Project_category
      Project_a (keep=nlihc_id proj_name category_code cat_at_risk cat_more_info cat_lost cat_replaced);
    by nlihc_id;

  run;

  **** Compare with earlier version ****;

  proc compare base=Prescat.project_category compare=Project_category listbasevar listcompvar maxprint=(40,32000);
    id nlihc_id;
  run;

  %Finalize_data_set( 
    /** Finalize data set parameters **/
    data=Project_category,
    out=Project_category,
    outlib=PresCat,
    label="Preservation Catalog, Project category",
    sortby=Nlihc_id,
    archive=N,
    /** Metadata parameters **/
    revisions=%str(Add new projects from &input_file_pre._*.csv.),
    /** File info parameters **/
    printobs=0,
    freqvars=
  )

  title2 'Project_category: New records';

  proc print data=Project_category n;
    where put( nlihc_id, $New_nlihc_id. ) ~= "";
  run;
  
  title2;

  ** Update metadata for Project_category_view **;

  %Dc_update_meta_file(
    ds_lib=PresCat,
    ds_name=Project_category_view,
    creator_process=&_program,
    restrictions=None,
    revisions=%str(Add new projects from &input_file_pre._*.csv.)
  )

%mend Add_new_projects_project;

/** End Macro Definition **/

