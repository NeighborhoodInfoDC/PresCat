/**************************************************************************
 Program:  Edit_subsidy_except.sas
 Library:  PresCat
 Project:  NeighborhoodInfo DC
 Author:   P. Tatian
 Created:  03/06/2018
 Version:  SAS 9.4
 Environment:  Local Windows session (desktop)
 
 Description:  Manually edit PresCat.subsidy_except data set. 

 This program can be run in either an interactive or batch session.
 
 Once this program is submitted, click on the open Viewtable window
 and switch to edit mode (From main menu: Edit > Edit mode) 

 When entering data for formatted variables, enter the *unformatted* value. 
 The label will be filled in automatically when you press Enter or Tab.
 Ex: For Status, enter "A" for active or "I" for inactive. 

 When changing the project flags, enter 1 for Yes and 0 for No. 

 Modifications:
**************************************************************************/

%include "L:\SAS\Inc\StdLocal.sas";

** Define libraries **;
%DCData_lib( PresCat, local=n, rreadonly=n )

dm "viewtable prescat.subsidy_except";

