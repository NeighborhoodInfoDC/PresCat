/**************************************************************************
 Program:  Address_clean.sas
 Library:  PresCat
 Project:  NeighborhoodInfo DC
 Author:   P. Tatian
 Created:  07/27/13
 Version:  SAS 9.1
 Environment:  Windows
 
 Description:  Autocall macro to clean project addresses.

 Modifications:
**************************************************************************/

/** Macro Address_clean - Start Definition **/

%macro Address_clean( source, target );

  &target = propcase( left( compbl( &source ) ) );
  
  &target = tranwrd( &target, 'Ne', 'NE' );
  &target = tranwrd( &target, 'Se', 'SE' );
  &target = tranwrd( &target, 'Nw', 'NW' );
  &target = tranwrd( &target, 'Sw', 'SW' );

  &target = tranwrd( &target, 'NEw', 'New' );
  
%mend Address_clean;

/** End Macro Definition **/

