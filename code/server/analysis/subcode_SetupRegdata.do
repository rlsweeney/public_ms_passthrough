use "$generated_dir/fpmj_prices_state_all", clear
replace Sales_A = 0 if valid_state == 0 | Sales_A < 10
replace Sales_W = 0 if valid_state == 0 | Sales_W < 10
keep FPid firm_id year month state_abv product Sales_* shipcost

reshape long Sales, i(FPid firm_id year month state_abv product) j(sales_type) str
drop if Sales == 0 
drop Sales

merge m:1 firm_id year month state_abv product sales_type ///
	using $generated_dir/sales_company_state_channel, nogen keep(match)

save tempdat_st, replace

*GET AVERAGES BY WEIGHTED BY MATCHED PRODUCT FOR TP 
use tempdat_st, clear
drop if product == "total"

global wvars Price frac_resale mshare HHI av_mshare av_HHI *nfirms shipcost frac_light

foreach v of varlist $wvars {
	replace `v' = `v' * Sales
}

gcollapse (sum) $wvars Sales*, ///
	by(FPid year month state_abv sales_type)

foreach v of varlist $wvars {
	replace `v' = `v' / Sales
}

gen product = "_TP"
append using tempdat_st


*BRING IN STATE LEVEL DEMOGRAPHIC VARS
merge m:1 state_abv year month using $generated_dir/demodat, ///
	keep(match master) nogen ///
	keepusing(CDD HDD income_pc pop)

foreach v of varlist CDD HDD income_pc pop {
	rename `v' _X_`v'
}
gen _X_log_pop = log(_X_pop)

bys year month state_abv prod firm_id: gen nFPids = _N

rename product prod
replace prod = "_G" if prod == "gas"
replace prod = "_D" if prod == "diesel"
replace prod = "_O" if prod == "other"
replace prod = "_T" if prod == "total"

merge m:1 FPid year month using "$generated_dir/fp_ref_crude_data", nogen keep(match)

save salesdata_st, replace

* gcollapse TO FP LEVEL
use salesdata_st, clear
global wvars Price frac_resale mshare HHI av_mshare av_HHI *nfirms shipcost ///
	nFPids frac_light _X*

foreach v of varlist $wvars {
	replace `v' = `v' * Sales
}

gen nstates = 1

collapse (sum) $wvars Sales nstates, by(FPid year month prod sales_type)

foreach v of varlist $wvars {
	replace `v' = `v' / Sales
}

merge m:1 FPid year month using "$generated_dir/fp_ref_crude_data", nogen keep(match)

save salesdata_fp, replace

use salesdata_st, clear
keep FPid year month Price Sales sales_type prod state_abv
rename Price P
rename Sales Q
reshape wide P Q, i(FPid year month state_abv prod) j(sales_type) str
reshape wide P_A P_W Q_A Q_W, i(FPid year month state_abv) j(prod) str

foreach v of varlist Q_* {
	replace `v' = 0 if `v' == .
}

foreach it_p in T TP G D O {
	gen frac_resale_`it_p' = Q_W_`it_p'/ Q_A_`it_p'
}

gen frac_light_W_TP = (Q_W_G + Q_W_D)/Q_W_TP
gen frac_light_A_TP = (Q_A_G + Q_A_D)/Q_A_TP

save widedat_st, replace


use salesdata_fp, clear
keep FPid year month Price Sales sales_type prod
rename Price P
rename Sales Q
reshape wide P Q, i(FPid year month prod) j(sales_type) str
reshape wide P_A P_W Q_A Q_W, i(FPid year month) j(prod) str

foreach v of varlist Q_* {
	replace `v' = 0 if `v' == .
}

foreach it_p in T TP G D O {
	gen frac_resale_`it_p' = Q_W_`it_p'/ Q_A_`it_p'
}

gen frac_light_W_TP = (Q_W_G + Q_W_D)/Q_W_TP
gen frac_light_A_TP = (Q_A_G + Q_A_D)/Q_A_TP

save widedat_fp, replace

****************************************************************************************************8	
*MERGE IN REFINERY AND CRUDE DATA 
local stype W

use salesdata_st, clear
keep if sales_type == "_`stype'"

merge m:1 FPid year month state_abv using widedat_st, nogen keep(match master)
gen frac_gas_T = Q_`stype'_G/ Q_`stype'_T
gen frac_gas_TP = Q_`stype'_G/ Q_`stype'_TP
gen frac_dist_T = Q_`stype'_D/ Q_`stype'_T
gen frac_dist_TP = Q_`stype'_D/ Q_`stype'_TP

capture drop co_padd 
egen co_padd = group(FPid) 
egen fevar = group(FPid state_abv)

egen av_frac_light = mean(frac_light), by(fevar)
egen av_frac_resale = mean(frac_resale), by(fevar prod)
rename av_mshare av_mshare_782
egen av_mshare = mean(mshare), by(fevar prod)
egen av_sales = mean(Sales), by(fevar prod)

rename p_brent_spot brent_cru
save "$generated_dir/regdata_st", replace

use salesdata_fp, clear
keep if sales_type == "_`stype'"

merge m:1 FPid year month using widedat_fp, nogen keep(match master)
gen frac_gas_T = Q_`stype'_G/ Q_`stype'_T
gen frac_gas_TP = Q_`stype'_G/ Q_`stype'_TP
gen frac_dist_T = Q_`stype'_D/ Q_`stype'_T
gen frac_dist_TP = Q_`stype'_D/ Q_`stype'_TP

capture drop co_padd 
egen co_padd = group(FPid) 
gen fevar = co_padd // define i level of fe regs. also used for clustering 

egen av_frac_light = mean(frac_light), by(fevar)
egen av_frac_resale = mean(frac_resale), by(fevar prod)
rename av_mshare av_mshare_782
egen av_mshare = mean(mshare), by(fevar prod)
egen av_sales = mean(Sales), by(fevar prod)

rename p_brent_spot brent_cru

save "$generated_dir/regdata_fp", replace
