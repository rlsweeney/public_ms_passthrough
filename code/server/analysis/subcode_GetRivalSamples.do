use "$generated_dir/fpmj_prices_state_all", clear
replace Sales_A = 0 if valid_state == 0 | Sales_A < 10
replace Sales_W = 0 if valid_state == 0 | Sales_W < 10

keep year month state_abv firm_id FPid product Sales* shipcost linear_distance ref_flag_producing_j

	replace product = "_G" if product == "gas"
	replace product = "_D" if product == "diesel"
	replace product = "_O" if product == "other"

	replace product = "_T" if product == "total"

	replace shipcost = shipcost + .01
	replace linear_distance = linear_distance + 10

	rename ref_flag_producing_j ref_flag
	
	reshape wide Sales_* shipcost linear_distance ref_flag, i(FPid year month state_abv) j(product) str

	foreach v of varlist Sales_* {
		replace `v' = 0 if `v' == .
	}


	*GET TOTAL FOR PRODUCT SPECIFIC M2M
	gen Sales_A_TP = Sales_A_D + Sales_A_G + Sales_A_O
	gen Sales_W_TP = Sales_W_D + Sales_W_G + Sales_W_O
	
	egen ref_flag_TP = rowmax(ref_flag_D ref_flag_G ref_flag_O)
	replace ref_flag_TP = ref_flag_TP if ref_flag_TP == .
	
	gen shipcost_TP = (shipcost_G *Sales_A_G +shipcost_D * Sales_A_D + ///
		shipcost_O * Sales_A_O)/ Sales_A_TP
			
	replace shipcost_TP = shipcost_G if shipcost_TP == .

	gen linear_distance_TP = (linear_distance_G *Sales_A_G +linear_distance_D * Sales_A_D + ///
		linear_distance_O * Sales_A_O)/ Sales_A_TP
			
	replace linear_distance_TP = linear_distance_G if linear_distance_TP == .
	
	*GET AVERAGE Q REST OF YEAR 
	*NEED TOTAL AND LIGHT SHIPCOSTS 
	
	foreach s in A W {	
	foreach v in G D O T TP { 
		capture drop tq
		capture drop tn
		gegen tq = sum(Sales_`s'_`v'), by(FPid state_abv year)
		gegen tn = count(Sales_`s'_`v'), by(FPid state_abv year)
		gen av_Sales_`s'_`v' = (tq - Sales_`s'_`v')/(tn-1)
		replace av_Sales_`s'_`v' = 0 if tn == 1
		drop tq tn
	}
	}
	save fpm_state_wide, replace

	*JOIN ALL PAIRS

	use fpm_state_wide, clear

	foreach v of varlist FPid firm_id Sales_* shipcost* av_Sales* linear_distance* ref_flag* {
		rename `v' r_`v'
	}

	keep state_abv year month r_*

	save rdat, replace

	use fpm_state_wide, clear
	drop if Sales_A_T == 0 & Sales_A_TP == 0 
	drop shipcost* linear_distance* ref_flag*

	joinby state_abv year month using rdat

	drop if FPid == r_FPid
	
	reshape long Sales_A Sales_W av_Sales_A av_Sales_W r_av_Sales_A r_av_Sales_W r_Sales_A r_Sales_W ///
		r_shipcost r_linear_distance r_ref_flag, ///
		i(FPid r_FPid state_abv year month) j(prod) str
	di _N
	
	save tempdat, replace
	
	use tempdat, clear
	
	local stype A 
	foreach v in Sales av_Sales r_Sales r_av_Sales {
		rename `v'_`stype' `v'
		drop `v'_*
	}
	drop if Sales == 0 	
	di _N
	save "$generated_dir/all_pairs_instate_long_`stype'", replace
	
	use tempdat, clear
	local stype W
	foreach v in Sales av_Sales r_Sales r_av_Sales {
		rename `v'_`stype' `v'
		drop `v'_*
	}
	drop if Sales == 0 	
	di _N
	save "$generated_dir/all_pairs_instate_long_`stype'", replace
	
