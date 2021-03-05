* ASSEMBLE HETEROGENEITY TABLES 

foreach it_market in fp st {
	local it_estdir "${Testdir}/${Trlabel}/`it_market'"

eststo clear 
estimates clear
		
if "${Trlabel}" == "Rship" | "${Trlabel}" == "Rdist" {
qui{	
	foreach it_hetero in $list_hetero {
			
		setIntLables "`it_hetero'"
		local cleanIntLabel = "`r(pass)'"
		
			* GET OLS RESULTS
			estimates use "`it_estdir'/Int_`it_hetero'/mods_ols_${Tprod}", number(1)
				qui: estimates replay
				estadd local hlab "`cleanIntLabel'"
				estimates store MoS_O_`it_hetero'

			estimates use "`it_estdir'/Int_`it_hetero'/mods_ols_${Tprod}", number(2)
				qui: estimates replay
				estadd local hlab "`cleanIntLabel'"
				estimates store YM_O_`it_hetero'			

			*GET IV RESULTS
			
			estimates use "`it_estdir'/Int_`it_hetero'/mods_${Tprod}_iv_${main_iv}", number(1)
				qui: estimates replay
				estadd local hlab "`cleanIntLabel'"
				estimates store MoS_I_`it_hetero'
			
			estimates use "`it_estdir'/Int_`it_hetero'/mods_${Tprod}_iv_${main_iv}", number(6)
				qui: estimates replay
				estadd local hlab "`cleanIntLabel'"
				estimates store YM_I_`it_hetero'
	}
}

	*EXPORT OLS and IV RESULTS in ONE TABLE
	
	esttab YM_O_* YM_I_*, keep(*cru*) replace label ///
		se starlevels(* 0.10 ** 0.05 *** 0.01)  compress ///
		stat(hlab timefes IV fstat N, label("Interaction" "Time FE" "IV" "fstat")) nomtitles nonotes ///
		coeflabels(Pcru "Own" _Rival_Pcru "Rival" brent_cru "Brent Spot" /// 
					IntPcru "Own X Int" Int_Rival_Pcru "Rival X Int")  ///
		order(Pcru IntPcru _Rival_Pcru Int_Rival_Pcru) 

	esttab YM_O_* YM_I_* using "${outdir}/HeterogeneityYM_`it_market'.tex", booktabs /// 
	keep(*cru*) replace label ///
	se starlevels(* 0.10 ** 0.05 *** 0.01)  compress ///
	stat(hlab timefes IV fstat N, label("Interaction" "Time FE" "IV" "fstat")) nomtitles nonotes ///
	coeflabels(Pcru "Own" _Rival_Pcru "Rival" brent_cru "Brent Spot" /// 
				IntPcru "Own X Int" Int_Rival_Pcru "Rival X Int")  ///
	order(Pcru IntPcru _Rival_Pcru Int_Rival_Pcru) 
	
}
else {
qui{	
	foreach it_hetero in $list_hetero {
			
		setIntLables "`it_hetero'"
		local cleanIntLabel = "`r(pass)'"

		* GET OLS RESULTS
		estimates use "`it_estdir'/Int_`it_hetero'/mods_ols_${Tprod}", number(1)
			qui: estimates replay
			estadd local hlab "`cleanIntLabel'"
			estimates store MoS_O_`it_hetero'

		estimates use "`it_estdir'/Int_`it_hetero'/mods_ols_${Tprod}", number(2)
			qui: estimates replay
			estadd local hlab "`cleanIntLabel'"
			estimates store YM_O_`it_hetero'			

		*GET IV RESULTS
		
		estimates use "`it_estdir'/Int_`it_hetero'/mods_${Tprod}_iv_${main_iv}", number(1)
			qui: estimates replay
			estadd local hlab "`cleanIntLabel'"
			estimates store MoS_I_`it_hetero'
		
		estimates use "`it_estdir'/Int_`it_hetero'/mods_${Tprod}_iv_${main_iv}", number(8)
			qui: estimates replay
			estadd local hlab "`cleanIntLabel'"
			estimates store YM_I_`it_hetero'

	}

	*EXPORT OLS and IV RESULTS in ONE TABLE
	
	esttab YM_O_* YM_I_*, keep(*cru*) replace label ///
		se starlevels(* 0.10 ** 0.05 *** 0.01)  compress ///
		stat(hlab timefes IV fstat N, label("Interaction" "Time FE" "IV" "fstat")) nomtitles nonotes ///
		coeflabels(Pcru "Own" _Rival_Pcru "Rival" _NonRival_Pcru "Fringe" brent_cru "Brent Spot" /// 
					IntPcru "Own X Int" Int_Rival_Pcru "Rival X Int" Int_NonRival_Pcru "Fringe X Int" )  ///
		order(Pcru IntPcru _Rival_Pcru Int_Rival_Pcru _NonRival_Pcru Int_NonRival_Pcru) 
		
	esttab YM_O_* YM_I_* using "${outdir}/${outprefix}HeterogeneityYM_`it_market'.tex", booktabs /// 
	keep(*cru*) replace label ///
	se starlevels(* 0.10 ** 0.05 *** 0.01)  compress ///
	stat(hlab timefes IV fstat N, label("Interaction" "Time FE" "IV" "fstat")) nomtitles nonotes ///
	coeflabels(Pcru "Own" _Rival_Pcru "Rival" _NonRival_Pcru "Fringe" brent_cru "Brent Spot" /// 
					IntPcru "Own X Int" Int_Rival_Pcru "Rival X Int" Int_NonRival_Pcru "Fringe X Int" )  ///
	order(Pcru IntPcru _Rival_Pcru Int_Rival_Pcru _NonRival_Pcru Int_NonRival_Pcru) 
}
}
}
