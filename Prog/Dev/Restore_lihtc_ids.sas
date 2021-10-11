/**************************************************************************
 Program:  Restore_lihtc_ids.sas
 Library:  PresCat
 Project:  NeighborhoodInfo DC
 Author:   P. Tatian
 Created:  05/31/17
 Version:  SAS 9.2
 Environment:  Local Windows session (desktop)
 
 Description:  Restore HUD LIHTC project IDs from original Catalog to
PresCat.Subsidy. 

 Modifications:
**************************************************************************/

%include "\\sas1\DCdata\SAS\Inc\StdLocal.sas";

** Define libraries **;
%DCData_lib( PresCat )
%DCData_lib( HUD )

proc sort 
    data=PresCat.dc_info_07_08_15 (where=(not missing( id_lihtc )))
    out=dc_info;
  by nlihc_id;
run;

data dc_info_orchardpk dc_info_other;

  set dc_info;
  
  if nlihc_id in ( 'NL000273' ) then do;
    subsidy_id = 6;
    output dc_info_orchardpk;
  end;
  else if nlihc_id in ( 'NL000274' ) then do;
    nlihc_id = 'NL000273';
    subsidy_id = 10;
    output dc_info_orchardpk;
  end;
  else if nlihc_id in ( 'NL000261', 'NL000997' ) then do;
    delete;
  end;
  else if nlihc_id in ( 'NL000325' ) then do;
    output dc_info_other;
    nlihc_id = 'NL000316';
    output dc_info_other;
    nlihc_id = 'NL001034';
    output dc_info_other;
    nlihc_id = 'NL001035';
    output dc_info_other;
  end;
  else do;
    output dc_info_other;
  end;
  
run;

proc sort data=dc_info_other;
  by nlihc_id;

data Subsidy_lihtc Subsidy_nolihtc;

  set PresCat.Subsidy;
  
  if portfolio = 'LIHTC' then output Subsidy_lihtc;
  else output Subsidy_nolihtc;
  
run;

data dc_info_other_subsidy_id;

  merge
    dc_info_other (in=in1)
    Subsidy_lihtc (keep=nlihc_id subsidy_id in=in2);
  by nlihc_id;
  
  if in1 and not in2 then do;
    %warn_put( msg='PROJECT NOT FOUND: ' nlihc_id= Proj_Name= LIHTC_ASSUNITS= )
  end;
  
  if in1 and in2;
  
run;

proc sort data=dc_info_other_subsidy_id;
  by nlihc_id subsidy_id;

data dc_info_subsidy_id;

  set
    dc_info_orchardpk
    dc_info_other_subsidy_id;
  by nlihc_id subsidy_id;
  
run;

%Dup_check(
  data=dc_info_subsidy_id,
  by=id_lihtc,
  id=nlihc_id subsidy_id proj_name lihtc_assunits,
  out=_dup_check,
  listdups=Y,
  count=dup_check_count,
  quiet=N,
  debug=N
)

proc print data=dc_info_subsidy_id;
  id nlihc_id subsidy_id;
  var id_lihtc Proj_Name LIHTC_ASSUNITS;
  title2 "data=dc_info_subsidy_id";
run;
title2;


data Subsidy_lihtc_w_id;

  merge 
    Subsidy_lihtc (in=in1)
    dc_info_subsidy_id 
      (keep=nlihc_id subsidy_id id_lihtc Proj_Name LIHTC_ASSUNITS
       rename=(id_lihtc=subsidy_info_source_id)
       in=in2);
  by nlihc_id subsidy_id;
  
  if in2 and not in1 then put nlihc_id= Proj_Name= LIHTC_ASSUNITS=;
  
  if in1;
  
  if in2 then subsidy_info_source = 'HUD/LIHTC';
  
run;

proc print data=Subsidy_lihtc_w_id;
  id nlihc_id subsidy_id;
  var proj_name subsidy_info_source subsidy_info_source_id units_assist LIHTC_ASSUNITS;
  title2 'data=Subsidy_lihtc_w_id';
run;
title2;

data Subsidy;

  set 
    Subsidy_lihtc_w_id (drop=proj_name lihtc_assunits) 
    Subsidy_nolihtc;
  by nlihc_id subsidy_id;
  
  if nlihc_id = 'NL000153' and subsidy_id = 2 then do;
    units_assist = 156;
  end;
  
run;

proc compare base=PresCat.Subsidy compare=Subsidy listall maxprint=(40,32000);
  id nlihc_id subsidy_id;
run;

%Finalize_data_set( 
  data=Subsidy,
  out=Subsidy,
  outlib=PresCat,
  label="Preservation Catalog, Project subsidies",
  sortby=nlihc_id subsidy_id,
  revisions=%str(Restored HUD LIHTC IDs from original Catalog.)
)


**************************************************************************
  Check matches against HUD data 
**************************************************************************;

proc sort data=Subsidy_lihtc_w_id (where=(not missing(subsidy_info_source_id))) out=Subsidy_lihtc_comp;
  by subsidy_info_source_id;
  
proc compare base=Subsidy_lihtc_comp (rename=(subsidy_info_source_id=hud_id)) compare=Hud.Lihtc_2013_dc maxprint=(400,32000);
  id hud_id;
  var units_assist;
  with li_units;
run;

%let hud_id_list = 
  'DCB2001010', 'DCB2003050', 'DCB2006045', 'DCB2006060', 'DCB2007040', 'DCB2007045', 'DCB2007055',
  'DCB1995010', 'DCB1995015';

proc print data=Subsidy_lihtc_comp;
  where subsidy_info_source_id in ( &hud_id_list );
  id subsidy_info_source_id;
  by subsidy_info_source_id;
  var nlihc_id proj_name units_assist LIHTC_ASSUNITS;
  sumby subsidy_info_source_id;
  title2 'data=Subsidy_lihtc_comp';
run;
title2;

%let cat_id_list = 
  'NL000033', 'NL000325', 'NL000267', 'NL000304', 'NL000153', 'NL000065', 'NL000343', 'NL000316', 'NL001034', 'NL001035',
  'NL000995', 'NL000996', 'NL000154', 'NL000388';

proc print data=Subsidy;
  where nlihc_id in ( &cat_id_list );
  id nlihc_id;
  by nlihc_id;
  var subsidy_id portfolio subsidy_active units_assist poa_start;
  title2 'data=Subsidy';
run;

proc print data=PresCat.Project;
  where nlihc_id in ( &cat_id_list );
  id nlihc_id;
  var proj_name proj_units_tot;
  title2 'data=PresCat.Project';
run;


proc print data=Hud.Lihtc_2013_dc;
  where hud_id in ( &hud_id_list );
  id hud_id;
  var project proj_add n_units li_units yr_pis;
  title2 'data=Hud.Lihtc_2013_dc';
run;
title2;
