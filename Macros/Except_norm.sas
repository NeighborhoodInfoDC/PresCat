/**************************************************************************
 Program:  Except_norm.sas
 Library:  PresCat
 Project:  NeighborhoodInfo DC
 Author:   P. Tatian
 Created:  06/27/15
 Version:  SAS 9.2
 Environment:  -
 
 Description:  Autocall macro to normalize Preservation Catalog
 exception file. Normalizing combines multiple update records for an
 individual project/subsidy. A warning is made to the LOG if there
 are multiple updates given for the same field for a project/subsidy.

 Modifications:
**************************************************************************/

/** Macro Except_norm - Start Definition **/

%macro Except_norm( 
  lib=PresCat,   /** Library **/
  data=,      /** Input data set name (no lib) **/
  out=,       /** Output data set name (no lib). If omitted, out=&data._norm **/
  by=         /** BY variable(s) identifying unique obs **/ 
  );

  %local charvarlist charvarlistclean charvarlistret numvarlist numvarlistclean numvarlistret
         lastby;

  %if &out= %then %let out = &data._norm;
  
  %let lastby = %scan( &by, -1, %str( ) );

  proc sql noprint;
    select distinct name into :charvarlist separated by ' '
    from dictionary.columns
    where libname="%upcase(&lib)" and memname="%upcase(&data)" and type='char';

    select distinct name into :numvarlist separated by ' '
    from dictionary.columns
    where libname="%upcase(&lib)" and memname="%upcase(&data)" and type='num';
  quit;

  proc sort data=&lib..&data out=&data._srt;
    by &by descending except_date;
  run;

  %let charvarlistclean = %ListDelete( %lowcase(&charvarlist), %lowcase( &by ) except_init );

  %let charvarlistret = %ListChangeDelim( &charvarlistclean, new_delim=%str( ), suffix=_ret );

  %let numvarlistclean = %ListDelete( %lowcase(&numvarlist), %lowcase( &by ) except_date );

  %let numvarlistret = %ListChangeDelim( &numvarlistclean, new_delim=%str( ), suffix=_ret );

  %put _local_;

  data &out;

    set &data._srt;
    by &by;

    length &charvarlistret $ 400;
    length &numvarlistret 8;
    
    retain &charvarlistret;
    retain &numvarlistret;
    
    array cvar{*} &charvarlistclean;
    array cret{*} &charvarlistret;
    array nvar{*} &numvarlistclean;
    array nret{*} &numvarlistret;
    
    if first.&lastby then do;
    
      do i = 1 to dim( cret );
        cret{i} = '';
      end;
      
      do i = 1 to dim( nret );
        nret{i} = .;
      end;
      
    end;
    
    do i = 1 to dim( cret );
      if cret{i} = '' then cret{i} = cvar{i};
      else if cvar{i} ~= '' then do;
        %warn_put( msg="Multiple exceptions specified: " (&by) (=) cvar{i}= except_date= )
      end;
    end;
    
    do i = 1 to dim( nret );
      if nret{i} = . then nret{i} = nvar{i};
      else if nvar{i} ~= . then do;
        %warn_put( msg="Multiple exceptions specified: " (&by) (=) nvar{i}= except_date= )
      end;
    end;

    if last.&lastby then do;
    
      do i = 1 to dim( cret );
        cvar{i} = cret{i};
      end;

      do i = 1 to dim( nret );
        nvar{i} = nret{i};
      end;

      output;

    end;
    
    drop i &charvarlistret &numvarlistret Except_: ;
    
  run;

%mend Except_norm;

/** End Macro Definition **/

