/**************************************************************************
 Program:  DCInfo_corrections.sas
 Library:  PresCat
 Project:  NeighborhoodInfo DC
 Author:   P. Tatian
 Created:  09/09/13
 Version:  SAS 9.1
 Environment:  Windows
 
 Description:  Corrections to Preservation Catalog data
 (PresCat.DC_Info).
 Autocall macro.

 Modifications:
  10/15/14 PAT Added correct total unit count for NL000046.
**************************************************************************/

/** Macro Corrections - Start Definition **/

%macro DCInfo_corrections(  );

  ** Assign new NLIHC_ID to St. Dennis (duplicate ID with CEMI - Bethune House) **;

  if NLIHC_ID = "NL001007" and upcase( Proj_Name ) = "ST. DENNIS" then
    NLIHC_ID = "NL001030";
    
  if NLIHC_ID = "NL000046" then do;
    units = 535;
    Category = "1";
  end;

%mend DCInfo_corrections;

/** End Macro Definition **/

