/**************************************************************************
 Program:  Catalog_Project_sorted_list.sas
 Library:  PresCat
 Project:  NeighborhoodInfo DC
 Author:   P. Tatian
 Created:  06/10/14
 Version:  SAS 9.2
 Environment:  Local Windows session (desktop)
 
 Description:  Create list of Preservation Catalog projects sorted by
number of units.

 Modifications:
**************************************************************************/

%include "L:\SAS\Inc\StdLocal.sas";

** Define libraries **;
%DCData_lib( PresCat )

data Project;

  set PresCat.Project (where=(status='A'));
  
  if 0 < Proj_Units_Tot < Proj_Units_Assist_Max then Proj_Units_Assist_Max = .;
  
run;

proc sort data=Project;
  by descending Proj_Units_Tot descending Proj_Units_Assist_Max Proj_Name;
run;

%fdate()

ods pdf file="D:\DCData\Libraries\PresCat\Prog\Project_sorted_list.pdf" style=Printer startpage=no
  notoc;
ods listing close;

goptions vsize=4.5in;

proc gchart data=Project;
  hbar Proj_units_tot / midpoints=25 to 750 by 50;
  label Proj_units_tot=' ' Proj_Units_Assist_Max=' '; 
  title1 height=12pt j=l italic 'DC Preservation Catalog';
  title2 height=14pt j=c 'Number of Active Projects by Total Units';
run;

proc gchart data=Project;
  hbar Proj_Units_Assist_Max / midpoints=25 to 750 by 50;
  label Proj_units_tot=' ' Proj_Units_Assist_Max=' '; 
  title1 height=12pt j=l ' ';
  title2 height=14pt j=c 'Number of Active Projects by Assisted Units';
  footnote1 height=9pt j=l "Prepared by NeighborhoodInfo DC (www.NeighborhoodInfoDC.org)";
run;

options label missing='?';

proc print data=Project noobs label;
  var Proj_Name Proj_Units_Tot Proj_Units_Assist_Max;
  label 
    Proj_Name = 'Project name'
    Proj_units_tot = 'Total units'
    Proj_Units_Assist_Max = 'Assisted units';
  title1 height=12pt j=l 'DC Preservation Catalog';
  title2 height=14pt j=c 'List of Active Projects by Total and Assisted Units';
  footnote1 height=9pt j=l "Prepared by NeighborhoodInfo DC (www.NeighborhoodInfoDC.org)";
run;

ods pdf close;
ods listing;

