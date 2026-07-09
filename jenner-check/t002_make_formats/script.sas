/**************************************************************************
 A subset of Prog/Make_formats.sas from this repo. The value blocks below
 ($Status, $Categry, $Infosrc, $rptype, $ownmgrtype) are copied verbatim
 from that program; only two lines were changed so the bundle is
 self-contained: the leading %include of StdLocal.sas and the
 %DCData_lib( PresCat ) call are removed, and the format catalog is written
 to WORK instead of the PresCat library. A short caller then applies the
 formats to a handful of catalog records so the mappings are visible.
**************************************************************************/

proc format library=work;

  value $Status
    "A" = "Active"
    "I" = "Inactive";

  value $Categry
    "1" = "At-Risk or Flagged for Follow-up"
    "2" = "Expiring Subsidy"
    "3" = "Recent Failing REAC Score"
    "4" = "More Info Needed"
    "5" = "Other Subsidized Property"
    "6" = "Lost Rental"
    "7" = "Replaced";

  value $Infosrc
    "HUD/MFA" = "HUD/Multifamily Assistance and Section 8 Contracts"
    "HUD/MFIS" = "HUD/Insured Multifamily Mortgages"
    "HUD/LIHTC" = "HUD/Low Income Housing Tax Credits"
    "HUD/PSH" = "HUD/Picture of Subsidized Households"
    "VCU-CNHED/LECOOP" = "VCU-CNHED/Limited equity cooperative database";

  value $rptype
    "OTR/SALE" = "OTR: Property sale"
    "ROD/FCLNOT" = "ROD: Foreclosure notice"
    "NIDC/FCLOUT" = "NIDC: Foreclosure outcome"
    "DHCD/RCASD" = "DHCD: RCASD notice";

  value $ownmgrtype
    "LD" = "Limited dividend"
    "NP" = "Non-profit"
    "NC" = "Non-profit controlled"
    "OT" = "Other"
    "HA" = "Public housing authority"
    "PM" = "Profit motivated"
    "IN" = "Individual";

run;

/* Apply the formats to a small set of catalog-shaped records. */
data catalog;
  length nlihc_id $ 16 status $ 1 category $ 1 info_source $ 20 owner_type $ 2;
  input nlihc_id $ status $ category $ info_source $ owner_type $;
  datalines;
NL000046 A 1 HUD/MFA NP
NL000093 A 2 HUD/LIHTC PM
NL000319 I 6 HUD/PSH HA
NL001007 A 3 HUD/MFIS NC
NL001030 A 5 VCU-CNHED/LECOOP IN
;
run;

proc print data=catalog noobs label;
  var nlihc_id status category info_source owner_type;
  format status $Status. category $Categry. info_source $Infosrc. owner_type $ownmgrtype.;
  label nlihc_id = "Project ID" status = "Status" category = "Category"
        info_source = "Information source" owner_type = "Owner/manager type";
run;
