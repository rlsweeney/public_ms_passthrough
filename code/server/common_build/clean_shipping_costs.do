/***************************************************************************
* BRING IN EXTERNALLY COMPUTED SHIPPING COSTS AND IMPUTE MISSINGS 
****************************************************************************/
clear
global repodir "/home/sweeneri/ms_pt_clean"
do "$repodir/code/setup.do"

*set working directory
cd "$commondir/temp"

********************************************************************************
*BRING IN REFINERY INFORMATION

use $generated_dir/common_build/refinery_info, clear
keep site_id ref_state_abv ref_state location_code site_name latitude longitude
save refdat, replace

*FIGURE OUT WHICH REFINERIES HAVE CALCULATED SHIPPING COSTS
use $publicdir/Manual/shipping_costs_by_ref, clear
bys state_abv: gen te = _n
drop if te > 1
keep state_abv
sort state_abv
gen snum = _n
di _N
save slist, replace

use refdat, clear
keep site_id 
expand 52 
bys site_id: gen snum = _n
merge m:1 snum using slist, nogen
merge 1:1 site_id state_abv using $publicdir/Manual/shipping_costs_by_ref
gen flag_inship = cond(_merge == 3,1,0)
drop _merge

replace shipcost = shipcost_truck if shipcost == 0

keep site_id ref_state shipcost state_abv flag_inship dist_truck_ref_state
rename dist_truck_ref_state linear_distance

egen n_inship = sum(flag_inship), by(site_id)

save shipdat_in, replace

use shipdat_in, clear
bys site_id: gen te = _n
keep if te == 1
drop te
keep site_id n_inship
merge 1:1 site_id using refdat
save tempdat, replace

*FILL IN MISSING COSTS WITH COSTS FOR CLOSEST REFINERY
use tempdat, clear
keep if n_inship  < 52
keep site_id latitude longitude ref_state
save slist, replace

use tempdat, clear
keep if n_inship  == 52
keep site_id latitude longitude
foreach v of varlist site_id latitude longitude {
	rename `v' n_`v'
}
save nlist, replace

use slist, clear
geonear site_id latitude longitude using nlist, ///
	n(n_site_id n_latitude n_longitude) ignoreself long ///
	near(1)
drop if km > 250 & site_id != 80 // fill in hovensa
save mlist, replace

use mlist, clear
rename site_id t_site_id
rename n_site_id site_id
drop km
merge 1:m site_id using shipdat_in, nogen keep(match)

drop site_id 
rename t_site_id site_id
rename shipcost t_shipcost
rename linear_distance t_linear_distance
keep site_id state_abv t_shipcost t_linear_distance

merge 1:1 site_id state_abv using shipdat_in
replace shipcost = t_shipcost if _merge == 3
replace linear_distance = t_linear_distance if _merge == 3
drop _merge t_shipcost t_linear_distance

merge m:1 site_id using refdat, nogen keep(match)

save $generated_dir/common_build/refinery_shipping_costs, replace

*GET LIST OF DISTANCES BETWEEN ALL REFINERIES
use tempdat, clear
keep site_id latitude longitude
save slist, replace

use tempdat, clear
keep site_id latitude longitude
foreach v of varlist site_id latitude longitude {
	rename `v' n_`v'
}
save nlist, replace

use slist, clear
local nrefs = _N -1 
di `nrefs'
geonear site_id latitude longitude using nlist, ///
	n(n_site_id n_latitude n_longitude) ignoreself long ///
	near(`nrefs')
save mlist, replace
local npairs = _N/`nrefs'
di `npairs'
di _N
save $generated_dir/common_build/refinery_pair_distances, replace

********************************************************************************
*remove temp files created
shell rm *.dta

