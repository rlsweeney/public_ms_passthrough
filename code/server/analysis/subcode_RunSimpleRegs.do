use "${sampledir_channel}/regdata_st", clear
do "${sampledir_regsample}/subcode_samplerestrict_st.do"

capture drop co_padd 
egen co_padd = group(FPid state_abv)
capture drop state_num 
egen state_num = group(state_abv)
save tempregdat, replace


*SET MAIN CONTROLS
global xvars  frac_resale frac_light
global stvars _X_CDD _X_HDD _X_income_pc _X_log_pop  HHI

*T ALWAYS HAS TO GO FIRST! IN ORDER FOR APPEND STATMENT TO WORK
global prodlist T TP G D O

foreach it_prod in $prodlist {
	
	use tempregdat, clear
	keep if prod == "_`it_prod'" 

	qui{

	eststo clear
	estimates clear

	* MOS-ST REGS 
	eststo : reghdfe Price Pcru $xvars , ///
		absorb(i.year#i.month#i.state_num i.co_padd) cluster(co_padd)
	estadd local timefes "MoS-St", replace
	estadd local product "`it_prod'", replace

	if "`it_prod'" == "T" {
		di "new!"
		estimates save "${sampledir_estimates}/mods_simple_StMoS", replace
		}

	if "`it_prod'" != "T" {
		di "append L"
		estimates save "${sampledir_estimates}/mods_simple_StMoS", append
		}
		
	* MOS REGS 
	eststo : reghdfe Price Pcru $xvars $stvars , ///
		absorb(i.year#i.month i.co_padd) cluster(co_padd)
	estadd local timefes "MoS", replace
	estadd local product "`it_prod'", replace

	if "`it_prod'" == "T" {
		di "new!"
		estimates save "${sampledir_estimates}/mods_simple_MoS", replace
		}

	if "`it_prod'" != "T" {
		di "append L"
		estimates save "${sampledir_estimates}/mods_simple_MoS", append
		}
	}
}

estimates describe using "${sampledir_estimates}/mods_simple_StMoS" 
local nmods `r(nestresults)'
di "`nmods'"
clear  
eststo clear
estimates clear

forval i = 1/`nmods' {
	estimates use "${sampledir_estimates}/mods_simple_StMoS"  , number(`i')
	estimates store M_`i'
}

esttab M_*, keep(*cru*) replace label ///
	 se starlevels(* 0.10 ** 0.05 *** 0.01)  compress ///
	 stat(product timefes N r2, label("Product" "TimeFes")) nomtitles nonotes ///
	 coeflabels(Pcru "Own") ///
	 title("St-Mos Results")
	 
estimates describe using "${sampledir_estimates}/mods_simple_StMoS" 
local nmods `r(nestresults)'
di "`nmods'"
clear  
eststo clear
estimates clear

forval i = 1/`nmods' {
	estimates use "${sampledir_estimates}/mods_simple_MoS"  , number(`i')
	estimates store M_`i'
}

esttab M_*, keep(*cru*) replace label ///
	 se starlevels(* 0.10 ** 0.05 *** 0.01)  compress ///
	 stat(product timefes N r2, label("Product" "TimeFes")) nomtitles nonotes ///
	 coeflabels(Pcru "Own") ///
	 title("St-Mos Results")
