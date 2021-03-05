/***********************
This file creates summary tables and figures by sample
***********************/

*BRING IN PADD LEVEL DATA MERGED TOGETHER
use "${sampledir_channel}/regdata_fp", clear
do "${sampledir_regsample}/subcode_samplerestrict_fp.do"

keep if prod == "_TP"
gen frac_gas = frac_gas_TP
gen frac_dist = frac_dist_TP

gen P_gas = P_${sample_stype}_G
gen P_dist = P_${sample_stype}_D
gen P_tot = P_A_TP
gen WP_tot = P_W_TP

replace frac_resale = frac_resale_TP

rename frac_dom_crude_14 frac_dom_crude

split FPid, p(-) gen(tk)
destring tk2, gen(FPid_padd)
gen padd = FPid_padd

clonevar cru_price_tot =  Pcru

gen ymdate = ym(year,month)
format ymdate %tm

rename brent p_brent_spot

gen diff_cru_price = cru_price_tot - p_brent

save statdat, replace

********************************************************************************
****** TABLE: GET NUMBER OF OBSERVATIONS BY YEAR
********************************************************************************

use statdat, clear

bys FPid year: gen Nf = _n 
drop if Nf > 1

forval i = 1/5 {
	gen N_P`i' = Nf if FPid_padd == `i'
}


tabstat N_P*, stat(sum) by(year)

tabout year using "${sampledir_tables}/Nfirms_padd_year.tex", replace ///
c(sum N_P1 sum N_P2 sum N_P3 sum N_P4 sum N_P5) sum f(0c) style(tex) bt ///
topf($latdir/top.tex) topstr(\textwidth) botf($latdir/bot.tex) ///
h1(nil) ///
h2(nil) ///
h3( Year & Padd 1 & Padd 2 & Padd 3 & Padd 4 & Padd 5 \\) // wide(5)

********************************************************************************
*SHOW PRICE DISPERSION WITHIN PADDS ACROSS TIME
********************************************************************************

use statdat, clear

collapse (mean) cru_* Price p_*, by(year month ymdate padd)

drop if padd > 5

forval i = 1/5 {
	foreach v in tot {
		gen cp_`v'_`i' = cru_price_`v' if padd == `i'
		label var cp_`v'_`i' "PADD `i'"
	}
}

sort padd ymdate
twoway (line cp_tot* ymdate if year > 2008) (line p_brent ymdate if padd == 3 & year> 2008), ///
		ytitle("Price ($/gallon)")  xtitle("")  legend(rows(2)) 		

graph export "${sampledir_figures}/avg_padd_crude_price.eps" , replace	

*SHOW SAME THING IN DIFFERENCES FROM BRENT
capture drop cp_*
forval i = 1/5 {
	foreach v in tot /*dom for*/ {
		gen cp_`v'_`i' = cru_price_`v' - p_brent if padd == `i'
		label var cp_`v'_`i' "PADD `i'"
	}
}

label var cp_tot_1 "(1) East Coast"
label var cp_tot_2 "(2) Midwest"
label var cp_tot_3 "(3) Gulf"
label var cp_tot_4 "(4) Plains"
label var cp_tot_5 "(5) West Coast"


sort padd ymdate
qui: twoway (line cp_tot* ymdate if year > 2008), ///
		ytitle("Crude Cost - Brent ($/gallon)")  xtitle("")  legend(rows(2))
		
graph export "${sampledir_figures}/avg_padd_crude_diff_brent.eps" ,  replace	


*SHOW SAME THING IN DIFFERENCES FROM BRENT
capture drop d_*
forval i = 1/5 {
	gen d_`i' = Price - cru_price_tot if padd == `i'
	*gen d_`i' = WP_gas - p_brent if padd == `i'
	label var d_`i' "PADD `i'"
}

label var d_1 "(1) East Coast"
label var d_2 "(2) Midwest"
label var d_3 "(3) Gulf"
label var d_4 "(4) Plains"
label var d_5 "(5) West Coast"

sort padd ymdate
qui: twoway (line d_* ymdate if year > 2008) , ///
		ytitle("Revenue - Crude Cost ($/gallon)")  xtitle("") legend(rows(2))
		
graph export "${sampledir_figures}/avg_padd_markup_tot.eps" ,  replace	


use statdat, clear

gen cp_diff = cru_price_tot - p_brent
collapse (mean) cru_price_tot cp_diff p_brent p_wti, by(FPid year padd)
label var cp_diff "Firm Crude Price - Brent Spot ($/gal)"
qui: twoway scatter cp_diff year, ///
	by(padd, note("Graphs presented by PADD. Each point is a firm's average annual crude acquisition cost within that" "PADD minus the Brent spot price.") ///
	) msize(small) xtitle("") 
