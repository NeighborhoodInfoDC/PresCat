/**************************************************************************
 Program:  TOPA_match_notices_property.sas
 Library:  PresCat
 Project:  Urban-Greater DC
 Author:   Elizabeth Burton
 Created:  12/13/2022
 Version:  SAS 9.4
 Environment:  Local Windows session (desktop)
 
 Description:  Match TOPA notices to the same properties
 
 Modifications:
**************************************************************************/

%include "\\sas1\DCdata\SAS\Inc\StdLocal.sas";

** Define libraries **;
%DCData_lib( PresCat )
%DCData_lib( DHCD )
%DCData_lib( MAR )
%DCData_lib( RealProp )

%File_info( data=PresCat.TOPA_SSL, printobs=5 )
%File_info( data=PresCat.TOPA_realprop, printobs=5 ) /** some IDs don't have real_prop info**/
%File_info( data=PresCat.TOPA_addresses, printobs=5 )

/** merge address_id ssl and real_prop info **/

data Topa_address_ssl_realprop;
  merge
    PresCat.TOPA_SSL (keep=id address_id ssl)
    PresCat.TOPA_realprop (keep=id SALEDATE offer_sale_date CASD_date ADDRESS1 ADDRESS3 Ownername_full days_notice_to_sale ui_proptype Anc2012 cluster2017 Geo2020 GeoBg2020 GeoBlk2020 Psa2012 VoterPre2012 Ward2022 Ward2012)
    PresCat.TOPA_addresses (keep =id address);
run;

%File_info( data=Topa_address_ssl_realprop, printobs=5 )

/** sorting by id then address id**/
proc sort data=Topa_address_ssl_realprop out=Topa_address_ssl_realprop_sort;
  by id address_id;
run;

%File_info( data=Topa_address_ssl_realprop_sort, printobs=5 )

/** create ID (notice) x address_id crosswalk **/
data Topa_id_x_address; 
  set Topa_address_ssl_realprop_sort;
  by id; 
  if first.id then output; 
  keep address_id id; 
  rename address_id=address_id_ref;
run; 

%File_info( data=Topa_id_x_address, printobs=5 )

/** address_id_ref as property id **/
data Topa_addressid_merge; 
  merge
    Topa_id_x_address Topa_address_ssl_realprop_sort;
  by id; 
run; 

%File_info( data=Topa_addressid_merge, printobs=5 )

/** sorting by address_id-ref then address id**/
proc sort data=Topa_addressid_merge out=Topa_propertyid;
  by address_id_ref;
run;

%File_info( data=Topa_propertyid, printobs=5 )

proc export data=Topa_propertyid
    outfile="&_dcdata_default_path\PresCat\Prog\AddNew\Topa_propertyid.csv"
    dbms=csv
    replace;
run;

  %Finalize_data_set( 
    /** Finalize data set parameters **/
    data=Topa_id_x_address,
    out=Topa_id_x_address,
    outlib=PresCat,
    label="Preservation Catalog, ID (TOPA notice) and address_id crosswalk",
    sortby=id,
    /** Metadata parameters **/
    revisions=%str(New data set.),
    /** File info parameters **/
    printobs=10 
  )





