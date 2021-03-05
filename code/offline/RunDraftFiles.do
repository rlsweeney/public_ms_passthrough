/* THIS RUNS ALL OF THE DO FILES USED IN THE DRAFT (AND APPENDIX) */

* SETUP ************************************************************************

* ASSUMES YOU HAVE RUN setup_offline.do

*remove temp files created previously
cd "$repodir/output/offline/tables/draft" 
shell rm *
cd "$repodir/output/offline/tables/draft/appendix" 
shell rm *
cd "$repodir/output/offline/tables/from_public_data" 
shell rm *
cd "$repodir/output/offline/figures/draft" 
shell rm *
cd "$repodir/output/offline/figures/from_public_data" 
shell rm *

*set working directory
cd "$repodir/temp"

*********************************************
* COPY OVER FIGURES AND TABLES GENERATED ON SERVER 
global tabdir "$repodir/output/offline/tables/draft" 
global figdir "$repodir/output/offline/figures/draft" 

* SET PATH TO MAIN SAMPLE AND CHANNEL 
global Tsample main
global Tchannel wholesale

global servertabdir "$repodir/output/from_server/tables/by_sample/${Tsample}/${Tchannel}" 

foreach v in summary_stats_firm crude_discount_change crude_discount_change_panel Nfirms_padd_year {
	copy "${servertabdir}\\`v'.tex" "${tabdir}\\`v'.tex", replace
}

* COPY OVER FIGURES MADE ON SERVER
global serverfigdir "$repodir/output/from_server/figures/by_sample/${Tsample}/${Tchannel}" 

foreach v in padd_crude_price_boxplot.eps avg_frac_dom_crude.eps {
	copy "${serverfigdir}\\`v'" "${figdir}\\`v'", replace
}

local v FPP_discount_by_API.eps
copy "$repodir/output/from_server/figures/`v'" "${figdir}\\`v'", replace


* CONSTRUCT OFFLINE TABLES 
do "${repodir}\code\offline\AssembleTables.do"

* CONSTRUCT CARBON TAX TABLES AND FIGURES
do "${repodir}\code\offline\taxFigures.do"

* CONSTRUCT PUBLIC SHALE BOOM TABLES AND FIGURES
do "${repodir}\code\offline\PublicDataFigures.do"

* RUN WTI SPOT ANALYSIS
do "${repodir}\code\offline\InputCost_vs_WTIspot.do"


*remove temp files created
shell rm *.dta

capture log close

exit

