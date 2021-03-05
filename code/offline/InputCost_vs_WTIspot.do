* This file compares average refiner prices to the WTI spot price

*GLOBAL DIRs
clear
set more off
cd "$repodir/temp"		

* run setup first
*do ${repodir}\code\offline\setup_offline.do

global PublicData "$repodir/data/public_data/EIA"
global tabdir "$repodir/output/offline/tables/from_public_data" 
global figdir "$repodir/output/offline/figures/from_public_data" 

clear all  

import excel using "$PublicData/PET_PRI_SPT_S1_M.xls", clear sheet("Data 1") firstrow cellrange(A3:C396) 
rename Cushing WTISpot 
rename Europe BrentSpot 

tempfile spotprices 
save `spotprices', replace 

import excel using "$PublicData/PET_PRI_RAC2_DCU_NUS_M.xls", clear sheet("Data 1") firstrow cellrange(A3:D539) 
rename USCrudeOilComp 	InputPriceComposite 
rename USCrudeOilDom	InputPriceDomestic 
rename USCrudeOilImp	InputPriceImported 

merge 1:1 Date using `spotprices' 

tab _merge 

keep if _merge==3 

drop _merge 
save `spotprices', replace 


import excel using "$PublicData/PET_PRI_RAC2_A_EPC0_PCT_DPBBL_M.xls", clear sheet("Data 1") firstrow cellrange(A3:G539) 
drop USCrudeOilComp 
foreach x in EastCoast Midwest GulfCoast RockyMountain WestCoast { 
rename `x' 	InputPrice`x' 
} 

merge 1:1 Date using `spotprices' 

tab _merge 

gen year = year(Date) 
gen month = month(Date) 

keep if _merge==3 

sort Date 

gen deltaWTISpot = WTISpot[_n]-WTISpot[_n-1] 
label var delta`x' "$\Delta WTISpot_t$" 
foreach x of varlist InputPrice* { 
gen delta`x' = `x'[_n]-`x'[_n-1] 
} 

forvalues x = 1/4 { 
gen lag`x'_WTISpot = WTISpot[_n-`x'] 
label var lag`x'_WTISpot "$WTISpot_{t-`x'}$" 
gen lag`x'_deltaWTISpot = deltaWTISpot[_n-`x'] 
label var lag`x'_deltaWTISpot "$\Delta WTISpot_{t-`x'}$" 
} 


foreach x in Composite Domestic Imported EastCoast Midwest GulfCoast RockyMountain WestCoast{ 
	label var InputPrice`x' "Avg. Oil Input Cost - `x'" 
	label var deltaInputPrice`x' "$\Delta$ Avg. Oil Input Cost - `x'" 
} 


graph twoway scatter WTISpot InputPriceComposite Date, ///
legend(label(1 "WTI Spot") label(2 "Ref. Input Price - Composite"))  ///
c(l l) m(i i)  ///
ytitle("$/bbl") ///
name("Composite", replace) ///
nodraw 

graph twoway scatter WTISpot InputPriceDomestic Date,  ///
legend(label(1 "WTI Spot") label(2 "Ref. Input Price - Domestic")) ///
c(l l) m(i i)  ///
ytitle("$/bbl") ///
name("Domestic", replace) ///
nodraw 

graph twoway scatter WTISpot InputPriceImported Date,  ///
legend(label(1 "WTI Spot") label(2 "Ref. Input Price - Imported")) ///
c(l l) m(i i)  ///
ytitle("$/bbl") ///
name("Imported", replace) ///
nodraw 

graph combine Composite Domestic Imported,  ///
	rows(2) iscale(.45) holes(2) ///
	title("WTI Spot price and Refinery Input costs")  

	graph export "$figdir/WTI_Spot_Input_Price.png", replace 
	graph export "$figdir/WTI_Spot_Input_Price.pdf", replace 

/*Specification 1: Change in Input Costs on Change in Spot Prices*/

