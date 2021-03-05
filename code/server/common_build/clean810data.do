/***********************
This file cleans the EIA-810 data

data read in in readin810Data.do
***********************/
clear
global repodir "/home/sweeneri/ms_pt_clean"
do "$repodir/code/setup.do"

*set working directory
cd "$commondir/temp"
*******************************************************************************

*these should be in each dataset
global idvars site_id corporate_id facility_type location_code location_name padd

****************************************************************************** CLEAN ACTIVITY DATA, PULL OUT PRODUCTS OF INTEREST, TRANSPOSE
*/


global sortvars $idvars year month
use $generated_dir/clean_confidential_data/810Activity, clear

gen Q_ship_ = shipments
gen Q_prod_ = gross_production
gen Q_rec_ = receipts
gen Q_inpt_ = inputs
foreach v of varlist Q* {
	replace `v' = 0 if `v' == .
}

egen totQ = rowtotal(Q*)
drop if totQ == 0
gen Q_estock_ = ending_stocks
keep $sortvars aglabel Q*

*back out shipments 
gen T = 12*(year-1986)+ month
bysort site_id  aglabel T: gen te = _n
tab te
egen tg = group(site_id aglabel)
tsset tg T
gen Q_bstock = L.Q_estock
replace Q_bstock = Q_estock - Q_rec + Q_inpt - Q_prod + Q_ship if Q_bstock == .

gen tship = Q_bstock + Q_rec - Q_inpt + Q_prod - Q_estock

sum tship if inlist(aglabel,"distHS","distLS","distULS"), detail
replace tship = 0 if tship < 0
replace Q_ship = tship if inlist(aglabel,"distHS","distLS","distULS")
drop tship te tg T 

save actdat, replace


/*GET INPUT VARS */
use actdat, clear
gen tokeep = inlist(aglabel,"cru_tot","ngpl_tot","hyrenox_tot","spec_naphta","proc_gain")
replace tokeep = 1 if inlist(aglabel,"total","kerosene","ufo_tot","cru_dom","cru_for","cru_ak")
replace tokeep = 1 if inlist(aglabel,"total","pcfeed_tot","renew_tot","mtbe","oxy_tot")
keep if tokeep
gen Q_netinpt_ = Q_inpt - Q_prod
replace Q_netinpt_ = Q_rec if aglabel == "cru_dom" | aglabel == "cru_for" | aglabel == "cru_ak"
replace Q_netinpt_ = Q_inpt if aglabel == "total"
keep $sortvars agl Q_net
reshape wide Q_* , i($sortvars) j(aglabel) str
foreach v of varlist Q* {
	replace `v' = 0 if `v' == .
}
rename Q_netinpt_total Q_total 
label var Q_total "Total Inputs (=Total Production)"

gen pct_foreign_crude = Q_netinpt_cru_for /(Q_netinpt_cru_for  + Q_netinpt_cru_dom)
label var pct_foreign_crude "Share of crude reciepts from foreign countries"
gen pct_alaskan_crude = Q_netinpt_cru_ak /(Q_netinpt_cru_for  + Q_netinpt_cru_dom)
label var pct_alaskan_crude "Share of crude reciepts from Alaska (included in Dom as well)"

rename  Q_netinpt_cru_dom Q_rec_cru_dom
rename  Q_netinpt_cru_for Q_rec_cru_for
rename  Q_netinpt_cru_ak Q_rec_cru_ak
save inpdat, replace

/*GET PRODUCTS I WANT TO KEEP */
use actdat, clear
gen tokeep = inlist(aglabel,"mgbc_tot","gas_tot","rfg_tot","rfo_tot","gas_oxy_p04")
replace tokeep = 1 if inlist(aglabel,"dist_tot","distHS","distLS","distULS","jet_kero")
keep if tokeep
reshape wide Q_* , i($sortvars) j(aglabel) str
foreach v of varlist Q* {
	replace `v' = 0 if `v' == .
}
save widdat, replace


/*FIX RFG
MGBC IS NOT BROKEN OUT BY RFG AND CONVENTIONAL UNTIL 2004. NEED TO ALLOCATE NET INPUTS SOMEHOW
-basically almost all mgbc pre 2004 is RBOB. 
- 2004-2005 mgbc shares are pretty stable, so using those to allocate pre2004 mgbc to rfg
*/

