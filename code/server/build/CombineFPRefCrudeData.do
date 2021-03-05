*******************************************************************************
*GET FP LEVEL REFINERY INFO, INSTRUMENTS
********************************************************************************/
use "$generated_dir/common_build/refinery_data_monthly", clear

*GET WEIGHTED VARS AT FP LEVEL
gen nrefs = 1
gen nrefs_operating = flag_operating

local wlist api_gravity pct_domestic_810 NCI pre_*
foreach v of varlist `wlist' {
	gen w_`v'= `v'* Q_total 
	
}

collapse (sum) w_* Q_total ds* nrefs* totcap* opcap810 ///
	(mean) pct_domestic_810 api_gravity NCI pre_*, by(FPid year month firm_id ref_padd) 

*JUST KEEP WEIGHTED AVERAGES
foreach v of varlist `wlist' {
	replace `v' =  w_`v' / Q_total 
	drop w_`v'
	
	replace `v' = . if Q_total == 0
	capture drop te 
	egen te = mean(`v'), by(FPid) 
	replace `v' = te if `v' == . 	
	
}


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


rename totcap_820_sd totcap

capture drop tk 
egen tk = sum(totcap), by(year month ref_padd)
gen capshare_padd = totcap/tk

capture drop tf 
egen tf = sum(totcap), by(year month firm_id)
capture drop tn
egen tn = sum(totcap), by(year month)
gen capshare_us = tf/tn

drop Q_* ds* totcap_* tk tf tn
save "$generated_dir/FP_refinery_data", replace

********************************************************************************
* GET ANNUAL GHG INFO
********************************************************************************
use $repodir/generated_data/refinery_data_monthly, clear

collapse (sum) inputsgross receipts_or_inputs Q_total Q_netinpt_cru_tot  ///
	(mean)  ds* tot* cap_* api_gravity NCI ///
	(first) site_id firm_* ref_state_abv ref_padd, by(GHGRPID year) 
	
drop if GHGRPID == . | GHGRPID == 0
merge 1:1 GHGRPID year using $generated_dir/ghgdata_clean, nogen keep(match)
drop if GHG == 0 | GHG == .
drop if year == 2010
capture drop ghg_

gen ghg_bar  = GHG/(receipts_or_inputs*1000)
gen tax_cpg = ghg_bar*40/42

save "$generated_dir/taxdata", replace

/*******************************************************************************
*COLLAPSE GHG DATA TO THE FPid level PADD LEVEL
*******************************************************************************/
use  "$generated_dir/taxdata", clear

do $repodir/code/build/subcode_getFPid.do

capture drop tk
gen tk = tax * receipts_or_inputs
collapse (mean) tax (sum) tk receipts_or_inputs, by(FPid year)
gen av_tax = tk / rec
drop tk 
drop receipts_or_inputs

save "$generated_dir/FP_taxdata", replace

/***************************************************************
FIGURE OUT WHICH REFINERIES APPEAR IN CRUDE DATA IN A GIVEN MONTH
- GET FIRM-PADD REFINERY INFO
- FIGURE OUT WHICH ONES ARE ALSO IN EIA- 14
*****************************************************/

use "$generated_dir/FP_refinery_data", clear // from prep_refinery_data.do
gen flag_in810 = 1
save fp_ref_dat, replace


* BRING IN CRUDE PRICE DATA 
use $repodir/generated_data/FP_crudepricedat, clear

rename crude_padd ref_padd
gen flag_in14 = 1
save crudedat, replace

merge 1:1 FPid year month using fp_ref_dat
replace flag_in810 = 0 if flag_in810 ==.
replace flag_in14 = 0 if flag_in14 ==.
drop _merge

egen pct_in810_byin14 = mean(flag_in810), by(FPid flag_in14)

*FILL MISSING REFINING VARS WITH LAST NM
local rvars api_gravity pct_domestic_810 pre_* 
sort FPid year month
foreach v of varlist `rvars' {
	replace `v' = `v'[_n-1] if `v' == . & (FPid[_n-1]  == FPid)
}
gsort FPid -year -month
foreach v of varlist `rvars' {
	replace `v' = `v'[_n-1] if `v' == . & (FPid[_n-1]  == FPid)
}

replace flag_in810 = 1 if api != . & pct_in810 > .9 

*SAVING THIS FOR USE IN ANALYSIS/COMBINE_FP_REF_CRUDE_DATA
save "$generated_dir/fp_ref_crude_flags", replace


use "$generated_dir/fp_ref_crude_flags", clear

keep if flag_in14 == 1 & flag_in810 == 1

*CONSTRUCT INSTRUMENTS

