/**************************************************************************
 Program:  Strikeforce_tbls.sas
 Library:  PresCat
 Project:  NeighborhoodInfo DC
 Author:   P. Tatian
 Created:  10/15/15
 Version:  SAS 9.2
 Environment:  Local Windows session (desktop)
 
 Description:  Tables for Strike Force presentation, 10-16-15.

 Modifications:
**************************************************************************/

%include "L:\SAS\Inc\StdLocal.sas";

** Define libraries **;
%DCData_lib( PresCat, local=n )
%DCData_lib( RealProp, local=n )

/** Macro Ward_tbl - Start Definition **/

%macro Ward_tbl( ProgCatValues=, Title= );

  proc tabulate data=PresCat.Project_assisted_units format=comma10. noseps missing;
    where ProgCat in &ProgCatValues;
    class ward2012;
    var mid_asst_units;
    table 
      /** Rows **/
      all='\b Total' Ward2012=' ',
      /** Columns **/
      n='Projects'
      sum='Assisted units' * ( mid_asst_units=' ' )
      ;
    title3 "Project and assisted unit unique counts";
    title4 &title;
    footnote1 height=9pt "Source: DC Preservation Catalog";
    footnote2 height=9pt "Prepared by Urban-Greater DC (greaterdc.urban.org), &fdate..";
    footnote3 height=9pt j=r '{Page}\~{\field{\*\fldinst{\pard\b\i0\chcbpat8\qc\f1\fs19\cf1{PAGE }\cf0\chcbpat0}}}';
  run;
  title4;

%mend Ward_tbl;

/** End Macro Definition **/

/** Macro Expiration_tbl - Start Definition **/

%macro Expiration_tbl( Portfolio=, Title=, Date=poa_end );

  proc tabulate data=Subsidy_project_owner format=comma10. noseps missing;
    where Subsidy_active and Portfolio = &Portfolio and year( &date ) >= 2015;
    class &Date;
    var units_assist;
    table 
      /** Rows **/
      all='\b Total' &Date=' ',
      /** Columns **/
      sum='Assisted units' * ( Units_assist=' ' )
      n='Projects'
      ;
    format &Date year4.;
    title3 "Project and assisted unit counts by expiration date";
    title4 &title;
    footnote1 height=9pt "Source: DC Preservation Catalog";
    footnote2 height=9pt "Prepared by Urban-Greater DC (greaterdc.urban.org), &fdate..";
    footnote3 height=9pt j=r '{Page}\~{\field{\*\fldinst{\pard\b\i0\chcbpat8\qc\f1\fs19\cf1{PAGE }\cf0\chcbpat0}}}';
  run;
  title4;

%mend Expiration_tbl;

/** End Macro Definition **/

/** Macro Units_tbl - Start Definition **/

%macro Units_tbl( Portfolio=, Title=, Where=, class=, classfmt= );

  proc tabulate data=Subsidy_project_owner format=comma10. noseps missing;
    where Subsidy_active and Portfolio = &Portfolio and &where;
    class &Class;
    var units_assist;
    table 
      /** Rows **/
      all='\b Total' &Class=' ',
      /** Columns **/
      sum='Assisted units' * ( Units_assist=' ' )
      n='Projects'
      ;
    format &Class &Classfmt;
    title3 "Project and assisted unit counts by &class";
    title4 &title;
    title5 &where;
    footnote1 height=9pt "Source: DC Preservation Catalog";
    footnote2 height=9pt "Prepared by Urban-Greater DC (greaterdc.urban.org), &fdate..";
    footnote3 height=9pt j=r '{Page}\~{\field{\*\fldinst{\pard\b\i0\chcbpat8\qc\f1\fs19\cf1{PAGE }\cf0\chcbpat0}}}';
  run;
  
  /*
  proc print data=Subsidy_project_owner;
    where Subsidy_active and Portfolio = &Portfolio and &where;
    id nlihc_id;
    var &class Portfolio parcel_owner_name units_assist;
  run;
  */
  
  title4;

