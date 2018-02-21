/**************************************************************************
 Program:  Update_LIHTC_subsidy.sas
 Library:  PresCat
 Project:  NeighborhoodInfo DC
 Author:   P. Tatian
 Created:  09/19/15
 Version:  SAS 9.2
 Environment:  -
 
 Description:  Autocall macro to update PresCat.Subsidy 
 with LIHTC data set.
 
 Modifications:
**************************************************************************/

/** Macro Update_LIHTC_subsidy - Start Definition **/

%macro Update_LIHTC_subsidy( Update_file=, Subsidy_except=, Manual_subsidy_match=, Manual_project_match=, Address_correct=, Quiet=Y );

  %LET DEBUG_PROJ_LIST = 'NL000234', 'NL000310', 'NL000096';
  
  **************************************************************************
  ** Initial setup and checks;
  
  %local Compare_opt;
  
  %if %upcase( &Quiet ) = N %then %do;
    %let Compare_opt = listall;
  %end;
  %else %do;
    %let Compare_opt = noprint;
  %end;
  
  ** Check for duplicates **;
  
  /****************
  title2 '***** THERE SHOULD NOT BE ANY DUPLICATES OF SUBSIDY_INFO_SOURCE_ID IN PRESCAT.SUBSIDY *****';

  %Dup_check(
    data=PresCat.Subsidy (where=(Subsidy_Info_Source=&Subsidy_Info_Source)),
    by=Subsidy_Info_Source_ID,
    id=nlihc_id contract_number Subsidy_Info_Source portfolio,
    out=_dup_check,
    listdups=Y,
    count=dup_check_count,
    quiet=N,
    debug=N
  )

  title2;
  *********************/
  
  ** Normalize exception file;

  %Except_norm( data=&Subsidy_except, by=nlihc_id subsidy_id )


  **************************************************************************
  ** Get data for updating subsidy file;

  data Subsidy_update_recs;

    set Hud.&Update_file._dc;
    
    
    **************************************************************************************;
    **************************************************************************************;
    **** TEMPORARY CODE FOR DEBUGGING - DELETE LATER!!! ****;
