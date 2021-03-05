/**************************************************
This file puts the cleaned EIA data in the right form for pass through regressions
- puts all prices in present dollars
- defines firm_id
****************************************************************/

use $generated_dir/common_build/firm_crude_prices, clear

do $repodir/code/build/subcode_getfirmid.do

*count Hess's VI Hovensa refinery in padd 1
replace padd = 1 if corp_id == 245755 & padd == 6
drop Total* 
gen frac_dom_crude_14 = Q14_dom/Q14_tot
replace frac_dom = 0 if frac_dom < 0

**Put in present dollars (12/2013)
merge m:1 year month using $generated_dir/common_build/deflator, nogen keep(match master)

foreach v of varlist cru_* {
	replace `v' = `v'*deflator/42
}

*NEED TO COLLAPSE BECAUSE I'M AGGREGATING FIRM_IDS 
gen w_cru_price_dom = cru_price_dom * Q14_dom
gen w_cru_price_for = cru_price_for * Q14_for
gen w_cru_price_tot = cru_price_tot * Q14_tot
gen w_frac_dom_crude_14 = frac_dom_crude_14 * Q14_tot

collapse (sum) w_* Q14*, by(year month padd firm_*) 

gen cru_price_dom = w_cru_price_dom / Q14_dom
gen cru_price_for = w_cru_price_for / Q14_for
gen cru_price_tot = w_cru_price_tot / Q14_tot
gen frac_dom_crude_14 = w_frac_dom_crude_14 / Q14_tot

drop w_*
drop Q14_dom Q14_for 

rename padd crude_padd 
save $generated_dir/crude_prices_firm, replace


* BRING IN PUBLIC CRUDE PRICES
use $generated_dir/common_build/crudeprice, clear
drop day
*PUT EVERYTHING THING CURRENT DOLLARS PER GALLON (NOT BARELL)
merge m:1 year month using $generated_dir/common_build/deflator, nogen keep(match)

foreach v of varlist Dom* Imp* COF* p_*  {
	replace `v' = `v'*deflator/42
}

*GET CRUDE PRICE INSTRUMENTS
gen hl_spread_dom = (DomFPP_35_40 + DomFPP_G40 - DomFPP_U20 - DomFPP_20_25)/2
la var hl_spread_dom "Domestic API G40 - U20"
gen hl_spread_dom_narrow = (DomFPP_35_40 - DomFPP_20_25)/2
la var hl_spread_dom_narrow "Domestic API 40 - 20"

gen hl_spread_imp = (ImpFOB_35_40 - ImpFOB_20_25)/2
la var hl_spread_imp "Imported API 40 - 20"

gen hl_spread_lls_mars = DomFPP_LA_LightSweet - DomFPP_Mars
la var hl_spread_lls_mars "Light Louisiana Sweet - Mars"

gen hl_spread_lls_lhs = DomFPP_LA_LightSweet - DomFPP_LA_HeavySweet
la var hl_spread_lls_lhs "Light - Heavy Louisiana Sweet"

save $generated_dir/pub_crude_prices, replace


/*******************************************************************************
*PREPARE CRUDE PRICES 
*******************************************************************************/
use $generated_dir/pub_crude_prices, clear
keep year month p_wti p_brent /// 
	COFPP_US COFPP_P1 COFPP_P2 COFPP_P3 COFPP_P4 COFPP_P5 ///
	DomFPP_U20 DomFPP_20_25 DomFPP_25_30 DomFPP_30_35 DomFPP_35_40 DomFPP_G40 ///
	ImpFOB* hl_*
	
merge 1:m year month using  $generated_dir/crude_prices_firm, nogen keep(match using)

*GET FPid
gen str6 tf = string(firm_id,"%06.0f")
gen FPid=  tf + "-" + string(crude_padd)
drop tf

drop if crude_padd > 5
drop if year < 2004


*GET CRUDE PRICE INSTRUMENTS
gen COFPP_padd = .
forval i= 1/5 {
	replace COFPP_padd = COFPP_P`i' if crude_padd == `i'
}
drop COFPP_P*

*get avg and weighted average national and padd level crude prices each month
gen tn = 1
egen nf = sum(tn), by(year month) 
egen ts = sum(cru_price_tot), by(year month)
gen avg_cru_p_nat = ts / nf 
gen l1o_avg_cru_p_nat = (ts - cru_price_tot)/(nf -1)
label var avg_cru_p_nat "US Avg Crude Price"
label var l1o_avg_cru_p_nat "US Avg Crude Price (leave one out)"
drop nf ts

*get padd average
egen nf = sum(tn), by(year month crude_padd) 
egen ts = sum(cru_price_tot), by(year month crude_padd)
gen avg_cru_p_padd = ts / nf 
gen l1o_avg_cru_p_padd = (ts - cru_price_tot)/(nf -1)
label var avg_cru_p_padd "Padd Avg Crude Price"
label var l1o_avg_cru_p_padd "Padd Avg Crude Price (leave one out)"
drop nf ts tn
save $generated_dir/FP_crudepricedat, replace


********************************************************************************
*remove temp files created
shell rm *.dta
exit

capture log close
exit