graph export "${sampledir_figures}/padd_crude_price_by_firm.eps" ,  replace	

keep if padd == 3 | padd == 2
qui: twoway scatter cp_diff year, ///
	by(padd, note("Graphs presented by PADD. Each point is a firm's average annual crude acquisition cost within that" "PADD minus the Brent spot price.") ///
	) msize(small) xtitle("") 
graph export "${sampledir_figures}/padd_crude_price_by_firm_Padds_23.eps" ,  replace	

***** BOX PLOT 
use statdat, clear
gen cp_diff = cru_price_tot - p_brent
collapse (mean) ave = cp_diff (sd) sd= cp_diff , by(year padd)
gen lb = ave - 2*sd
gen ub = ave + 2*sd

qui: twoway (scatter ave year) (rcap lb ub year), by(padd, ///
	note("Graphs presented by PADD. Bars represent 95% confidence intervals") ///
	legend(off)) xtitle("") ytitle("Firm Crude Price - Brent Spot ($/gal)")
graph export "${sampledir_figures}/padd_crude_price_boxplot.eps" ,  replace	


***** LOOK AT TRENDS IN DOMESTIC CRUDE SHARE
use statdat, clear

collapse (mean) cru_* Price p_* frac_dom_crude, by(year month ymdate padd)

drop if padd > 5
drop if year < 2009

forval i = 1/5 {
	gen fd_`i' = frac_dom_crude if padd == `i'
	label var fd_`i' "PADD `i'"
}

label var fd_1 "(1) East Coast"
label var fd_2 "(2) Midwest"
label var fd_3 "(3) Gulf"
label var fd_4 "(4) Plains"
label var fd_5 "(5) West Coast"

sort padd ymdate
qui: twoway (line fd* ymdate) , ///
		ytitle("% Dom Crude")  xtitle("") legend(rows(2))
		
qui: graph export "${sampledir_figures}/avg_frac_dom_crude.eps" ,  replace	

*BY FIRM
use statdat, clear
collapse (mean) frac_dom_crude, by(FPid year padd)
label var frac_dom_crude "% Dom. Crude"
qui: twoway scatter frac_dom_crude year, ///
	by(padd, note("Graphs presented by PADD. Each point is a firm's average annual share of crude coming from domestic sources.")) msize(small) xtitle("") 
	
graph export "${sampledir_figures}/padd_frac_dom_crude_by_firm.eps" ,  replace	


********************************************************************************
* SHOW REFINERY LEVEL DETERMINANTS OF CHANGE IN PRICES
********************************************************************************

* MEAN DIFFERENCES
use statdat, clear

gen y = 0 if year > 2004 & year < 2009
replace y = 1 if year > 2009 & year < 2014

drop if y == .
gen npers = 1

collapse (mean) api frac_dom_crude NCI share_* cru_price* ///
	p_brent diff* nrefs  totcap (sum) npers, by(y FPid padd)

egen co_padd = group(FPid)
tsset co_padd y

gen d_price = (F.diff_cru - diff_cru)

*FIRST CREATE A SCATTER PLOT OF CHANGES BY PADD TO SHOW HETEROGENEITY 
gen reverse_padd = -padd
twoway scatter d_price reverse_padd, ///
	xlabel(-1 "East Coast" -2 "Midwest" -3 "Gulf" ///
		-4 "Plains" -5 "West Coast", angle(45)) ///
	xtitle("") ytitle("Change in Brent Differential ($/gal)") 

graph export "${sampledir_figures}/crude_discount_change_by_padd.eps" ,  replace	

********************************************************************************
*NOW RUN A REGRESSION ON THIS COLLAPSED SAMPLE
*SHOW DETERMINANTS OF WITHIN PADD HETEROGENEITY USING REGRESSION

egen minpers = min(npers), by(FPid)

la var api "API Gravity"
la var frac_dom "\% Domestic Crude"
la var share_ds "Downstream Capacity"
la var NCI "Complexity"

gen logtotcap = log(totcap)

la var logtotcap "Log(Capacity)"

forval i = 2/5 {
	gen _Dpadd_`i' = cond(padd == `i',1,0)
}
label var _Dpadd_2 "(P2) Midwest"
label var _Dpadd_3 "(P3) Gulf"
label var _Dpadd_4 "(P4) Plains"
label var _Dpadd_5 "(P5) West Coast"

