/***********************
This file imports and cleans the annual capacity files
***********************/
clear
global repodir "/home/sweeneri/ms_pt_clean"
do "$repodir/code/setup.do"

*set working directory
cd "$commondir/temp"

*******************************************************************************

*READ IN DOWNSTREAM CAPACITY
import excel using "$publicdir/Manual/820codes.xlsx", firstrow sheet(downstream) clear
save 820codes_ds, replace

import excel using "$eiadir/EIA 820 1986 to 2015.xlsx", firstrow sheet("downstream cap") clear

gen tempd = substr(SURVEY_PERIOD_END_DATE,1,9)
gen edate = date(tempd,"DMY")
format edate %td
gen month = month(edate)
gen year = year(edate)
merge m:1 DOWNSTREAM_CAPACITY_TYPE using 820codes_ds, nogen
save dscapdat, replace

*READ IN PRODUCTION CAPACITY
import excel using "$publicdir/Manual/820codes.xlsx", firstrow sheet(prod_cap) clear
save 820codes_prod, replace

import excel using "$eiadir/EIA 820 1986 to 2015.xlsx", firstrow sheet("production cap") clear
gen tempd = substr(SURVEY_PERIOD_END_DATE,1,9)
gen edate = date(tempd,"DMY")
format edate %td
gen month = month(edate)
gen year = year(edate)
merge m:1 PRODUCTION_CAPACITY_PROD_CODE using 820codes_prod, nogen
save prodcapdat, replace

*READ IN DISTILLATION CAPACITY
import excel using "$eiadir/EIA 820 1986 to 2015.xlsx", firstrow sheet("distillation cap") clear

gen tempd = substr(SURVEY_PERIOD_END_DATE,1,9)
gen edate = date(tempd,"DMY")
format edate %td
gen month = month(edate)
gen year = year(edate)

gen captype = "oprtng"
replace captype = "idle" if DISTILLATION_CAPACITY_TYPE == 400
replace captype = "proj_oprbl" if DISTILLATION_CAPACITY_TYPE == 501

rename CALENDAR_DAY_QUANTITY cap_820_cd_
rename STREAM_DAY_QUANTITY cap_820_sd_
keep SITE_ID year month cap* 
save opcap, replace
reshape wide cap_820_cd cap_820_sd, i(SITE_ID year month) j(captype) str

egen totcap_820_sd = rowtotal(cap_820_sd_idle cap_820_sd_oprtng)
egen totcap_820_cd = rowtotal(cap_820_cd_idle cap_820_cd_oprtng)
save opcap_wide, replace

