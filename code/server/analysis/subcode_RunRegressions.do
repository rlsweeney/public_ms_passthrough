/* SUBCODE THAT DOES ALL OLS and IV REGS for a given definition of RivalDefs
*/

* SET COMMON REGRESSION PARAMETERS 
global xvars  _X_CDD _X_HDD _X_income_pc _X_log_pop  ///
	frac_resale nrefs api_gravity share_ds shipcost frac_light

********************************************************************************
* OLS REGS
********************************************************************************


global prodlist T TP G D O

foreach p in $prodlist {
	global prodlabel `p'
	
	use tempregdat, clear
	keep if prod == "_${prodlabel}" 

	qui{

	eststo clear
	estimates clear

	local mlabel "MoS_Rival"
	eststo : reghdfe Price Pcru _Rival_Pcru $xvars , ///
		absorb(i.year#i.month i.fevar) cluster(fevar)
	estadd local timefes "MoS", replace
	estadd local product "${prodlabel}", replace
	estadd local modlabel "`mlabel'", replace
	estadd local rivallabel "${rlabel}", replace

	estimates save "${estoutdir}/mods_ols_${prodlabel}", replace

	local mlabel "Mos_NonRival"
	eststo : reghdfe Price Pcru _Rival_Pcru _NonRival_Pcru $xvars, ///
		absorb(i.year#i.month i.fevar) cluster(fevar)
	estadd local timefes "MoS", replace
	estadd local product "${prodlabel}", replace
	estadd local modlabel "`mlabel'", replace
	estadd local rivallabel "${rlabel}", replace

	estimates save "${estoutdir}/mods_ols_${prodlabel}", append

	local mlabel "YM_NonRival"
	eststo : reghdfe Price Pcru _Rival_Pcru _NonRival_Pcru $xvars, ///
		absorb(i.year i.month i.fevar) cluster(fevar)
	estadd local timefes "Y,M", replace
	estadd local product "${prodlabel}", replace
	estadd local modlabel "`mlabel'", replace

	estimates save "${estoutdir}/mods_ols_${prodlabel}", append

	local mlabel "YM_Brent"
	eststo : reghdfe Price Pcru _Rival_Pcru _NonRival_Pcru brent_cru $xvars, ///
		absorb(i.year i.month i.fevar) cluster(fevar)
	estadd local timefes "Y,M", replace
	estadd local product "${prodlabel}", replace
	estadd local modlabel "`mlabel'", replace
	estadd local rivallabel "${rlabel}", replace

	estimates save "${estoutdir}/mods_ols_${prodlabel}", append
	}

	estimates describe using "${estoutdir}/mods_ols_${prodlabel}" 
	local nmods `r(nestresults)'
	di "`nmods'"
	clear  
	eststo clear
	*eststo clear M_*
	estimates clear

	forval i = 1/`nmods' {
		estimates use "${estoutdir}/mods_ols_${prodlabel}" , number(`i')
		*estimates replay
		estimates store M_`i'
	}

	esttab M_*, keep(*cru*) replace label ///
		 se starlevels(* 0.10 ** 0.05 *** 0.01)  compress ///
		 stat(rivallabel product timefes N r2, label("Rival" "Product" "TimeFes")) nomtitles nonotes ///
		 coeflabels(Pcru "Own" _Rival_Pcru "Rival" _NonRival_Pcru "NonRival" brent_cru "Brent Spot") ///
		 title("OLS Results: Product = ${prodlabel}")
}
	
*********** IV REGS ************************************

* DEFINE PROGRAMS TO STORE FIRST STAGE INFO AND RUN IV
capture program drop saveffirst
program define saveffirst 
	local itmod "`e(modlabel)'"
	di "`itmod'"
	forval i = 1/3 {
		estimates restore reghdfe_first`i' 
		estadd local firstmodel = `i'
		estadd local timefes "Y,M", replace
		estadd local IVstage "1", replace
		estadd local product "${prodlabel}", replace
		estadd local modlabel "`itmod'", replace
		estadd local rivallabel "${rlabel}", replace
		estadd local IVvars "${ivlabel}", replace
		
		estimates save "${estoutdir}/mods_${prodlabel}_iv_${ivlabel}", append
	}
end

capture program drop runIV
program define runIV
	qui{
	estimates clear 
	eststo clear 

	local mlabel "IV_Mos_NonRival"
	eststo : reghdfe Price $xvars ///
		(Pcru _Rival_Pcru _NonRival_Pcru = $ivvars )  , ///
		absorb(i.year#i.month i.fevar) cluster(fevar) ivsuite(ivreg2) ffirst stages(first)
	local tF = round(e(cdf))
	estadd local fstat = `tF'
	estadd local timefes "MoS", replace
	estadd local product "${prodlabel}", replace
	estadd local modlabel "`mlabel'", replace
	estadd local endog "both", replace
	estadd local IV "Yes", replace
	estadd local IVstage "2", replace
	estadd local IVvars "${ivlabel}", replace
	estadd local rivallabel "${rlabel}", replace

	estimates save "${estoutdir}/mods_${prodlabel}_iv_${ivlabel}", replace


	saveffirst


	local mlabel "IV_YM_Brent"
	eststo : reghdfe Price brent_cru $xvars ///
		(Pcru _Rival_Pcru _NonRival_Pcru = $ivvars )  , ///
		absorb(i.year i.month i.fevar) cluster(fevar) ivsuite(ivreg2) ffirst stages(first)
	local tF = round(e(cdf))
	estadd local fstat = `tF'
	estadd local timefes "Y,M", replace
	estadd local product "${prodlabel}", replace
	estadd local modlabel "`mlabel'", replace
	estadd local endog "both", replace
	estadd local IV "Yes", replace
	estadd local IVstage "2", replace
	estadd local IVvars "${ivlabel}", replace
	estadd local rivallabel "${rlabel}", replace
	
	estimates save "${estoutdir}/mods_${prodlabel}_iv_${ivlabel}", append

	saveffirst

	*Print second stage 
	estimates describe using "${estoutdir}/mods_${prodlabel}_iv_${ivlabel}" 
	local nmods `r(nestresults)'
	
	clear  
	eststo clear
	estimates clear

	forval i = 1/`nmods' {
		estimates use "${estoutdir}/mods_${prodlabel}_iv_${ivlabel}" , number(`i')
		*di "`e(IVstage)'"
		if `e(IVstage)' == 2 {
			qui: estimates replay
			estimates store M_`i'
		}
	}

	}

	esttab M_*, keep(*cru*) replace label ///
		 se starlevels(* 0.10 ** 0.05 *** 0.01)  compress ///
		 stat(rivallabel product timefes fstat N r2, label("Rival" "Product" "TimeFes" "fstat")) nomtitles nonotes ///
		 coeflabels(Pcru "Own" _Rival_Pcru "Rival" _NonRival_Pcru "NonRival" brent_cru "Brent Spot") ///
		 title("IV Results: Product = ${prodlabel}; IV = ${ivlabel}")

end

*++++++++++++++++++++++++++++++++++++++++++++++++++
*IV SPEC: avd domestic and api first purchase price

global subivlist Z_PapiAvg Z_avg_dom 
global ivlabel old_ivs

foreach p in $prodlist {
	global prodlabel `p'
	
	use tempregdat, clear
	keep if prod == "_${prodlabel}" 

	global ivvars $subivlist
	foreach v of varlist $subivlist {
		global ivvars $ivvars _Rival_`v' _NonRival_`v'
	}

	runIV 
}