/********    IF HUD_ID IN ( 'DCB2011808', 'DCB2011805', 'DCB2011806', 'DCB2011807' ) THEN DELETE; ***********/
    **************************************************************************************;
    **************************************************************************************;
    
    
    ** Create update variables **;

    length 
      Units_Assist POA_start POA_end Compl_end 8
      Subsidy_Active 3
      Rent_to_fmr_description $ 40
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

    if &Assisted_units_src > 0 then Units_Assist = &Assisted_units_src;

    POA_start = &POA_start_src;
    
    POA_end = &POA_end_src;
    
    Compl_end = &Compl_end_src;

    if &Is_inactive_src then do;
      Subsidy_Active = 0;
      POA_end_actual = &POA_end_actual_src;
    end;
    else do;
      Subsidy_Active = 1;
      POA_end_actual = .n;
    end;
    
    Rent_to_fmr_description = &rent_to_fmr_description_src;

    ** Program code **;
    
    length Program $ 32;
    
    Program = &Program_src;
    
    ** Address corrections **;
    
    &Address_correct
    
    %if %length( &project_name ) > 0 %then %do;
      %Project_name_clean( &project_name, &project_name )
    %end;
    
    /*
    if missing( Program ) then do;
      %warn_put( msg="Missing program type: " _n_= property_id= contract_number= &Assisted_units_src= program_type_name= )
    end;
    */
    
    /********** SKIP FOR NOW ************
    length Agency $ 80;
    
    if Program = "Low Income Housing Tax Credit" then Agency = "DC Dept of Housing and Community Development; DC Housing Finance Agency";
    else if Subsidy_info_Source =: "DCFHA" then Agency = "DC Housing Finance Agency";
    else if Subsidy_Info_Source =: "DCHA" then Agency = "DC Housing Authority";
    else if Subsidy_Info_Source in ( "Email from KIM DCHA", "Email from Kim Cole DCHA" ) then Agency = "DC Housing Authority";
    else if Subsidy_Info_Source =: "DHCD" then Agency = "DC Dept of Housing and Community Development";
    else if Subsidy_Info_Source =: "DC/" then Agency = "DC";
    else if Subsidy_Info_Source =: "HUD" then Agency = "US Dept of Housing and Urban Development";
    else Agency = "Other";
    **********************************/

    format POA_start POA_end Compl_end Subsidy_Info_Source_Date mmddyy10. Update_Dtm datetime16.;
    
    keep
      Units_Assist POA_start POA_end Compl_end POA_end_actual
      Subsidy_Active Program rent_to_FMR_description 
      Subsidy_info_source_property
      &Subsidy_tech_vars &Subsidy_missing_info_vars &Subsidy_dupcheck_id_vars
      &Project_address &Project_zip &Proj_units_tot;

  run;

  proc sort data=Subsidy_update_recs;
    by Subsidy_Info_Source_ID;
  run;
  
  ** Check for duplicate records in update file **;
  
  title2 '**** THERE SHOULD NOT BE ANY DUPLICATE RECORDS IN THE UPDATE FILE ****';
  
  %Dup_check(
    data=Subsidy_update_recs,
    by=Subsidy_Info_Source_ID,
    id=&Subsidy_dupcheck_id_vars,
    out=_dup_check,
    listdups=Y,
    count=dup_check_count,
    quiet=N,
    debug=N
  )
  
  title2;
  
  
  **************************************************************************
  ** Apply update to Catalog data;
  
  ** Separate Catalog records to be updated
  ** Subsidy_target = All Catalog subsidy records for target program 
  ** Subsidy_other = All other Catalog subsidy records;

  data Subsidy_target Subsidy_other (drop=_POA_end_hold); 

    set PresCat.Subsidy;
    
    &manual_subsidy_match
    
    _POA_end_hold = POA_end;
    
    /**if Subsidy_Info_Source=&Subsidy_Info_Source and not( missing( Subsidy_Info_Source_ID ) ) then **/
    if Portfolio = 'LIHTC' then
      output Subsidy_target;
    else 
      output Subsidy_other;
    
  run;

  proc sort data=Subsidy_target;
    by Subsidy_Info_Source_ID;
  run;

  ** Apply update
  ** Subsidy_target_update_a = Initial application of LIHTC update to Catalog subsidy records;

  data Subsidy_target_update_a (drop=_POA_end_hold &Proj_units_tot) Subsidy_update_nomatch_0 (drop=_POA_end_hold Subsidy_id);

    update 
      Subsidy_target 
        (where=(not(missing(Subsidy_Info_Source_ID)))
         in=in1)
      Subsidy_update_recs 
        (keep=&Subsidy_update_vars &Subsidy_tech_vars &Subsidy_missing_info_vars Subsidy_Info_Source_ID
              &Proj_units_tot
         where=(not(missing(Subsidy_Info_Source_ID)))
         in=in2);
    by Subsidy_Info_Source_ID;
    
    In_Subsidy_target = in1;
    
    ** Update POA_end_prev if POA_end changed **;
    
    if POA_end ~= _POA_end_hold then POA_end_prev = _POA_end_hold;

    ** Write observations **;
    
    if not( In_subsidy_target ) and in2 then output Subsidy_update_nomatch_0;
    else output Subsidy_target_update_a;

  run;

  proc sort data=Subsidy_target_update_a;
    by Nlihc_id Subsidy_id;
  run;
  
PROC PRINT DATA=SUBSIDY_TARGET_UPDATE_A;
  ID NLIHC_ID SUBSIDY_ID;
  BY NLIHC_ID;
  VAR POA_START POA_END UNITS_ASSIST SUBSIDY_INFO_SOURCE SUBSIDY_INFO_SOURCE_ID;
  TITLE2 'DATA=SUBSIDY_TARGET_UPDATE_A';
RUN;
TITLE2;

  data Subsidy_update_nomatch Subsidy_update_manual_match;
  
    set Subsidy_update_nomatch_0;
    
    &manual_project_match
    
    if missing( nlihc_id ) then output Subsidy_update_nomatch;
    else output Subsidy_update_manual_match;
    
  run;

