/**************************************************************************
 Program:  Pres_gantt_viz.sas
 Library:  PresCat
 Project:  NeighborhoodInfo DC
 Author:   P. Tatian
 Created:  01/18/15
 Version:  SAS 9.2
 Environment:  Local Windows session (desktop)
 
 Description:  Create export file for Gantt visualization of
 Preservation Catalog data.

 Modifications:
**************************************************************************/

%include "\\sas1\DCdata\SAS\Inc\StdLocal.sas";

** Define libraries **;
%DCData_lib( PresCat, local=n )

/*
data Subsidy;

  set PresCat.Subsidy;
  
  where subsidy_active = 1;
  
  format portfolio ;
  
run;
*/

proc format;
  value $portf_sum
    "202/811" = "Fin"
    "221-3-4" = "Fin"
    "221-BMIR" = "Fin"
    "223" = "Fin"
    "232" = "Fin"
    "236" = "Fin"
    "542" = "Fin"
    "HUDMORT" = "Fin"
    "CDBG" = "Oth"
    "DC HPTF" = "Hpt"
    "HOME" = "Oth"
    "HOPE VI" = "Oth"
    "LIHTC" = "Ltc"
    "MCKINNEY" = "Oth"
    "OTHER" = "Oth"
    "PB8" = "Pb8"
    "PBV" = "Oth"
    "PRAC" = "Oth"
    "PUBHSNG" = "Pha"
    "TEBOND" = "Oth";
  value $portf_grp
    "Pb8" = "1"
    "Ltc" = "2"
    other = "3";
  value $portf_sort
    "Pb8" = "1"
    "Ltc" = "2"
    "Fin" = "3"
    "Hpt" = "4"
    "Oth" = "5";
run;

proc summary data=PresCat.Subsidy nway;
  where subsidy_active = 1 and poa_end >= '01jan2014'd;
  class nlihc_id portfolio;
  var subsidy_active poa_start compl_end poa_end units_assist;
  output out=Subsidy_det (drop=_type_)
    max( subsidy_active )=
    min( poa_start )=
    max( compl_end poa_end ) =
    sum( units_assist )=;
  format portfolio ;
run;


proc summary data=Subsidy_det nway;
  class nlihc_id portfolio;
  var subsidy_active poa_start poa_end units_assist;
  output out=Subsidy_sum (drop=_type_)
    max( subsidy_active )=
    min( poa_start )=
    max( compl_end poa_end ) =
    max( units_assist )=;
  format portfolio $portf_sum.;
run;

data Subsidy_sum_b;

  set Subsidy_sum;
  
  length portfolio_grp $1;
  
  portfolio_grp = put( put( portfolio, $portf_sum. ), $portf_grp. );
  
run;

proc sort data=Subsidy_sum_b;
  by nlihc_id portfolio_grp descending units_assist descending poa_end;
  format portfolio $portf_grp.;
run;

%file_info( data=subsidy_sum_b, freqvars=portfolio, printobs=0 )

proc print data=Subsidy_sum_b (obs=40);
  id nlihc_id portfolio;
  by nlihc_id;
  format portfolio /*$portf_sum.*/;
run;

/*
data Subsidy_sum_a;

  merge
    Subsidy_sum (in=in1)
    PresCat.Project_category_view (keep=nlihc_id Proj_name Proj_units_tot);
  by nlihc_id;
  
  if in1;
  
  units_assist = min( units_assist, Proj_units_tot );
  
  *if first.nlihc_id then output;
  
run;
*/

proc tabulate data=Subsidy_sum_b format=mmddyy10. noseps missing;
  var poa_start poa_end;
  table 
    /** Rows **/
    poa_start poa_end,
    /** Columns **/
    n*f=comma8.0 min max
    / rts=50
  ;
run;

