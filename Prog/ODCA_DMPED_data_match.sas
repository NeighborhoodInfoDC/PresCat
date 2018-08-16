/**************************************************************************
 Program:  ODCA_DMPED_data_match.sas
 Library:  PRESCAT
 Project:  NeighborhoodInfo DC
 Author:   M. Cohen
 Created:  8/13/18
 Version:  SAS 9.2
 Environment:  Local Windows session (desktop)
 
 Description:  Match projects from ODCA and DMPED data sets to create unique new projects list.

 Modifications:
**************************************************************************/

/*data match;                                                                                                                                 
  set hptf_proj_mar (rename = (address_std=addr1)) nobs=nobs1;
	*tmp1=soundex(address_std);                                                                                                                  
  do i=1 to nobs1; 
    set odca_hptf_mar (rename=(address_std = addr2)) point=i;
	*tmp2=soundex(address_std2) ;
    *dif=compged(addr1,addr2,999,'i');                                                                                                             
   * if _n_ then do;                                                                                                                 
      possible_match='Yes';                                                                                                             
   *   output;                                                                                                                                                                                                                                                       
*  end; 
	end; 
	keep addr1 addr2 dif;
run;   */

proc sql; 
  create table matches as 
  select a._dcg_adr_geocode as add1, b._dcg_adr_geocode as add2,  
         compged(a._dcg_adr_geocode,b._dcg_adr_geocode,999,'iL' ) as match
    from hptf_proj_mar a, odca_hptf_mar b 
      /*order by calculated gedscore*/; 
quit;
 
proc print; run;