PROC PRINT DATA=Subsidy_update_manual_match N;
  ID SUBSIDY_INFO_SOURCE_ID;
  VAR NLIHC_ID POA_START POA_END UNITS_ASSIST SUBSIDY_INFO_SOURCE;
  TITLE2 'DATA=Subsidy_update_manual_match';
RUN;
TITLE2;

PROC PRINT DATA=Subsidy_update_nomatch N;
  ID SUBSIDY_INFO_SOURCE_ID;
  VAR NLIHC_ID POA_START POA_END UNITS_ASSIST SUBSIDY_INFO_SOURCE;
  TITLE2 'DATA=Subsidy_update_nomatch';
RUN;
TITLE2;


  **************************************************************************
  ** Geocode unmatched update records for possible property-level matching;
  
  %DC_mar_geocode(
    geo_match=Y,
    data=Subsidy_update_nomatch,
    out=Subsidy_update_nomatch_geocode,
    staddr=&Project_address,
    zip=&Project_zip,
    id=Subsidy_Info_Source_ID,
    ds_label=,
    listunmatched=Y
  )
  
  %Dup_check(
    data=Subsidy_update_nomatch_geocode,
    by=ssl,
    id=Subsidy_Info_Source_ID &Project_address &Project_zip,
    out=_dup_check,
    listdups=Y,
    count=dup_check_count,
    quiet=N,
    debug=N
  )

  proc sql noprint;
    create table Id_to_ssl as
      select coalesce( Parcel.ssl, Update.ssl ) as ssl, Parcel.nlihc_id, 
        put( Parcel.nlihc_id, $nlihcid2status. ) as Project_status,
        Update.*
      from Subsidy_update_nomatch_geocode (where=(ssl ~= '')) as Update 
      left join PresCat.Parcel as Parcel
      on Parcel.ssl = Update.ssl
    order by ssl, nlihc_id;
  quit;
  
  PROC PRINT DATA=ID_TO_SSL;
    BY SSL;
    ID SSL;
    VAR NLIHC_ID PROJECT_STATUS POA_START UNITS_ASSIST SUBSIDY_INFO_SOURCE_ID &PROJECT_ADDRESS &PROJECT_ZIP;
    TITLE2 'DATA=ID_TO_SSL';
  RUN;
  TITLE2;
  
  
  **************************************************************************
  ** Match to existing subsidy records;
  
  proc sql noprint;
    create table Subsidy_rec_match as
      select coalesce( Update.Nlihc_id, Subsidy.Nlihc_id ) as Nlihc_id, 
        Subsidy.Subsidy_id, Subsidy.poa_start as Subsidy_poa_start, Subsidy.Units_assist as Subsidy_units_assist,
        Update.*
      from Id_to_ssl as Update
      left join
      /*PresCat.Subsidy (where=(portfolio='LIHTC'))*/ Subsidy_target as Subsidy
      on Update.Nlihc_id = Subsidy.Nlihc_id and year( Subsidy.Poa_start ) = year( Update.Poa_start )
      order by Nlihc_id, Subsidy_id;
    quit;
      
  
PROC PRINT DATA=SUBSIDY_REC_MATCH;
  ID NLIHC_ID SUBSIDY_ID;
  BY NLIHC_ID;
  VAR SUBSIDY_POA_START POA_START SUBSIDY_UNITS_ASSIST UNITS_ASSIST SUBSIDY_INFO_SOURCE_ID;
  TITLE2 'DATA=SUBSIDY_REC_MATCH';
RUN;
TITLE2;

  data Subsidy_target_update_a2 Subsidy_update_nomatch_2;
  
    set Subsidy_rec_match Subsidy_update_manual_match;
    
    if not( missing( nlihc_id ) ) then do;
      if missing( subsidy_id ) then Subsidy_id = &NO_SUBSIDY_ID;
      output Subsidy_target_update_a2;
    end;
    else do;
      if missing( poa_end_actual ) then poa_end_actual = .;
      output Subsidy_update_nomatch_2;
    end;
    
  run;
  
  proc sort data=Subsidy_target_update_a2;
    by Nlihc_id Subsidy_id poa_start poa_end Subsidy_Info_Source_ID;
  run;
  
  data Subsidy_other_2;
  
    merge 
      Subsidy_other 
      Subsidy_target_update_a2 (keep=nlihc_id subsidy_id in=in2);
    by Nlihc_id Subsidy_id;
    
    if not in2;
    
  run;