/****
%Super_transpose(  
  data=Subsidy_sum_b,
  out=Subsidy_tr,
  var=subsidy_active,
  id=portfolio,
  by=nlihc_id,
  mprint=N
)

proc print data=Subsidy_tr (obs=10);
  id nlihc_id;
  format portfolio ;
run;

proc freq data=Subsidy_tr;
  tables subsidy_active_pb8 * subsidy_active_ltc * subsidy_active_fin * subsidy_active_hpt * subsidy_active_oth 
    / missing list nopercent;
run;
*******/

proc summary data=Subsidy_sum_b;
  by nlihc_id;
  output out=Subsidy_count (drop=_type_ rename=(_freq_=Subsidy_count));
run;

%let RPT_START_DT = '01jan1970'd;
%let RPT_END_DT = '31dec2060'd;


data Export;

  merge
    Subsidy_sum_b (in=in1)
    Subsidy_count
    PresCat.Project (keep=nlihc_id Proj_name Proj_units_tot);
  by nlihc_id;
  
  if in1;
  
  length
    Mult_subsidy $ 1
    Portfolio_sort $ 1
    Proj_label $ 80
    Chart_start_dt 8
    Chart_poa_start 8
    Pb8_end Ltc_c_end Ltc_a_end Fin_end Hpt_end Oth_end Label_end_dt 8
  ;
    
  retain Chart_start_dt &RPT_START_DT;
  
  if first.nlihc_id then do;

    units_assist = min( units_assist, Proj_units_tot );

    if Subsidy_count > 1 then Mult_subsidy = "*";
    else Mult_subsidy = "";
    
    Proj_label = trim( Proj_name ) ||  trim( Mult_subsidy );
    
    if units_assist > 0 then Proj_label = trim( Proj_label ) || " [" ||
      trim( left( put( units_assist, comma8.0 ) ) ) || "]";
      
    Chart_poa_start = Poa_start - Chart_start_dt;
      
    select ( put( portfolio, $portf_sum. ) );
      when ( "Pb8" ) Pb8_end = Poa_end - Poa_start;
      when ( "Ltc" ) do;
        Ltc_c_end = Compl_end - Poa_start;
        Ltc_a_end = Poa_end - Compl_end;
      end;
      when ( "Fin" ) Fin_end = Poa_end - Poa_start;
      when ( "Hpt" ) Hpt_end = Poa_end - Poa_start;
      when ( "Oth" ) Oth_end = Poa_end - Poa_start;
      otherwise do;
        %err_put( msg="Unknown subsidy portfolio: " nlihc_id= portfolio= )
      end;
    end;

    Label_end_dt = Poa_end;
    
    Portfolio_sort = put( put( Portfolio, $portf_sum. ), $portf_sort. );
    
    output;
      
  end;
  
  format Portfolio $portf_sum. chart_start_dt label_end_dt mmddyy10.;
  
  keep nlihc_id portfolio_sort portfolio proj_label chart_start_dt chart_poa_start 
       Pb8_end Ltc_c_end Ltc_a_end Fin_end Hpt_end Oth_end Label_end_dt;
  
run;

proc sort data=Export;
  by Portfolio_sort label_end_dt proj_label;
run;

data Export_b;

  set Export end=last_obs;
  by Portfolio_sort;
  
  array n{*} chart_start_dt chart_poa_start 
       Pb8_end Ltc_c_end Ltc_a_end Fin_end Hpt_end Oth_end Label_end_dt;
  array c{*} nlihc_id portfolio_sort portfolio proj_label;
  
  output;
  
  if last.Portfolio_sort and not( last_obs ) then do;
    
    do i = 1 to dim( n );
      n{i} = .;
    end;
    
    do i = 1 to dim( c );
      c{i} = "";
    end;
    
    output;
    
  end;
  
  drop i;

run;

proc print data=Export_b (obs=100);
  id nlihc_id;
run;

filename fexport "&_dcdata_default_path\PresCat\Prog\Pres_gantt_viz.csv" lrecl=2000;

proc export data=Export_b
    outfile=fexport
    dbms=csv replace;

run;

filename fexport clear;

