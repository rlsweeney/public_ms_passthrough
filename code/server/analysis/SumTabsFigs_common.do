/***********************
This file creates summary tables and figures
***********************/
 
********************************************************************************
****** SUMMARIZE REFINERY LEVEL CO2 DATA 
********************************************************************************

use  "$generated_dir/taxdata", clear // FROM CombineFPRefCrudeData.do

hist ghg_bar , freq xtitle("MT Co2e /barrel")
*graph export "$outdir/figures/hist_co2e_refinery.png" ,  replace	
graph export "$outdir/figures/hist_co2e_refinery.eps" ,  replace	
graph close 

hist tax_cpg , freq xtitle("Cost increase under $40 CO2 tax (cents/gal)")
*graph export "$outdir/figures/hist_co2_tax_refinery.png" ,  replace	
graph export "$outdir/figures/hist_co2_tax_refinery.eps" ,  replace	
graph close 

* RUN CO2 DETERMINANT REGS 
capture drop tk 
egen tk = rowmax(ds*)
replace totcap_820_sd = tk if totcap_820_sd == 0 & tk > 0 & tk != .

capture drop tk 
egen tk = rowtotal(ds*)
gen share_ds = tk / totcap_820_sd
replace share_ds = 1 if tk > 0 & totcap_820_sd == 0

capture drop tk 
egen tk = rowtotal(dscap_catcrack dscap_cathyrc)
gen share_crack = tk/ totcap_820_sd
replace share_crack = 1 if tk > 0 & totcap_820_sd == 0

replace dscap_therm = 0 if dscap_therm ==.
gen share_coke = dscap_therm / totcap_820_sd
replace share_coke = 1 if dscap_therm > 0 & totcap_820_sd == 0

gen log_cap =log(totcap_820_sd)

la var log_cap "log(Capacity)"
la var api "API Gravity"
la var share_ds "Downstream Capacity"
la var share_crack "\% Cracking"
la var share_coke "\% Coking"

eststo clear
estimates clear

eststo: reg ghg_bar i.year i.ref_padd api log_c share_cok share_cra 
sum tax_cpg, detail
estadd local avY = round(`r(mean)'*1000)/1000
estadd local timefes "Y", replace
estadd local yvar "ghg_bar", replace
estadd local reglevel "refinery", replace

esttab, drop(*padd* *year*) replace label ///
	 se starlevels(* 0.10 ** 0.05 *** 0.01)  compress ///
	 stat(avY timefes N r2, label("mean(Y)" "TimeFes")) /// 
	 nomtitles nonotes

esttab using "$outdir/tables/co2e_regression_refinery.tex", drop(*padd* *year*) replace label ///
	 se starlevels(* 0.10 ** 0.05 *** 0.01)  compress ///
	 stat(avY timefes N r2, label("mean(Y)" "TimeFes")) /// 
	 nomtitles nonotes booktabs 
		 
estimates save "$outdir/estimates/samples/co2_regs_refinery", replace

eststo clear
eststo: reg tax_cpg i.year i.ref_padd api log_c share_cok share_cra 
sum tax_cpg, detail
estadd local avY = round(`r(mean)'*1000)/1000
estadd local timefes "Y", replace
estadd local yvar "tax_cpg", replace
estadd local reglevel "refinery", replace

esttab, drop(*padd* *year*) replace label ///
	 se starlevels(* 0.10 ** 0.05 *** 0.01)  compress ///
	 stat(avY timefes N r2, label("mean(Y)" "TimeFes")) /// 
	 nomtitles nonotes

esttab using "$outdir/tables/co2_tax_regression_refinery.tex", drop(*padd* *year*) replace label ///
	 se starlevels(* 0.10 ** 0.05 *** 0.01)  compress ///
	 stat(avY timefes N r2, label("mean(Y)" "TimeFes")) /// 
	 nomtitles nonotes booktabs 
	 
estimates save "$outdir/estimates/samples/co2_regs_refinery", append

		
estimates describe using "$outdir/estimates/samples/co2_regs_refinery" 
local nmods `r(nestresults)'
di "`nmods'"
eststo clear
estimates clear

forval i = 1/`nmods' {
	estimates use "$outdir/estimates/samples/co2_regs_refinery"  , number(`i')
	*estimates replay
	estimates store M_`i'
}

esttab M_*, drop(*padd* *year*) replace label ///
	 se starlevels(* 0.10 ** 0.05 *** 0.01)  compress ///
	 stat(yvar avY timefes reglevel N r2, label("Y var" "mean(Y)" "TimeFes" "Level")) /// 
	 nomtitles nonotes
	 

********************************************************************************
** USE PUBLIC DATA TO SHOW HOW FRACKING SHOCKED DIFFERENT TYPES OF CRUDE:
use $generated_dir/pub_crude_prices, clear
drop if year < 2009

capture drop d_*
capture drop AF* 

egen AFPP_l25 = rowmean(DomFPP_U20 DomFPP_20_25)
label var AFPP_l25 "API < 25"
egen AFPP_25_35 = rowmean(DomFPP_25_30 DomFPP_30_35)
label var AFPP_25_35 "API 25 - 35"
egen AFPP_g35 = rowmean(DomFPP_35_40 DomFPP_G40)
label var AFPP_g35 "API > 35"

foreach v of varlist AFPP* {
	replace `v' = (`v' - p_brent_spot) // 
}
qui: twoway (line AF* ymdate) , ytitle("Dom. FPP - Brent spot ($/gallon)")  xtitle("") legend(rows(1))

graph export "$outdir/figures/FPP_discount_by_API.eps" , replace	
graph close 


********************************************************************************
* GRAPH HEAVY LIGHT CRUDE SPREADS
use $generated_dir/pub_crude_prices, clear
sort ymdate
twoway (line hl* ymdate if year > 2003), ///
		ytitle("Price ($/gallon)")  xtitle("") 		

*graph export "$outdir/figures/hl_spreads.png" , replace	
graph export "$outdir/figures/hl_spreads.eps" , replace	
graph close 
