/**************************************************************************
 Program:  Archive_catalog_data.sas
 Library:  PresCat
 Project:  NeighborhoodInfo DC
 Author:   P. Tatian
 Created:  06/27/15
 Version:  SAS 9.2
 Environment:  -
 
 Description:  Autocall macro to archive Catalog data sets.

 Modifications:
**************************************************************************/

/** Macro Archive_catalog_data - Start Definition **/

%macro Archive_catalog_data( 
  data=,     /** List of data set names **/
  zip_suf=,  /** Suffix for ZIP file name **/
  zip_pre=,  /** Prefix for ZIP file name (if missing current datetime is used) **/
  path=&_dcdata_r_path\PresCat\Data,   /** ZIP file path **/
  overwrite=n  /** Overwrite older files in archive **/
  );

  %local i v update_switches;
  
  %if %upcase( &overwrite ) = Y %then %let update_switches = ;
  %else %let update_switches = -uy1z1;  /** Copy previously saved older files to new archive **/
  
  %if &zip_pre = %then 
    %let zip_pre = %sysfunc( putn( %sysfunc( datetime() ), b8601dt19.0 ) );
    
  %put _local_;

  %let i = 1;
  %let v = %scan( &data, &i, %str( ) );

  %do %until ( &v = );

    x "&_dcdata_r_drive:\Tools\7-zip\7z a &update_switches -tzip &path\Archive\&zip_pre.&zip_suf &path\&v..sas7bdat";

    %let i = %eval( &i + 1 );
    %let v = %scan( &data, &i, %str( ) );

  %end;

%mend Archive_catalog_data;

/** End Macro Definition **/