*++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
*IV SPEC: weighted API index price and interaction wiht average share of downstream capacity

global subivlist Z_PapiAvg Z_PapiDSAvg 
global ivlabel Papi_DS

foreach p in $prodlist {
	global prodlabel `p'
	
	use tempregdat, clear
	keep if prod == "_${prodlabel}" 

	global ivvars $subivlist
	foreach v of varlist $subivlist {
		global ivvars $ivvars _Rival_`v' _NonRival_`v'
	}

	runIV 
}

*++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
*IV SPEC: Estimated crude price with fixed coefficients 

global subivlist Z_EstPcru
global ivlabel EstPcru

foreach p in $prodlist {
	global prodlabel `p'
	
	use tempregdat, clear
	keep if prod == "_${prodlabel}" 

	global ivvars $subivlist
	foreach v of varlist $subivlist {
		global ivvars $ivvars _Rival_`v' _NonRival_`v'
	}

	runIV 
}

*++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
*IV SPEC: Estimated crude price with firm-specific coefficients 

global subivlist Z_EstPcru_hd
global ivlabel EstPcru_hd

foreach p in $prodlist {
	global prodlabel `p'
	
	use tempregdat, clear
	keep if prod == "_${prodlabel}" 

	global ivvars $subivlist
	foreach v of varlist $subivlist {
		global ivvars $ivvars _Rival_`v' _NonRival_`v'
	}

	runIV 
}


*++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
*IV SPEC: Papi_DS plus interactions for Padd's 2 and 4 

global subivlist Z_PapiAvg Z_PapiDSAvg Z_P24_DScap_HL Z_P24_US
global ivlabel Papi_DS_P24

foreach p in $prodlist {
	global prodlabel `p'
	
	use tempregdat, clear
	keep if prod == "_${prodlabel}" 

	global ivvars $subivlist
	foreach v of varlist $subivlist {
		global ivvars $ivvars _Rival_`v' _NonRival_`v'
	}

	runIV 
}



*+++++++++++++++++  PRINT TO SCREEN 
clear  
eststo clear
*eststo clear M_*
estimates clear

foreach p in $prodlist {
	global prodlabel `p'
	
	global ivlabel Papi_DS_P24

	estimates describe using "${estoutdir}/mods_ols_${prodlabel}" 
		local nmods `r(nestresults)'
		di "`nmods'"
		clear  
		eststo clear
		*eststo clear M_*
		estimates clear

		forval i = 1/`nmods' {
			estimates use "${estoutdir}/mods_ols_${prodlabel}" , number(`i')
			*estimates replay
			estimates store O_`i'
		}

	*Print second stage 
	estimates describe using "${estoutdir}/mods_${prodlabel}_iv_${ivlabel}" 
	local nmods `r(nestresults)'

	forval i = 1/`nmods' {
		estimates use "${estoutdir}/mods_${prodlabel}_iv_${ivlabel}" , number(`i')
		*di "`e(IVstage)'"
		if `e(IVstage)' == 2 {
			qui: estimates replay
			estimates store I_`i'
		}
	}

	esttab O_* I_*, keep(*cru*) replace label ///
		 se starlevels(* 0.10 ** 0.05 *** 0.01)  compress ///
		 stat(rivallabel product timefes IV fstat N r2, label("Rival" "Product" "TimeFes" "IV" "fstat")) nomtitles nonotes ///
		 coeflabels(Pcru "Own" _Rival_Pcru "Rival" _NonRival_Pcru "NonRival" brent_cru "Brent Spot") ///
		 title("Main Results: Rival Def = ${rlabel}; Product = ${prodlabel}; IV = ${ivlabel}")
}

exit
