/**************************************************************************
 Program:  DC_Pipeline_2022_07.sas
 Library:  PresCat
 Project:  Urban Greater DC
 Author:   Elizabeth Burton
 Created:  07/26/2022
 Version:  SAS 9.4
 Environment:  Local Windows session (desktop)
 
 Description:  combined pipeline 5+ dataset in PresCat library (TOPA study)

 Modifications:
**************************************************************************/

%include "\\sas1\DCdata\SAS\Inc\StdLocal.sas";

** Define libraries **;
%DCData_lib( PresCat )

proc import datafile="\\sas1\dcdata\Libraries\PresCat\Raw\TOPA\combined_pipeline_5.csv"
            dbms=csv
            out=DC_Pipeline_2022_07
            replace;
		
     getnames=yes;
	 guessingrows=max;

run;



proc print data=DC_Pipeline_2022_07;
run;

  %Finalize_data_set( 
    /** Finalize data set parameters **/
    data="\\sas1\dcdata\Libraries\PresCat\Raw\TOPA\combined_pipeline_5+.csv",
    out=DC_Pipeline_2022_07,
    outlib=PresCat,
    label="Preservation Catalog, new DC pipeline dataset (TOPA)",
    sortby=unique identifier variable(s) for each row,
    /** Metadata parameters **/
    revisions=%str(New data set.),
    /** File info parameters **/
    printobs=10,
	freqvars=list of variables for frequency tables
  )
