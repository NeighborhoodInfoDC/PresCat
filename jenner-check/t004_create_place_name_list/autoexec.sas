/* cap input rows for the captured run */
options obs=100;

/* Mock stand-ins for the two source tables the macro reads. In the repo these
   are PresCat.Building_geocode (project buildings, keyed by bldg_address_id)
   and Mar.Points_of_interest (MAR landmark/alias names, keyed by address_id).
   Only the columns the macro touches are populated; the rows are invented so
   the bundle is self-contained. */

data Building_geocode;
  length nlihc_id $ 16 bldg_address_id 8;
  input nlihc_id $ bldg_address_id;
  datalines;
NL000046 101
NL000046 102
NL000093 201
NL000319 301
NL000319 302
NL000319 303
;
run;

data Points_of_interest;
  length address_id 8 Place_name $ 80;
  input address_id Place_name $char80.;
  datalines;
101 EDGEWOOD TERRACE
102 EDGEWOOD COMMONS
201 THE ARTHUR CAPPER SENIOR
301 GALEN TERRACE
302 GALEN STREET APARTMENTS
303 SAVANNAH HEIGHTS
;
run;
