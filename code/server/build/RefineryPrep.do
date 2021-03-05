/***********************************************************
*PREP REFINERY DATA 
This file puts the cleaned EIA data in the right form for pass through regressions
*************************************************************/

**** FIRST BRING IN 810 DATA ******
use $generated_dir/common_build/refinery_data_monthly, clear

do $repodir/code/build/subcode_getfirmid.do

egen Q_prod_light = rowtotal(Q_prod_dist_tot Q_prod_gas_mgbc_tot Q_prod_jet_kero)

*NEED PRODUCT CATEGORIES THAT MATCH 782 SALES CATEGORIES 
gen Q_other = Q_total - Q_prod_gas_tot - Q_prod_dist_tot

keep year month site_id corp_id padd firm_* ///
	sulfur_pct api_gravity Q_rec_cru_ak Q_rec_cru_dom Q_rec_cru_for Q_netinpt_cru_tot pct_foreign_crude ///
	Q_total Q_netinpt_cru_tot cap_* inputsgross receipts_or_inputs Q_prod_light facility_type ///
	Q_prod_gas_tot Q_prod_dist_tot Q_other

gen pct_domestic_810 = 1 - pct_foreign
drop pct_foreign 

foreach v of varlist Q_netinpt_cru_tot receipts_or_inputs inputsgross {
	replace pct_domestic_810 = 0 if pct_domestic_810  == . & `v' == 0
	replace api = 0 if api  == . & `v' == 0
}

gen ymdate = ym(year,month)

gsort site_id ymdate -Q_total api
by site_id ymdate: gen te = _n
drop if te > 1

*BRING IN ANNUAL CAPACITY INFO
save tempdat, replace

use $generated_dir/common_build/refinery_annual, clear
keep site_id year NCI dscap_catcrack dscap_cathyrc dscap_therm dscap_vac totcap_820_sd totcap_820_cd cap_820_cd_oprtng cap_820_sd_oprtng
merge 1:m site_id year using tempdat, keep(match using)

drop if facility_type == "BLND" & _merge == 2
drop _merge 

rename padd ref_padd 
save tempdat, replace

*BRING IN GHG ID AND STATE
use $generated_dir/common_build/refinery_info, clear
keep GHGRPID ghg_joint_flag ghg_notes site_id ref* ref_state_abv
merge 1:m site_id using tempdat, keep(match using) nogen


** SAMPLE RESTRICTIONS *************************************
*count Hess's VI Hovensa refinery in padd 1
replace ref_padd = 1 if site_id == 80
drop if ref_padd > 5

*DROP AK AND HI REFINERIES (DROP STATES FROM PRICES AS WELL)
drop if ref_state_abv == "AK" | ref_state_abv == "HI"

gen flag_operating = cond(Q_total > 20,1,0)

*DROP REFINERIES THAT NEVER PRODUCE IN SAMPLE
capture drop te
gen te = cond(flag_operating == 1 & year > 2003,1,0)
egen ts = sum(te), by(site_id)
drop if ts == 0
drop ts te 

*FILL IN MISSING / OUTLYING GRAVITY 
replace api_gravity = . if api_gravity < 15

foreach m in site_id ref_state_abv ref_padd {
	capture drop te 
	egen te = mean(api_gravity), by(`m')
	replace api_gravity = te if api_gravity == .
	capture drop te 
	egen te = mean(api_gravity), by(`m' year)
	replace api_gravity = te if api_gravity == .
}

*GET LAGGED AND PRE PERIOD API AND DOM SHARE FOR INSTRUMENTS 

foreach v of varlist pct_domestic_810 api_gravity {
	capture drop te 
	gen te = `v' if year >=2002 & year < 2004
	egen pre_`v' = mean(te), by(site_id)
	drop te

	gen te = `v' if year >=2002 
	egen tp = mean(te), by(site_id)
	replace pre_`v' = tp if pre_`v' == .
	drop te tp

}


*DEFINE CAPACITY VARIABLES
gen totcap820 = totcap_820_cd
replace totcap820 = totcap_820_sd if totcap_820_cd == 0 & totcap_820_sd > 0 & totcap_820_sd != .
gen opcap810 = cap_810_oprtng

*RESTRICT SAMPLE TO YEARS WE HAVE CRUDE PRICE FOR
keep if year >= 2004

do $repodir/code/build/subcode_getFPid.do

save $generated_dir/refinery_data_monthly, replace

********************************************************************************
*remove temp files created
shell rm *.dta
