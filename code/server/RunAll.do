/***********************
This file runs everything in order
***********************/
clear
*global repodir "/home/sweeneri/ms_pt_clean"

*do "$repodir/code/setup.do" // manually run this file first 
*set working directory
cd "$repodir/temp"

********************************************************************************
* BUILD FILES  
********************************************************************************

* COMMON BUILD FILES
do "$repodir/code/common_build/master_common_build.do" 

* BUILD FILES 
do "$repodir/code/build/get_deflator.do" 
do "$repodir/code/build/prep_sales_data.do" 
do "$repodir/code/build/prep_crudeprice_data.do" 
do "$repodir/code/build/RefineryPrep.do" 
do "$repodir/code/build/CombineFPRefCrudeData.do"  
do "$repodir/code/build/Map2Markets_All.do"  

* GET RIVAL SAMPLES BY CHANNEL 
do "$repodir/code/analysis/subcode_GetRivalSamples.do" 

* RUN CHANNEL - SPECIFIC BUILD FILES
** WHOLESALE SALES
global sampledir_channel "$generated_dir/wholesale" 
shell mkdir -p "${sampledir_channel}"
global stype W

*** CONSTRUCT RIVAL VARS
do "$repodir/code/analysis/subcode_ConstructRivalVars.do"

** ALL SALES
global sampledir_channel "$generated_dir/total" 
shell mkdir -p "${sampledir_channel}"
global stype A

*** CONSTRUCT RIVAL VARS
do "$repodir/code/analysis/subcode_ConstructRivalVars.do"

* SETUP REGDATA
do "$repodir/code/analysis/subcode_SetupRegdata.do"

* MAKE SUMMARY TABS AND FIGS 
do "$repodir/code/analysis/SumTabsFigs_common.do"

********************************************************************************
* ANALYSIS FILES

/*NOTES 
- I DEFINE FOUR TYPES OF REGRESSIONS: NONRIVALS ARE SEPARATE OR NOT, AND WHETHER THOSE EFFECTS ARE INTERACTED WITH OTHER REFINERY CHARACTERISTICS. 
- THE PROGRAMS BELOW SPECIFIC CALLS TO SUBCODE WHICH EXECUTES ONE SET OF THESE REGRESSIONS. 
- THE BLOCKED CODE BELOW THAT LOOPS THROUGH DIFFERENT SAMPLES AND OUTCOME MEASURES AND CALLS THESE PROGRAMS. 
*/
********************************************************************************

/*************** DEFINE PROGRAMS ***************
- "FP" STANDS FOR FIRM-PADD REGS. "ST" STANDS FOR STATE LEVEL. 
*/

** NONRIVAL REGS
capture program drop runregs_2D 
program define runregs_2D 
	global estoutdir "${sampledir_estimates}/${rlabel}/fp" 
	shell mkdir -p "${estoutdir}"

	* FP REG SETUP
		use tempregdat_fp, clear
		do "${sampledir_regsample}/subcode_samplerestrict_fp.do"
		do "${repodir}/code/analysis/subcode_GetInstruments"
		save tempregdat, replace

		do "$repodir/code/analysis/subcode_RunRegressions.do"
		
		** get CO2 
		global figoutdir "${sampledir_figures}/${rlabel}/fp" 
		shell mkdir -p "${figoutdir}"
		
		do "$repodir/code/analysis/co2_tax_analysis.do"

	* ST REG SETUP
		global estoutdir "${sampledir_estimates}/${rlabel}/st" 
		shell mkdir -p "${estoutdir}"

		use tempregdat_st, clear
		do "${sampledir_regsample}/subcode_samplerestrict_st.do"
		do "${repodir}/code/analysis/subcode_GetInstruments"
		save tempregdat, replace

		do "$repodir/code/analysis/subcode_RunRegressions.do"

		** get CO2 
		global figoutdir "${sampledir_figures}/${rlabel}/st" 
		shell mkdir -p "${figoutdir}"
		
		do "$repodir/code/analysis/co2_tax_analysis.do"

end

