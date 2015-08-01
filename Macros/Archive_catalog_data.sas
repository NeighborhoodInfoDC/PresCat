/**************************************************************************
 Program:  Archive_catalog_data.sas
 Library:  PresCat
 Project:  NeighborhoodInfo DC
 Author:   P. Tatian
 Created:  06/27/15
 Version:  SAS 9.2
 Environment:  -
 
 Description:  Autocall macro to archive Catalog data sets.
 
 Note: Overwrite=N (default) prevents replacement of older files in a 
 previously existing archive. 

 Modifications:
**************************************************************************/

/** Macro Archive_catalog_data - Start Definition **/

%macro Archive_catalog_data( 
  data=,     /** List of data set names **/
  zip_suf=,  /** Suffix for ZIP file name **/
  zip_pre=,  /** Prefix for ZIP file name (if missing current datetime is used) **/
  path=&_dcdata_r_path\PresCat\Data,   /** ZIP file path (don't include \Archive\ subfolder **/
  overwrite=n,  /** Overwrite older files in archive **/
  zip_program= %str(""&_dcdata_r_drive:\Tools\7-zip\7z"")  /** Location of 7z program **/,
  quiet=n  /** Suppress warning messages **/
  );

  %local i v update_switches;
  
  %if %upcase( &overwrite ) = Y %then %do;
    %let update_switches = ;
    %if %upcase( &quiet ) ~= Y %then %do;
      %warn_mput( macro=Archive_catalog_data, 
                  msg=%str(Overwrite=%upcase( &overwrite ) specified, older files in existing archive will be replaced.) )
    %end;
  %end;
  %else %do;
    %let update_switches = -uy1z1;  %** Copy previously saved older files to new archive **;
    %if %upcase( &quiet ) ~= Y %then %do;
      %note_mput( macro=Archive_catalog_data, 
                  msg=%str(Overwrite=%upcase( &overwrite ) specified, older files in existing archive will not be replaced.) )
    %end;
  %end;
  
  %if &zip_pre = %then 
    %let zip_pre = %sysfunc( putn( %sysfunc( datetime() ), b8601dt19.0 ) );
    
  %put _local_;

  %let i = 1;
  %let v = %scan( &data, &i, %str( ) );

  %do %until ( &v = );

    x "&zip_program a &update_switches -tzip &path\Archive\&zip_pre.&zip_suf &path\&v..sas7bdat";

    %let i = %eval( &i + 1 );
    %let v = %scan( &data, &i, %str( ) );

  %end;

%mend Archive_catalog_data;

/** End Macro Definition **/
