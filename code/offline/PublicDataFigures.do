* SETUP *******************************************************************************
clear
set linesize 200
* run setup first
*do ${repodir}\code\offline\setup_offline.do

global monotype s1mono // sj s2mono 

global figdir "$repodir/output/offline/figures/from_public_data" 
global PublicData "$repodir/data/public_data/EIA"

* FIGURE 1: PRODUCTION *******************************************************

import excel using "$PublicData/PET_CRD_CRPDN_ADC_MBBLPD_M.xls", ///
sheet("Data 1") cellrange(A2) firstrow clear

* Rename variables
rename Sourcekey DATE
rename MCRFPUS2 Prod_US
rename MCRFPP12 Prod_P1
rename MCRFPP22 Prod_P2 
rename MCRFPP32 Prod_P3 
rename MCRFPP42 Prod_P4
rename MCRFPP52 Prod_P5

keep Prod_* DATE
* Drop unwanted variable and observations
drop if DATE == "Date" 
drop if DATE == ""

* Reformat DATE to be consistent Mon-YY format
gen date = date(DATE,"DMY")
format date %tm
gen month = month(date)
gen year = year(date)
gen ymdate = ym(year,month)
format ymdate %tm
drop DATE 
destring Prod*, replace
save tempdat, replace 

use tempdat, clear
keep if year >= 2000 & year <= 2015
drop Prod_US

label var Prod_P1 "(1) East Coast"
label var Prod_P2 "(2) Midwest"
label var Prod_P3 "(3) Gulf"
label var Prod_P4 "(4) Plains"
label var Prod_P5 "(5) West Coast"

sort ymdate

set scheme s2color
twoway (line Prod_* ymdate), ///
		ytitle("Mbbl/d")  xtitle("")  legend(rows(2))
		
graph export "${figdir}/EIA_oil_production_padd.png" ,  replace	
graph export "${figdir}/EIA_oil_production_padd.pdf" ,  replace	

set scheme $monotype
twoway (line Prod_* ymdate), ///
		ytitle("Mbbl/d")  xtitle("")  legend(rows(2))

graph export "${figdir}/mono_EIA_oil_production_padd.png" ,  replace	
graph export "${figdir}/mono_EIA_oil_production_padd.pdf" ,  replace	

* FIGURE 2: GLOBAL SPOT PRICE COMPARISON ***************************************

import excel using "$PublicData/PET_PRI_SPT_S1_M.xls", clear sheet("Data 1") firstrow cellrange(A3:C396)
rename Cushing wti_spot
rename Europe brent_spot

gen brent_wti_differential = brent_spot - wti_spot

label var brent_spot "Brent Oil Spot Price"
label var wti_spot "West Texas Oil Spot Price"
label var brent_wti_differential "Brent - WTI Differential"

tempfile spotprices
save `spotprices', replace

*READ IN PADD CRUDE PRICES 
import excel using "$PublicData/PET_PRI_RAC2_A_EPC0_PCT_DPBBL_M.xls", ///
	clear sheet("Data 1") firstrow cellrange(A3:G539)
drop USCrudeOilComp
foreach x in EastCoast Midwest GulfCoast RockyMountain WestCoast {
rename `x' 	InputPrice`x'
}

