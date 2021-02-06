/**************************************************************************
 Program:  Create_TA_notes.sas
 Library:  PresCat
 Project:  NeighborhoodInfo DC
 Author:   P. Tatian
 Created:  09/03/15
 Version:  SAS 9.2
 Environment:  Local Windows session (desktop)
 
 Description:  Create data set with TA notes and provider info from
DC_info.
This data set will probably be discarded later.

 Modifications:
**************************************************************************/

%include "\\sas1\DCdata\SAS\Inc\StdLocal.sas";

** Define libraries **;
%DCData_lib( PresCat, local=n )

data PresCat.TA_notes (label="DC Preservation Catalog, TA notes");

  set PresCat.dc_info_07_08_15;
  
  if
    TA_NOTES = "" and
    TA_NOTES_ARCHIVE = "" and
    TA_Notes_Cont = "" and
    TA_Notes_Cont_4 = "" and
    TA_Notes_Cont_5 = "" and
    TA_Notes_Cont_6 = "" and
    TA_Notes_Cont_Again = "" and
    TA_Notes_Still_Cont = "" and
    TA_PROVIDER = ""
  then delete;

  ** Apply standard corrections **;
  
  %DCInfo_corrections()
  
  ** Missing project IDs **;
  
  select ( Proj_name );
    when ( '1919 Calvert Street NW' )
      Nlihc_id = 'NL001031';
    when ( 'CONGRESS HEIGHTS PUD' )
      Nlihc_id = 'NL001032';
    otherwise
      /** Do nothing **/;
  end;
  
  keep nlihc_id ta_: ;
  
run;

proc sort data=PresCat.TA_notes;
  by nlihc_id;

%File_info( data=PresCat.TA_notes, printobs=20, freqvars=ta_provider )