gen Z_APIPre = pre_api_gravity
capture drop te
egen Z_APIAvg = mean(api_gravity), by(FPid)

capture program drop binapi
program define binapi 

	capture drop _temp_domfp_api
	gen _temp_domfp_api = DomFPP_U20
	replace _temp_domfp_api = DomFPP_20_25 if _temp_api_var > 20 
	replace _temp_domfp_api = DomFPP_25_30 if _temp_api_var > 25
	replace _temp_domfp_api = DomFPP_30_35 if _temp_api_var > 30
	replace _temp_domfp_api = DomFPP_35_40 if _temp_api_var > 35
	replace _temp_domfp_api = DomFPP_G40 if _temp_api_var > 40

	capture drop _temp_impfp_api 
	gen _temp_impfp_api = ImpFOB_U20
	replace _temp_impfp_api = ImpFOB_20_25 if _temp_api_var > 20 
	replace _temp_impfp_api = ImpFOB_25_30 if _temp_api_var > 25
	replace _temp_impfp_api = ImpFOB_30_35 if _temp_api_var > 30
	replace _temp_impfp_api = ImpFOB_35_40 if _temp_api_var > 35
	replace _temp_impfp_api = ImpFOB_40_45 if _temp_api_var > 40 & ImpFOB_40_45 != .
	replace _temp_impfp_api = ImpFOB_G45 if _temp_api_var > 45 & ImpFOB_G45 != . 
end
	
capture drop _temp_api_var
gen _temp_api_var = Z_APIPre
binapi
rename _temp_domfp_api Z_PapiDomPre
rename _temp_impfp_api Z_PapiImpPre

capture drop _temp_api_var
gen _temp_api_var = Z_APIAvg
binapi
rename _temp_domfp_api Z_PapiDomAvg
rename _temp_impfp_api Z_PapiImpAvg

*GET SHARE DOMESTIC CRUDE

gen Z_DomPre =  pre_pct_domestic_810 
egen Z_DomAvg = mean(frac_dom_crude_14), by(FPid)

gen Z_PapiPre = Z_PapiDomPre*Z_DomPre + Z_PapiImpPre*(1-Z_DomPre)
gen Z_PapiAvg = Z_PapiDomAvg*Z_DomAvg + Z_PapiImpAvg*(1-Z_DomAvg)

replace share_ds = 0 if share_ds == .
egen Z_DScap = mean(share_ds), by(FPid)

gen Z_PapiDSPre = Z_PapiPre * Z_DScap
gen Z_PapiDSAvg= Z_PapiAvg * Z_DScap

gen HLsprd = hl_spread_dom
gen USsprd = p_wti_spot - p_brent

gen Z_DomUSPre =  Z_DomPre * USsprd
gen Z_DomUSAvg =  Z_DomAvg * USsprd

gen Z_PDSHL = HLsprd * Z_DScap

gen Z_P24 = cond(ref_padd == 2 | ref_padd == 4,1,0)
	foreach z in APIAvg DomAvg DScap {
		gen Z_P24_`z' = Z_`z' * Z_P24
	}

egen co_padd = group(FPid)

set matsize 10000
eststo clear
eststo: qui: reg cru_price_tot Z_PapiAvg* COFPP_padd i.co_padd  i.year i.month
predict Z_EstPcru 
eststo: qui: reg cru_price_tot i.co_padd#c.(Z_PapiDomAvg Z_PapiImpAvg COFPP_padd) i.co_padd  i.year i.month
predict Z_EstPcru_hd 

gen Z_avg_dom = COFPP_US*Z_DomPre + p_brent_spot*(1-Z_DomPre)

drop Z_PapiImp* 

*add in tax data
merge m:1 FPid year using "$generated_dir/FP_taxdata", keep(match master)

*fill in missings
foreach v of varlist av_tax tax_cpg {
	capture drop ti
	egen ti = mean(`v'), by(FPid) 
	capture drop tp
	egen tp = mean(`v'), by(ref_padd year) 
	capture drop tn
	egen tn = mean(`v'), by(year) 
	
	replace `v' = ti if `v' == . & year > 2010
	replace `v' = tp if `v' == . & year > 2010
	replace `v' = tn if `v' == . & year > 2010
}


* RENAME SOME VARIABLES SO THEIR SUBSEQUENT SUMMED NAMES ARE SHORTER
rename cru_price_tot Pcru 

keep FPid year month flag_in* 	*tax* firm_id /// 
	nrefs share* api_g totcap Pcru p_* Z_* *avg* frac_dom_crude_14 NCI /// 
	Imp* DomF*  hl_* capshare* ref_padd

save "$generated_dir/fp_ref_crude_data", replace
exit
*remove temp files created
shell rm *.dta