PROC PRINT DATA=SUBSIDY_TARGET_UPDATE_A;
  WHERE NLIHC_ID IN ( &DEBUG_PROJ_LIST );
  ID NLIHC_ID SUBSIDY_ID;
  BY NLIHC_ID;
  VAR POA_START UNITS_ASSIST SUBSIDY_INFO_SOURCE_ID;
  TITLE2 'DATA=SUBSIDY_TARGET_UPDATE_A';
RUN;
TITLE2;

PROC PRINT DATA=SUBSIDY_TARGET_UPDATE_A2;
  WHERE NLIHC_ID IN ( &DEBUG_PROJ_LIST );
  ID NLIHC_ID SUBSIDY_ID;
  BY NLIHC_ID;
  VAR SUBSIDY_POA_START POA_START SUBSIDY_UNITS_ASSIST UNITS_ASSIST SUBSIDY_INFO_SOURCE_ID;
  TITLE2 'DATA=SUBSIDY_TARGET_UPDATE_A2';
RUN;
TITLE2;

PROC PRINT DATA=SUBSIDY_OTHER_2;
  WHERE NLIHC_ID IN ( &DEBUG_PROJ_LIST );
  ID NLIHC_ID SUBSIDY_ID;
  BY NLIHC_ID;
  VAR POA_START UNITS_ASSIST SUBSIDY_INFO_SOURCE_ID;
  TITLE2 'DATA=SUBSIDY_OTHER_2';
RUN;
TITLE2;

PROC PRINT DATA=SUBSIDY_UPDATE_NOMATCH_2;
  ***WHERE NLIHC_ID IN ( &DEBUG_PROJ_LIST );
  ***ID NLIHC_ID SUBSIDY_ID;
  ***BY NLIHC_ID;
  ***VAR POA_START UNITS_ASSIST SUBSIDY_INFO_SOURCE_ID;
  TITLE2 'DATA=SUBSIDY_UPDATE_NOMATCH_2';
RUN;
TITLE2;


************************************************************************************;
************************************************************************************;
************************************************************************************;
************************************************************************************;
  
  ** Subsidy_target_update_b = Add unique Subsidy_ID to any new subsidy records created by update **;

  data Subsidy_target_update_b;

    set 
      Subsidy_target_update_a (in=in1)
      Subsidy_target_update_a2 (in=in2)
      Subsidy_other_2;
    by nlihc_id Subsidy_id;
    
    retain Subsidy_id_ret;
    
    _new_subsidy = 0;
    
    if first.nlihc_id then Subsidy_id_ret = 0;
    
    if Subsidy_id = &NO_SUBSIDY_ID then do;
      Subsidy_id = Subsidy_id_ret + 1;
      _new_subsidy = 1;
    end;
    
    Subsidy_id_ret = Subsidy_id;
    
    if in1 or in2 then output;
    
    drop Subsidy_id_ret &Subsidy_missing_info_vars;
    
  run;
  
  PROC PRINT DATA=SUBSIDY_TARGET_UPDATE_B;
    WHERE NLIHC_ID IN ( &DEBUG_PROJ_LIST );
    ID NLIHC_ID SUBSIDY_ID;
    BY NLIHC_ID;
    VAR _NEW_SUBSIDY UNITS_ASSIST POA_START POA_END SUBSIDY_INFO_SOURCE SUBSIDY_INFO_SOURCE_ID SUBSIDY_INFO_SOURCE_DATE;
    TITLE2 'DATA=SUBSIDY_TARGET_UPDATE_B';
  RUN;

