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

/*export SSL data to see if same address_id for different notice ids (there are many) */
proc export data=PresCat.topa_ssl
    outfile="&_dcdata_default_path\PresCat\PresCat\Prog\AddNew\topa_ssl.csv"
    dbms=csv
    replace;
run;

%File_info( data=PresCat.TOPA_SSL, printobs=5 )
%File_info( data=PresCat.TOPA_realprop, printobs=5 )
%File_info( data=PresCat.TOPA_addresses, printobs=5 )

/** merge address_id ssl and real_prop info **/
data Topa_address_ssl_realprop;

  merge
    PresCat.TOPA_SSL (keep=id address_id ssl)
    PresCat.TOPA_realprop (keep=id SALEDATE offer_sale_date CASD_date ADDRESS1 ADDRESS3 Ownername_full days_notice_to_sale ui_proptype Anc2012 cluster2017 Geo2020 GeoBg2020 GeoBlk2020 Psa2012 VoterPre2012 Ward2022 Ward2012)
    PresCat.TOPA_addresses (keep =id address);
 by id;

run;

** trying to create property_id not working**;
proc sort data=Topa_address_ssl_realprop out=Topa_addressid nodupkey;
  by address_id id;
run;
proc sort data=Topa_addressid out=tempdata nodupkey; 
  by address_id; 
run; 
 data Topa_propertyid;
  merge Topa_addressid tempdata(keep=address_id id rename=(address_id=property_id)); 
  by id; 
run; 

%File_info( data=Topa_addressid, printobs=5 )

** try #2 to merge three datasets (address_id ssl and real_prop) **;
proc sql noprint;
  create table Topa_address_ssl_realprop2 as   /** Name of output data set to be created **/
  select
    coalesce(TOPA_SSL.ID, TOPA_realprop.id, TOPA_addresses.id) as ID,    /** Matching variables **/
	TOPA_SSL.address_id, TOPA_SSL.ssl, TOPA_realprop.offer_sale_date, TOPA_realprop.SALEDATE, TOPA_addresses.address, TOPA_realprop.ADDRESS1, TOPA_realprop.ADDRESS3,
	TOPA_realprop.Ownername_full, TOPA_realprop.ui_proptype, TOPA_SSL.Anc2012, TOPA_SSL.cluster2017, TOPA_SSL.Geo2020, TOPA_SSL.GeoBg2020, TOPA_SSL.GeoBlk2020, TOPA_SSL.Psa2012, TOPA_SSL.VoterPre2012, TOPA_SSL.Ward2022
    from PresCat.TOPA_SSL (where=(not(missing(address_id))))as TOPA_SSL
      full join PresCat.TOPA_realprop as TOPA_realprop
	  	on TOPA_SSL.ID = TOPA_realprop.ID
	  full join PresCat.TOPA_addresses as TOPA_addresses
	  	on TOPA_SSL.ID = TOPA_addresses.ID 
  order by TOPA_SSL.address_id, TOPA_SSL.ID;   
quit;

%File_info( data=Topa_address_ssl_realprop2)

proc export data=Topa_address_ssl_realprop2
    outfile="&_dcdata_default_path\PresCat\Prog\AddNew\Topa_address_ssl_realprop2.csv"
    dbms=csv
    replace;
run;

proc export data=Topa_addressid
    outfile="&_dcdata_default_path\PresCat\Prog\AddNew\Topa_addressid.csv"
    dbms=csv
    replace;
run;







