/**************************************************************************
 Program:  Create_place_name_list.sas
 Library:  PresCat
 Project:  Urban-Greater DC
 Author:   P. Tatian
 Created:  07/31/25
 Version:  SAS 9.4
 Environment:  Local Windows session (desktop)
 GitHub issue:  
 
 Description:  Create Place_name_list variable from
 Mar.Points_of_interest file based on list of addresses provided and
 summarized by BY variable. 

 Modifications:
**************************************************************************/

%macro Create_place_name_list( by=, data=PresCat.Building_geocode, out=Place_name_list_&by );

  ** Reduce Place_name to one per &BY= value **;

  proc sql noprint;
    create table _Place_name as
    select distinct &by, Place_name from
    (
      select 
        coalesce( Addr.bldg_address_id, POI.address_id ) as match_address_id, Addr.&by, POI.Place_name 
        from PresCat.Building_geocode as Addr left join Mar.Points_of_interest as POI
      on Addr.bldg_address_id = POI.address_id
      where not( missing( POI.Place_name ) )
    )
    order by &by, Place_name;
  quit;

  data &out;

    set _Place_name;
    by &by;

    retain Place_name_list;
    
    length Place_name_list $ 1000;
    
    if first.&by then do;
      Place_name_list = "";
    end;
    
    Place_name_list = catx( '; ', Place_name_list, propcase( Place_name ) );
    
    if last.&by then output;
    
    drop Place_name;
    
    label
      Place_name_list = "List of MAR point of interest names (aliases)";
      
  run;

  ** Clean up temporary files **;
  
  proc datasets library=Work memtype=(data) nolist;
    delete _Place_name;
  quit;
  run;

%mend Create_place_name_list;