%DUP_CHECK(
  DATA=SUBSIDY_TARGET_UPDATE_B,
  BY=SUBSIDY_INFO_SOURCE_ID,
  ID=NLIHC_ID SUBSIDY_ID _NEW_SUBSIDY UNITS_ASSIST POA_START SUBSIDY_INFO_SOURCE_DATE,
  OUT=_DUP_CHECK,
  LISTDUPS=Y,
  COUNT=DUP_CHECK_COUNT,
  QUIET=N,
  DEBUG=N
)

  TITLE2;

  
  ** Use Proc Compare to summarize update changes **;
  
  proc sort data=Subsidy_target;
    by nlihc_id Subsidy_ID;

  proc sort data=Subsidy_target_update_b;
    by nlihc_id Subsidy_ID;

  proc compare base=Subsidy_target compare=Subsidy_target_update_b 
      &Compare_opt outbase outcomp outdif maxprint=(40,32000)
      out=Update_subsidy_result (rename=(_type_=comp_type));
    id nlihc_id Subsidy_ID Subsidy_Info_Source Subsidy_Info_Source_ID &Subsidy_compare_id_vars;
    var &Subsidy_update_vars;
  run;
  
  PROC PRINT DATA=UPDATE_SUBSIDY_RESULT;
    WHERE NLIHC_ID IN ( &DEBUG_PROJ_LIST );
    ID NLIHC_ID SUBSIDY_ID;
    TITLE2 'DATA=UPDATE_SUBSIDY_RESULT';
  RUN;

  ** Format Proc Compare output file;
  
  data Update_subsidy_result_b;
  
    set Update_subsidy_result;
    
    retain In 1;
    
  run;
  
  %Super_transpose(  
    data=Update_subsidy_result_b,
    out=Update_subsidy_result_tr,
    var=In &Subsidy_update_vars,
    id=comp_type,
    by=nlihc_id Subsidy_ID /*Subsidy_Info_Source Subsidy_Info_Source_ID &Subsidy_compare_id_vars*/,
    mprint=Y
  )
  
  PROC PRINT DATA=UPDATE_SUBSIDY_RESULT_TR;
    WHERE NLIHC_ID IN ( &DEBUG_PROJ_LIST );
    ID NLIHC_ID SUBSIDY_ID;
    BY NLIHC_ID;
    VAR UNITS_ASSIST: ;
    TITLE2 'DATA=UPDATE_SUBSIDY_RESULT_TR';
  RUN;
  TITLE2;

  
  **************************************************************************
  ** Apply exception file;
  
  data Subsidy_target_except;

    update Subsidy_target_update_b (in=in1 drop=In_Subsidy_target) &Subsidy_except._norm;
    by nlihc_id Subsidy_ID;
    
    if in1;
    
  run;
  
  PROC PRINT DATA=&SUBSIDY_EXCEPT._NORM;
    WHERE NLIHC_ID IN ( &DEBUG_PROJ_LIST );
    ID NLIHC_ID SUBSIDY_ID;
    BY NLIHC_ID;
    TITLE2 "DATA=&SUBSIDY_EXCEPT._NORM";
  RUN;
  TITLE2;

  PROC PRINT DATA=SUBSIDY_TARGET_EXCEPT;
    WHERE NLIHC_ID IN ( &DEBUG_PROJ_LIST );
    ID NLIHC_ID SUBSIDY_ID;
    BY NLIHC_ID;
    TITLE2 'DATA=SUBSIDY_TARGET_EXCEPT';
  RUN;
  TITLE2;

  ** Transpose exception file for change report **;

  data &Subsidy_except._b;

    set &Subsidy_except._norm;
    
    retain comp_type 'EXCEPT';
    
  run;

  %Super_transpose(  
    data=&Subsidy_except._b,
    out=&Subsidy_except._tr,
    var=&Subsidy_update_vars,
    id=comp_type,
    by=nlihc_id Subsidy_ID,
    mprint=Y
  )

  PROC PRINT DATA=&SUBSIDY_EXCEPT._TR;
    WHERE NLIHC_ID IN ( &DEBUG_PROJ_LIST );
    ID NLIHC_ID SUBSIDY_ID;
    BY NLIHC_ID;
    VAR UNITS_ASSIST: ;
    TITLE2 "DATA=&SUBSIDY_EXCEPT._TR";
  RUN;
  TITLE2;


  **************************************************************************
  ** Combine update and exception changes **;

  data Update_subsidy_result_except_tr;

    merge Update_subsidy_result_tr (in=in1) &Subsidy_except._tr Subsidy_target_update_b (keep=nlihc_id subsidy_id subsidy_info_source subsidy_info_source_id);
    by nlihc_id subsidy_id;
    
    if in1;
    
    ** Convert DIF for char vars to missing if no differences **;
    
    array charvars{*} Program_DIF &Subsidy_char_diff_vars;
    
    do i = 1 to dim( charvars );
      charvars{i} = compress( charvars{i}, '.' );
    end;
    
    ** Add category codes for report **;
    
    length Category_code $ 1;
    
    Category_code = put( nlihc_id, $nlihcid2cat. );
    
    format Category_code $categry.;
    
  run;
  
  PROC PRINT DATA=UPDATE_SUBSIDY_RESULT_EXCEPT_TR;
    WHERE NLIHC_ID IN ( &DEBUG_PROJ_LIST );
    ID NLIHC_ID SUBSIDY_ID;
    BY NLIHC_ID;
    VAR UNITS_ASSIST: SUBSIDY_INFO: ;
    TITLE2 'DATA=UPDATE_SUBSIDY_RESULT_EXCEPT_TR';
  RUN;
  TITLE2;


  **************************************************************************
  ** Recombine with other subsidy data **;

  data Subsidy_Update_&Update_file (label="Preservation Catalog, Project subsidies" sortedby=nlihc_id Subsidy_id);

    set Subsidy_target_except Subsidy_other;
    by nlihc_id Subsidy_id;
    
    where not( missing( nlihc_id ) );
    
    ** Recode old LIHTC program code **;
    
    if program = 'LIHTC' then program = 'LIHTC/UNKWN';
    
    ** Subsidy portfolio **;
    
    length Portfolio $ 16;
    
    Portfolio = put( Program, $progtoportfolio. );
    
    if missing( Portfolio ) then do;
      %warn_put( msg="Missing subsidy portfolio: " _n_= nlihc_id= subsidy_id= Program= )
    end;
    
  run;
  
  title2 "DUP_CHECK: data=Subsidy_Update_&Update_file";
  
  %Dup_check(
    data=Subsidy_Update_&Update_file,
    by=nlihc_id subsidy_id,
    id=portfolio poa_start units_assist subsidy_info_source subsidy_info_source_id,
    listdups=Y
  )

  %Dup_check(
    data=Subsidy_Update_&Update_file (where=(subsidy_info_source='HUD/LIHTC')),
    by=subsidy_info_source_id,
    id=nlihc_id subsidy_id poa_start units_assist,
    listdups=Y
  )

  title2;

