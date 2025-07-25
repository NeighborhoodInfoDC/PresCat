/**************************************************************************
 Program:  Pres_cat_web_pdfs.sas
 Library:  PresCat
 Project:  NeighborhoodInfo DC
 Author:   P. Tatian
 Created:  02/25/14
 Version:  SAS 9.2
 Environment:  Local Windows session (desktop)
 
 Description:  Create PDFs for Preservation Catalog web site.

 Run time: About 10-20 minutes.

 Modifications:
  11/10/14 PAT Changed assisted units total to max.
  01/29/15 PAT Made correction for new Update_dtm var in PresCat.Subsidy.
               All existing PDFs are deleted before new ones created.
  06/18/15 PAT Changed sort order to list active subsidies before inactive. 
  11/09/15 PAT Added RCASD notices to Network version of PDFs. 
**************************************************************************/

%include "\\sas1\DCdata\SAS\Inc\StdLocal.sas";

** Define libraries **;
%DCData_lib( PresCat, local=n )
%DCData_lib( RealProp, local=n )

%let output_path = &_dcdata_default_path\PresCat\Prog\PDFs;

/** Macro Create_pdf - Start Definition **/

%macro Create_pdf( proj_select, ver, proj_name );

  %local len_place_name_list;

  %let ver = %mcapitalize( &ver );

  data Project;

    set PresCat.Project_category_view;
    if Nlihc_id = "&proj_select";
      
    length Subsidy_range $ 80 Place_name_list_w_label $ 1000;
    
    Subsidy_range = trim( put( Subsidy_start_first, mmddyy10. ) ) || ' to ' ||
                    trim( put( Subsidy_end_last, mmddyy10. ) );
    
    Place_name_list_w_label = catx( ' ', 'Aliases from MAR:', Place_name_list );
    
    call symput( 'len_place_name_list', length( compress( place_name_list, '', 's' ) ) );
          
  run;
  
  data Subsidy;

    set PresCat.Subsidy;
    where NLIHC_ID = "&proj_select";
    
    Update_date = datepart( Update_dtm );
    
    format Update_date mmddyy8.;

  run;

  proc sort data=Subsidy;
    by descending Subsidy_active POA_End descending Units_assist POA_Start;
  run;

  options nodate nonumber;

  ods listing close;

  ods pdf file="&output_path\&ver\&proj_select.-detailed.pdf" 
    style=Listing 
    startpage=never 
    notoc;

  title1 "DC Preservation Catalog Project Profile - &proj_select";
  title2 " ";
  title3 height=16pt &proj_name;
  footnote1 height=9pt "Prepared by Urban-Greater DC (greaterdc.urban.org), &fdate..";

  %if &len_place_name_list > 1 %then %do;
    proc report data=Project list nowd /*noheader*/
        style(report)={rules=none frame=void cellspacing=0}
        style(header)={fontsize=2}
        style(column)={fontsize=4 font_weight=bold font_style=italic};
      column 
        Place_name_list_w_label
      ;
      define Place_name_list_w_label / ' ' display;
    run;
  %end;

  proc report data=Project list nowd
      style(header)={fontsize=2}
      style(column)={fontsize=4 font_weight=bold};
    column 
      Proj_Addre
      Proj_ZIP
    ;
    define Proj_Addre / width=120 ' ' display;
    define Proj_ZIP / ' ' display;
  run;

  proc report data=Project list nowd /*noheader*/
      style(header)={fontsize=2}
      style(column)={fontsize=2};
    column 
      Ward2022
      Anc2023
      Psa2012
      Geo2020
      Cluster2017
    ;
    define Ward2022 / ' ' display;
    define Anc2023 / ' ' display;
    define Psa2012 / ' ' display;
    define Geo2020 / ' ' display;
    define Cluster2017 / ' ' format=$CLUS17F. display;
  run;

  proc report data=Project list nowd
      style(header)={fontsize=2}
      style(column)={fontsize=2};
    column 
      Status 
      Subsidized 
      Category_Code
      Cat_expiring
      Cat_failing_insp
    ;
    define Status / 'Status?' display;
    define Subsidized / 'Subsidized?' display
                          style(column)={textalign=center};
    define Category_Code / 'Main Category' display;
    define Cat_expiring / 'Units expiring in next 12 months?' display
                          style(column)={textalign=center cellwidth=2in};
    define Cat_failing_insp / 'Failed recent inspection?' display
                          style(column)={textalign=center cellwidth=1.5in};
  run;

  proc report data=Project list nowd
      style(header)={fontsize=2}
      style(column)={fontsize=2};
    column 
      Proj_units_tot
      Proj_units_assist_max
      Subsidy_range
    ;
    define Proj_units_tot / 'Total project units' display
                          style(column)={textalign=center cellwidth=1.5in};
    define Proj_units_assist_max / 'Assisted units' spacing=20 display
                          style(column)={textalign=center cellwidth=1.5in};
    define Subsidy_range / 'Subsidy date range' display;
  run;

  proc report data=Subsidy list nowd
      style(header)={fontsize=2}
      style(column)={fontsize=2};
    column 
      Program
      Subsidy_active
      Units_assist
      ( "Affordability" POA_start POA_end )
      Subsidy_Info_Source
      Update_date
    ;
    define Program / 'Program' display;
    define Subsidy_active / 'Active?' display;
    define Units_assist / 'Assisted units' display;
    define POA_start / 'Start' display;
    define POA_end / 'End' display;
    define Subsidy_Info_Source / 'Info source' display;
    define Update_date / 'Updated' display;
  run;
  
  ** Parcel list **;
  
  proc report data=Parcel list nowd
      style(header)={fontsize=2}
      style(column)={fontsize=2};
    where NLIHC_ID = "&proj_select";
    column
      ( "Real property parcels comprising project"
        ssl
        premiseadd
        Parcel_owner_name
      )
    ;
    define ssl / 'SSL' display;
    define premiseadd / 'Address' display;
    define Parcel_owner_name / 'Owner' display;
  run;    
  
  %if &ver = Network %then %do;

    ** Real property events **;
    
    proc report data=PresCat.Real_property list nowd
        style(header)={fontsize=2}
        style(column)={fontsize=2};
      where NLIHC_ID = "&proj_select";
      column
        ( rp_date
          rp_desc
        )
      ;
      define rp_date / 'Date' display;
      define rp_desc / 'Property sales, notices, other events' display;
    run;    
    
    ** REAC scores **;
    
    proc sort data=PresCat.Reac_score out=Reac_score;
      by descending reac_date;
    run;
    
    proc report data=Reac_score list nowd
        style(header)={fontsize=2}
        style(column)={fontsize=2};
      where NLIHC_ID = "&proj_select";
      column
        ( reac_date
          reac_score
        )
      ;
      define reac_date / 'Date' display;
      define reac_score / 'REAC inspection score' display;
    run;
    
  %end;

  ods pdf close;
  ods listing;

