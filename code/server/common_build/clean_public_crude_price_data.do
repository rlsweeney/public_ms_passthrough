/*This file reads in publicly available crude prices from EIA data
- some are manually cleaned a bit in excel first
*/
******************************************/
clear
global repodir "/home/sweeneri/ms_pt_clean"
do "$repodir/code/setup.do"

*set working directory
cd "$commondir/temp"

/********************************************************
READ IN CRUDE PRICE DATA
******************************************************/
*first import cushing and brent spot prices
import excel using "$publicdir\EIA\EIA_spot_prices.xls", sheet("Data 1") clear
drop if _n < 4
ds A, not
global ivars "`r(varlist)'"
destring $ivars, replace
rename B p_wti_spot
rename C p_brent_spot
drop D
save adata, replace
drop if A == ""
gen edate = date(A,"DMY")
format edate %td
gen month = month(edate)
gen year = year(edate)
gen day = day(edate)
drop A 
save crudeprice, replace

*import first purchase price crude values
*this file as first purchase price by region, and i've mannually pulled them out by padd
*PET_PRI_DFP1_K_M_RSwork.xls
import excel using "$gitdir\publicdir\EIA\EIA_dom_cru_FPP_by_area.xls", sheet("work") firstrow clear
ds Date, not
global ivars "`r(varlist)'"
gen month = month(Date)
gen year = year(Date)
gen day = day(Date)
drop Date 
drop if month == .

merge 1:1 year month using crudeprice
*keep if _merge == 3
drop _merge
save crudeprice, replace

*import heavy light crude spreads
*this file as first purchase price by region, and i've mannually pulled them out by padd
*PET_PRI_DFP1_K_M_RSwork.xls


*Import Landed Costs of Imported Crude by API Gravity
*goes back to 1983
import excel using "$publicdir\EIA\EIA_landed_cost_import_cru_by_API.xls", sheet("Data 1") clear
drop if _n < 4
ds A, not
global ivars "`r(varlist)'"
destring $ivars, replace
rename B ImpLand_U20
rename C ImpLand_20_25
rename D ImpLand_25_30
rename E ImpLand_30_35
rename F ImpLand_35_40
rename G ImpLand_40_45
rename H ImpLand_G45
save adata, replace
drop if A == ""
gen edate = date(A,"DMY")
format edate %td
gen month = month(edate)
gen year = year(edate)
gen day = day(edate)
drop A 

merge 1:1 year month using crudeprice
*keep if _merge == 3
drop _merge
save crudeprice, replace

*F.O.B. Costs of Imported Crude Oil by API Gravity
*goes back to 1983
import excel using "$publicdir\EIA\EIA_FOB_cost_import_cru_by_API.xls", sheet("Data 1") clear
drop if _n < 4
ds A, not
global ivars "`r(varlist)'"
destring $ivars, replace
rename B ImpFOB_U20
rename C ImpFOB_20_25
rename D ImpFOB_25_30
rename E ImpFOB_30_35
rename F ImpFOB_35_40
rename G ImpFOB_40_45
rename H ImpFOB_G45
save adata, replace
drop if A == ""
gen edate = date(A,"DMY")
format edate %td
gen month = month(edate)
gen year = year(edate)
gen day = day(edate)
drop A 

merge 1:1 year month using crudeprice
*keep if _merge == 3
drop _merge
save crudeprice, replace


*Domestic Crude Oil First Purchase Prices by API Gravity
*only goes back to 1994
import excel using "$publicdir\EIA\EIA_dom_cru_FPP_by_API.xls", sheet("Data 1") clear
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
save adata, replace
drop if A == ""
gen edate = date(A,"DMY")
format edate %td
gen month = month(edate)
gen year = year(edate)
gen day = day(edate)
drop A 

merge 1:1 year month using crudeprice
*keep if _merge == 3
drop _merge
save crudeprice, replace


*Domestic Crude Oil First Purchase Prices by Stream
*only goes back to 1993 for most, but goes back to 1970s for AK slope
import excel using "$publicdir\EIA\EIA_dom_cru_FPP_by_stream.xls", sheet("Data 1") clear
drop if _n < 4
ds A, not
global ivars "`r(varlist)'"
destring $ivars, replace
rename B DomFPP_AK_NSlope
rename C DomFPP_CA_Kern
rename D DomFPP_CA_Midway
rename E DomFPP_LA_HeavySweet
rename F DomFPP_LA_LightSweet
rename G DomFPP_Mars
rename H DomFPP_WTI
rename I DomFPP_WTSour
rename J DomFPP_WY_Sweet
save adata, replace
drop if A == ""
gen edate = date(A,"DMY")
format edate %td
gen month = month(edate)
gen year = year(edate)
gen day = day(edate)
drop A 

merge 1:1 year month using crudeprice
*keep if _merge == 3
drop _merge
save crudeprice, replace

drop H I K edate 
gen ymdate = ym(year,month)
format ymdate %tm

save "$generated_dir/common_build/crudeprice", replace

