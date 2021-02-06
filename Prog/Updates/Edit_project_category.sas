/**************************************************************************
 Program:  Edit_project_category.sas
 Library:  PresCat
 Project:  NeighborhoodInfo DC
 Author:   P. Tatian
 Created:  12/03/15
 Version:  SAS 9.2
 Environment:  Local Windows session (desktop)
 
 Description:  Manually edit PresCat.Project_category data set. 

 This program can be run in either an interactive or batch session.
 
 Once this program is submitted, click on the open Viewtable window
 and switch to edit mode (From main menu: Edit > Edit mode) 

 When changing the project category, just type the number of the category
 (1, 2, 3, 4, 5, 6). The label will be filled in automatically when you
 press Enter or Tab.

 When changing the project flags, enter 1 for Yes and 0 for No. 

 Modifications:
**************************************************************************/

%include "\\sas1\DCdata\SAS\Inc\StdLocal.sas";

** Define libraries **;
%DCData_lib( PresCat, local=n, rreadonly=n )

dm "viewtable prescat.project_category";

