/**************************************************************************
 Program:  Quick_analysis.sas
 Library:  PresCat
 Project:  Urban-Greater DC
 Author:   P. Tatian
 Created:  03/16/23
 Version:  SAS 9.4
 Environment:  Local Windows session (desktop)
 GitHub issue:  ???
 
 Description:

 Modifications:
**************************************************************************/

%include "\\sas1\DCdata\SAS\Inc\StdLocal.sas";

** Define libraries **;
%DCData_lib( PresCat )

**** Quick analysis ****;

data TOPA_by_property;

  merge Prescat.Topa_database Topa_id_x_address;
  by id;

  Offer_of_Sale_date = input( Offer_of_Sale_date__usually_DHCD, ANYDTDTE12. );
  
  format Offer_of_Sale_date mmddyy10.;

run;

proc summary data=TOPA_by_property nway;
  where not( missing( address_id_ref ) );
  class address_id_ref;
  output out=TOPA_notice_counts;
run;

proc freq data=TOPA_notice_counts;
  tables _freq_;
run;

proc sort data=TOPA_notice_counts;
  by descending _freq_;
run;

proc print data=TOPA_notice_counts (obs=50);
  id address_id_ref;
  var _freq_;
run;

proc print data=TOPA_by_property;
  where address_id_ref in ( 38674 );
  id id;
  var Offer_of_Sale_date;
run;

data Sales_by_property;

  merge
    Prescat.Topa_realprop Topa_id_x_address;
  by id;

run;

proc sort data=Sales_by_property out=Sales_by_property_nodup nodupkey;
  by address_id_ref saledate;
run;

proc sort data=TOPA_by_property;
  by address_id_ref offer_of_sale_date id;
run;

data Combo;

  set 
    TOPA_by_property 
    (keep=address_id_ref id offer_of_sale_date
     rename=(offer_of_sale_date=ref_date))
    Sales_by_property_nodup
	  (keep=address_id_ref saledate saleprice ownername_full ui_proptype
	   rename=(saledate=ref_date));
	by address_id_ref ref_date;

run;

proc print data=Sales_by_property_nodup;
  where address_id_ref in ( 38674 );
  id id;
  var saledate saleprice ownername_full;
run;