%mend Create_pdf;

/** End Macro Definition **/


*************************
*****  Parcel data  *****
*************************;

proc sort data=PresCat.Parcel out=Parcel_a;
  by ssl;

data Parcel;

  merge 
    Parcel_a (in=in1)
    RealProp.Parcel_base (keep=ssl premiseadd);
  by ssl;
    
  if in1;
  
  %address_clean( premiseadd, premiseadd )
  
run;


*****************************
*****  Create all PDFs  *****
*****************************;

** Create format for project names **;

%Data_to_format(
  FmtLib=work,
  FmtName=$nlihc_id_to_proj_name,
  Data=Prescat.Project_category_view,
  Value=nlihc_id,
  Label=compress( Proj_name, '"' ),
  OtherLabel="",
  Print=N,
  Contents=N
  )

%fdate()

options noxwait;

x "del /q &output_path\network\*.pdf";

data _null_;

  set PresCat.Project (keep=NLIHC_ID);
  /***UNCOMMENT FOR TESTING*** WHERE NLIHC_ID IN ( "NL000001", "NL000027", "NL000069", "NL000208", "NL000217", "NL000277", "NL000319", "NL001035" ); ***/
  
  ** Note: %nrstr() is necessary below to use call symput in a macro invoked by call execute **;
  
  call execute ( cats( '%nrstr(%Create_pdf( ', NLIHC_ID, ', network, %str("', put( nlihc_id, $nlihc_id_to_proj_name. ), '")))' ) );

run;