eststo clear
eststo: reg d_price _Dpa* api frac_dom logtotcap share_ds if minpers >= 24
sum d_price, detail
estadd local avY = round(`r(mean)'*100)/100
esttab, label drop(_cons) se starlevels(* 0.10 ** 0.05 *** 0.01) ///
	 stat(avY N r2 , label("mean(Y)"))  nomtitles nonotes nonumber 

esttab *  using "${sampledir_tables}/crude_discount_change.tex" , drop( _cons) replace label ///
	 se starlevels(* 0.10 ** 0.05 *** 0.01) compress booktabs  ///
	 stat(avY N r2 , label("mean(Y)"))  nomtitles nonotes  nonumber  
	 
hist d_price, xtitle("Change in Brent Discount, 2005-08 vs 2010-2013")
graph export "${sampledir_figures}/hist_brent_discount.eps" ,  replace	

twoway (scatter  d_price api) (lfit d_price api) , xtitle("Average API Gravity 2005-08") ///
	ytitle("Change in Brent Discount") legend(off)
graph export "${sampledir_figures}/scatter_brent_discount_api.eps" ,  replace	

twoway (scatter  d_price frac_dom ) (lfit d_price frac_dom ) , xtitle("Average Domestic Crude Share 2005-08") ///
	ytitle("Change in Brent Discount") legend(off)
graph export "${sampledir_figures}/scatter_brent_discount_fracdom.eps" ,  replace	

********************************************************************************
*RUN REGRESSION ON FULL SAMPLE 
use statdat, clear

gen logtotcap = log(totcap)
tabstat diff_cru, by(year)

*DEFINE FRACKING PERIOD
gen period = "Pre" if year <= 2007
replace period = "Post" if year >= 2010 // & year < 2015
gen PostInd = cond(period == "Post",1,0)

*create interactions
foreach v of varlist api frac_dom logtotcap share_ds {
	capture drop te
	gen te = `v' if period == "Pre"
	egen Post_`v' = mean(`v'), by(FPid) 
	replace Post_`v' = 0 if period != "Post"
}

forval i = 2/5 {
	gen Post_padd_`i' = cond(padd==`i' & period == "Post",1,0)
}


la var Post_api "API Gravity"
la var Post_frac_dom "\% Domestic Crude"
la var Post_share_ds "Downstream Capacity"
la var Post_logtotcap "Log(Capacity)"

label var Post_padd_2 "(P2) Midwest"
label var Post_padd_3 "(P3) Gulf"
label var Post_padd_4 "(P4) Plains"
label var Post_padd_5 "(P5) West Coast"

*RUN REGRESSIONS
eststo clear

*DROP 2008 - 2009 RAMP UP PERIOD
replace inreg = cond(year == 2009 | year == 2008 ,0,1)
qui: eststo M_donut: areg cru_price_tot PostInd i.ymdate Post_*  if inreg , absorb(FPid) cluster(FPid)

esttab, keep(*Post_*) se starlevels(* 0.10 ** 0.05 *** 0.01) label ///
	nomtitles nonotes nonumber 
	
esttab M_donut  using "${sampledir_tables}/crude_discount_change_panel.tex" , keep(*Post_*) replace label ///
	 se starlevels(* 0.10 ** 0.05 *** 0.01) compress booktabs  ///
	 stat(N r2 )  nomtitles nonotes  nonumber  

**********************************************************************************************************
****GET TABLE SUMMARIZING KEY VARIABLES 
use statdat, clear

label var cru_price_tot "Crude cost (2013 \\$/gal)"
label var diff_cru "Crude - Brent"
label var frac_dom_crude "\% Domestic"

label var frac_gas "\% Gas"
label var frac_dist "\% Distillate"
label var frac_resale "\% Resale"

label var P_gas "Price Gas"
label var P_dist "Price Distillate"
label var P_tot "Price Total"
label var WP_tot "Resale Price Total"

eststo clear
estpost summarize cru_price_tot diff_cru_price  frac_dom_crude P_gas P_dist /// 
	P_tot WP_tot frac_gas frac_dist frac_resale 

esttab , cells("mean(fmt(a3)) sd(fmt(a3))") noobs stat(N) nomtitle nonumber label 

esttab , cells("mean(fmt(a3)) sd(fmt(a3))") noobs stat(N) nomtitle nonumber label /// 
	varlabels(, elist(frac_dom_crude "{break}{hline @width}" WP_tot "{break}{hline @width}"))

esttab using "${sampledir_tables}/summary_stats_firm.tex" ,  replace compress booktabs  ///
		cells("mean(fmt(a3)) sd(fmt(a3))")  noobs stat(N) nomtitle nonumber label wide

********************************************************************************
*remove temp files created
shell rm *.dta

exit