PROC PRINT DATA=SUBSIDY_UPDATE_&UPDATE_FILE;
  WHERE NLIHC_ID IN ( &DEBUG_PROJ_LIST );
  ID NLIHC_ID SUBSIDY_ID;
  BY NLIHC_ID;
  VAR &SUBSIDY_FINAL_VARS;
  TITLE2 "DATA=SUBSIDY_UPDATE_&UPDATE_FILE";
RUN;
TITLE2;


  **************************************************************************
  ** Update Subsidy_update_history data set;

  %Update_history_recs( data=Update_subsidy_result_except_tr, out=Subsidy_update_history_recs, Update_vars=&Subsidy_update_vars )
  
PROC PRINT DATA=SUBSIDY_UPDATE_HISTORY_RECS;
  WHERE NLIHC_ID IN ( &DEBUG_PROJ_LIST );
  ID NLIHC_ID SUBSIDY_ID;
  BY NLIHC_ID;
  TITLE2 "DATA=SUBSIDY_UPDATE_HISTORY_RECS";
RUN;
TITLE2;

  data Subsidy_update_history_del;

    set PresCat.Subsidy_update_history;
    
    if Subsidy_info_source = &Subsidy_info_source and Subsidy_info_source_date = &Subsidy_Info_Source_Date then delete;
    
  run;
  
  proc sort data=Subsidy_update_history_del;
    by Nlihc_id Subsidy_id Subsidy_info_source Subsidy_info_source_date;
  run;

  data Subsidy_update_history_new (label="Preservation Catalog, Subsidy update history");

    update updatemode=nomissingcheck
      Subsidy_update_history_del
      Subsidy_update_history_recs;
    by Nlihc_id Subsidy_id Subsidy_info_source Subsidy_info_source_date;
    
  run;
  
  proc sort data=Subsidy_update_history_new;
    by Nlihc_id Subsidy_id descending Update_dtm;
  run;

