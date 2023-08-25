clear all 
set more off
set maxvar 100000

*** Working Folder Path ***
global path_in "..\Documents\DHS" 
global path_out "$path_in\DTA"

****************************************************************************************
**** STEP1: Merge Women and Household members datasets
**** This will introduce household characteristics to the Women's dataset
****************************************************************************************
	 
*a.Open the secondary dataset, and sort by ID variable
use "..$path_in\ETPR71FL.DTA", clear
sort hhid  // sort by ID Variable

*b. Save a temporary file of just the variables to merge in 
tempfile secondary_HHD 
save "`secondary_HHD'", replace  

*c. Open primary file * i.e. Women dataset, and sort by ID Variable and merge
use "..$path_in\ETIR71FL.DTA", clear
gen hhid =substr(caseid,1,12) // changed ID variable name to match ID variable name in the second file 
sort hhid 

merge m:m hhid using "`secondary_HHD'"
drop if _merge ==1 // drops unmatched from master
drop if _merge ==2 // drops unmatched from using

tab _merge //check if all is well


save "$path_out\WM_HHM_Merged.DTA", replace  // save merged file

****************************************************************************************
**** STEP2: Setting survey parameters for complex survey design  and installing tabout for
**** weighted table production taking into account the survey design. 
****************************************************************************************
ssc install tabout 

gen wt=hv005/1000000  //generating weight variable 
egen strata=group(v024 v025) 
* svyset [pw=x], psu(y) strata(z), where pw stands for probability weight, x = weight variable, ///
y = cluster variable, z = strata variable. 
svyset [pw=wt], psu(v021) strata(v022) singleunit(centered)  

***************************************************************************************
**** STEP 4: Dataset Exploration 
***************************************************************************************
**** a. Total population
gen pop=0.
replace pop=1 if hv001 >0
label variable pop "individual women found"   // we created an individual value 1 for each identified case and 
                                             //That is how we were able to calculate the total population
gen totpop=sum(pop)
su totpop  // summing the total population of women

**** b. Disaggregation by subgroups **************
 
       *** 1. Urban  vs rural*******************

tab hv025 [iweight=wt]

       ***  2. Population by region *************
tab  v024 [iweight=wt]

       ***  3. Women's age disaggregation *******
gen m_agewm=.
replace m_agewm=1 if hv105<5 
replace m_agewm=2 if hv105 >=5  & hv105<15
replace m_agewm=3 if hv105 >=15 & hv105<49
replace m_agewm=4 if hv105 >=49 & hv105<95
replace m_agewm=5 if hv105 >=95 & hv105 != 98
replace m_agewm=6 if hv105 == 98

label variable m_agewm "Age group of Female Household Member"
label define m_agewm 1 "<5" 2 "5-15" 3 "15-49" 4 "49-95" 5 "95+" 6 "don't know"
label values m_agewm m_agewm

tab m_agewm  

        *** 4 Urban vs. rural population distribution by age groups 
svy: tab m_agewm hv025, per // pop age urban vs rural

***********************************************************************************************
****** STEP 5: Descriptive statistics **********
***********************************************************************************************
        ***a.  mean, median age per age group 
table m_agewm, statistic(mean hv105) statistic(median hv105) // mean and median age per age group

        ***b. Min, Max age per age group 
table m_agewm, statistic(min hv105) statistic(max hv105)

**********************************************************************************************
****** STEP 6: Computing Indicators 
**********************************************************************************************

      ***a. wealth index
gen wealthwm=.
replace wealthwm=0 if inlist(hv270,1,2)
replace wealthwm=1 if inlist(hv270,3,4,5)
label variable wealthwm "Women Wealth Group"
label define wealthwm 0 "Poor and Poorest" 1 "Middle, rich and richest" 
label values wealthwm wealthwm

                   ***1. By residence
svy: tab wealthwm hv025, per  // wealth index by residence 
                   ***2. By region
svy: tab wealthwm hv024, per  // wealth index by region  

                   ***3. By gender
svy: tab  v024 hv270,per
tab  v024 hv270 [iweight=wt]

    ***b. Access to Education 

tab hv025 v149 

gen eduwm=.
replace eduwm=0 if v149==0
replace eduwm=1 if inlist(v149,1,2,3,4,5)
label variable eduwm "Highest Education"
label define eduwm 1 "Above Primary" 0 "Below Primary"
label values eduwm eduwm

                   ***1. By residence
svy: tab eduwm hv025, per  


    *** c. Overcrowding conditions/ living space
 
gen room_crowd=.
replace hv012 = hv013 if hv012 == 0  // if dejure members (HV012) is 0 then  hv013 (de facto members) = 0 as well. 

replace room_crowd = hv012 if hv216 == 0  // if the number of rooms for sleeping (HV216) is 0 then all de jure members have no sufficient living => hv216 = 0.

replace room_crowd = (hv012 / hv216) if hv216 != 0 // if number of rooms is not 0, then person per room = persons/number of rooms.

replace room_crowd = 98 if room_crowd >= 98  // Accounting for Invalid entries and missing values, entries with 98.
//  Calculating overcrowding conditions
 
gen living_space = 1
*As per standards, if persons per room is greater than 3, the no sufficient living space, hence, living1=0. 
replace living_space = 0 if room_crowd > 3
label variable living_space "Overcrowding Conditions"
label define living_space 1 "Sufficient Living Space" 0 "Over crowded"
// Calculating living space indicator

             ***1. Computing women living in overcrowded conditions by age group

tab living_space m_agewm [iweight=wt] 
svy: tab living_space m_agewm, per

svy: tab living_space v102, per

**********************************************************************************************
****** STEP 7: *Regression and variable associations
**********************************************************************************************


        ***a. Studying the significance of the association of residence, sex, education, and wealth in relation to overcrowding
		 
tabout living_space hv025 [iw=wt] using "residencech2.xls",c(col) f(1) stats(chi2) svy nwt(wt) per pop replace // disaggregation by residence
tabout living_space hv024 [iw=wt] using "regionch2.xls",c(col) f(1) stats(chi2) svy nwt(wt) per pop replace // disaggregation by region
tabout living_space v149 [iw=wt] using "educationch2.xls",c(col) f(1) stats(chi2) svy nwt(wt) per pop replace // disaggregation by education
tabout living_space hv270 [iw=wt] using "wealthch2.xls",c(col) f(1) stats(chi2) svy nwt(wt) per pop replace // disaggregation by wealth
tabout living_space hv219 [iw=wt] using "hheadch2.xls",c(col) f(1) stats(chi2) svy nwt(wt) per pop replace // disaggregation by hhold head
// Saving results of the crosstabulations and the ch2 test for further analysis. 

        *** b. Logistic regression model to study whether wealth is explained by residence, education, and sex:  

logit wealthwm  i.hv025 i.eduwm i.hv104 i.hv025  

        *** Results are interpreted by analyzing the p-value depending on the level of significance chosen. 
