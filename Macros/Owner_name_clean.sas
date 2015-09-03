/**************************************************************************
 Program:  Owner_name_clean.sas
 Library:  PresCat
 Project:  NeighborhoodInfo DC
 Author:   P. Tatian
 Created:  07/27/13
 Version:  SAS 9.1
 Environment:  Windows
 
 Description:  Autocall macro to clean owner names.

 Modifications:
**************************************************************************/

/** Macro Owner_name_clean - Start Definition **/

%macro Owner_name_clean( source, target );

  &target = propcase( left( compbl( &source ) ) );
  
  &target = tranwrd( &target, 'Dchfa', 'DCHFA' );
  &target = tranwrd( &target, 'Dc', 'DC' );
  &target = tranwrd( &target, 'Iii', 'III' );
  &target = tranwrd( &target, 'Ii', 'II' );
  &target = tranwrd( &target, 'Iv', 'IV' );
  &target = tranwrd( &target, 'Ne', 'NE' );
  &target = tranwrd( &target, 'NEw', 'New' );
  &target = tranwrd( &target, 'NEighborhood', 'Neighborhood' );
  &target = tranwrd( &target, 'Nw', 'NW' );
  &target = tranwrd( &target, 'Se', 'SE' );
  &target = tranwrd( &target, 'SEnior', 'Senior' );
  &target = tranwrd( &target, 'SEcond', 'Second' );
  &target = tranwrd( &target, 'SErvices', 'Services' );
  &target = tranwrd( &target, 'SEnate', 'Senate' );
  &target = tranwrd( &target, 'SEven', 'Seven' );
  &target = tranwrd( &target, 'SEan', 'Sean' );
  &target = tranwrd( &target, 'Sw', 'SW' );
  &target = tranwrd( &target, 'Na', 'NA' );
  &target = tranwrd( &target, 'Ncba', 'NCBA' );
  &target = tranwrd( &target, 'Ncb', 'NCB' );
  &target = tranwrd( &target, 'Of', 'of' );
  &target = tranwrd( &target, 'Fsb', 'FSB' );
  &target = tranwrd( &target, 'Pnc', 'PNC' );
  &target = tranwrd( &target, 'Lp', 'LP' );
  &target = tranwrd( &target, 'L.P.', 'LP' );
  &target = tranwrd( &target, 'Llp', 'LLP' );
  &target = tranwrd( &target, 'L.L.P.', 'LLP' );
  &target = tranwrd( &target, 'Llc', 'LLC' );
  &target = tranwrd( &target, 'Nja', 'NJA' );
  
  &target = tranwrd( &target, 'IVy', 'Ivy' );
  &target = tranwrd( &target, 'NAtion', 'Nation' );
  &target = tranwrd( &target, 'NAylor', 'Naylor' );
  &target = tranwrd( &target, 'atlantic', 'Atlantic' );
  
  &target = tranwrd( &target, 'Nhcoa', 'NHCOA' );
  &target = tranwrd( &target, 'Nhte', 'NHTE' );
  &target = tranwrd( &target, 'Nmi', 'NMI' );
  &target = tranwrd( &target, 'Cih', 'CIH' );
  &target = tranwrd( &target, 'Ct', 'CT' );
  &target = tranwrd( &target, 'Shnir', 'SHNIR' );
  &target = tranwrd( &target, 'Wr', 'WR' );
  &target = tranwrd( &target, 'Op', 'OP' );
  &target = tranwrd( &target, 'Ndc', 'NDC' );
  &target = tranwrd( &target, 'Cpdc', 'CPDC' );
  &target = tranwrd( &target, 'Hfa', 'HFA' );
  &target = tranwrd( &target, 'Ksi', 'KSI' );
  &target = tranwrd( &target, 'Spm', 'SPM' );
  &target = tranwrd( &target, 'Fpw', 'FPW' );
  &target = tranwrd( &target, 'Npcdc', 'NPCDC' );
  &target = tranwrd( &target, 'Nhpmn', 'NHPMN' );
  &target = tranwrd( &target, 'Gra Properties', 'GRA Properties' );
  &target = tranwrd( &target, 'Poah', 'POAH' );
  &target = tranwrd( &target, 'Sc Elsinore', 'SC Elsinore' );
  
%mend Owner_name_clean;

/** End Macro Definition **/

