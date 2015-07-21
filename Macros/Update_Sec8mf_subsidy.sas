/**************************************************************************
 Program:  Update_Sec8mf_subsidy.sas
 Library:  PresCat
 Project:  NeighborhoodInfo DC
 Author:   P. Tatian
 Created:  07/18/15
 Version:  SAS 9.2
 Environment:  -
 
 Description:  Autocall macro to update PresCat.Subsidy 
 with Sec8mf data set.

 Modifications:
**************************************************************************/

/** Macro Update_Sec8mf_subsidy - Start Definition **/

%macro Update_Sec8mf_subsidy( Update_file=, Subsidy_except= );

  
  **************************************************************************
  ** Initial setup and checks;
  
  ** Check for duplicates **;
  
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
  
  ** Normalize exception file;

  %Except_norm( data=&Subsidy_except, by=nlihc_id subsidy_id )


  **************************************************************************
  ** Get data for updating subsidy file;

  data Sec8MF_subsidy_update;

    set Hud.&Update_file._dc;
    where not( program_type_name = "UnasstPrj SCHAP" and assisted_units_count = 0 );

    ** Create update variables **;

    length 
      Units_Assist POA_start POA_end Compl_end 8
      Subsidy_Active 3
      Subsidy_Info_Source $ 40
      Subsidy_Info_Source_ID $ 40
      Subsidy_Info_Source_Date 8
      Update_Dtm 8
    ;
    
    retain Subsidy_Info_Source &Subsidy_Info_Source;
   
    Subsidy_Info_Source_ID = trim( left( put( property_id, 16. ) ) ) || "/" || 
                             left( contract_number );
    
    Subsidy_Info_Source_Date = extract_date;

    Update_Dtm = &Update_Dtm;

    if assisted_units_count > 0 then Units_Assist = assisted_units_count;

    POA_start = tracs_effective_date;
    
    POA_end = tracs_overall_expiration_date;
    
    Compl_end = POA_end;

    if tracs_status in ( 'T' ) then Subsidy_Active = 0;
    else Subsidy_Active = 1;

    ** Program code **;
    
    length Program $ 32;
    
    Program = put( program_type_name, $mfatoprog. );
    
    if missing( Program ) then do;
      %warn_put( msg="Missing program type: " _n_= property_id= contract_number= assisted_units_count= program_type_name= )
    end;
    
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
      Units_Assist POA_start POA_end Compl_end
      contract_number rent_to_FMR_description Subsidy_Active
      Subsidy_Info_Source 
      Subsidy_Info_Source_ID Subsidy_Info_Source_Date Update_Dtm 
      Program
      property_name_text address_line1_text program_type_name
      ownership_effective_date
      owner_organization_name owner_individual_full_name
      owner_organization_name owner_individual_full_name
      mgmt_agent_org_name mgmt_agent_full_name
      mgmt_agent_org_name mgmt_agent_full_name;

  run;

  proc sort data=Sec8MF_subsidy_update;
    by Subsidy_Info_Source_ID;
  run;
  
  ** Check for duplicate records in update file **;
  
  title2 '**** THERE SHOULD NOT BE ANY DUPLICATE RECORDS IN THE UPDATE FILE ****';
  
  %Dup_check(
    data=Sec8MF_subsidy_update,
    by=Subsidy_Info_Source_ID,
    id=contract_number,
    out=_dup_check,
    listdups=Y,
    count=dup_check_count,
    quiet=N,
    debug=N
  )
  
  title2;
  
  
  **************************************************************************
  ** Apply update to Catalog data;
  
  ** Separate Catalog records to be updated **;

  data Subsidy_mfa Subsidy_other; 

    set PresCat.Subsidy;
    
    if Subsidy_Info_Source=&Subsidy_Info_Source then output Subsidy_mfa;
    else output Subsidy_other;
    
  run;

  proc sort data=Subsidy_mfa;
    by Subsidy_Info_Source_ID;
  run;

  ** Apply update **;

  data Subsidy_mfa_update_a;

    update 
      Subsidy_mfa 
      Sec8MF_subsidy_update (keep=&Subsidy_update_vars &Subsidy_tech_vars &Subsidy_missing_info_vars);
    by Subsidy_Info_Source_ID;
    
    if missing( Subsidy_id ) then Subsidy_id = &NO_SUBSIDY_ID;
    
  run;

  proc sort data=Subsidy_mfa_update_a;
    by Nlihc_id Subsidy_id poa_start poa_end;
  run;

  ** Add unique Subsidy_ID to any new subsidy records **;

  data Subsidy_mfa_update_b;

    set Subsidy_mfa_update_a (in=in1) Subsidy_other;
    by nlihc_id Subsidy_id;
    
    retain Subsidy_id_ret;
    
    if first.nlihc_id then Subsidy_id_ret = 0;
    
    if Subsidy_id = &NO_SUBSIDY_ID then Subsidy_id = Subsidy_id_ret + 1;
    
    Subsidy_id_ret = Subsidy_id;
    
    if in1 then output;
    
    drop Subsidy_id_ret &Subsidy_missing_info_vars;
    
  run;
  
  ** Summarize update changes and format output **;
  
  proc sort data=Subsidy_mfa;
    by nlihc_id Subsidy_ID;

  proc sort data=Subsidy_mfa_update_b;
    by nlihc_id Subsidy_ID;

  proc compare base=Subsidy_mfa compare=Subsidy_mfa_update_b 
      /*listall*/ noprint outbase outcomp outdif maxprint=(40,32000)
      out=Update_subsidy_result (rename=(_type_=comp_type));
    id nlihc_id Subsidy_ID &Subsidy_tech_vars;
    var &Subsidy_update_vars;
  run;

  %Super_transpose(  
    data=Update_subsidy_result,
    out=Update_subsidy_result_tr,
    var=&Subsidy_update_vars,
    id=comp_type,
    by=nlihc_id Subsidy_ID &Subsidy_tech_vars,
    mprint=N
  )
  
  
  **************************************************************************
  ** Apply exception file;
  
  data Subsidy_mfa_except;

    update Subsidy_mfa_update_b (in=in1) &Subsidy_except._norm;
    by nlihc_id Subsidy_ID;
    
    if in1;
    
  run;
  
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


  **************************************************************************
  ** Combine update and exception changes **;

  data Update_subsidy_result_except_tr;

    merge Update_subsidy_result_tr &Subsidy_except._tr;
    by nlihc_id subsidy_id;
    
    ** Convert DIF for char vars to missing if no differences **;
    
    array charvars{*} rent_to_FMR_description_DIF Program_DIF;
    
    do i = 1 to dim( charvars );
      charvars{i} = compress( charvars{i}, '.' );
    end;
    
    ** Add category codes for report **;
    
    length Category_code $ 1;
    
    Category_code = put( nlihc_id, $nlihcid2cat. );
    
    format Category_code $categry.;
    
  run;


  **************************************************************************
  ** Recombine with other subsidy data **;

  data Subsidy_Update_&Update_file;

    set Subsidy_mfa_except Subsidy_other;
    by nlihc_id Subsidy_id;
    
    where not( missing( nlihc_id ) );
    
    ** Subsidy portfolio **;
    
    length Portfolio $ 16;
    
    Portfolio = put( Program, $progtoportfolio. );
    
    if missing( Portfolio ) then do;
      %warn_put( msg="Missing subsidy portfolio: " _n_= nlihc_id= subsidy_id= Program= )
    end;

  run;


  **************************************************************************
  ** Update Update_subsidy_history data set;

  %Update_history_recs( data=Update_subsidy_result_except_tr, out=Update_subsidy_history_recs, Update_vars=&Subsidy_update_vars )

  data Update_subsidy_history_del;

    set PresCat.Update_subsidy_history;
    
    if Subsidy_info_source = &Subsidy_info_source and Subsidy_info_source_date = &Subsidy_Info_Source_Date then delete;
    
  run;

  data Update_subsidy_history_new;

    update updatemode=nomissingcheck
      Update_subsidy_history_del
      Update_subsidy_history_recs;
    by Nlihc_id Subsidy_id Subsidy_info_source Subsidy_info_source_date;
    
  run;


  **************************************************************************
  ** Create update report;

  proc sort data=Update_subsidy_result_except_tr;
    by Category_code nlihc_id subsidy_id;
  run;

  data Update_subsidy_result_report;

    set Update_subsidy_result_except_tr;
    
    length Subsidy_desc $ 400;
    
    if not missing( Program_Compare ) then Subsidy_desc = put( Program_Compare, $progshrt. );
    else Subsidy_desc = put( Program_Base, $progshrt. );
    
    if not missing( Subsidy_Info_Source_ID ) then 
      Subsidy_desc = trim( Subsidy_desc ) || ' [' || trim( Subsidy_Info_Source_ID ) || ']';
    
    length Var $ 32 Old_value New_value Except_value $ 80;
    
    %Update_rpt_write_var( var=Subsidy_active, fmt=dyesno., lbl="Subsidy active" )
    %Update_rpt_write_var( var=POA_start, fmt=mmddyy10., lbl="Affordability start" )
    %Update_rpt_write_var( var=POA_end, fmt=mmddyy10., lbl="Affordability end" )
    %Update_rpt_write_var( var=Units_assist, fmt=comma10., lbl="Assisted units" )
    %Update_rpt_write_var( var=rent_to_FMR_description, fmt=$80., lbl="Rent level", typ=c )
    %Update_rpt_write_var( var=Program, fmt=$80., lbl=, typ=c )
    
    keep category_code nlihc_id Subsidy_ID Subsidy_desc Program_Compare Subsidy_Info_Source_ID 
         Var Old_value New_value Except_value;
    
  run;

  ods listing close;
  ods pdf file="&_dcdata_r_path\PresCat\Prog\Updates\Update_&Update_file._subsidy.pdf" 
    style=Styles.Rtf_arial_9pt pdftoc=2 bookmarklist=hide uniform;

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
   
  ** Non-matching records **;

  proc print data=Subsidy_mfa_update_a label;
    where missing( nlihc_id );
    id Subsidy_Info_Source_ID;
    var property_name_text address_line1_text program_type_name Subsidy_active Units_assist poa_start poa_end;
    label 
      address_line1_text = "Address"
      program_type_name = "Program";
    title3 "PresCat.Subsidy - Unmatched subsidy records in update file";
  run;

  title2;
    
  ods pdf close;
  ods listing;


  **************************************************************************
  ** End of macro;
  
  
%mend Update_Sec8mf_subsidy;

/** End Macro Definition **/

