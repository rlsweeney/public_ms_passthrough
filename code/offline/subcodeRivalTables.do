* ASSEMBLE TABLES THAT COMPARE DIFFERENT RIVAL COST SPECS

eststo clear 
estimates clear
	
qui{
foreach it_market in fp st {
foreach it_rlabel in $Trivals {
	setCompLables "`it_rlabel'"
	local cleanLabel = "`r(pass)'"

	if "`it_rlabel'" == "Rship" | "`it_rlabel'" == "Rdist" {
		* GET OLS RESULTS

		estimates use "${Testdir}/`it_rlabel'/`it_market'/mods_ols_${Tprod}", number(1)
			qui: estimates replay
			estadd local rlab "`cleanLabell'"
			estimates store `it_market'MoS_O_`cleanLabel'
		estimates use "${Testdir}/`it_rlabel'/`it_market'/mods_ols_${Tprod}", number(3)
			qui: estimates replay
			estadd local rlab "`cleanLabel'"
			estimates store `it_market'YM_O_`cleanLabel'

		*GET IV RESULTS - SECOND STAGE

		estimates use "${Testdir}/`it_rlabel'/`it_market'/mods_${Tprod}_iv_${main_iv}", number(1)
			qui: estimates replay
			estadd local rlab "`cleanLabel'"
				estimates store `it_market'MoS_I_`cleanLabel'

		estimates use "${Testdir}/`it_rlabel'/`it_market'/mods_${Tprod}_iv_${main_iv}", number(4)
			qui: estimates replay
			estadd local rlab "`cleanLabel'"
				estimates store `it_market'YM_I_`cleanLabel'
				
		*GET IV RESULTS - FIRST STAGE

		estimates use "${Testdir}/`it_rlabel'/`it_market'/mods_${Tprod}_iv_${main_iv}", number(2)
			qui: estimates replay
			estadd local rlab "`cleanLabel'"
			estadd local dv "Own"
				estimates store `it_market'MoS_FOwn_`cleanLabel'
		
		estimates use "${Testdir}/`it_rlabel'/`it_market'/mods_${Tprod}_iv_${main_iv}", number(3)
			qui: estimates replay
			estadd local rlab "`cleanLabel'"
			estadd local dv "Rival"
				estimates store `it_market'MoS_FRival_`cleanLabel'

		estimates use "${Testdir}/`it_rlabel'/`it_market'/mods_${Tprod}_iv_${main_iv}", number(5)
			qui: estimates replay
			estadd local rlab "`cleanLabel'"
			estadd local dv "Own"
				estimates store `it_market'YM_FOwn_`cleanLabel'
		
		estimates use "${Testdir}/`it_rlabel'/`it_market'/mods_${Tprod}_iv_${main_iv}", number(6)
			qui: estimates replay
			estadd local rlab "`cleanLabel'"
			estadd local dv "Rival"
				estimates store `it_market'YM_FRival_`cleanLabel'
	}		
			
	else{
		*FOR THESE RUNS, FIRST OLS MODEL JUST INCLUDES RIVAL (SO START AT NUMBER(2))
		* GET OLS RESULTS

		estimates use "${Testdir}/`it_rlabel'/`it_market'/mods_ols_${Tprod}", number(2)
			qui: estimates replay
			estadd local rlab "`cleanLabel'"
			estimates store `it_market'MoS_O_`cleanLabel'
		estimates use "${Testdir}/`it_rlabel'/`it_market'/mods_ols_${Tprod}", number(4)
			qui: estimates replay
			estadd local rlab "`cleanLabel'"
			estimates store `it_market'YM_O_`cleanLabel'

		*GET IV RESULTS - SECOND STAGE 

		estimates use "${Testdir}/`it_rlabel'/`it_market'/mods_${Tprod}_iv_${main_iv}", number(1)
			qui: estimates replay
			estadd local rlab "`cleanLabel'"
				estimates store `it_market'MoS_I_`cleanLabel'

		estimates use "${Testdir}/`it_rlabel'/`it_market'/mods_${Tprod}_iv_${main_iv}", number(5)
			qui: estimates replay
			estadd local rlab "`cleanLabel'"
				estimates store `it_market'YM_I_`cleanLabel'
	
		*GET IV RESULTS - FIRST STAGE

		estimates use "${Testdir}/`it_rlabel'/`it_market'/mods_${Tprod}_iv_${main_iv}", number(2)
			qui: estimates replay
			estadd local rlab "`cleanLabel'"
			estadd local dv "Own"
				estimates store `it_market'MoS_FOwn_`cleanLabel'
		
		estimates use "${Testdir}/`it_rlabel'/`it_market'/mods_${Tprod}_iv_${main_iv}", number(3)
			qui: estimates replay
			estadd local rlab "`cleanLabel'"
			estadd local dv "Rival"
				estimates store `it_market'MoS_FRival_`cleanLabel'
		
		estimates use "${Testdir}/`it_rlabel'/`it_market'/mods_${Tprod}_iv_${main_iv}", number(4)
			qui: estimates replay
			estadd local rlab "`cleanLabel'"
			estadd local dv "Fringe"
				estimates store `it_market'MoS_FFringe_`cleanLabel'
				
		estimates use "${Testdir}/`it_rlabel'/`it_market'/mods_${Tprod}_iv_${main_iv}", number(6)
			qui: estimates replay
			estadd local rlab "`cleanLabel'"
			estadd local dv "Own"
				estimates store `it_market'YM_FOwn_`cleanLabel'
		
		estimates use "${Testdir}/`it_rlabel'/`it_market'/mods_${Tprod}_iv_${main_iv}", number(7)
			qui: estimates replay
			estadd local rlab "`cleanLabel'"
			estadd local dv "Rival"
				estimates store `it_market'YM_FRival_`cleanLabel'
		
		estimates use "${Testdir}/`it_rlabel'/`it_market'/mods_${Tprod}_iv_${main_iv}", number(8)
			qui: estimates replay
			estadd local rlab "`cleanLabel'"
			estadd local dv "Fringe"
				estimates store `it_market'YM_FFringe_`cleanLabel'	
	}
}
}
}