%mend Units_tbl;

/** End Macro Definition **/


data Project_owner;

  merge
    PresCat.Project (keep=nlihc_id proj_units_tot)
    PresCat.Parcel (keep=nlihc_id parcel_owner_type parcel_owner_name where=(parcel_owner_type~=""));
  by nlihc_id;
  
  if first.nlihc_id;
  
run;

data Subsidy_project_owner;

  merge
    PresCat.Subsidy (in=in1)
    Project_owner;
  by nlihc_id;
  
  if in1;
  
run;


%fdate()

proc format;
  value units
    1 - 5 = "1 - 5 units"
    6 - 10 = "6 - 10"
    11 - 20 = "11 - 20"
    21 - 50 = "21 - 50"
    51 - 100 = "51 - 100"
    101 - 200 = "101 - 200"
    201 - high = "201+";
  value ProgCat (notsorted)
    1 = 'Public housing'
    2 = 'Section 8 only'
    9 = 'Section 8 and other subsidies'
    8 = 'LIHTC w/tax exempt bonds'
    3 = 'LIHTC w/o tax exempt bonds'
    7 = 'HUD-insured mortgage only'
    4,5 = 'HOME/CDBG only'
    6 = 'DC HPTF only'
    10 = 'Section 202/811 only'
    20, 30 = 'Other subsidies/combinations';
run;

ods rtf file="D:\DCData\Libraries\PresCat\Prog\Strikeforce_tbls.rtf" style=Styles.Rtf_arial_9pt;

%Ward_tbl( ProgCatValues=( 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 20, 30 ), Title="All projects" )

%Ward_tbl( ProgCatValues=( 1 ), Title="Public housing" )

%Ward_tbl( ProgCatValues=( 2, 9 ), Title="Section 8" )

%Ward_tbl( ProgCatValues=( 8, 3 ), Title="LIHTC" )

%Expiration_tbl( Portfolio="PB8", Title="Section 8" )

%Expiration_tbl( Portfolio="LIHTC", Title="LIHTC", date=compl_end )

%Expiration_tbl( Portfolio="HUDMORT", Title="HUD mortgage" )

%Units_tbl( Portfolio="PB8", Title="Section 8", where=('01jan2015'd<=poa_end<='31dec2020'd), class=proj_units_tot, classfmt=units. )
%Units_tbl( Portfolio="PB8", Title="Section 8", where=('01jan2015'd<=poa_end<='31dec2020'd), class=parcel_owner_type, classfmt=$owncat. )

%Units_tbl( Portfolio="LIHTC", Title="LIHTC", where=('01jan2015'd<=compl_end<='31dec2020'd), class=proj_units_tot, classfmt=units. )
%Units_tbl( Portfolio="LIHTC", Title="LIHTC", where=('01jan2015'd<=compl_end<='31dec2020'd), class=parcel_owner_type, classfmt=$owncat. )

ods rtf close;


ods rtf file="D:\DCData\Libraries\PresCat\Prog\Strikeforce_tbls_handout.rtf" style=Styles.Rtf_arial_9pt;

options nodate nonumber missing='-';

proc tabulate data=PresCat.Project_assisted_units format=comma10. noseps missing;
  where ProgCat ~= .;
  class ProgCat / preloadfmt order=data;
  class ward2012;
  var mid_asst_units;
  table 
    /** Rows **/
    all='\b Total' ProgCat=' ',
    /** Columns **/
    n='Projects' * ( all='Total' ward2012=' ' )
    ;
  table 
    /** Rows **/
    all='\b Total' ProgCat=' ',
    /** Columns **/
    sum='Assisted units' * ( all='Total' ward2012=' ' ) * mid_asst_units=' '
    ;
  format ProgCat ProgCat.;
  title1 "Prepared for District of Columbia Housing Preservation Strike Force";
  title2 " ";
  title3 "Project and assisted unit counts";
run;

ods rtf close;

