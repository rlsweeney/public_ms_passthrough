/**************************************
- Bring in cleaned eia data
- Save files by reporting level
- clean up and standardize the EIA corporate id's across surveys
******************************************/
clear
global repodir "/home/sweeneri/ms_pt_clean"
do "$repodir/code/setup.do"

*set working directory
cd "$commondir/temp"
**********************************************
/*******************************************************************************
READ IN CORPIDS AND NEW IDS
********************************************************************************/
* IMPORT A UNIQUE LIST OF CORP ID NAMES GENERATED FROM PUBLIC REFINERY CAPACITY FILES
import excel using "$publicdir/Manual/corp_id_list_ms_pt.xlsx", firstrow clear sheet("corp_id_names")
save idnames, replace

* IMPORT NEWID THAT DEALS WITH JVS AND IMPROVES MERGES ACROSS SURVEYS 
import excel using "$publicdir/Manual/corp_id_list_ms_pt.xlsx", firstrow clear sheet("my_corp_id_edits")
gen fdate = ym(fyear,fmonth)
format fdate %tm
gen ldate = ym(lyear,lmonth)
format ldate %tm
drop corp_name fyear fmonth lyear lmonth
drop if flag_uncertain == 1
save myidnames, replace
global nedits = _N
di $nedits


*GET REGION DEFINITIONS
use $publicdir/Manual/region_definitions, clear
save $generated_dir/common_build/region_definitions, replace

/*********************************************************************
READ IN STATIC REFINERY DATA
- combines the EIA refinery data with exernal, public, time invariant information
*********************************************************************/

*import refinery site names and locations from desktop
use "$publicdir/Manual/refinery_info_locations", clear
save tempdat, replace

use $generated_dir/clean_confidential_data/810all, clear
drop if Q_total == 0 | Q_total == .
collapse (min) first_year_810 = year (max) last_year_810 = year /// 
	(lastnm) location_code location_name padd facility_type, by(site_id)
	
merge 1:1 site_id using tempdat
drop if _merge == 1 & facility_type == "BLND"
gen flag_no_810 =cond(_merge == 2,1,0)
drop _merge 

gen state_up = upper(STATE)
drop STATE
save tempdat, replace

use $publicdir/Manual/region_definitions, clear
gen state_up = upper(state_name)
merge 1:m state_up using tempdat, nogen keep( match)

gen ref_state = upper(state_name)
rename state_abv ref_state_abv 
drop state_name state_up
save $generated_dir/common_build/refinery_info, replace

/*******************************************************************************
READ IN ANNUAL REFINERY DATA
********************************************************************************/
use $generated_dir/clean_confidential_data/820capdata_clean, clear
save $generated_dir/common_build/refinery_annual, replace

/*********
READ IN MONTHLY REFINERY DATA
*****************************************************/
use $generated_dir/clean_confidential_data/810all, clear

*clean corp_id's 
gen len = length(corporate_id)
gen corp_id = substr(corporate_id,1,6)
destring corp_id, replace
drop len

gen ymdate = ym(year, month)
format ymdate %tm
save sdat, replace

use sdat, clear
keep site_id corp_id ymdate
gen newid = .
save tdat, replace

forval i = 1/$nedits {
quietly{
	use myidnames, clear
	keep if _n == `i'
	save tm, replace

	use tm, clear
	merge 1:m corp_id using tdat
	replace newid = my_corp_id if _merge == 3 & ymdate >= fdate & ymdate <= ldate
	keep site_id corp_id newid ymdate
	save tdat, replace
}
}

use tdat, clear
replace newid = corp_id if newid == .
merge m:1 corp_id using idnames, keep(match master) nogen
drop corp_name_notes flag_outofscoree scopenotes
rename corp_id tcorpid
rename corp_name_clean tcorp_name_clean
rename newid corp_id 
merge m:1 corp_id using idnames, keep(match master) nogen
rename corp_name_clean my_corp_name_clean
rename corp_id my_corp_id 
rename tcorpid corp_id 
rename tcorp_name_clean corp_name_clean
drop corp_name_notes flag_outofscoree scopenotes

merge 1:1 site_id corp_id ymdate using sdat, nogen

save $generated_dir/common_build/refinery_data_monthly, replace

/****************************************************************
READ IN FIRM CRUDE PRICE DATA
and CLEAN CORP_IDS
*************************************************************/
use $generated_dir/clean_confidential_data/EIA14data, clear

gen ymdate = ym(year, month)
format ymdate %tm
save sdat, replace

use sdat, clear
keep padd corp_id ymdate
gen newid = .
save tdat, replace

forval i = 1/$nedits {
quietly{
	use myidnames, clear
	keep if _n == `i'
	save tm, replace

	use tm, clear
	merge 1:m corp_id using tdat
	replace newid = my_corp_id if _merge == 3 & ymdate >= fdate & ymdate <= ldate
	keep padd corp_id newid ymdate
	save tdat, replace
}
}

