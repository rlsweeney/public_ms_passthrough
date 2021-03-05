/***********************
This file creates summary tables and figures related to a carbon tax
***********************/
*******************************************************************************
** PREDICT CHANGES
*******************************************************************************
********************************************************************************
* OLS REGS
********************************************************************************

foreach it_p in $prodlist {
	use tempregdat, clear
	keep if prod == "_`it_p'" 
qui{
	estimates use "${estoutdir}/mods_ols_`it_p'" , number(4)

	lincom Pcru + _Rival_Pcru + _NonRival_Pcru + brent_cru
	global tbeta = r(estimate)

	di $tbeta

	predict	p_est

	replace Pcru = Pcru + av_tax

	predict	p_tax_own

	gen pt_tax_own = p_tax_own - p_est

	gen pt_margin_own = pt_tax_own - av_tax

	replace _Rival_Pcru = _Rival_Pcru + _Rival_av_tax

	replace _NonRival_Pcru = _NonRival_Pcru + _NonRival_av_tax

	capture drop te
	gen te = av_tax if year > 2010 & av_tax != .
	egen mean_tax = mean(te) 

	replace brent_cru = brent_cru + mean_tax

	predict	p_tax

	gen pt_tax = p_tax - p_est

	gen pt_margin = pt_tax - av_tax

	gen p_tot = p_est + ($tbeta)*av_tax 

	gen pt_margin_tot = p_tot - p_est - av_tax

	save estdat, replace

	use estdat, clear
	keep if av_tax != . & year > 2010
}
	sum pt*, detail
qui{
	kdensity pt_margin if av_tax != .,  title("Markup change under $40 CO2 Tax") xtitle("Price - Tax ($/gal)") ///
		lwidth(medthick) lcolor(blue)
		
	graph export "${figoutdir}/co2_tax_mu_change_kdensity_`it_p'.eps" ,  replace	


	sum pt_margin_tot
	local av_margin = r(mean)

	twoway (kdensity pt_margin_own, legend(lab(1 "Firm PT")) lwidth(medthick)  lcolor(red) ) ///
		(kdensity pt_margin if av_tax != . , legend(lab(2 "Full PT")) lwidth(medthick) lcolor(blue) ///
		xline(`av_margin', lpattern(-) lcolor(blue)) lwidth(medthick)) , ///
		title("Markup change distribution under $40 CO2 Tax") xtitle("Price - Tax ($/gal)")  xlabel(-.04(.02).02) 

	graph export "${figoutdir}/co2_tax_mu_change_kdensity_own_`it_p'.eps" ,  replace	
}
}
graph close 
exit
