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
**************************************************************************/

%include "L:\SAS\Inc\StdLocal.sas";

** Define libraries **;
%DCData_lib( PresCat, local=n )
%DCData_lib( RealProp, local=n )

/** Macro Create_pdf - Start Definition **/

%macro Create_pdf( proj_select, ver );

  %let ver = %mcapitalize( &ver );

  data Project;

    *merge PresCat.Project PresCat.Project_geocode;
    set PresCat.Project;
    *by NLIHC_ID;
    where NLIHC_ID = "&proj_select";
      
    length Subsidy_range $ 80;
    
    Subsidy_range = trim( put( Subsidy_start_first, mmddyy10. ) ) || ' to ' ||
                    trim( put( Subsidy_end_last, mmddyy10. ) );
      
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

  ods pdf file="L:\Libraries\PresCat\Prog\PDFs\&ver\&proj_select.-detailed.pdf" 
    style=Printer /*Styles.Rtf_arial_9pt*/ 
    startpage=never 
    notoc;

  proc report data=Project list nowd /*noheader*/
      /*style(report)=[width=2in postimage='http://citizenatlas.dc.gov/mobilevideo/20040926/QQ112940.jpg']*/
      style(header)={fontsize=2}
      style(column)={fontsize=2};
    column 
/*      NLIHC_ID */
      Proj_Name
      Proj_Addre
      Proj_ZIP
    ;
/*    define NLIHC_ID / ' ' group; */
    define Proj_Name / ' ' display;
    define Proj_Addre / width=120 ' ' display;
    define Proj_ZIP / ' ' display;
    title1 "DC Preservation Catalog Project Profile - &ver Version - &proj_select";
    footnote1 height=9pt "Prepared by NeighborhoodInfo DC (www.NeighborhoodInfoDC.org), &fdate..";
  run;

  proc report data=Project list nowd /*noheader*/
      style(header)={fontsize=2}
      style(column)={fontsize=2};
    column 
      Ward2012
      Anc2012
      Psa2012
      Geo2010
      Cluster_tr2000
    ;
    define Ward2012 / ' ' display;
    define Anc2012 / ' ' display;
    define Psa2012 / ' ' display;
    define Geo2010 / ' ' display;
    define Cluster_tr2000 / ' ' format=$CLUS00F. display;
  run;

  proc report data=Project list nowd /*noheader*/
      /*style(report)=[width=2in postimage='http://citizenatlas.dc.gov/mobilevideo/20040926/QQ112940.jpg']*/
      style(header)={fontsize=2}
      style(column)={fontsize=2};
    column 
      Status 
      Subsidized 
      Category_Code
      Cat_expiring
      Cat_failing_insp
    ;
    define Status / display;
    define Subsidized / 'Subsidized?' display
                          style(column)={textalign=center};
    define Category_Code / 'Main Category' display;
    define Cat_expiring / 'Units expiring in next 12 months?' display
                          style(column)={textalign=center cellwidth=2in};
    define Cat_failing_insp / 'Failed recent inspection?' display
                          style(column)={textalign=center cellwidth=1.5in};
  run;

  proc report data=Project list nowd /*noheader*/
      style(header)={fontsize=2}
      style(column)={fontsize=2};
    column 
      Proj_units_tot
      Proj_units_assist_max
      /*( "Subsidy date range" Subsidy_start_first Subsidy_end_last )*/
      Subsidy_range
    ;
    define Proj_units_tot / 'Total project units' display
                          style(column)={textalign=center cellwidth=1.5in};
    define Proj_units_assist_max / 'Assisted units' spacing=20 display
                          style(column)={textalign=center cellwidth=1.5in};
    define Subsidy_range / 'Subsidy date range' display;
  run;

  proc report data=Subsidy list nowd /*noheader*/
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

proc print data=Parcel;
  id ssl;
  WHERE NLIHC_ID IN ( "NL000046" ); 
run;


*****************************
*****  Create all PDFs  *****
*****************************;

%fdate()

options noxwait;

x "del /q L:\Libraries\PresCat\Prog\PDFs\network\*.pdf";
x "del /q L:\Libraries\PresCat\Prog\PDFs\public\*.pdf";

data _null_;

  set PresCat.Project (keep=NLIHC_ID);
  ***WHERE NLIHC_ID IN ( "NL000208", "NL000319" ); 
  
  call execute ( '%Create_pdf( ' || NLIHC_ID || ', public )' );

  call execute ( '%Create_pdf( ' || NLIHC_ID || ', network )' );

run;

    
