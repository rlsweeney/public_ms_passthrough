* This file creates co2 tax pass through figures 

clear
set more off

cd "$repodir/temp"		

*LOAD PREFERRED ESTIMATES **************************************************
global estdir "$repodir/output/from_server/estimates" 
global Testdir "${estdir}/samples/main/wholesale"
global outdir "${repodir}/output/offline/figures/draft"

global Tprod T
local it_rlabel R1av_Nshav
local it_market fp

estimates use "${Testdir}/`it_rlabel'/`it_market'/mods_ols_${Tprod}", number(4)
estimates replay

* BRING IN ANONYMIZED TAX DATA FROM SERVER **************************************
import delimited using "$repodir/output/server_postdata/FPtax_covariance.csv", clear
rename _rival_av_tax _Rival_av_tax
rename _nonrival_av_tax _NonRival_av_tax

gen dP_Own = _b[Pcru]*av_tax
gen dP_Rival = _b[_Rival_Pcru]*_Rival_av_tax 
gen dP_NonRival = _b[_NonRival_Pcru]*_NonRival_av_tax 
gen dP_Brent = _b[brent_cru]*brent_av_tax 

gen dP_Market = dP_Own + dP_Rival
gen dP_US = dP_Market + dP_NonRival
gen dP_Full = dP_US + dP_Brent

*get markup changes 
foreach v in Own Market US Full {
	gen dMU_`v' = dP_`v' - av_tax 
}

capture drop tpct
foreach v of varlist dP_* dMU_* {
	di "`v'"
	sum `v'
	gen tpct = cond(`v' > 0 ,1, 0)
	sum tpct
	drop tpct
}

egen Mean_Rival_av_tax = mean(_Rival_av_tax)
gen dP_MeanRival = _b[_Rival_Pcru]*Mean_Rival_av_tax
gen dP_Market_MeanRival = dP_Own + dP_MeanRival

foreach x in Own Market US Full Market_MeanRival {
	gen PT_`x' = (dP_`x'/av_tax)
	gen dPret_`x' = dP_`x' + av_tax
}

sum PT*, detail

save chartdata, replace

* CREATE MARKUP CHANGE CDFS ****************************************************
use chartdata, clear

set scheme s2color
distplot dMU_Own dMU_Market dMU_US dMU_Full , ///
	xtitle("Change in Marginal Revenue ($/barrel)") ///
	legend(rows(1) lab(1 "Own") lab(2 "Regional") lab(3 "US") lab(4 "Industry"))

graph export "${outdir}/CO2TaxMUChange_FP.png" ,  replace		
graph export "${outdir}/CO2TaxMUChange_FP.pdf" ,  replace		

set scheme s2mono
distplot dMU_Own dMU_Market dMU_US dMU_Full , ///
	xtitle("Change in Marginal Revenue ($/barrel)") ///
	legend(rows(1) lab(1 "Own") lab(2 "Regional") lab(3 "US") lab(4 "Industry"))
	
graph export "${outdir}/mono_CO2TaxMUChange_FP.png" ,  replace		
graph export "${outdir}/mono_CO2TaxMUChange_FP.pdf" ,  replace	
	
set scheme s2color
* CREATE HETEROGENEITY GRAPHS 
distplot av_tax, ///
	xtitle("Refiner Tax ($/barrel)") ///
	legend(off)

graph export "${outdir}/CO2TaxCDF_FP.png" ,  replace		
graph export "${outdir}/CO2TaxCDF_FP.pdf" ,  replace		

set scheme s2mono
* CREATE HETEROGENEITY GRAPHS 
distplot av_tax, ///
	xtitle("Refiner Tax ($/barrel)") ///
	legend(off)

graph export "${outdir}/mono_CO2TaxCDF_FP.png" ,  replace		
graph export "${outdir}/mono_CO2TaxCDF_FP.pdf" ,  replace		

* PASS THROUGH PERCENTAGE BY SCOPE ********************************************* 
use chartdata, clear

label var PT_Own "Pass-through of firm-level tax (%)"
label var PT_Market "Pass-through of regional tax (%)"
label var PT_US "Pass-through of domestic tax (%)"
label var PT_Full "Pass-through of world-wide tax (%)"

label var av_tax "Firm-level cost impact of tax ($/barrel)"
label var av_tax "Avg impact of tax on rivals($/barrel)"

set scheme s2color
distplot PT_Own PT_Market PT_US PT_Full , ///
	legend(rows(1) lab(1 "Own") lab(2 "Regional") lab(3 "US") lab(4 "Industry")) ///
	note("A value of 1 denotes full pass-through of a firm's cost shock onto consumers.") ///
	xtitle("")

graph export "${outdir}/CO2Tax_PT_Allshocks.png" ,  replace	
graph export "${outdir}/CO2Tax_PT_Allshocks.pdf" ,  replace	

set scheme s2mono
distplot PT_Own PT_Market PT_US PT_Full , ///
	legend(rows(1) lab(1 "Own") lab(2 "Regional") lab(3 "US") lab(4 "Industry")) ///
	note("A value of 1 denotes full pass-through of a firm's cost shock onto consumers.") ///
	xtitle("")

graph export "${outdir}/mono_CO2Tax_PT_Allshocks.png" ,  replace	
graph export "${outdir}/mono_CO2Tax_PT_Allshocks.pdf" ,  replace	

exit 
