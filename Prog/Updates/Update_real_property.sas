/**************************************************************************
 Program:  Update_real_property.sas
 Library:  PresCat
 Project:  NeighborhoodInfo DC
 Author:   P. Tatian
 Created:  10/09/16
 Version:  SAS 9.1
 Environment:  Local Windows session (desktop)
 
 Description:  Create Real_Property table for Preservation Catalog
 (real property events such as sales, foreclosures).

 Modifications:
**************************************************************************/

%include "\\sas1\DCdata\SAS\Inc\StdLocal.sas";

** Define libraries **;
%DCData_lib( PresCat )
%DCData_lib( RealProp, local=n )
%DCData_lib( ROD, local=n )
%DCData_lib( DHCD, local=n )


%Update_real_property( )

run;
