/*******************************************************************************
This file puts the cleaned EIA data in the right form for pass through regressions
- puts all prices in present dollars
- defines firm_id 
- selects product categories 
- collapses to firm-state-product-month level
********************************************************************************/

/*******************************************************************************
FIRST CLEAN UP 782 DATA
********************************************************************************/
use $generated_dir/common_build/782Adata, clear
keep if year >= 2004 

drop if state_abv == "HI" | state_abv == "AK"

do $repodir/code/build/subcode_getfirmid.do

**Put in present dollars (12/2013)
merge m:1 year month using $main_dir/clean_eia_refinery_data/input/deflator, nogen keep(match master)
replace price = price*deflator

*CREATE PODUCT AND SALES CHANNEL BINS
gen product = "other"
replace product = "gas" if inlist(prod_label,"Conv-Mid","Conv-Prm","Conv-Prm-Pre94","Conv-Reg")
replace product = "gas" if inlist(prod_label,"Lead-Reg","Oxy-Mid","Oxy-Prm", "Oxy-Reg", "Ref-Mid","Ref-Prm","Ref-Reg","UnLead-Mid","Unlead") 
replace product = "diesel" if inlist(prod_label,"Diesel Pre94","HS Diesel","LS Diesel","ULS Diesel")
replace product = "diesel" if inlist(prod_label,"Kerojet") // Adding jet fuel to distillates 

gen channel = "other"  // mainly other end users, commercial, industrial
replace channel = "retail" if (scode == 10 )|(scode==14) // second code is for outlets
replace channel = "resale" if (scode == 20)
replace channel = "rack" if (scode == 22)
replace channel = "dtw" if (scode == 21)
replace channel = "bulk" if (scode == 23)

* 'A' FOR ALL (OR ANY CHANNEL), 'W' FOR WHOLESALE
rename Q782A Sales_A
gen Revenue_A = Sales_A*price

*KEEP TRACK OF WHOLESALE SEPARATELY
gen resale = cond(channel == "other" | channel == "retail",0,1)

gen Sales_W = Sales_A * resale
gen Revenue_W = Revenue_A * resale

*COLLAPSE TO PRODUCT LEVEL 

collapse (sum) Sales_* Revenue_*, by(firm_id year month state_abv product)

save tempdat, replace

use tempdat, clear
collapse (sum) Sales_* Revenue_*, by(firm_id year month state_abv)
gen product = "total"

append using tempdat

gen Price_A = Revenue_A/Sales_A
gen Price_W = Revenue_W/Sales_W

*MERGE IN REGION DEFINITIONS
merge m:1 state_abv using $generated_dir/common_build/region_definitions, ///
	nogen keep(match master) keepusing(padd snum)

save $rgenerated_dir/generated_data/sales_company_state, replace

use $generated_dir/generated_data/sales_company_state, clear
gen frac_resale = Sales_W/ Sales_A

reshape long Sales Price Revenue, i(firm_id year month state_abv product) j(sales_type) str
drop if Sales == . | Sales == 0

*GET MSHARE, HHI and Nfirms 
capture drop _te
gegen _te = sum(Sales), by(state_abv product year month sales_type)
gen mshare = Sales/_te

capture drop _te
gen _te = mshare^2
gegen HHI = sum(_te), by(state_abv product year month sales_type)

gegen nfirms = count(firm_id), by(state_abv product year month sales_type)

*GET LEAVE ONE OUT ANNUAL AVERAGES 
foreach v of varlist HHI nfirms {
	capture drop _ti
	gsort state_abv product year month sales_type - Sales
	by state_abv product year month  sales_type: gen _ti = _n
	replace _ti = . if _ti > 1
	
	capture drop _tn 
	gegen _tn = sum(_ti) , by(state_abv product year sales_type) 
	
	capture drop _te
	gen _te = `v' * _ti 
	capture drop _ts
	gegen _ts = sum(_te), by(state_abv product year sales_type)
	
	gen av_`v' = (_ts - `v')/(_tn - 1)
	replace av_`v' = 0 if av_`v' == .
}

*get leave one out mshare averages by firm
capture drop _ts
egen _ts = sum(mshare), by(state_abv product year firm_id sales_type) 
capture drop _tn 
egen _tn = count(month), by(state_abv product year firm_id sales_type) 

gen av_mshare = (_ts - mshare)/(_tn - 1)

replace av_mshare = 0 if av_mshare == .
drop _t*

*GET LIGHT SHARE
capture drop te
gen te = Sales if prod == "gas" | prod == "diesel" 
gegen Sales_L = sum(te), by(firm_id state_abv year month sales_type) 

replace te = Sales if prod == "other"
gegen Sales_C = sum(te), by(firm_id state_abv year month sales_type)

gen frac_light = Sales_L / Sales_C

drop te Sales_C Sales_L

save $generated_dir/sales_company_state_channel, replace

********************************************************************************
*remove temp files created
shell rm *.dta
exit