esttab stYM_O_* stYM_I_*, keep(*cru*) replace label ///
	order(Pcru _Rival_Pcru _NonRival_Pcru brent_cru) ///
	se starlevels(* 0.10 ** 0.05 *** 0.01)  compress ///
	stat(rlab product timefes IV fstat N r2, label("Rival Def" "Product" "Time FE" "IV" "fstat")) nomtitles nonotes ///
	coeflabels(Pcru "Own" _Rival_Pcru "Rival" _NonRival_Pcru "Fringe" brent_cru "Brent Spot") ///
	title("`it_title'")
		
esttab stYM_O_* stYM_I_* using "${outdir}/${outprefix}RivalComp_YM_st.tex", booktabs ///
	keep(*cru*) replace label ///
	order(Pcru _Rival_Pcru _NonRival_Pcru brent_cru) ///
	se starlevels(* 0.10 ** 0.05 *** 0.01)  compress ///
	stat(rlab IV fstat N, label("Rival Measure" "IV" "fstat")) nomtitles nonotes ///
	coeflabels(Pcru "Own" _Rival_Pcru "Rival" _NonRival_Pcru "Fringe" brent_cru "Brent Spot")

esttab stYM_F*, keep(*Z_*) replace label ///
	order(Pcru _Rival_Pcru _NonRival_Pcru brent_cru) ///
	se starlevels(* 0.10 ** 0.05 *** 0.01)  compress ///
	stat(rlab dv N r2, label("Rival Measure" "Endogenous Var")) nomtitles nonotes ///
	coeflabels(Z_PapiAvg "Own: API" Z_PapiDSAvg "Own: API-Downstream" ///
						Z_P24_DScap_HL "Own: PADD 2,4-HL" Z_P24_US "Own: PADD 2,4-WTI" /// 
				_Rival_Z_PapiAvg "Rival: API" _Rival_Z_PapiDSAvg "Rival: API-Downstream" ///
					_Rival_Z_P24_DScap_HL "Rival: PADD 2,4-HL" _Rival_Z_P24_US "Rival: PADD 2,4-WTI" ///
				_NonRival_Z_PapiAvg "Fringe: API" _NonRival_Z_PapiDSAvg "Fringe: API-Downstream" ///
					_NonRival_Z_P24_DScap_HL "Fringe: PADD 2,4-HL" _NonRival_Z_P24_US "Fringe: PADD 2,4-WTI")