*READ N IN REFINERY RECEIPTS
import excel using "$eiadir/EIA 820 1986 to 2015.xlsx", firstrow sheet("refinery receipts") clear
gen tempd = substr(SURVEY_PERIOD_END_DATE,1,9)
gen edate = date(tempd,"DMY")
format edate %td
gen month = month(edate)
gen year = year(edate)
gen te = cond(SOURCE_NAME == "DOMESTIC","dom_","for_")
gen mylab = te + TRANSPORT_METHOD_TYPE
rename REC cru_rec_
keep SITE_ID mylab month year cru_rec
reshape wide cru_rec, i(SITE year month) j(mylab) str
gen cru_rec_total_for = 0
foreach v of varlist cru_rec_for* {
	replace `v' = 0 if `v' == .
	replace cru_rec_total_for = cru_rec_total_for + `v'
}

gen cru_rec_total_dom = 0
foreach v of varlist cru_rec_dom* {
	replace `v' = 0 if `v' == .
	replace cru_rec_total_dom = cru_rec_total_dom + `v'
}

gen cru_rec_total = cru_rec_total_dom + cru_rec_total_for
label var cru_rec_total "Ref Crude Receipts (K Bbl)"
save "$generated_dir/clean_confidential_data/ref_receipts", replace

*NOW READ IN FUEL USE DATA
import excel using "$eiadir/EIA 820 1986 to 2015.xlsx", firstrow sheet("fuel consumed") clear
gen tempd = substr(SURVEY_PERIOD_END_DATE,1,9)
gen edate = date(tempd,"DMY")
format edate %td
gen month = month(edate)
gen year = year(edate)
gen mylab = ""
replace mylab = "elec" if FUEL_NAME == "PURCHASED ELECTRICITY (million kWh)"
replace mylab = "natgas" if FUEL_NAME == "NATURAL GAS (million cubic feet)"
replace mylab = "petcoke_cat" if FUEL_NAME == "PETROLEUM COKE, CATALYST"
replace mylab = "hydrogen" if FUEL_NAME == "HYDROGEN FEEDSTOCK"
replace mylab = "steam" if FUEL_NAME == "PURCHASED STEAM (million pounds)"
replace mylab = "still_gas" if FUEL_NAME == "STILL GAS"
drop if mylab == ""
rename FUEL_QUANTITY fueluse_
rename SITE_ID site_id 
keep year site_id fueluse mylab
gsort site_id year mylab -fueluse
by site_id year mylab: gen te= _n
drop if te > 1
drop te
save pdat, replace

*fill in missing years 1995 and 1997
use pdat if year == 1994 | year == 1996, clear
collapse (mean) fuel, by(site_id mylab)
gen year = 1995
save itdat, replace
use pdat, clear
append using itdat
save pdat, replace
use pdat if year == 1996 | year == 1998, clear
collapse (mean) fuel, by(site_id mylab)
gen year = 1997
save itdat, replace
use pdat, clear
append using itdat
save tedat, replace

use tedat, clear
reshape wide fueluse_ , i(year site_id) j(mylab) str

label var fueluse_elec "PURCHASED ELECTRICITY (Mil.kWh)"
label var fueluse_natgas "NATURAL GAS (Mil.cub.ft.)"
label var fueluse_hydrogen "HYDROGEN FEEDSTOCK"
label var fueluse_petcoke "PETROLEUM COKE, CATALYST"
label var fueluse_steam "PURCHASED STEAM (Mil lbs)"

save "$generated_dir/clean_confidential_data/ref_fuel_use", replace

************************************
*CLEAN DATA 

*FIX ERRONEOUS ENTRIES IN DSCAP DATA
use dscapdat, clear
/*desulf appears misreported as hydrocracking in these years*/
replace STREAM_DAY_QUANTITY = STREAM_DAY_QUANTITY + 96000 if SITE_ID == 125 ///
	& DOWNSTREAM_CAPACITY_TYPE == 429 & RPT_PERIOD > 1999 & RPT_PERIOD < 2004 
use dscapdat, clear
replace STREAM_DAY_QUANTITY = STREAM_DAY_QUANTITY + 96000 if SITE_ID == 125 ///
	& DOWNSTREAM_CAPACITY_TYPE == 413 & RPT_PERIOD == 1999 & RPT_PERIOD < 2004 
replace STREAM_DAY_QUANTITY = STREAM_DAY_QUANTITY - 96000 if SITE_ID == 125 /// 
	& DOWNSTREAM_CAPACITY_TYPE == 436 & RPT_PERIOD >= 1999 & RPT_PERIOD < 2004 
save tempdat, replace

*filling in 1986 vac dist cap with 1987 values
keep if year == 1987
replace year = 1986
append using tempdat


*GET NELSON COMPLEXITY 
append using prodcapdat
gen NCItemp_single = NCI_factor*STREAM_DAY_QUANTITY
gen sdcap_proc = STREAM_DAY_QUANTITY
save allcapdat, replace

gen NCItemp2 = NCItemp_single
gen vacdist = STREAM_DAY_QUANTITY
replace vacdist = . if spec_label != "vac"
replace NCItemp2 = 0 if spec_label == "petcoke" | spec_label == "asphalt" | spec_label == "lube" | spec_label == "sulfur"
collapse (sum) STREAM_DAY_QUANTITY NCItemp = NCItemp_single NCItemp2 vacdist, by(year month SITE_ID)
save sumdat, replace

use opcap_wide, clear
gen maxsd_cap = totcap_820_sd
merge 1:1 SITE_ID year month using sumdat
gen cap_flag = "inboth"
replace cap_flag = "no_ds" if _merge == 1
replace cap_flag = "ds_only" if _merge == 2
replace maxsd_cap = vacdist if cap_flag == "ds_only" 
gen NCI = (maxsd_cap + NCItemp)/(maxsd_cap)
replace NCI = 1 if cap_flag == "no_ds"
gen NCI2 = (maxsd_cap + NCItemp2)/(maxsd_cap)
replace NCI2 = 1 if cap_flag == "no_ds"
drop _merge
save NCIdat, replace

merge 1:m SITE_ID year month using allcapdat
save tempdat, replace

use tempdat, clear
sort NCI SITE_ID year month NCItemp_s
gen pctcap = sdcap_proc/maxsd_cap
order year month SITE_ID spec_ agg* NCI NCI2 cap_flag NCItemp_s pct

use allcapdat, clear
replace agg_label2 = agg_label if agg_label2 == ""
collapse (sum) dscap_ = STREAM_DAY_QUANTITY, by(year month SITE_ID agg_label2)
gen flag_allcapdat = 1
merge m:1 year month SITE_ID using opcap_wide
gen flag_opcapdat = 1 if _merge > 1

replace flag_all = 0 if flag_all == .
replace flag_op = 0 if flag_op == .

replace agg_label2 = "nocap" if agg_label2 == ""
drop _merge
reshape wide dscap_ , i(year month SITE_ID) j(agg_label2) str
foreach v of varlist dscap* {
	label var `v' "`v' BBL/SD"
}

save tempdat, replace

use NCIdat, replace
keep SITE_ID year month NCI NCI2
merge 1:1 SITE_ID year month using tempdat, nogen
rename SITE_ID site_id
drop month
save pdat, replace



*fill in missing years 1996 and 1998
use pdat if year == 1995 | year == 1997, clear
collapse (mean) NCI* dscap* cap* tot* (min) flag*, by(site_id)
gen year = 1996
save itdat, replace
use pdat, clear
append using itdat
save pdat, replace
use pdat if year == 1999 | year == 1997, clear
collapse (mean) NCI* dscap* cap* tot* (min) flag*, by(site_id)
gen year = 1998
save itdat, replace
use pdat, clear
append using itdat

gen refcaptype = "normal"
replace refcaptype = "nodistcap" if flag_all == 0 & flag_op == 1 
replace refcaptype = "noDScap" if flag_all == 1 & flag_op == 0 & year > 1986

save "$generated_dir/clean_confidential_data/820capdata_clean", replace


*remove temp files created
shell rm *.dta
