* ASSEMBLE TABLE COMPARING FIXED EFFECTS 

clear  
eststo clear 
estimates clear

local it_mod "${Testdir}/mods_simple_MoS" 
estimates describe using  "`it_mod'"
estimates use "`it_mod'", number(${Tpnum})
	qui: estimates replay
	estimates store M_MoS


local it_mod "${Testdir}/mods_simple_StMoS" 
estimates describe using  "`it_mod'"
estimates use "`it_mod'", number(${Tpnum})
	qui: estimates replay
	estimates store M_StMoS

*BRING IN RIVALS 
local it_mod "${Testdir}/Rship/st/mods_ols_${Tprod}" 

	estimates describe using  "`it_mod'"
	local nmods `r(nestresults)'

	forval i = 1/`nmods' {
		estimates use "`it_mod'", number(`i')
		qui: estimates replay
		estimates store M_R`i'
	}

*NOT INCLUDING IV IN FIRST TABLE
esttab M_*, keep(*cru*) replace label ///
	se starlevels(* 0.10 ** 0.05 *** 0.01)  compress ///
	stat(timefes N r2, label("Time FE")) nomtitles nonotes ///
	coeflabels(Pcru "Own" _Rival_Pcru "Rival" _NonRival_Pcru "Fringe" brent_cru "Brent Spot") ///
	title("`it_title'")

esttab M_* using "${outdir}/${outprefix}StateLevelFEComp.tex", keep(*cru*) replace label ///
	se starlevels(* 0.10 ** 0.05 *** 0.01)  compress booktabs  ///
	stat(timefes N r2, label("Time FE")) nomtitles nonotes ///
	coeflabels(Pcru "Own" _Rival_Pcru "Rival" _NonRival_Pcru "Fringe" brent_cru "Brent Spot") 