** RIVAL ONLY REGS
capture program drop runregs_1D  
program define runregs_1D 
	* FP REG SETUP
		global estoutdir "${sampledir_estimates}/${rlabel}/fp" 
		shell mkdir -p "${estoutdir}"


		use tempregdat_fp, clear
		do "${sampledir_regsample}/subcode_samplerestrict_fp.do"
		do "${repodir}/code/analysis/subcode_GetInstruments"
		save tempregdat, replace


		do "$repodir/code/analysis/subcode_RunInvRivalRegs.do"
		

	* ST REG SETUP
		global estoutdir "${sampledir_estimates}/${rlabel}/st" 
		shell mkdir -p "${estoutdir}"

		use tempregdat_st, clear
		do "${sampledir_regsample}/subcode_samplerestrict_st.do"
		do "${repodir}/code/analysis/subcode_GetInstruments"
		save tempregdat, replace


		do "$repodir/code/analysis/subcode_RunInvRivalRegs.do"	

end

************************
* NONRIVAL REGS WITH INTERACTIONS FOR HETEROGENEITY
capture program drop runinteractions_2D  
program define runinteractions_2D 
	* FP REG SETUP
		use tempregdat_fp, clear
		do "${sampledir_regsample}/subcode_samplerestrict_fp.do"
		do "${repodir}/code/analysis/subcode_GetInstruments"
		do "${repodir}/code/analysis/subcode_GetInteractions"
		save tempregdat_it, replace

		foreach it_int in ${intvar_list} {
			global intvar `it_int'
			global estoutdir "${sampledir_estimates}/${rlabel}/fp/Int_${intvar}" 
			shell mkdir -p "${estoutdir}"
			
			use tempregdat_it, clear
				foreach v of varlist Pcru Z* _Rival_* _NonRival_* {
					gen Int`v' = `v' * Intflag_${intvar}
				}
			save tempregdat, replace
			
			do "$repodir/code/analysis/subcode_Run2D_Interactions.do"
		}

	* ST REG SETUP
		use tempregdat_st, clear
		do "${sampledir_regsample}/subcode_samplerestrict_st.do"
		do "${repodir}/code/analysis/subcode_GetInstruments"
		do "${repodir}/code/analysis/subcode_GetInteractions"
		save tempregdat_it, replace

		foreach it_int in ${intvar_list} {
			global intvar `it_int'
			global estoutdir "${sampledir_estimates}/${rlabel}/st/Int_${intvar}" 
			shell mkdir -p "${estoutdir}"
			
			use tempregdat_it, clear
				foreach v of varlist Pcru Z* _Rival_* _NonRival_* {
					gen Int`v' = `v' * Intflag_${intvar}
				}
			save tempregdat, replace
			
			do "$repodir/code/analysis/subcode_Run2D_Interactions.do"
		}

end

************************
* RIVAL ONLY REGS WITH INTERACTIONS FOR HETEROGENEITY
capture program drop runinteractions_1D  
program define runinteractions_1D 
	* FP REG SETUP
		use tempregdat_fp, clear
		do "${sampledir_regsample}/subcode_samplerestrict_fp.do"
		do "${repodir}/code/analysis/subcode_GetInstruments"
		do "${repodir}/code/analysis/subcode_GetInteractions"
		save tempregdat_it, replace

		foreach it_int in ${intvar_list} {
			global intvar `it_int'
			global estoutdir "${sampledir_estimates}/${rlabel}/fp/Int_${intvar}" 
			shell mkdir -p "${estoutdir}"
			
			use tempregdat_it, clear
				foreach v of varlist Pcru Z* _Rival_* {
					gen Int`v' = `v' * Intflag_${intvar}
				}
			save tempregdat, replace
			
			do "$repodir/code/analysis/subcode_Run1D_Interactions.do"
		}

	* ST REG SETUP
		use tempregdat_st, clear
		do "${sampledir_regsample}/subcode_samplerestrict_st.do"
		do "${repodir}/code/analysis/subcode_GetInstruments"
		do "${repodir}/code/analysis/subcode_GetInteractions"
		save tempregdat_it, replace

		foreach it_int in ${intvar_list} {
			global intvar `it_int'
			global estoutdir "${sampledir_estimates}/${rlabel}/st/Int_${intvar}" 
			shell mkdir -p "${estoutdir}"
			
			use tempregdat_it, clear
				foreach v of varlist Pcru Z* _Rival_* {
					gen Int`v' = `v' * Intflag_${intvar}
				}
			save tempregdat, replace
			
			do "$repodir/code/analysis/subcode_Run1D_Interactions.do"
		}
