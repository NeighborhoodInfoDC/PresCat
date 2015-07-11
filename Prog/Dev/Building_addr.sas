/**************************************************************************
 Program:  Building_addr.sas
 Library:  PresCat
 Project:  NeighborhoodInfo DC
 Author:   P. Tatian
 Created:  10/05/13
 Version:  SAS 9.1
 Environment:  Windows
 
 Description:  Compile data of building addresses, including
 corrected addresses, for geocoding.

 NOTE: Need to put quotes (") around the SSL value for the 1st obs
 in DC_Info_02_08_13_buildings.csv and around ZIP code in both input
 files so that the vars will be char. 

 Modifications:
**************************************************************************/

%include "K:\Metro\PTatian\DCData\SAS\Inc\Stdhead.sas";
/*%include "C:\DCData\SAS\Inc\Stdhead.sas";*/

** Define libraries **;
%DCData_lib( PresCat )

filename fimport "&_dcdata_path\PresCat\Raw\DC_Info_02_08_13_for_geocoding (address corrections).csv" lrecl=2000;

proc import out=Addr_corr
    datafile=fimport
    dbms=csv replace;
  datarow=2;
  guessingrows=500;
  getnames=yes;

run;

filename fimport clear;

proc sort data=Addr_corr;
  by NLIHC_ID Proj_Name;
run;


filename fimport "&_dcdata_path\PresCat\Raw\DC_Info_02_08_13_buildings.csv" lrecl=2000;

proc import out=Bldg_addr
    datafile=fimport
    dbms=csv replace;
  datarow=2;
  guessingrows=500;
  getnames=yes;

run;

filename fimport clear;

proc sort data=Bldg_addr;
  by NLIHC_ID Proj_Name;
run;

** Merge data **;

data Bldg_addr_corr;

  merge 
    Addr_corr (drop=marid mar_: in=in1)
    Bldg_addr (drop=Proj_Addre in=in2);
  by NLIHC_ID Proj_Name;

  if not in1 then do;
    %warn_put( msg="No entry in project list: " _n_= NLIHC_ID= Proj_Name= )
  end;
  
  if Proj_Addre_corrected = "{multiple}" and not in2 then do;
    %warn_put( msg="No entry in building file for project with multiple addresses: " _n_= NLIHC_ID= Proj_Name= )
  end;
  
  length Bldg_Addre_new $ 120;
  
  if Bldg_Addre = "" then do;
    if Proj_Addre_corrected = "" then do;
      Bldg_Addre_new = Proj_Addre;
    end;
    else do;
      Bldg_Addre_new = Proj_Addre_corrected;
    end;
    Bldg_City = Proj_City;
    Bldg_ST = Proj_ST;
    Bldg_Zip = Proj_Zip;
  end;
  else do;
    Bldg_Addre_new = Bldg_Addre;
  end;
  
  format _all_ ;
  informat _all_ ;

run;

%File_info( data=Bldg_addr_corr, printobs=30, stats= )

data Bldg_addr_corr_export;

  set Bldg_addr_corr;
  
  keep NLIHC_ID Proj_Name Bldg_SSL Bldg_City Bldg_ST Bldg_Zip Bldg_Addre_new;
  
run;

%fdate( fmt=yymmddd10. )

filename fexport "&_dcdata_path\PresCat\Raw\DC_Info_02_08_13_buildings_for_geocoding (&fdate).csv" lrecl=2000;

proc export data=Bldg_addr_corr_export
    outfile=fexport
    dbms=csv replace;

run;

filename fexport clear;


