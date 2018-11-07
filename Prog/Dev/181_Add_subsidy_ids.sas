/**************************************************************************
 Program:  181_Add_subsidy_ids.sas
 Library:  PresCat
 Project:  Urban-Greater DC
 Author:   P. Tatian
 Created:  11/07/18
 Version:  SAS 9.4
 Environment:  Local Windows session (desktop)
 
 Description:  Add/update subsidy IDs for Section 8 projects. 

 GitHub issue #181.

 Three Section 8 subsidies currently not matching with projects in Catalog. 
 Need to add or update subsidy records to correctly match these updates.

 NL000109 (Ft Chaplin Park) - Add subsidy record with ID 800243935/DC39H001010
 NL000133 (Gibson Plaza) - Add subsidy record with ID 800003725/DC39M000033
 NL000243 (Portner Flats) - Update subsidy 2 with ID 800242032/DC390007005

 Modifications:
**************************************************************************/

%include "L:\SAS\Inc\StdLocal.sas";

** Define libraries **;
%DCData_lib( PresCat )

data Subsidy;

  set PresCat.Subsidy;
  by nlihc_id subsidy_id;
  
  select ( nlihc_id );
  
    when ( 'NL000109' ) do;  /** Ft Chaplin Park **/
    
      output;

      if last.nlihc_id then do;

        subsidy_id = subsidy_id + 1;
        
        agency = 'US Dept of Housing and Urban Development';
        contract_number = 'DC39H001010';
        compl_end = .;
        poa_end = .;
        poa_end_actual = .;
        poa_end_prev = .;
        poa_start = .;
        poa_start_orig = .;
        portfolio = 'PB8';
        program = 'S8-SR';
        rent_to_fmr_description = '';
        subsidy_active = 1;
        subsidy_info_source = 'HUD/MFA';
        subsidy_info_source_date = .;
        subsidy_info_source_id = '800243935/DC39H001010';
        subsidy_info_source_property = '800243935';
        units_assist = 72;
        update_dtm = .;
        
        output;
        
      end;
      
    end;
      
    when ( 'NL000133' ) do;  /** Gibson Plaza **/
    
      output;

      if last.nlihc_id then do;

        subsidy_id = subsidy_id + 1;
        
        agency = 'US Dept of Housing and Urban Development';
        contract_number = 'DC39M000033';
        compl_end = .;
        poa_end = .;
        poa_end_actual = .;
        poa_end_prev = .;
        poa_start = .;
        poa_start_orig = .;
        portfolio = 'PB8';
        program = 'LMSA';
        rent_to_fmr_description = '';
        subsidy_active = 1;
        subsidy_info_source = 'HUD/MFA';
        subsidy_info_source_date = .;
        subsidy_info_source_id = '800003725/DC39M000033';
        subsidy_info_source_property = '800003725';
        units_assist = 122;
        update_dtm = .;
        
        output;
        
      end;
      
    end;
    
    when ( 'NL000243' ) do;  /** Portner Flats **/
    
      if subsidy_id = 2 then do;
      
        contract_number = 'DC390007005';
        subsidy_info_source_id = '800242032/DC390007005';
        subsidy_info_source_property = '800242032';
        
        output;
      
      end;
      else do;
      
        output;
        
      end;
    
    end;
    
    otherwise
      output;
      
  end;
      
run;

proc compare base=PresCat.Subsidy compare=Subsidy listall maxprint=(40,32000);
  id nlihc_id subsidy_id;
run;


%Finalize_data_set( 
  /** Finalize data set parameters **/
  data=Subsidy,
  out=Subsidy,
  outlib=PresCat,
  label='Preservation Catalog, Project subsidies',
  sortby=nlihc_id subsidy_id,
  archive=Y,
  /** Metadata parameters **/
  restrictions=None,
  revisions=%str(Update S8 subsidy IDs for NL000109, NL000133, NL000243.),
  /** File info parameters **/
  printobs=0
)