merge 1:1 Date using `spotprices'
tab _merge

gen month = month(Date)
gen year = year(Date)
*gen day = day(date)
gen ymdate = ym(year,month)
format ymdate %tm
rename Date date

save pricedat, replace

use pricedat, clear
keep if year >= 2000 & year <= 2015
gen timeperiod = "2000-2010"
replace timeperiod = "post2011" if year>2010
replace timeperiod = "pre2000" if year<2000
tab timeperiod, sum(brent_wti)

bys timeperiod: sum date
sort date

set scheme s2color
graph twoway (line brent_spot wti_spot date, lc(gs1 gs10) lwidth(medium medium)) ///
(line brent_wti_differential date, lc(blue)) ///
(function 12.03, range(18634 20209) lp(dash) lc(red)) ///
(function -1.41, range(14616 18627) lp(dash) lc(red))if year>1999, ytitle("$/bbl") ///
text(13 15900 "2000-2010:" "Mean = -$1.40 / bbl", place(e) c(red) size(small) )  ///
text(38 18750 "2011 - present:""Mean = $10.82 / bbl", place(e) c(red) size(small))  ///
legend(order(1 2 3))

graph export "${figdir}/oil_spot_price.png", replace
graph export "${figdir}/oil_spot_price.pdf", replace

set scheme $monotype
graph twoway (line brent_spot wti_spot date, lc(gs1 gs10) lwidth(medium medium)) ///
(line brent_wti_differential date, lc(gs5) lp(longdash)) ///
(function 12.03, range(18634 20209) lp(shortdash) lc(gs5)) ///
(function -1.41, range(14616 18627) lp(shortdash) lc(gs5))if year>1999, ytitle("$/bbl") ///
text(13 15900 "2000-2010:" "Mean = -$1.40 / bbl", place(e) size(small) )  ///
text(38 18750 "2011 - present:""Mean = $10.82 / bbl", place(e) size(small))  ///
legend(order(1 2 3))

graph export "${figdir}/mono_oil_spot_price.png", replace
graph export "${figdir}/mono_oil_spot_price.pdf", replace

* FIGURE 3: PADD PRICES  ***************************************

use pricedat, clear
keep if year >= 2000 & year <= 2015

gen PD_P1 = InputPriceEastCoast - brent_spot
gen PD_P2 = InputPriceMidwest - brent_spot
gen PD_P3 = InputPriceGulfCoast - brent_spot
gen PD_P4 = InputPriceRockyMountain - brent_spot
gen PD_P5 = InputPriceWestCoast - brent_spot

label var PD_P1 "(1) East Coast"
label var PD_P2 "(2) Midwest"
label var PD_P3 "(3) Gulf"
label var PD_P4 "(4) Plains"
label var PD_P5 "(5) West Coast"

sort ymdate

set scheme s2color
twoway (line PD_* ymdate), ///
		ytitle("$/bbl")  xtitle("")  legend(rows(2))
		
graph export "${figdir}/EIA_PADD_price_diff_brent.png" ,  replace	
graph export "${figdir}/EIA_PADD_price_diff_brent.pdf" ,  replace	

set scheme $monotype
twoway (line PD_* ymdate, lc(gs0 gs9 gs3 gs13 gs6)), ///
		ytitle("$/bbl")  xtitle("")  legend(rows(2))
		
graph export "${figdir}/mono_EIA_PADD_price_diff_brent.png" ,  replace	
graph export "${figdir}/mono_EIA_PADD_price_diff_brent.pdf" ,  replace	

* FIGURE 4: HEAVY LIGHT SPREAD (DOMESTIC) ***************************************
import excel using "$PublicData/PET_PRI_DFP3_K_M.xls", sheet("Data 1") clear
drop if _n < 4
ds A, not
global ivars "`r(varlist)'"
destring $ivars, replace
rename B DomFPP_U20
rename C DomFPP_20_25
rename D DomFPP_25_30
rename E DomFPP_30_35
rename F DomFPP_35_40
rename G DomFPP_G40
drop if A == ""
gen edate = date(A,"DMY")
format edate %td
gen month = month(edate)
gen year = year(edate)
gen day = day(edate)
drop A H
gen ymdate = ym(year,month)
format ymdate %tm

gen hl_spread = DomFPP_35_40 - DomFPP_20_25

keep if year >= 2000 & year <= 2015

sort ymdate

set scheme s2color
twoway (line hl_spread ymdate), ///
		ytitle("$/bbl")  xtitle("")  legend(off)
		
graph export "${figdir}/DomFPP_HL_spread_4020.png" ,  replace	
graph export "${figdir}/DomFPP_HL_spread_4020.pdf" ,  replace	

set scheme $monotype
twoway (line hl_spread ymdate), ///
		ytitle("$/bbl")  xtitle("")  legend(off)
		
graph export "${figdir}/mono_DomFPP_HL_spread_4020.png" ,  replace	
graph export "${figdir}/mono_DomFPP_HL_spread_4020.pdf" ,  replace	

*remove temp files created
shell rm *.dta

exit

