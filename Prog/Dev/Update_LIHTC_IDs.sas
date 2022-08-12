/**************************************************************************
 Program:  Update_LIHTC_ID.sas
 Library:  PresCat
 Project:  Urban-Greater DC
 Author:   Peter Tatian 
 Created:  08/12/2022
 Version:  SAS 9.4
 Environment:  Local Windows session (desktop)
 GitHub issue: #318 
  
 Description: Update LIHTC Project IDs in catalog from old format (DCB + 4 digit year + 3 digit number
 with leading zeroes) to new format (DCB + 4 digit year + 4 digit number with leading zeroes)

 Modifications:
**************************************************************************/

%include "\\sas1\DCdata\SAS\Inc\StdLocal.sas";

** Define libraries **;
%DCData_lib( PresCat )


data Subsidy;    /** This is the temporary data set we will create **/

  set Prescat.Subsidy;   /** Read in the existing Subsidy data set **/

  /** Only change LIHTC records that have a HUD project ID **/

  if portfolio = "LIHTC" and not( missing( subsidy_info_source_id ) ) then do;   
  
    /** Reformat IDs: 
            The first part takes the original 7 characters from the old ID.
            The second part reads the remaining characters as a number and reformats it
            as 4-character text with leading zeros (the z4. format).
            These two pieces are concatenated together (||) to make the new ID.
            The trim() and left() functions are used to remove trailing and leading blanks.
    **/

    subsidy_info_source_id = 
      trim( substr( subsidy_info_source_id, 1, 7 ) ) || 
      left( put( input( substr( subsidy_info_source_id, 8, 3 ), 3. ), z4. ) );

  end;

run;

%Finalize_data_set( 
  /** Finalize data set parameters **/
  data=Subsidy,
  out=Subsidy,
  outlib=PresCat,
  label="Preservation Catalog, Project subsidies",
  sortby=nlihc_id subsidy_id,
  /** Metadata parameters **/
  revisions=%str(Update LIHTC project IDs to new HUD format.),
  /** File info parameters **/
  printobs=0
)
