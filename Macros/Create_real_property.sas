/**************************************************************************
 Program:  Create_real_property.sas
 Library:  PresCat
 Project:  NeighborhoodInfo DC
 Author:   P. Tatian
 Created:  06/03/17
 Version:  SAS 9.2
 Environment:  Local Windows session (desktop)
 
 Description:  Autocall macro to create updated Real_property data
 set from PresCat.Parcel, RealProp.Sales_master,
 Realprop.Sales_master_forecl, Rod.Foreclosures_????, and
 Dhcd.Rcasd_????.

 RealProp, ROD, and DHCD libraries must be declared before calling 
 this macro.
 
 NOTE: THIS MACRO IS DEPRECATED. USE %UPDATE_REAL_PROPERTY() INSTEAD. 

 Modifications:
**************************************************************************/

/** Macro Create_real_property - Start Definition **/

%macro Create_real_property( 
  data=PresCat.Parcel, 
  out=Real_property,
  revisions=, 
  compare=Y,
  finalize=Y, 
  archive=N 
  );

  %err_mput( macro=Create_real_property, msg=%nrstr(This macro is deprecated. Use %Update_real_property() instead.) )
  
  %note_mput( macro=Create_real_property, msg=Macro exiting. )

%mend Create_real_property;

/** End Macro Definition **/

