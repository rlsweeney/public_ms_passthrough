/***********************
This file imports and rearanges EIA-810 data
***********************/
clear
global repodir "/home/sweeneri/ms_pt_clean"
do "$repodir/code/setup.do"

*set working directory
cd "$commondir/temp"

*******************************************************************************

global idvars site_id corporate_id facility_type location_code location_name padd

/**************CLEAN CAPACITY DATA ***************/
import excel using "$eiadir/EIA 810 Capacity 1986 to 2000.xlsx", firstrow clear

save tempdatA, replace

import excel using "$eiadir/EIA 810 Capacity 2001 to 2015.xlsx", firstrow clear

append using tempdatA

save tempdat, replace

foreach v of var * { 
	rename `v' `=lower("`v'")' 
}


*rename and reformat date
gen tempd = substr(survey_period_end_date,1,9)
gen edate = date(tempd,"DMY")
format edate %td
gen month = month(edate)
gen year = year(edate)

*contains operable dist cap and storage. keep only distcap
drop if capacity_category_code == "S"

*drop other data for now;
keep $idvars year month capacity_type_code capacity

*some capacities are missing. this messes up the transpose;
drop if capacity == . 

*TRANSPOSE
*convert capacity types to column variables
reshape wide capacity, i($idvars year month) j(capacity_type_code) string


rename capacityI cap_810_idle
rename capacityO cap_810_oprtng
label var cap_810_idle "Idle Dist Cap 1st day of month (BBL/CD)"
label var cap_810_oprtng "Operating Dist Cap 1st day of month (BBL/CD)"
save $generated_dir/clean_confidential_data/810capacity, replace

use $generated_dir/clean_confidential_data/810capacity, clear
by site_id corp year month, sort: gen te = _N
tab te
*so there are no site_id-corp_id pairs with multiple facility types. 
drop te
by site_id year month, sort: gen te = _N
tab te
*nor are there multiple corp_ids per site with positive capacity
tab site_id faci
* no site_ids appear as both blender and refinery

/***************** CLEAN GRAVITY AND SULFUR DATA **************************************/
clear
import excel using "$eiadir/EIA 810 Gravity Sulfur 1986 to 2000.xlsx", firstrow clear

save tempdatA, replace

import excel using "$eiadir/EIA 810 Gravity Sulfur 2001 to 2015.xlsx", firstrow clear

append using tempdatA

foreach v of var * { 
	rename `v' `=lower("`v'")' 
}

*rename and reformat date
gen tempd = substr(survey_period_end_date,1,9)
gen edate = date(tempd,"DMY")
format edate %td
gen month = month(edate)
gen year = year(edate)

*drop missing
drop if receipts_or_inputs == . 
*check unique
sort site_id year month

*there are 3 month site combos with both inputs and reciepts. when this happens, drop inputs
drop if site_id == 110 & input_capacity_code == 30
drop if site_id == 381 & input_capacity_code == 40
drop if site_id == 2468 & input_capacity_code == 30

keep $idvars year month receipts_or_inputs sulfur_pct api_gravity

save $generated_dir/clean_confidential_data/810SulfGrav, replace

use $generated_dir/clean_confidential_data/810SulfGrav, clear
by site_id corp year month, sort: gen te = _N
tab te
*so there are no site_id-corp_id pairs with multiple facility types. 
drop te
by site_id year month, sort: gen te = _N
tab te
*nor are there multiple corp_ids per site with positive capacity
tab site_id faci
* 2 site ids appear as as both blender and refinery: 142 & 143.

/***************** CLEAN STREAM INPUTS DATA **************************************/
clear
import excel using "$eiadir/EIA 810 downstream inputs 1986 to 2000.xlsx", firstrow clear

save tempdatA, replace

import excel using "$eiadir/EIA 810 downstream inputs 2001 to 2015.xlsx", firstrow clear

append using tempdatA

foreach v of var * { 
	rename `v' `=lower("`v'")' 
}

*rename and reformat date
gen tempd = substr(survey_period_end_date,1,9)
gen edate = date(tempd,"DMY")
format edate %td
gen month = month(edate)
gen year = year(edate)

compress

keep $idvars year month input_capacity_code input_capacity_name inputs
*some streams are missing. this messes up the transpose. 
drop if inputs == . 

*transpose streams
*first gen new labels;
gen slabel =""
replace slabel = "gross" if input_capacity_code == 990
replace slabel = "crack" if input_capacity_code == 491
replace slabel = "hydrocrack" if input_capacity_code == 492
replace slabel = "reform" if input_capacity_code == 490
replace slabel = "coke" if input_capacity_code == 493

drop input_capacity_code input_capacity_name
reshape wide inputs, i($idvars year month) j(slabel) string

foreach v in gross crack hydrocrack reform coke {
	label var inputs`v' "`v' inputs (KBBL)"
}

save $generated_dir/clean_confidential_data/810StreamInputs, replace


***************************ACTIVITY DATA*************************************
clear
import excel using "$eiadir/EIA 810 Activity 1986 to 2000.xlsx", firstrow clear

save tempdatA, replace

import excel using "$eiadir/EIA 810 Activity 2001 to 2015.xlsx", firstrow clear

append using tempdatA

foreach v of var * { 
	rename `v' `=lower("`v'")' 
}

*rename and reformat date
gen tempd = substr(survey_period_end_date,1,9)
gen edate = date(tempd,"DMY")
format edate %td
gen month = month(edate)
gen year = year(edate)

compress
*drop other data for now;
drop survey_period_end_date respondent_id survey_id survey_name tempd 
save active_temp1, replace

use active_temp1, clear
gsort site_id corporate_id facility_type year month -ship -gross -end
by site_id corporate_id facility_type year month: gen te = _n
keep if te == 1
save active_idlist, replace

use active_idlist, replace
drop te
by site_id corp year month, sort: gen te = _N
tab te
drop te
by site_id year month, sort: gen te = _N
tab te


*MERGE IN PRODCUT CODES
import excel using "$publicdir/Manual/product_code_bridge_810_fin.xlsx", firstrow sheet(level_bridge) clear
drop A firstdig
destring code, gen(product_code)
merge 1:m product_code using active_temp1
drop if _merge == 1 
drop _merge
save merged, replace

*create total variables that aren't in my data but are in the documentation
global svars ending_stocks receipts inputs gross_production shipments use_loss 

*first get totals
use merged, clear
drop if code1 == ""
collapse (sum) $svars, by(code1 label1 $idvars year month)
gen agcode = code1
gen aglabel = label1
save apdat, replace

use merged, clear
drop if code2 == ""
collapse (sum) $svars, by(code2 label2 $idvars year month)
gen agcode = code2
gen aglabel = label2
append using apdat
save apdat, replace

use merged, clear
drop if code3 == ""
collapse (sum) $svars, by(code3 label3 $idvars  year month)
gen agcode = code3
gen aglabel = label3
append using apdat
save apdat, replace

use merged, clear
drop if code4 == .
collapse (sum) $svars, by(code4 label4 $idvars  year month)
gen agcode = "999"
gen aglabel = label4
append using apdat
save apdat, replace

use merged, clear
collapse (sum) $svars, by($idvars  year month)
gen agcode = "1"
gen aglabel = "total"
append using apdat
save apdat, replace

use merged, clear
keep if keep_original == "y"
tostring product_code, replace
rename product_code agcode
rename label aglabel
append using apdat
save apdat, replace

drop code* label*

save $generated_dir/clean_confidential_data/810Activity, replace


*remove temp files created
shell rm *.dta