use actdat, clear
gen tokeep = inlist(aglabel,"mgbc_tot","mgbc_ref_tot")
keep if tokeep
reshape wide Q_* , i($sortvars) j(aglabel) str
foreach v of varlist Q* {
	replace `v' = 0 if `v' == .
}

gen qtr = ceil(month/3)

foreach v in prod inpt rec ship {
	gen arat = (Q_`v'_mgbc_ref_tot/Q_`v'_mgbc_tot)
	replace arat = . if year < 2004 | year > 2005
	egen qrat = mean(arat), by(site_id qtr)
	egen yrat = mean(arat), by(site_id)
	gen Q_`v'_mgbc_ref_adj = Q_`v'_mgbc_ref_tot 
	
	/*manual changes. based on googling these refineries: */
	replace qrat = 1 if site_id == 431
	replace qrat = 0 if site_id == 333
	
	replace Q_`v'_mgbc_ref_adj = qrat*Q_`v'_mgbc_tot if year < 2004 & year > 1994 & qrat != .
	replace Q_`v'_mgbc_ref_adj = yrat*Q_`v'_mgbc_tot if year < 2004 & year > 1994 & qrat == . & yrat != .
	drop arat yrat qrat
}

save rfgdat, replace

/*MERGE BACK TOGETHER */
use widdat, clear
merge 1:1 $sortvars using rfgdat, nogen
merge 1:1 $sortvars using inpdat, nogen
foreach v of varlist Q_* {
	replace `v' = 0 if `v' == .
}
drop qtr

/*GENERATE GAS_MGBC, RFG_MGBC AND CONV VARS */
foreach v in ship prod rec inpt {
	gen Q_`v'_gas_mgbc_tot =  Q_`v'_gas_tot + Q_`v'_mgbc_tot
	gen Q_`v'_rfg_mgbc_tot =  Q_`v'_rfg_tot + Q_`v'_mgbc_ref_adj
	gen Q_`v'_conv_tot =  Q_`v'_gas_tot - Q_`v'_rfg_tot
	gen Q_`v'_conv_mgbc_tot =  Q_`v'_gas_mgbc_tot - Q_`v'_rfg_mgbc_tot
}

save $generated_dir/clean_confidential_data/810Activity_wide, replace


*****************************************************************************
*get clean list of observations
use $generated_dir/clean_confidential_data/810Activity_wide, clear
*SITE 230, WHICH IS A BLENDER, IS INITALLY LISTED AS BEING IN ILLONOIS, THEN LISTED IN INDIANA FROM 1996 ON. 
*RESETTING ALL TO INDIANA
replace location_code = 30 if site_id == 230
replace location_name = "INDIANA" if site_id == 230

replace location_code = 48 if site_id == 361
replace location_name = "NEVADA" if site_id == 361
replace padd = 5 if site_id == 361

gen flag_in_activity = 1

*Compare ids across data sets:
merge 1:1 site_id corporate_id facility_type year month using $generated_dir/clean_confidential_data/810StreamInputs
gen flag_in_stream = 1 if _merge > 1
drop _merge
merge 1:1 site_id corporate_id facility_type year month using $generated_dir/clean_confidential_data/810capacity
gen flag_in_capacity = 1 if _merge > 1
drop _merge
merge 1:1 site_id corporate_id facility_type year month using $generated_dir/clean_confidential_data/810SulfGrav 
gen flag_in_suflgrav = 1 if _merge > 1
drop _merge

/* FILL IN MISSING SULFUR AND GRAVITY */

gen flag_nosulfgrav = cond(api_gravity ==.,1,0)
gen te = api if site_id == 381
egen tem = mean(te)
replace api_gravity = tem if site_id == 381
drop te tem
gen te = sulfur_pct if site_id == 381
egen tem = mean(te)
replace sulfur_pct = tem if site_id == 381
drop te tem

sort site_id year month api
by site_id: gen ti = _n
tsset site_id ti
replace api_gravity = L.api_gravity if api_gravity == . 
replace sulfur_pct = L.sulfur_pct if sulfur_pct == . 
drop ti
tsset, clear

save $generated_dir/clean_confidential_data/810all, replace

*remove temp files created
shell rm *.dta
