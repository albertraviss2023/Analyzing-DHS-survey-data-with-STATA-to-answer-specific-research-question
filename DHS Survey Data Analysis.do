/******************************************************************************
   Purpose: Illustrating an example of an analysis to answer a research question
   from start to finish.
   Data input: The model dataset women's file (IR) and household members file
   (PR) for Ethiopia DHS 2019. 
   Date Last Modified: August 29, 2023 by Albert Lutakome. 

Notes/Instructions:

* Please have the model dataset downloaded and ready to use. We will use the IR file.
* You can download the model dataset here: https://www.dhsprogram.com/data/Model-Datasets.cfm
* For the code below to work, you must save the do file and 2 folders (indata and outdata)
 in the same parent folder, . 
* In this example, we will answer a specific research question and show how to 
produce the results including descriptive, crosstabs, and regression results. 

* Research question: 
  Is there significant association between room over crowding, education, residence and wealth index.
  for women aged between 15 and 49? 

* !!! Please follow the notes throughout the do file
******************************************************************************/
	 
	 *** Working Folder Path ***
global path_in "C:\Users\alber\OneDrive\Documents\Github Projects\Project1 DHS Survey data Analysis and Indicator calculation with STATA\indata"
global path_out "outdta"
	 
*******************************************************************************
*STEP 1: Merge Women and Household memebrs datasets***************
****This will introuduce household characteristics to the Women dataset
*******************************************************************************

*1.Open secondary dataset, and sort by ID variable
use "$path_in\ETPR71FL.DTA", clear
*2. Rename IDs (uniquely identify a case)
rename (hv001 hv002 hvidx) (v001 v002 v003)

*3. Save temporary file of just the variables to merge in 
tempfile pr_secondary 
save "`pr_secondary'", replace  

*4. open primary file * i.e. IR_Women dataset
use "$path_in\ETIR71FL.DTA", clear

***** merge 
merge 1:1 v001 v002 v003 using "`pr_secondary'" 

**drop households without eligible women
tab _merge	
keep if _merge==3
drop _merge 

save "$path_out/ETPR_IR_Merge.dta", replace 
// Save merged dataset


*******************************************************************************
***STEP 2: Recode variables ***
*******************************************************************************
*** Socio-demographic variables ***

* education: recode v106 to combine secondary and higher categories
recode v106 (0=0 None) (1=1 Primary) (2/3=2 "Sec+"), gen(edu)

* wealth quintile: use v190

* place of residence: use v025

* region: use v024

* Outcome vriable: living space 

gen mem_usual =hv012
replace mem_usual=hv013 if mem_usual==0
gen crowd=.
replace crowd=trunc(mem_usual/hv216) if hv216>0
replace crowd=mem_usual if hv216==0
replace crowd=. if hv216>=99
recode crowd (0/2=0 "No") (3/max=1 "Yes"), gen(living_space)

label var living_space "Available Living Space"
label define living_space 1 "Over crowded" 0 "Not crowded"
label values living_space living_space

*******************************************************************************
** STEP 3: Descriptive Statistics and Crosstabulations  
*******************************************************************************
* We generate weight and set survey design parameters. 
* svyset [pw=x], psu(y) strata(z), where pw stands for probability weight, x =
* weight variable, y = cluster variable, z = strata variable. 
gen wt=hv005/1000000 
svyset [pw=wt], psu(v021) strata(v022) singleunit(centered)  

* Descriptive table: We check our variables: One way:
* The variables are tabulated among all women aged [15,49] in IR file
tabout edu v190 v025 v024 living_space using table1.xls, c(cell) oneway svy nwt(wt) per pop replace

* Crosstabulation of outcome variable with single social-demographic variable:  

svy: tab v025 living_space, row per

* Crosstabulation of outcome variable with multiple social-demographic variables: 
* The output will also perform the chi-square test and produce the p-value as we
** added the stats(chi2) option
tabout edu v190 v025 v024 living_space using table2.xls, c(row ci) stats(chi2) svy nwt(wt) per pop replace 

* Interpretation of chi2test:
* The results of the crosstabulation show that all variables were significantly 
** associated with vailable living space. 
* This is true if P<0.05, at 95% level of significance. 

* To further investigate, we can use the logistic regression in order to
* interprete at the odds ratios. 

*******************************************************************************
** STEP 4: Save coded data for future use. 
*******************************************************************************
*** Generate coutry and survey details***
char _dta[cty] "Ethiopia"
char _dta[ccty] "ET"
char _dta[year] "2020-2021" 	
char _dta[survey] "DHS"
**char _dta[ccnum] "004"
char _dta[type] "micro"


*** Sort, compress and save final coded dataset ***
sort hhid
compress
la da "Micro data for `_dta[ccty]' (`_dta[ccnum]') from `c(current_date)' (`c(current_time)')."
save "$path_out/ETIRPR_coded_fin.dta", replace 
