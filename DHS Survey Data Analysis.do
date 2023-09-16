/******************************************************************************
   Purpose: Analysis of DHS survey data to answer a research question
   
   Data input: The primary dataset women's file (IR) and the secondary dataset is the 
   household members file (PR) (from DHS). 
   Authur: Albert Lutakome
   Date Last Modified: September 11, 2023 by Albert Lutakome. 

* For the code below to work, you must save the do file and 2 folders (indata and outdata)
 in the same parent folder.
* In this example, we will produce results including descriptive, crosstabs, and ch2 (test of association). 

* Sample Research question: 
  Is there a significant association between overcrowding and social-demographic
  variables of education, residence and wealth index among women aged between 15 and 49? 
******************************************************************************/
	 
	 *** Working Folder Path ***
global path_in "..\Projects\DHS\indata"
global path_out "outdta"
	 
*******************************************************************************
*STEP 1: Merge Women and Household members datasets***************
****This will introduce household characteristics to the Women's dataset
*******************************************************************************

*1.Open the secondary dataset, and sort by ID variable
use "$path_in\ETPR71FL.DTA", clear
*2. Rename IDs (uniquely identify a case)
rename (hv001 hv002 hvidx) (v001 v002 v003)

*3. Save a temporary file of just the variables to merge in 
tempfile pr_secondary 
save "`pr_secondary'", replace  

*4. Open primary file * i.e. IR_Women dataset
use "$path_in\ETIR71FL.DTA", clear

***** merge 
merge 1:1 v001 v002 v003 using "`pr_secondary'" 

**Drop households without eligible women
tab _merge	
keep if _merge==3
drop _merge 

save "$path_out/ETPR_IR_Merge.dta", replace 
// Save merged dataset


*******************************************************************************
***STEP 2: Recode variables ***
*******************************************************************************
*** Socio-demographic variables ***

* Education: recode v106 to combine secondary and higher levels
recode v106 (0=0 None) (1=1 Primary) (2/3=2 "Sec+"), gen(edu)

* Wealth quintile: v190

* Place of residence: v025

* Region: v024

* Computing Outcome variable: living space 
* We use de facto members for this calculation 

gen mem_usual =hv012
replace mem_usual=hv013 if mem_usual==0
gen crowd=.
replace crowd=trunc(mem_usual/hv216) if hv216>0
replace crowd=mem_usual if hv216==0

* handling missing values
replace crowd=. if hv216>=99

*The threshold for sufficient living space is less or equal to 3 (3<=)
recode crowd (0/2=0 "No") (3/max=1 "Yes"), gen(over_crowd)

label var over_crowd "Overcrowding Conditions"
label define over_crowd 1 "Over crowded" 0 "Not crowded"
label values over_crowd over_crowd

*******************************************************************************
** STEP 3: Descriptive Statistics and Crosstabulations  
*******************************************************************************
* We generate weight and set survey design parameters. 
* svyset [pw=x], psu(y) strata(z), where pw stands for probability weight, x =
* weight variable, y = cluster variable, z = strata variable. 
gen wt=hv005/1000000 
svyset [pw=wt], psu(v021) strata(v022) singleunit(centered)  

* Descriptive table: We check our variables: One way:
* The variables are tabulated among all women aged [15,49] 
tabout edu v190 v025 v024 living_space using table1.xls, c(cell) oneway svy nwt(wt) per pop replace

* Crosstabulation of outcome variable with single social-demographic variable:  

svy: tab v025 over_crowd, row per

* Crosstabulation of outcome variable with multiple social-demographic variables: 
* The output will also perform the chi-square test and produce the p-value as we
** added the stats(chi2) option
tabout edu v190 v025 v024 over_crowd using table2.xls, c(row ci) stats(chi2) svy nwt(wt) per pop replace 

* Interpretation of chi2test:
* The results of the crosstabulation show that all variables are significantly 
** associated with variable over_crowd. 
* This is true for P<0.05, at 95% level of significance. 

* To further investigate the degree of variation that each independent variable has on over_crowd
* we can use logistic regression in order to get the odds ratios and coefficients. 

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


*** Sort and save final coded dataset ***
sort hhid
la da "Micro data for `_dta[ccty]' (`_dta[ccnum]') from `c(current_date)' (`c(current_time)')."
save "$path_out/ETIRPR_coded_fin.dta", replace 
