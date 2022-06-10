/**************************************************************************
 Program:  Update_REAC_init.sas
 Library:  PresCat
 Project:  NeighborhoodInfo DC
 Author:   M. Cohen
 Created:  07/3/18
 Version:  SAS 9.2
 Environment:  -
 
 Description:  Autocall macro to initialize macro variables and formats
 for REAC update.

 Modifications:
**************************************************************************/

/** Macro Update_REAC - Start Definition **/

%macro Update_REAC_init( Update_file= );

  %global 
	Update_dtm REAC_date REAC_score REAC_score_num REAC_score_letter REAC_score_star REAC_ID Subsidy_Info_Source_ID_src rems_property_id 
	inspec_score_1 release_date_1 inspec_score_2 release_date_2 inspec_score_3 release_date_3 property_name state city state_code;
    
  %let Update_dtm = %sysfunc( datetime() );
  
  ** Create $reac_nlihcid. format to add NLIHC ID from HUD property ID **;

  proc format;
    value $reac_nlihcid
    "800000023" = "NL000064"
    "800000032" = "NL000101"
    "800000063" = "NL000243"
    "800000073" = "NL000309"
    "800003669" = "NL000021"
    "800003671" = "NL000023"
    "800003672" = "NL000026"
    "800003673" = "NL000028"
    "800003674" = "NL000031"
    "800003675" = "NL000046"
    "800003678" = "NL000036"
    "800003679" = "NL000038"
    "800003680" = "NL000039"
    "800003681" = "NL000040"
    "800003683" = "NL000047"
    "800003684" = "NL000048"
    "800003685" = "NL000052"
    "800003686" = "NL000342"
    "800003687" = "NL000055"
    "800003688" = "NL000056"
    "800003689" = "NL000057"
    "800003690" = "NL000060"
    "800003691" = "NL000065"
    "800003694" = "NL000224"
    "800003696" = "NL000074"
    "800003698" = "NL000080"
    "800003699" = "NL000081"
    "800003700" = "NL000295"
    "800003701" = "NL000220"
    "800003702" = "NL000082"
    "800003703" = "NL000035"
    "800003704" = "NL000096"
    "800003705" = "NL000091"
    "800003706" = "NL000092"
    "800003708" = "NL000094"
    "800003709" = "NL000102"
    "800003710" = "NL000371"
    "800003713" = "NL000296"
    "800003714" = "NL000105"
    "800003715" = "NL000112"
    "800003716" = "NL000113"
    "800003717" = "NL000111"
    "800003719" = "NL000114"
    "800003720" = "NL000116"
    "800003721" = "NL000117"
    "800003722" = "NL000120"
    "800003724" = "NL000127"
    "800003725" = "NL000133"
    "800003727" = "NL000134"
    "800003728" = "NL000135"
    "800003729" = "NL000136"
    "800003730" = "NL000137"
    "800003735" = "NL000142"
    "800003736" = "NL000297"
    "800003738" = "NL000152"
    "800003739" = "NL000164"
    "800003741" = "NL000001"
    "800003742" = "NL000170"
    "800003744" = "NL000175"
    "800003745" = "NL000179"
    "800003746" = "NL000185"
    "800003747" = "NL000186"
    "800003750" = "NL000195"
    "800003751" = "NL000196"
    "800003753" = "NL000202"
    "800003755" = "NL000208"
    "800003756" = "NL000229"
    "800003757" = "NL000259"
    "800003758" = "NL000216"
    "800003759" = "NL000217"
    "800003761" = "NL000218"
    "800003762" = "NL000069"
    "800003764" = "NL000222"
    "800003766" = "NL000227"
    "800003767" = "NL000228"
    "800003768" = "NL000232"
    "800003771" = "NL000298"
    "800003775" = "NL000252"
    "800003776" = "NL000253"
    "800003778" = "NL000226"
    "800003779" = "NL000262"
    "800003780" = "NL000273"
    "800003781" = "NL000274"
    "800003782" = "NL000275"
    "800003783" = "NL000277"
    "800003784" = "NL000280"
    "800003785" = "NL000284"
    "800003786" = "NL000283"
    "800003787" = "NL000288"
    "800003788" = "NL000290"
    "800003789" = "NL000291"
    "800003790" = "NL000293"
    "800003793" = "NL000307"
    "800003800" = "NL000319"
    "800003803" = "NL000324"
    "800003804" = "NL000329"
    "800003805" = "NL000303"
    "800003806" = "NL000334"
    "800003807" = "NL000070"
    "800024118" = "NL000206"
    "800024120" = "NL000310"
    "800024133" = "NL000306"
    "800024702" = "NL000126"
    "800024749" = "NL000068"
    "800024759" = "NL000271"
    "800024766" = "NL000147"
    "800024865" = "NL000261"
    "800025212" = "NL000190"
    "800025216" = "NL000041"
    "800025397" = "NL000316"
    "800025410" = "NL000029"
    "800053839" = "NL000242"
    "800053918" = "NL000084"
    "800054044" = "NL000286"
    "800054046" = "NL000183"
    "800054053" = "NL000200"
    "800112248" = "NL000301"
    "800210663" = "NL000016"
    "800210735" = "NL000255"
    "800211965" = "NL000279"
    "800212137" = "NL000320"
    "800213311" = "NL000215"
    "800213689" = "NL000151"
    "800214050" = "NL000236"
    "800214301" = "NL000083"
    "800214338" = "NL000076"
    "800214475" = "NL000037"
    "800214527" = "NL000234"
    "800215755" = "NL000077"
    "800216168" = "NL000204"
    "800216208" = "NL000166"
    "800218122" = "NL000045"
    "800218205" = "NL000413"
    "800218515" = "NL000138"
    "800220355" = "NL000260"
    "800220515" = "NL000171"
    "800221078" = "NL000221"
	"800003796" = "NL000311"
	"800024762" = "NL001014"
	"800025202" = "NL001018"
	"800054049" = "NL000251"
	"800210966" = "NL001010"
	"800218273" = "NL000052"
	"800218510" = "NL000154"
	"800218816" = "NL000103"
	"800218969" = "NL001000"
	"800227252" = "NL000054"
    "800218062" = "NL000351"
    "800218204" = "NL000066"
    "800218512" = "NL000276"
    "800219652" = "NL001033"
    "800222108" = "NL000153"
    "800223584" = "NL000326"
    "800225184" = "NL000385"
    "800240609" = "NL000303"
    "800243935" = "NL000109"
    "800227767" = "NL001013"  /** Yale Steam Laundry **/
    "800234530" = "NL001023"  /** Van Metre Columbia Uptown Apartments **/
    
    other = " ";

  ** Create $nlihcid_proj. format to add project ID and names to update report **;

  %Data_to_format(
    FmtLib=work,
    FmtName=$nlihcid_proj,
    Desc=,
    Data=PresCat.Project_category_view,
    Value=nlihc_id,
    Label=trim(proj_name) || ' - ' || left(proj_addre),
    OtherLabel='** Unidentified project **',
    DefaultLen=.,
    MaxLen=.,
    MinLen=.,
    Print=N,
    Contents=N
    )

%mend Update_REAC_init;

/** End Macro Definition **/