proc compare base=PresCat.SUBSIDY_UPDATE_HISTORY compare=SUBSIDY_UPDATE_HISTORY_NEW listall maxprint=(40,32000);
  id nlihc_id subsidy_id descending update_dtm;
run;



  **************************************************************************
  ** Create update report;
  
  ** Prepare data **;

  proc sort data=Update_subsidy_result_except_tr;
    by Category_code nlihc_id subsidy_id;
  run;

  data Update_subsidy_result_report;

    set Update_subsidy_result_except_tr;
    where In_base = 1;
    
    length Subsidy_desc $ 400;
    
    if not missing( Program_Compare ) then Subsidy_desc = put( Program_Compare, $progshrt. );
    else Subsidy_desc = put( Program_Base, $progshrt. );
    
    if not missing( Subsidy_Info_Source_ID ) then 
      Subsidy_desc = trim( Subsidy_desc ) || ' [' || trim( Subsidy_Info_Source_ID ) || ']';
    
    length Var $ 32 Old_value New_value Except_value $ 80;
    
    %Update_rpt_write_var( var=Subsidy_active, fmt=dyesno., lbl="Subsidy active" )
    %Update_rpt_write_var( var=POA_start, fmt=mmddyy10., lbl="Affordability start" )
    %Update_rpt_write_var( var=Compl_end, fmt=mmddyy10., lbl="Compliance end" )
    %Update_rpt_write_var( var=POA_end, fmt=mmddyy10., lbl="Affordability end" )
    %Update_rpt_write_var( var=POA_end_actual, fmt=mmddyy10., lbl="Subsidy actual end" )
    %Update_rpt_write_var( var=Units_assist, fmt=comma10., lbl="Assisted units" )
    %Update_rpt_write_var( var=rent_to_FMR_description, fmt=$80., lbl="Rent level", typ=c )
    %Update_rpt_write_var( var=Program, fmt=$80., lbl=, typ=c )
    
    keep category_code nlihc_id Subsidy_ID Subsidy_desc Program_Compare Subsidy_Info_Source_ID 
         Var Old_value New_value Except_value;
    
  run;
  
  proc summary data=Subsidy_Update_&Update_file;
    by nlihc_id;
    var _new_subsidy;
    output out=Subsidy_update_new_subsidy_proj max=_new_subsidy_project;
  run;
  
  data New_subsidy_report;
  
    merge
      Subsidy_Update_&Update_file
      Subsidy_update_new_subsidy_proj;
    by nlihc_id;
    
  run;
  
  proc print data=New_subsidy_report (obs=5);
    id nlihc_id;
    title2 'data=New_subsidy_report';
  run;
  title2;
  

  ** Write report **;

  options orientation=landscape;
 
  ods listing close;
  ods pdf file="&_dcdata_default_path\PresCat\Prog\Updates\Update_&Update_file._subsidy.pdf" 
    style=Styles.Rtf_arial_9pt pdftoc=2 bookmarklist=hide uniform;
    
  ods proclabel "Updated variables";

  proc report data=Update_subsidy_result_report nowd;
    by category_code ;
    column nlihc_id Subsidy_id Subsidy_desc Var Old_value New_value Except_value;
    define nlihc_id / order noprint;
    define Subsidy_id / display "ID" style=[textalign=center];
    define Subsidy_desc / display "Subsidy [source ID]" style=[textalign=left];
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
    title3 "PresCat.Subsidy - Updated variables";
  run;
   
  ods proclabel "New subsidy records";

  proc report data=New_subsidy_report nowd;
    where _new_subsidy_project;
    column nlihc_id _new_subsidy _new Subsidy_id Subsidy_Info_Source_ID &Subsidy_update_vars;
    define nlihc_id / order noprint;
    define _new_subsidy / display noprint;
    define _new / computed noprint;
    define Subsidy_id / display "Subsidy ID" style=[textalign=center];
    define Subsidy_Info_Source_ID / display "Project ID" style=[textalign=center];
    define Program / display format=$progshrt.;
    break before nlihc_id / ;
    compute _new;
      if _new_subsidy = 1 then do;
        call define(_row_, "style", "style=[background=yellow font_weight=bold]");
      end;
    endcomp;
    compute before nlihc_id / style=[textalign=left fontweight=bold];
      line nlihc_id $nlihcid_proj.;
    endcomp;
    title3 "PresCat.Subsidy - New subsidy records from &Update_file (added to Catalog)";
  run;

  ods pdf close;
  ods tagsets.excelxp file="&_dcdata_default_path\PresCat\Prog\Updates\Update_&Update_file._subsidy_nonmatch.xls" style=Minimal options(sheet_interval='Proc' );

  ods proclabel "Nonmatching subsidy records";

  proc print data=Subsidy_update_nomatch_2 label;
    where subsidy_active or intck( 'year', poa_end_actual, date() ) <= &NONMATCH_YEARS_CUTOFF;
    id Subsidy_Info_Source_ID;
    var &Subsidy_missing_info_vars Subsidy_active Units_assist poa_start poa_end poa_end_actual;
    title3 "PresCat.Subsidy - Nonmatching subsidy records in &Update_file (NOT added to Catalog)";
  run;

  ods tagsets.excelxp close;
  ods listing;
  
  options orientation=portrait;

  title2;
  
  
  **************************************************************************
  ** Export nonmatching subsidy records for adding to Catalog;
  
  ** Main file **;
  
  proc sql noprint;
    create table Export_main as
    select &Project_name as Proj_Name, "Washington" as Bldg_City, "DC" as Bldg_ST, &Project_zip as Bldg_Zip,
      &Project_address._std as Bldg_Addre, &Proj_units_tot as Proj_units_tot from 
      Subsidy_update_nomatch_2 
        (where=(subsidy_active or intck( 'year', poa_end_actual, date() ) <= &NONMATCH_YEARS_CUTOFF));
  quit;

  filename fexport "&_dcdata_r_path\PresCat\Raw\AddNew\Update_&Update_file..csv" lrecl=2000;

  proc export data=Export_main
      outfile=fexport
      dbms=csv replace;

  run;

  filename fexport clear;
  
  
  ** Subsidy file **;
  
  proc sql noprint;
    create table Export_subsidy as
    select Address_id as MARID, Units_assist, Poa_start as Current_Affordability_Start,
           Poa_end as Affordability_End, rent_to_fmr_description as Fair_Market_Rent_Ratio,
           Subsidy_Info_Source_ID, Subsidy_Info_Source, Subsidy_Info_Source_Date, 
           Update_Dtm as Update_Date_Time, Program, Compl_end as Compliance_End_Date, 
           Poa_end_prev as Previous_Affordability_end, Agency, Portfolio, 
           Poa_end_actual as Date_Affordability_Ended
    from 
      Subsidy_update_nomatch_2 
        (where=(subsidy_active or intck( 'year', poa_end_actual, date() ) <= &NONMATCH_YEARS_CUTOFF));
  quit;

  filename fexport "&_dcdata_r_path\PresCat\Raw\AddNew\Update_&Update_file._subsidy.csv" lrecl=2000;

  proc export data=Export_subsidy
      outfile=fexport
      dbms=csv replace;

  run;

  filename fexport clear;
  

  **************************************************************************
  ** End of macro;
  
  
%mend Update_LIHTC_subsidy;

/** End Macro Definition **/

