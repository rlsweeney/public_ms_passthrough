/***********************
Maps refinery locations and firm-padd ids to 782A data 
***********************/

clear
global repodir "/home/sweeneri/ms_pt_clean"
do "$repodir/code/setup.do"

/******************************************************
FOR ACTIVE REFINERIES ,GET CLOSEST REFINERY TO EACH STATE FOR EACH PRODUCT 
[by firm-padd]
********************************************************************/
use "$generated_dir/refinery_data_monthly", clear

keep site_id firm_id year month ref_padd ///
	Q_total Q_prod_gas_tot Q_prod_dist_tot Q_other flag_operating FPid

rename Q_prod_gas_tot Q_gas
rename Q_prod_dist_tot Q_diesel


foreach j in diesel gas other total {
	egen av_Q_`j' = mean(Q_`j'), by(site_id year)
}


reshape long Q_ av_Q_ , i(site_id year month) j(product) str
di _N

gen flag_producing_j =  cond(av_Q_ >= 10 | Q_ >= 10,1,0)

joinby site_id using $generated_dir/common_build/refinery_shipping_costs

*CREATE A SORT ORDER TO PRIORITIZE WHICH REFINERY LIKELY SERVED A STATE
capture drop te
gsort FPid year month state_abv product -flag_operating -flag_producing_j shipcost
by FPid year month state_abv product: gen te = _n

*all we care about is mapping to firm-padd (for crude price). 
drop if te > 1

foreach v of varlist Q_ flag_* {
	rename `v' ref_`v' 
}

keep firm_id ref_padd year month shipcost state_abv product ref_* site_id FPid linear_distance

save fp_ref_state_map, replace


/********************************************************************
*EXPAND FP DATA AND COMBINE TO STATE - MONTH - PRODUCT 
FOR ALL PERIODS WITH EITHER 810 OR 14 DATA
*******************************************************************/

use fp_ref_state_map, clear
bys year month state_abv product: gen te = _n
drop if te > 1
keep year month state_abv product
save slist, replace

use "$generated_dir/fp_ref_crude_flags", clear
keep FPid year month flag_* 

joinby year month using slist

*MERGE IN CLOSEST REFINERY DATA
merge 1:1 FPid year month product state_abv using fp_ref_state_map

*FOR FPID'S THAT ARE MISSING SHIPCOSTS THAT PERIOD, USE LAST NON-MISSING
capture drop te
sort FPid product state year month
by FPid product state: gen te = _n
replace shipcost = shipcost[_n-1] if shipcost == . ///
		& (FPid[_n-1]  == FPid) & te != 1 & flag_in810 == 1
replace linear_distance = linear_distance[_n-1] if linear_distance == . ///
		& (FPid[_n-1]  == FPid) & te != 1 & flag_in810 == 1
		
capture drop te
gsort FPid product state -year -month
by FPid product state: gen te = _n
replace shipcost = shipcost[_n-1] if shipcost == . ///
		& (FPid[_n-1]  == FPid) & te != 1 & flag_in810 == 1
replace linear_distance = linear_distance[_n-1] if linear_distance == . ///
		& (FPid[_n-1]  == FPid) & te != 1 & flag_in810 == 1
		
drop te 
drop _merge

/*******************************************************************************
*MERGE WITH SALES DATA
*******************************************************************************/

*DROP OBSERVATIONS NOT IN CRUDE
keep if flag_in14 == 1 & flag_in810 == 1

gen FPid_padd = substr(FPid,-1,1)
destring FPid_padd, replace

*KEEP MASTER SO WE CAN CALCULATE PRICE OF FRINGE FIRMS 
merge m:1 firm_id product state_abv year month using $generated_dir/sales_company_state, nogen keep(match master)

gsort firm_id state_abv product year month -ref_flag_operating -ref_flag_producing_j shipcost
by firm_id state_abv product year month: gen firm_st_rank = _n

gen valid_state = cond(firm_st_rank == 1,1,0)

*RULE OUT SOME MATCHES THAT WE KNOW ARE WRONG

replace valid_state = 0 if FPid_padd == 5 & padd < 3 // no shipping east coast to east coast
replace valid_state = 0 if FPid_padd == 1 & padd > 3 // no shipping east coast to west coast
replace valid_state = 0 if FPid_padd == 2 & padd == 5 
replace valid_state = 0 if FPid_padd == 4 & padd == 1 // no shipping east coast to west coast

*if not a valid state 
foreach v of varlist Sales* Price* {
	replace `v' = 0 if `v' == . | valid_state == 0
}

save "$generated_dir/fpmj_prices_state_all", replace
 
********************************************************************************
*remove temp files created
shell rm *.dta
