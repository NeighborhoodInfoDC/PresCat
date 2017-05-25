/**************************************************************************
 Program:  Del_metadata_099_Renumber_projects.sas
 Library:  PresCat
 Project:  NeighborhoodInfo DC
 Author:   P. Tatian
 Created:  05/25/17
 Version:  SAS 9.2
 Environment:  Local Windows session (desktop)
 
 Description:  Delete metadata revision history entries for
 099_Renumber_projects.sas on 4/14/17. Change was later reversed 
 by restoring archived data sets. 

 Modifications:
**************************************************************************/

%include "L:\SAS\Inc\StdLocal.sas";

** Define libraries **;
%DCData_lib( PresCat )
%DCData_lib( Metadata, local=n )

/** Macro Delete_last_revision - Start Definition **/

%macro Delete_last_revision( 
  library=,      /** Library name **/
  filename=,     /** Data set name **/
  before=,        /** SAS date value: If specified, 
                     delete all revision entries BEFORE this date. **/
  after=         /** SAS date value: If specified, 
                     delete all revision entries ON OR AFTER this date. **/
);

  %let library = %upcase( &library );
  %let filename = %upcase( &filename );

  options obs=max;

  proc print data=Metadata.Meta_history noobs n;
    where library = "&library" and filename = "&filename";
    by library filename;
    id FileUpdated;
    var FileProcess FileRevisions;
    title2 "Meta_history - BEFORE deletion";
    
  run;

  data /*Metadata.*/Meta_history;

    set Metadata.Meta_history;
    by library filename descending FileUpdated;

    if library = %upcase( "&library" ) and filename = %upcase( "&filename" ) and 
        %if &before ~= and &after ~= %then %do;
          ( &before > datepart( FileUpdated ) >= &after ) /** Delete all revisions before and after specified dates **/
        %end;
        %else %if &before ~= %then %do;
          ( &before > datepart( FileUpdated ) ) /** Delete all revisions before specified date **/
        %end;
        %else %if &after ~= %then %do;
          ( datepart( FileUpdated ) >= &after ) /** Delete all revisions on or after specified date **/
        %end;
        %else %do;
          first.filename /** Delete last revision only **/
        %end;
      then do;
        %note_put( msg="Deleting observation from Meta_history: "      
                        _n_= library= filename= FileUpdated= FileRevisions= )
        delete;
    end;

  run;

  proc print data=/*Metadata.*/Meta_history noobs n;
    where library = "&library" and filename = "&filename";
    by library filename;
    id FileUpdated;
    var FileProcess FileRevisions;
    title2 "Meta_history - AFTER deletion";
    
  run;

%mend Delete_last_revision;

/** End Macro Definition **/

%Delete_last_revision( library=PresCat, filename=Project, before='15apr2017'd, after='14apr2017'd )
%Delete_last_revision( library=PresCat, filename=Subsidy, before='15apr2017'd, after='14apr2017'd )
%Delete_last_revision( library=PresCat, filename=Building_geocode, before='15apr2017'd, after='14apr2017'd )
%Delete_last_revision( library=PresCat, filename=Parcel, before='15apr2017'd, after='14apr2017'd )
%Delete_last_revision( library=PresCat, filename=Project_category, before='15apr2017'd, after='14apr2017'd )
%Delete_last_revision( library=PresCat, filename=Project_geocode, before='15apr2017'd, after='14apr2017'd )
%Delete_last_revision( library=PresCat, filename=Project_update_history, before='15apr2017'd, after='14apr2017'd )
%Delete_last_revision( library=PresCat, filename=Reac_score, before='15apr2017'd, after='14apr2017'd )
%Delete_last_revision( library=PresCat, filename=Real_property, before='15apr2017'd, after='14apr2017'd )
%Delete_last_revision( library=PresCat, filename=Subsidy_notes, before='15apr2017'd, after='14apr2017'd )
%Delete_last_revision( library=PresCat, filename=Subsidy_update_history, before='15apr2017'd, after='14apr2017'd )

run;
