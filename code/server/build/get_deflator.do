* GET EIA DEFLATOR ******************************************************************/
clear
global repodir "/home/sweeneri/ms_pt_clean"
do "$repodir/code/setup.do"

*set working directory
cd "$commondir/temp"


*READ IN EXCEL with CPI
import excel using "$publicdir\EIA\real_prices_viewer_20160907.xlsx", firstrow sheet(forstata) clear
gen year = year(date)
gen month = month(date)
drop if month == .
gen te = cond(year == 2013 & month == 12,CPI,.)
egen base = mean(te)
gen deflator = base/CPI
label var deflator "Deflator (12/13 = 1)"
keep year month deflator
save "generated_dir\common_build\deflator", replace


* PREP STATE LEVEL DEMOGRAPHIC DATA
use $publicdir/Manual/state_demo_data, clear
keep state_abv padd subpadd year month PCP TAVG TMIN TMAX CDD HDD income pop
gen income_pc = income/pop/1000
replace pop = pop/1000000
keep if year > 2002
save $generated_dir/demodat, replace