estimates clear 

foreach x in Composite Domestic Imported EastCoast Midwest GulfCoast RockyMountain WestCoast{ 
	reg InputPrice`x' WTISpot lag*_WTISpot, robust 
	estimates store `x' 
} 

esttab * using "$tabdir/WTI_Spot_Input_Price.tex",  ///
	replace label se star(* 0.10 ** 0.05 *** 0.01) nogaps nonotes booktabs  ///
	b(a2) se(a2) stats(N r2,  labels("Observations" "R-Squared"))  ///
	subs("Yes" "X" "No" " ")  ///
	mtitles ///
	note("Dependent variables in Cols 1 - 3 are the average nationwide refinery costs of input from all, domestic and imported sources, respectively. Dependent variables in Cols 4 - 8 are the average input costs for refineries, by PADD.") 

	
esttab Composite Domestic Imported using "$tabdir/WTI_Spot_Input_Price_bySource.tex",  ///
	replace label se star(* 0.10 ** 0.05 *** 0.01) nogaps nonotes booktabs  ///
	b(a2) se(a2) stats(N r2,  labels("Observations" "R-Squared"))  ///
	subs("Yes" "X" "No" " ")  ///
	mtitles  ///
	note("Dependent variables in Cols 1 - 3 are the average nationwide refinery costs of input from all, domestic and imported sources, respectively.") 

	
esttab EastCoast Midwest GulfCoast RockyMountain WestCoast using "$tabdir/WTI_Spot_Input_Price_byPADD.tex",  ///
	replace label se star(* 0.10 ** 0.05 *** 0.01) nogaps nonotes booktabs  ///
	b(a2) se(a2) stats(N r2,  labels("Observations" "R-Squared"))  ///
	subs("Yes" "X" "No" " ")  ///
	mtitles ///
	note("Dependent variables are the average input costs for refineries, by PADD.") 


/*Specification 2: Change in Input Costs on Change in Spot Prices*/
	
estimates clear 
	
foreach x in Composite Domestic Imported EastCoast Midwest GulfCoast RockyMountain WestCoast{ 
	reg deltaInputPrice`x' deltaWTISpot lag*_deltaWTISpot, robust 
	estimates store `x' 
} 


esttab * using "$tabdir/Delta_WTI_Spot_Input_Price.tex",  ///
	replace label se star(* 0.10 ** 0.05 *** 0.01) nogaps nonotes booktabs  ///
	b(a2) se(a2) stats(N r2,  labels("Observations" "R-Squared"))  ///
	subs("Yes" "X" "No" " ")  ///
	mtitles 
	*note("Dependent variables in Cols 1 - 3 are the average nationwide refinery costs  ///
	*of input from all, domestic and imported sources, respectively. Dependent variables in Cols 4 - 8 
	*are the average input costs for refineries, by PADD.") 

	
esttab Composite Domestic Imported using "$tabdir/Delta_WTI_Spot_Input_Price_bySource.tex",  ///
	replace label se star(* 0.10 ** 0.05 *** 0.01) nogaps nonotes booktabs  ///
	b(a2) se(a2) stats(N r2,  labels("Observations" "R-Squared"))  ///
	subs("Yes" "X" "No" " ")  ///
	mtitles 
	*note("Dependent variables in Cols 1 - 3 are the average nationwide refinery costs of input from all, domestic and imported sources, respectively.") 

	
esttab EastCoast Midwest GulfCoast RockyMountain WestCoast using "$tabdir/Delta_WTI_Spot_Input_Price_byPADD.tex",  ///
	replace label se star(* 0.10 ** 0.05 *** 0.01) nogaps nonotes booktabs  ///
	b(a2) se(a2) stats(N r2,  labels("Observations" "R-Squared"))  ///
	subs("Yes" "X" "No" " ")  ///
	mtitles ///
	note("Dependent variables are the average input costs for refineries, by PADD.") 