end

************************************************************************
/* RUN ALL REGRESSIONS BY SAMPLE AND OUTCOME MEASURE */
************************************************************************

************************* MAIN SAMPLE **********************************
global regsample main
global sampledir_regsample "$repodir/code/analysis/samples/${regsample}" 

***************************
* WHOLESALE REGS
***************************
global sampledir_channel "${generated_dir}/wholesale" 
global sampledir_estimates "$outdir/estimates/samples/${regsample}/wholesale" 
global sampledir_figures "$outdir/figures/appendix/${regsample}/wholesale" 
global sampledir_tables "$outdir/tables/appendix/${regsample}/wholesale" 
global sample_stype W

shell mkdir -p "${sampledir_tables}"
shell mkdir -p "${sampledir_figures}"
shell mkdir -p "${sampledir_estimates}"

* GET SUMMARY TABS AND FIGS 
do "$repodir/code/analysis/SumTabsFigs_sample.do"

* RUN SIMPLE REGS
do "$repodir/code/analysis/subcode_RunSimpleRegs.do"

*++++++++++++++++++++++++++++++++++++++
* RUN 2D RIVAL REGS
global runlist R1av_Nshav R1_Nsh RQav_Nshav Rmaxav_Nsh R1avship_Nshav R1avdist_Ndistav R1ship_Nsh // description in subcode_ConstructRivalVars.do

global rvarlist Pcru Z_* tax_cpg av_tax

foreach rd in $runlist {
	do "$repodir/code/analysis/RivalDefs_`rd'.do"
	runregs_2D 
}

*++++++++++++++++++++++++++++++++++++++
* RUN 1D RIVAL REGS

foreach rd in Rdist Rship {
	do "$repodir/code/analysis/RivalDefs_`rd'.do"
	runregs_1D 
}

**+++++++++++++++++++++++++++++++++++++
* RUN HETEROGENEITY 
**+++++++++++++++++++++++++++++++++++++
global intvar_list totcap capPadd av_HHI capUS nfirmspc

*** 2D
foreach rd in $runlist {
	do "$repodir/code/analysis/RivalDefs_`rd'.do"
	runinteractions_2D 
}

*++++++++++++++++++++++++++++++++++++++
* RUN 1D RIVAL REGS

foreach rd in Rdist Rship {
	do "$repodir/code/analysis/RivalDefs_`rd'.do"
	runinteractions_1D
}

***************************
* TOTAL REGS
***************************
global sampledir_channel "${generated_dir}/total" 
global sampledir_estimates "$outdir/estimates/samples/${regsample}/total" 
global sampledir_figures "$outdir/figures/appendix/${regsample}/total" 
global sampledir_tables "$outdir/tables/appendix/${regsample}/total" 
global sample_stype A

shell mkdir -p "${sampledir_tables}"
shell mkdir -p "${sampledir_figures}"
shell mkdir -p "${sampledir_estimates}"

* GET SUMMARY TABS AND FIGS 
do "$repodir/code/analysis/SumTabsFigs_sample.do"

* RUN SIMPLE REGS
do "$repodir/code/analysis/subcode_RunSimpleRegs.do"

*++++++++++++++++++++++++++++++++++++++
* RUN 2D RIVAL REGS
global runlist R1av_Nshav R1_Nsh RQav_Nshav Rmaxav_Nsh R1avship_Nshav R1avdist_Ndistav R1ship_Nsh // description in subcode_ConstructRivalVars.do

global rvarlist Pcru Z_* tax_cpg av_tax

