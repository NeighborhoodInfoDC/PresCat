/**************************************************************************
 Program:  Project_name_clean.sas
 Library:  PresCat
 Project:  NeighborhoodInfo DC
 Author:   P. Tatian
 Created:  07/27/13
 Version:  SAS 9.1
 Environment:  Windows
 
 Description:  Autocall macro to clean project names.

 Modifications:
  01/09/15 PAT Added Senior, CHHI, and NCBA.
  02/14/15 PAT Added Neighborhood, Second, Services, CEMI, IDI, others.
**************************************************************************/

/** Macro Project_name_clean - Start Definition **/

%macro Project_name_clean( source, target );

  &target = propcase( left( compbl( &source ) ) );
  
  &target = tranwrd( &target, 'Iii', 'III' );
  &target = tranwrd( &target, 'Ii', 'II' );
  &target = tranwrd( &target, 'Iv', 'IV' );
  &target = tranwrd( &target, 'IVy', 'Ivy' );
  &target = tranwrd( &target, 'Ne', 'NE' );
  &target = tranwrd( &target, 'NEw', 'New' );
  &target = tranwrd( &target, 'NEighborhood', 'Neighborhood' );
  &target = tranwrd( &target, 'NEighbors', 'Neighbors' );
  &target = tranwrd( &target, 'Nw', 'NW' );
  &target = tranwrd( &target, 'Se', 'SE' );
  &target = tranwrd( &target, 'SEnior', 'Senior' );
  &target = tranwrd( &target, 'SEcond', 'Second' );
  &target = tranwrd( &target, 'SErvices', 'Services' );
  &target = tranwrd( &target, 'SEnate', 'Senate' );
  &target = tranwrd( &target, 'Sw', 'SW' );
  &target = tranwrd( &target, 'At', 'at' );
  &target = tranwrd( &target, 'atlantic', 'Atlantic' );

  &target = tranwrd( &target, 'Pud', 'PUD' );
  &target = tranwrd( &target, 'Chhi', 'CHHI' );
  &target = tranwrd( &target, 'Ncba', 'NCBA' );
  &target = tranwrd( &target, 'Cemi', 'CEMI' );
  &target = tranwrd( &target, 'Idi', 'IDI' );
  &target = tranwrd( &target, 'Wdc', 'WDC' );
  &target = tranwrd( &target, 'Mlk', 'MLK' );
  &target = tranwrd( &target, 'Ufas', 'UFAS' );
  &target = tranwrd( &target, 'Dmh', 'DMH' );
  &target = tranwrd( &target, 'Tcb', 'TCB' );

%mend Project_name_clean;

/** End Macro Definition **/