use tdat, clear
replace newid = corp_id if newid == .
merge m:1 corp_id using idnames, keep(match master) nogen
drop corp_name_notes flag_outofscoree scopenotes 
rename corp_id tcorpid
rename corp_name_clean tcorp_name_clean
rename newid corp_id 
merge m:1 corp_id using idnames, keep(match master) nogen
rename corp_name_clean my_corp_name_clean 
rename corp_id my_corp_id 
rename tcorpid corp_id 
rename tcorp_name_clean corp_name_clean
drop corp_name_notes flag_outofscoree scopenotes

merge 1:1 padd corp_id ymdate using sdat, nogen keep(match using)

save $generated_dir/common_build/firm_crude_prices, replace


/*******************************************************************************
READ IN FIRM 782 DATA
********************************************************************************/
* FIRST CLEAN UP 782 DATA
use $generated_dir/clean_confidential_data/782Adata_all_pre94, clear

*clean corp_id's 
gen len = length(ID)
replace corp_id = "0"+substr(ID,1,5) if len ==9
replace corp_id = "00"+substr(ID,1,4) if len ==8
replace corp_id = "000"+substr(ID,1,3) if len ==7
replace corp_id = ID if len ==6
destring corp_id, replace
drop len

gen ymdate = ym(year, month)
format ymdate %tm
save sdat, replace

use sdat, clear
bys corp_id ymdate: gen te = _n
keep if te == 1

keep corp_id ymdate
gen newid = .
save tdat, replace

forval i = 1/$nedits {
quietly{
	use myidnames, clear
	keep if _n == `i'
	save tm, replace

	use tm, clear
	merge 1:m corp_id using tdat
	replace newid = my_corp_id if _merge == 3 & ymdate >= fdate & ymdate <= ldate
	keep corp_id newid ymdate
	save tdat, replace
}
}

use tdat, clear
replace newid = corp_id if newid == .
merge m:1 corp_id using idnames, keep(match master) nogen
drop corp_name_notes flag_outofscoree scopenotes
rename corp_id tcorpid
rename corp_name_clean tcorp_name_clean
rename newid corp_id 
merge m:1 corp_id using idnames, keep(match master) nogen
rename corp_name_clean my_corp_name_clean
rename corp_id my_corp_id 
rename tcorpid corp_id 
rename tcorp_name_clean corp_name_clean
drop corp_name_notes flag_outofscoree scopenotes

merge 1:m corp_id ymdate using sdat, nogen 

*  CLEAN UP VARIABLE NAMES MORE 
rename volume Q782A
label var Q782A "Q782A (Kgal)"
rename ReportState state_abv

save $generated_dir/common_build/782Adata, replace

********************************************************************************
*NOW DO 782C. 
use $generated_dir/clean_confidential_data/782Cdata_all_pre94, clear
drop L ReportD

*clean corp_id's 
gen len = length(ID)
replace corp_id = "0"+substr(ID,1,5) if len ==9
replace corp_id = "00"+substr(ID,1,4) if len ==8
replace corp_id = "000"+substr(ID,1,3) if len ==7
replace corp_id = ID if len ==6
destring corp_id, replace
drop len

gen ymdate = ym(Year, Month)
format ymdate %tm
save sdat, replace

use sdat, clear
bys corp_id ymdate: gen te = _n
keep if te == 1

keep corp_id ymdate
gen newid = .
save tdat, replace

forval i = 1/$nedits {
quietly{
	use myidnames, clear
	keep if _n == `i'
	save tm, replace

	use tm, clear
	merge 1:m corp_id using tdat
	replace newid = my_corp_id if _merge == 3 & ymdate >= fdate & ymdate <= ldate
	keep corp_id newid ymdate
	save tdat, replace
}
}

use tdat, clear
replace newid = corp_id if newid == .
merge m:1 corp_id using idnames, keep(match master) nogen
drop corp_name_notes flag_outofscoree scopenotes
rename corp_id tcorpid
rename corp_name_clean tcorp_name_clean
rename newid corp_id 
merge m:1 corp_id using idnames, keep(match master) nogen
rename corp_name_clean my_corp_name_clean
rename corp_id my_corp_id 
rename tcorpid corp_id 
rename tcorp_name_clean corp_name_clean
drop corp_name_notes flag_outofscoree scopenotes

merge 1:m corp_id ymdate using sdat, nogen

*  CLEAN UP VARIABLE NAMES MORE 
rename Vol Q782C
label var Q782C "Kgal (782C)" 

rename ReportState state_abv
save $generated_dir/common_build/782Cdata, replace

********************************************************************************
*remove temp files created
shell rm *.dta