esttab stYM_F*  using "${outdir}/${outprefix}IVFirstStage_YM_st.tex", booktabs ///
	keep(*Z_*) replace label ///
	order(Pcru _Rival_Pcru _NonRival_Pcru brent_cru) ///
	se starlevels(* 0.10 ** 0.05 *** 0.01)  compress ///
	stat(rlab dv N r2, label("Rival Measure" "Endogenous Var")) nomtitles nonotes ///
	coeflabels(Z_PapiAvg "Own: API" Z_PapiDSAvg "Own: API-Downstream" ///
						Z_P24_DScap_HL "Own: PADD 2,4-HL" Z_P24_US "Own: PADD 2,4-WTI" /// 
				_Rival_Z_PapiAvg "Rival: API" _Rival_Z_PapiDSAvg "Rival: API-Downstream" ///
					_Rival_Z_P24_DScap_HL "Rival: PADD 2,4-HL" _Rival_Z_P24_US "Rival: PADD 2,4-WTI" ///
				_NonRival_Z_PapiAvg "Fringe: API" _NonRival_Z_PapiDSAvg "Fringe: API-Downstream" ///
					_NonRival_Z_P24_DScap_HL "Fringe: PADD 2,4-HL" _NonRival_Z_P24_US "Fringe: PADD 2,4-WTI")  
					
esttab fpYM_O_* fpYM_I_*, keep(*cru*) replace label ///
	order(Pcru _Rival_Pcru _NonRival_Pcru brent_cru) ///
	se starlevels(* 0.10 ** 0.05 *** 0.01)  compress ///
	stat(rlab product timefes IV fstat N, label("Rival Measure" "Product" "TimeFes" "IV" "First-stage F")) nomtitles nonotes ///
	coeflabels(Pcru "Own" _Rival_Pcru "Rival" _NonRival_Pcru "Fringe" brent_cru "Brent Spot") ///
	title("`it_title'")

		
esttab fpYM_O_* fpYM_I_* using "${outdir}/${outprefix}RivalComp_YM_fp.tex", booktabs ///
	keep(*cru*) replace label ///
	order(Pcru _Rival_Pcru _NonRival_Pcru brent_cru) ///
	se starlevels(* 0.10 ** 0.05 *** 0.01)  compress ///
	stat(rlab IV fstat N, label("Rival Measure" "IV" "First-stage F")) nomtitles nonotes ///
	coeflabels(Pcru "Own" _Rival_Pcru "Rival" _NonRival_Pcru "Fringe" brent_cru "Brent Spot") 
		
esttab fpYM_F*  using "${outdir}/${outprefix}IVFirstStage_YM_fp.tex", booktabs ///
	keep(*Z_*) replace label ///
	order(Pcru _Rival_Pcru _NonRival_Pcru brent_cru) ///
	se starlevels(* 0.10 ** 0.05 *** 0.01)  compress ///
	stat(rlab dv N r2, label("Rival Measure" "Endogenous Var")) nomtitles nonotes ///
	coeflabels(Z_PapiAvg "Own: API" Z_PapiDSAvg "Own: API-Downstream" ///
						Z_P24_DScap_HL "Own: PADD 2,4-HL" Z_P24_US "Own: PADD 2,4-WTI" /// 
				_Rival_Z_PapiAvg "Rival: API" _Rival_Z_PapiDSAvg "Rival: API-Downstream" ///
					_Rival_Z_P24_DScap_HL "Rival: PADD 2,4-HL" _Rival_Z_P24_US "Rival: PADD 2,4-WTI" ///
				_NonRival_Z_PapiAvg "Fringe: API" _NonRival_Z_PapiDSAvg "Fringe: API-Downstream" ///
					_NonRival_Z_P24_DScap_HL "Fringe: PADD 2,4-HL" _NonRival_Z_P24_US "Fringe: PADD 2,4-WTI") 
