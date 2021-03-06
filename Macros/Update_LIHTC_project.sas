/**************************************************************************
 Program:  Update_LIHTC_project.sas
 Library:  PresCat
 Project:  NeighborhoodInfo DC
 Author:   P. Tatian
 Created:  07/03/17
 Version:  SAS 9.2
 Environment:  -
 
 Description:  Autocall macro to update PresCat.Project 
 with LIHTC data set.

 Modifications:
**************************************************************************/

/** Macro Update_LIHTC_project - Start Definition **/

%macro Update_LIHTC_project( Update_file=, Project_except=, Quiet=Y );

  
  **************************************************************************
  ** Initial setup and checks;
  
  %local Compare_opt;
  
  %if %upcase( &Quiet ) = N %then %do;
    %let Compare_opt = listall;
  %end;
  %else %do;
    %let Compare_opt = noprint;
  %end;
    
  ** Create Project to update source link with Subsidy file **;

  proc sort 
      data=Subsidy_update_&Update_file 
        (where=(Subsidy_Info_Source=&Subsidy_info_source and not(missing(Subsidy_Info_Source_ID)))) 
      out=Subsidy_sort (keep=nlihc_id &Subsidy_tech_vars Units_assist);
    by nlihc_id descending Subsidy_Info_Source_Date descending Units_assist;
  run;

  data Project_source_link;

    set Subsidy_sort;
    by nlihc_id;
    
    if first.nlihc_id then output;
    
    keep nlihc_id &Subsidy_tech_vars;
    
  run;

  ** Normalize exception file;

  %Except_norm( data=&Project_except, by=nlihc_id )
  
  
  **************************************************************************
  ** Get data for updating project file;
  
  data LIHTC_project_update;

    set Hud.&Update_file._dc;

    ** Create update variables **;

    length 
      Hud_Own_Effect_dt  8
      Hud_Own_Name $ 80
      Hud_Own_Type $ 2
      Hud_Mgr_Name $ 80
      Hud_Mgr_Type $ 2
      Subsidy_Info_Source $ 40
      Subsidy_Info_Source_ID $ 40
      Subsidy_Info_Source_Date 8
      Subsidy_info_source_property $ 40
      Update_Dtm 8
    ;
   
    retain Subsidy_Info_Source &Subsidy_Info_Source;

    Subsidy_Info_Source_ID = &Subsidy_Info_Source_ID_src;

    Subsidy_Info_Source_Date = extract_date;

    Subsidy_info_source_property = &Subsidy_info_source_property_src;

    Update_Dtm = &Update_Dtm;

    Hud_Own_Effect_dt = &ownership_effective_date_src;
    
    if not( missing( &owner_organization_name_src ) ) then do;
      %owner_name_clean( &owner_organization_name_src, Hud_Own_Name )
    end;
    else if not( missing( &owner_individual_full_name_src ) ) then do;
      %owner_name_clean( &owner_individual_full_name_src, Hud_Own_Name )
    end;

    Hud_Own_Type = &Hud_Own_Type_src;
    
    if not( missing( &mgmt_agent_org_name_src ) ) then do;
      %owner_name_clean( &mgmt_agent_org_name_src, Hud_Mgr_Name )
    end;
    else if not( missing( &mgmt_agent_full_name_src ) ) then do;
      %owner_name_clean( &mgmt_agent_full_name_src, Hud_Mgr_Name )
    end;

    Hud_Mgr_Type = &Hud_Mgr_Type_src;

    format Hud_Own_Type $ownmgrtype. Hud_Mgr_Type $ownmgrtype.
           Hud_Own_Effect_dt Subsidy_Info_Source_Date mmddyy10. Update_Dtm datetime16.;
    
    keep &Project_src_update_vars &Project_missing_info_vars 
         &Subsidy_tech_vars Update_dtm; 

  run;

  proc sort data=LIHTC_project_update;
    by Subsidy_Info_Source_ID;
  run;

  title2 '**** THERE SHOULD NOT BE ANY DUPLICATE RECORDS IN THE UPDATE FILE ****';

  %Dup_check(
    data=LIHTC_project_update,
    by=Subsidy_Info_Source_ID,
    id=&Project_missing_info_vars
  )
  
  title2;

  ** Create updates from Subsidy file **;

  %Create_project_subsidy_update( data=Subsidy_update_&Update_file )


  **************************************************************************
  ** Apply update to Catalog data;
  
  ** Separate Catalog records to be updated
  ** Project_target = All Catalog project records with subsidies flagged with LIHTC as source 
  ** Project_other = All other Catalog project records;

  data Project_target Project_other; 

    merge PresCat.Project Project_source_link (drop=Update_dtm);
    by nlihc_id;
    
    if not( missing( Subsidy_Info_Source_ID ) ) then do;
      %Owner_name_clean( Hud_Own_Name, Hud_Own_Name )
      %Owner_name_clean( Hud_Mgr_Name, Hud_Mgr_Name )
      output Project_target;
    end;
    else do;
      output Project_other;
    end;
    
  run;

  proc sort data=Project_target;
    by Subsidy_Info_Source_ID;
  run;

  ** Apply update
  ** Project_target_update_a = Initial application of LIHTC update to Catalog project records;

  data Project_target_update_a;

    update 
      Project_target (in=in_Project)
      LIHTC_project_update 
        (keep=&Project_src_update_vars &Project_missing_info_vars &Subsidy_tech_vars Update_dtm);
    by Subsidy_Info_Source_ID;
    
    if in_Project;
    
    attrib &Project_subsidy_update_vars label=' ';
    
  run;

  proc sort data=Project_target_update_a;
    by Nlihc_id;
  run;

  ** Project_target_update_b = Add data from updated subsidy records **;

  data Project_target_update_b;

    update 
      Project_target_update_a (in=in_Project)
      Project_subsidy_update
        (keep=nlihc_id &Project_subsidy_update_vars);
    by Nlihc_id;
    
    if in_Project;
    
  run;
  
  ** Use Proc Compare to summarize update changes **;

  proc sort data=Project_target;
    by nlihc_id;

  proc compare base=Project_target compare=Project_target_update_b 
      &Compare_opt outbase outcomp outdif maxprint=(40,32000)
      out=Update_project_result (rename=(_type_=comp_type));
    id nlihc_id Subsidy_Info_Source Subsidy_Info_Source_ID;
    var &Project_src_update_vars &Project_subsidy_update_vars;
  run;

  ** Format Proc Compare output file;

  %Super_transpose(  
    data=Update_project_result,
    out=Update_project_result_tr,
    var=&Project_src_update_vars &Project_subsidy_update_vars,
    id=comp_type,
    by=nlihc_id Subsidy_Info_Source Subsidy_Info_Source_ID,
    mprint=N
  )


  **************************************************************************
  ** Apply exception file;

  proc sort data=&Project_except._norm;
    by nlihc_id;

  data Project_target_except;

    update Project_target_update_b (in=in1) &Project_except._norm;
    by nlihc_id;
    
    if in1;
    
  run;

  ** Transpose exception file for change report **;

  data &Project_except._b;

    set &Project_except._norm;
    
    retain comp_type 'EXCEPT' In 1;
    
  run;
  
  %Super_transpose(  
    data=&Project_except._b,
    out=Update_project_except_tr,
    var=In &Project_src_update_vars,
    id=comp_type,
    by=nlihc_id,
    mprint=N
  )


  **************************************************************************
  ** Combine update and exception changes;

  data Update_project_result_except_tr;

    merge Update_project_result_tr (in=in1) Update_project_except_tr;
    by nlihc_id;
    
    if in1;
    
    ** Add category codes for report **;
    
    length Category_code $ 1;
    
    Category_code = put( nlihc_id, $nlihcid2cat. );
    
    format Category_code $categry.;
    
  run;


  **************************************************************************
  ** Recombine with other project data;

  data Project_Update_all;

    set
      Project_target_except
      Project_other;
    by nlihc_id;
    
    where not( missing( nlihc_id ) );
    
    drop Subsidy_Info_Source_ID Subsidy_Info_Source Subsidy_Info_Source_Date
         &Project_missing_info_vars; 
    
  run;


  **************************************************************************
  ** Update project categories;

  proc sort data=PresCat.Project_category out=Project_category;
    by nlihc_id;
  run;

  data Project_Update_&Update_file (label="Preservation Catalog, Projects" sortedby=nlihc_id);

    update 
      Project_Update_all (in=in1)
      Project_category (keep=Nlihc_id Category_code Cat_:)
        updatemode=nomissingcheck;
    by nlihc_id;
    
    if in1;
    
  run;


  **************************************************************************
  ** Update Project_update_history data set;
  
  %if &Project_src_update_vars ~= %then %do;

    %Update_history_recs( data=Update_project_result_except_tr, out=Project_update_history_recs, Update_vars=&Project_src_update_vars )

    data Project_update_history_del;

      set PresCat.Project_update_history;
      
      if Subsidy_info_source = &Subsidy_info_source and Subsidy_info_source_date = &Subsidy_Info_Source_Date then delete;
      
    run;
    
    proc sort data=Project_update_history_del;
      by Nlihc_id Subsidy_info_source Subsidy_info_source_date;
    run;

    data Project_update_history_new (label="Preservation Catalog, Project update history" sortedby=Nlihc_id Subsidy_info_source Subsidy_info_source_date);

      update updatemode=nomissingcheck
        Project_update_history_del
        Project_update_history_recs;
      by Nlihc_id Subsidy_info_source Subsidy_info_source_date;
      
    run;
    
    proc sort data=Project_update_history_new;
      by Nlihc_id descending Update_dtm;
    run;
    
  %end;
  %else %do;
  
    ** No variables to update, just copy data set **;
  
    proc datasets library=Work memtype=(data) nolist;
      copy in=PresCat out=Work;
        select Project_update_history;
      change Project_update_history=Project_update_history_new;
    quit;
    
  %end;


  **************************************************************************
  ** Create update report;

  proc sort data=Update_project_result_except_tr;
    by Category_code nlihc_id;
  run;

  data Update_project_result_report;

    set Update_project_result_except_tr;

    length Var $ 32 Old_value New_value Except_value $ 80;
    
    %Update_rpt_write_var( var=Subsidized, fmt=dyesno., lbl="Subsidized", except=n ) 
    %Update_rpt_write_var( var=Proj_Units_Assist_Min, lbl="Assisted units (min)", except=n ) 
    %Update_rpt_write_var( var=Proj_Units_Assist_Max, lbl="Assisted units (max)", except=n ) 
    %Update_rpt_write_var( var=Subsidy_Start_First, fmt=mmddyy10., lbl="Subsidy start (first)", except=n ) 
    %Update_rpt_write_var( var=Subsidy_Start_Last, fmt=mmddyy10., lbl="Subsidy start (last)", except=n )
    %Update_rpt_write_var( var=Subsidy_End_First, fmt=mmddyy10., lbl="Subsidy end (first)", except=n )
    %Update_rpt_write_var( var=Subsidy_End_Last, fmt=mmddyy10., lbl="Subsidy end (last)", except=n )
    
    keep category_code nlihc_id 
         Var Old_value New_value Except_value;
    
  run;

  ods listing close;
  ods pdf file="&_dcdata_default_path\PresCat\Prog\Updates\Update_&Update_file._project.pdf" 
    style=Styles.Rtf_arial_9pt pdftoc=2 bookmarklist=hide uniform;

  ods proclabel "Updated variables";

  proc report data=Update_project_result_report nowd;
    by category_code ;
    column nlihc_id Var Old_value New_value Except_value;
    define nlihc_id / order noprint;
    define Var / display "Var" style=[textalign=left];
    define Old_value / display "Old value" style=[textalign=left];
    define New_value / display "New value" style=[textalign=left];
    define Except_value / display "Exception" style(column)=[background=$except_tl. textalign=left];
    break before nlihc_id / ;
    compute before nlihc_id / style=[textalign=left fontweight=bold];
      line nlihc_id $nlihcid_proj.;
    endcomp;
    label category_code = 'Category';
    title2 " ";
    title3 "PresCat.Project - Updated variables";
  run;
   
  title2;
    
  ods pdf close;
  ods listing;


  **************************************************************************
  ** End of macro;
  
  

%mend Update_LIHTC_project;

/** End Macro Definition **/

