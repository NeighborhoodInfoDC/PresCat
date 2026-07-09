/**************************************************************************
 The repo's %Create_place_name_list autocall macro
 (Macros/Create_place_name_list.sas), copied with one substitution: the
 two-level source names PresCat.Building_geocode and Mar.Points_of_interest
 in the PROC SQL are pointed at the WORK stand-ins built in autoexec.sas, so
 the bundle needs no external libraries. The macro's logic is unchanged: a
 coalesce/left-join gathers the MAR point-of-interest names for each
 project's building addresses, then a retain + catx pass with first./last.
 collapses them into one semicolon-delimited alias list per BY value.

 We then call it with by=nlihc_id and print the resulting alias lists.
**************************************************************************/

%macro Create_place_name_list( by=, data=Building_geocode, out=Place_name_list_&by );

  ** Reduce Place_name to one per &BY= value **;

  proc sql noprint;
    create table _Place_name as
    select distinct &by, Place_name from
    (
      select
        coalesce( Addr.bldg_address_id, POI.address_id ) as match_address_id, Addr.&by, POI.Place_name
        from Building_geocode as Addr left join Points_of_interest as POI
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

%Create_place_name_list( by=nlihc_id )

proc print data=Place_name_list_nlihc_id noobs label;
  var nlihc_id Place_name_list;
  label nlihc_id = "Project ID";
run;
