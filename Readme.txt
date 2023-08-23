The goal of this project is to Analyze DHS Data and extract valuable insights from the data. 
This project is aimed at providing STATA code to provide a thorough guide for analysis of DHS survey data. 

## General instructions:
This Code Project provides the code that can be used to merge datasets, perform weighted tabulations, recode data, compute indicators, as well as the standard tables to produce a report on World urban slum population. The code is organized into one single file in the parent folder and all guidelines from the Guide to DHS Statistics have been followed.  The folder "Crosstables with Ch2 tests" contains a sample of cross tables that will be produced if the code is run properly. These cross tables can also be used to study association between variables using the ch2 test statistic.  

## Main files:
The parent folder contains a Main .do script File from which the user can run all the code at once (.do) to compute slum indicators, compute descriptive statistics and perform tests of association and dependency. The user needs to set the paths in the data File files correctly. 
The parent folder also contains 1 output file in pdf form produced when the code is run properly. 

## Working with older surveys:
Additionally, because the indicators that are created using the Code Share Project are based on the Guide to DHS Statistics, they reflect the standard variables that are available in a recent DHS survey dataset. If the provided code is used to create indicators from older surveys, it is possible the variable names have changed over time or are not available in the older survey. The user may need to check the dataset in use for the availability of the variables needed used in the code and may need to adjust for missing variables or rename variables accordingly. Some of the code files will generate the variables with missing values for old surveys if the survey does not have that variable. 
In addition, older surveys (mainly before 2000) do not have a wealth index in the dataset and the files would need to be merged with a WI file to include the wealth index. Also, more categories have been added for variables on access to improved water, sanitation etc. It is advisable to check the categories available in the older datasets to adjust the code.
accordingly. 

## Creating tables 
Tabulation has been done using tabout package for STATA. This is a free package and can be installed as demonstrated in the code. 

