/**************************************************************************
 Program:  099_Renumber_projects.sas
 Library:  PresCat
 Project:  NeighborhoodInfo DC
 GitHub issue: #99
 Author:   P. Tatian
 Created:  04/13/17
 Version:  SAS 9.2
 Environment:  Local Windows session (desktop)
 
 Description:  Renumber projects: NLnnnnnn will become Nnnnnnn00

 Modifications:
**************************************************************************/

%include "L:\SAS\Inc\StdLocal.sas";

** Define libraries **;
%DCData_lib( PresCat )


/** Macro Renumber_projects - Start Definition **/

%macro Renumber_projects( data=, sortby=, newlabel= );

  %if %length( &newlabel ) = 0 %then %do;
  
    proc sql noprint;
      select memlabel into :label separated by ' ' from dictionary.tables
      where libname = 'PRESCAT' and memname = "%upcase( &data )";
    quit;
    
  %end;
  %else %do;
  
    %let label = &newlabel;
    
  %end;
  
  %put label=&label;
  
  data &data;
  
    length Nlihc_id_new $ 16;
  
    set PresCat.&data;
    where Nlihc_id ~= 'NL001019';  ** Drop obsolete project **;
    
    length _proj_num $ 6;
    
    _proj_num = left( substr( Nlihc_id, 3, 6 ) );
    
    Nlihc_id_new = 'N' || trim( _proj_num ) || '00';
    
    label
      Nlihc_id_new = "Preservation Catalog project ID"
      Nlihc_id = "Preservation Catalog project ID (old)";
        
    %if %upcase( &data ) = PROJECT %then %do;
      rename Nlihc_id_new=Nlihc_id Nlihc_id=Nlihc_id_old;
      drop _proj_num;
    %end;
    %else %do;
      rename Nlihc_id_new=Nlihc_id;
      drop _proj_num Nlihc_id;
    %end;
    
  run;
  
  %Finalize_data_set( 
    /** Finalize data set parameters **/
    data=&data,
    out=&data,
    outlib=PresCat,
    label="&label",
    sortby=&sortby,
    archive=Y,
    archive_name=,
    /** Metadata parameters **/
    creator_process=&_program,
    restrictions=None,
    revisions=%str(Renumber projects.),
    /** File info parameters **/
    contents=Y,
    printobs=5,
    printchar=N,
    printvars=,
    freqvars=,
    stats=
  )
  
  run;

%mend Renumber_projects;

/** End Macro Definition **/


%Renumber_projects( data=Project, sortby=nlihc_id )
%Renumber_projects( data=Subsidy, sortby=nlihc_id subsidy_id )
%Renumber_projects( data=building_geocode, sortby=nlihc_id bldg_addre )
%Renumber_projects( data=parcel, sortby=nlihc_id ssl )
%Renumber_projects( data=project_category, sortby=nlihc_id )
%Renumber_projects( data=project_geocode, sortby=nlihc_id )
%Renumber_projects( data=project_update_history, sortby=nlihc_id update_dtm )
%Renumber_projects( data=reac_score, sortby=nlihc_id descending REAC_date )
%Renumber_projects( data=real_property, sortby=nlihc_id descending rp_date rp_type )
%Renumber_projects( data=subsidy_notes, sortby=nlihc_id subsidy_id, newlabel=%str(Preservation Catalog, Subsidy notes archive from Access db) )
%Renumber_projects( data=subsidy_update_history, sortby=nlihc_id subsidy_id update_dtm )
%Renumber_projects( data=ta_notes, sortby=nlihc_id, newlabel=%str(Preservation Catalog, TA notes archive from Access db) )

