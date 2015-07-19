/**************************************************************************
 Program:  Update_history_recs.sas
 Library:  PresCat
 Project:  NeighborhoodInfo DC
 Author:   P. Tatian
 Created:  07/18/15
 Version:  SAS 9.2
 Environment:  Local Windows session (desktop)
 
 Description:  Autocall macro to create records for updating project
 and subsidy history data sets.

 Modifications:
**************************************************************************/

/** Macro Update_history_recs - Start Definition **/

%macro Update_history_recs( data=, out=, Update_vars= );

  %local Update_vars_dif Update_vars_base Update_vars_compare Update_vars_except
         Update_vars_dif_char Update_vars_dif_num Update_vars_base_char Update_vars_base_num
         Update_vars_compare_char Update_vars_compare_num Update_vars_except_char Update_vars_except_num;

  ***** Add record to Update_subsidy_history *****;

  %** Create variable lists **;
  
  %let Update_vars_dif = %ListChangeDelim( &Update_vars, new_delim=%str( ), suffix=_DIF );
  %let Update_vars_base = %ListChangeDelim( &Update_vars, new_delim=%str( ), suffix=_BASE );
  %let Update_vars_compare = %ListChangeDelim( &Update_vars, new_delim=%str( ), suffix=_COMPARE );
  %let Update_vars_except = %ListChangeDelim( &Update_vars, new_delim=%str( ), suffix=_EXCEPT );
  
  ** Separate lists of numeric and character vars **;

  proc sql noprint;

    select distinct name into :Update_vars_dif_char separated by ' '
    from dictionary.columns 
    where libname="WORK" and memname="%upcase(&data)" and type='char' 
      and indexw( "%upcase(&Update_vars_dif)", upcase( name ) ) > 0;

    select distinct name into :Update_vars_dif_num separated by ' '
    from dictionary.columns 
    where libname="WORK" and memname="%upcase(&data)" and type='num' 
      and indexw( "%upcase(&Update_vars_dif)", upcase( name ) ) > 0;

    select distinct name into :Update_vars_base_char separated by ' '
    from dictionary.columns 
    where libname="WORK" and memname="%upcase(&data)" and type='char' 
      and indexw( "%upcase(&Update_vars_base)", upcase( name ) ) > 0;

    select distinct name into :Update_vars_base_num separated by ' '
    from dictionary.columns 
    where libname="WORK" and memname="%upcase(&data)" and type='num' 
      and indexw( "%upcase(&Update_vars_base)", upcase( name ) ) > 0;

    select distinct name into :Update_vars_compare_char separated by ' '
    from dictionary.columns 
    where libname="WORK" and memname="%upcase(&data)" and type='char' 
      and indexw( "%upcase(&Update_vars_compare)", upcase( name ) ) > 0;

    select distinct name into :Update_vars_compare_num separated by ' '
    from dictionary.columns 
    where libname="WORK" and memname="%upcase(&data)" and type='num' 
      and indexw( "%upcase(&Update_vars_compare)", upcase( name ) ) > 0;

    select distinct name into :Update_vars_except_char separated by ' '
    from dictionary.columns 
    where libname="WORK" and memname="%upcase(&data)" and type='char' 
      and indexw( "%upcase(&Update_vars_except)", upcase( name ) ) > 0;

    select distinct name into :Update_vars_except_num separated by ' '
    from dictionary.columns 
    where libname="WORK" and memname="%upcase(&data)" and type='num' 
      and indexw( "%upcase(&Update_vars_except)", upcase( name ) ) > 0;

  quit;

  %put _local_;

  data &out;

    set &data;
    
    format &Update_vars_dif ;
    
    array difnum{*} &Update_vars_dif_num;
    array difchar{*} &Update_vars_dif_char;
    array compchar{*} &Update_vars_compare_char;
    array compnum{*} &Update_vars_compare_num;
    array basechar{*} &Update_vars_base_char;
    array basenum{*} &Update_vars_base_num;
    array exceptchar{*} &Update_vars_except_char;
    array exceptnum{*} &Update_vars_except_num;
    
    Write = 0;
    
    do i = 1 to dim( difnum );
      if not( missing( compnum{i} ) or not( abs( difnum{i} ) > 0 ) ) or not( missing( exceptnum{i} ) ) then do;
        Write = 1;
      end;
      else do;
        basenum{i} = .;
        compnum{i} = .;
        exceptnum{i} = .;
      end;
    end;
    
    do i = 1 to dim( difchar );
      difchar{i} = compress( difchar{i}, "." );
      if not( missing( compchar{i} ) or not( abs( difchar{i} ) > 0 ) ) or not( missing( exceptchar{i} ) ) then do;
        Write = 1;
      end;
      else do;
        basechar{i} = "";
        compchar{i} = "";
        exceptchar{i} = "";
      end;
    end;

    if Write;
      
    drop i Write Category_code &Update_vars_dif;
    
  run;

  /***%File_info( data=&out, stats= )***/

%mend Update_history_recs;

/** End Macro Definition **/