foreach rd in $runlist {
	do "$repodir/code/analysis/RivalDefs_`rd'.do"
	runregs_2D 
}

*++++++++++++++++++++++++++++++++++++++
* RUN 1D RIVAL REGS

foreach rd in Rdist Rship {
	do "$repodir/code/analysis/RivalDefs_`rd'.do"
	runregs_1D 
}
********************************************************************************

************************* BALANCED SAMPLE **********************************
global regsample balanced
global sampledir_regsample "$repodir/code/analysis/samples/${regsample}" 

***************************
* WHOLESALE REGS
***************************
global sampledir_channel "${generated_dir}/wholesale" 
global sampledir_estimates "$outdir/estimates/samples/${regsample}/wholesale" 
global sampledir_figures "$outdir/figures/appendix/${regsample}/wholesale" 
global sampledir_tables "$outdir/tables/appendix/${regsample}/wholesale" 
global sample_stype W

shell mkdir -p "${sampledir_tables}"
shell mkdir -p "${sampledir_figures}"
shell mkdir -p "${sampledir_estimates}"

* GET SUMMARY TABS AND FIGS 
do "$repodir/code/analysis/SumTabsFigs_sample.do"

* RUN SIMPLE REGS
do "$repodir/code/analysis/subcode_RunSimpleRegs.do"

*++++++++++++++++++++++++++++++++++++++
* RUN 2D RIVAL REGS
global runlist R1av_Nshav R1_Nsh Rmaxav_Nsh R1avship_Nshav // description in subcode_ConstructRivalVars.do

global rvarlist Pcru Z_* tax_cpg av_tax

foreach rd in $runlist {
	do "$repodir/code/analysis/RivalDefs_`rd'.do"
	runregs_2D 
}

*++++++++++++++++++++++++++++++++++++++
* RUN 1D RIVAL REGS

foreach rd in Rdist Rship {
	do "$repodir/code/analysis/RivalDefs_`rd'.do"
	runregs_1D 
}

**+++++++++++++++++++++++++++++++++++++
* RUN HETEROGENEITY 
**+++++++++++++++++++++++++++++++++++++
global intvar_list totcap capPadd av_HHI capUS nfirmspc

*** 2D
foreach rd in $runlist {
	do "$repodir/code/analysis/RivalDefs_`rd'.do"
	runinteractions_2D 
}

*++++++++++++++++++++++++++++++++++++++
* RUN 1D RIVAL REGS

foreach rd in Rdist Rship {
	do "$repodir/code/analysis/RivalDefs_`rd'.do"
	runinteractions_1D
}

***************************
* TOTAL REGS
***************************
global sampledir_channel "${generated_dir}/total" 
global sampledir_estimates "$outdir/estimates/samples/${regsample}/total" 
global sampledir_figures "$outdir/figures/appendix/${regsample}/total" 
global sampledir_tables "$outdir/tables/appendix/${regsample}/total" 
global sample_stype A

shell mkdir -p "${sampledir_tables}"
shell mkdir -p "${sampledir_figures}"
shell mkdir -p "${sampledir_estimates}"

* GET SUMMARY TABS AND FIGS 
do "$repodir/code/analysis/SumTabsFigs_sample.do"

* RUN SIMPLE REGS
do "$repodir/code/analysis/subcode_RunSimpleRegs.do"

*++++++++++++++++++++++++++++++++++++++
* RUN 2D RIVAL REGS
global runlist R1av_Nshav R1_Nsh Rmaxav_Nsh R1avship_Nshav // description in subcode_ConstructRivalVars.do

global rvarlist Pcru Z_* tax_cpg av_tax

foreach rd in $runlist {
	do "$repodir/code/analysis/RivalDefs_`rd'.do"
	runregs_2D 
}

*++++++++++++++++++++++++++++++++++++++
* RUN 1D RIVAL REGS

foreach rd in Rdist Rship {
	do "$repodir/code/analysis/RivalDefs_`rd'.do"
	runregs_1D 
}
********************************************************************************

********************************************************************************
*remove temp files created
shell rm *.dta


exit

exit
