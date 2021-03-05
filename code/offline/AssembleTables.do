/* This file reads in results from estiamtes generated on the server and creates tables for the paper*/

* SETUP ************************************************************************
clear
set linesize 200

cd "$repodir/temp"

* DEFINE SOME PROGRAMS THAT CLEAN UP NAMES IN TABLE ****************************
capture program drop setCompLables
program define setCompLables, rclass
	local outlabel = ""
	if "`1'" == "R1av_Nshav" {
		local outlabel = "Avg"
	}
	if "`1'" == "Rmaxav_Nsh" {
		local outlabel = "Max"
	}
	if "`1'" == "R1avship_Nshav" {
		local outlabel = "AvDist"
	}
	return local pass="`outlabel'"
end 

capture program drop setIntLables
program define setIntLables, rclass
	local outlabel = ""
	if "`1'" == "av_HHI" {
		local outlabel = "HHI"
	}
	if "`1'" == "nfirmspc" {
		local outlabel = "Firms"
	}
	if "`1'" == "capPadd" {
		local outlabel = "Cap.PADD"
	}
	if "`1'" == "capUS" {
		local outlabel = "Cap.US"
	}
	return local pass="`outlabel'"
end 

global estdir "$repodir/output/from_server/estimates" 

*set working directory
cd "$repodir/temp"

********************************************************************************
* MAIN TABLES AND FIGURES IN DRAFT
global tabdir "$repodir/output/offline/tables/draft" 
global figdir "$repodir/output/offline/figures/draft" 

* SET PATH TO MAIN SAMPLE AND CHANNEL 
global Tsample main
global Tchannel wholesale

* CONSTRUCT OFFLINE TABLES
** set paths  
global Trlabel Rship
global main_iv Papi_DS_P24 
global Tprod T
global Tpnum 1
global Testdir "${estdir}/samples/${Tsample}/${Tchannel}"
global outdir "${tabdir}"

*ADD PREFIX TO TABLES (SHOULD BE BLANK FOR MAIN TABLES)
global outprefix 

* TABLE 1: COMPARE STATE LEVEL OWN COST RUNS ***********************************

do "${repodir}\code\offline\subcodeFECompTables.do"

* TABLE 2: COMPARE RIVAL DEFS ************************************************** 

global Trivals Rship R1av_Nshav

do "${repodir}\code\offline\subcodeRivalTables.do"
					
* TABLE 3: HETEROGENEITY ******************************************************* 

global list_hetero av_HHI capPadd

do "${repodir}\code\offline\subcodeHeteroTables.do"

********************************************************************************
* APPENDIX TABLES
global outdir "${tabdir}/appendix"

** RIVAL TABLE WITH MAX AND RIVAL DISTANCE RESULTS *****************************

global outprefix Max_
global Trivals R1avship_Nshav Rmaxav_Nsh  

do "${repodir}\code\offline\subcodeRivalTables.do"

** GAS TABLES ******************************************************************
global Tprod G
global Tpnum 3
global Testdir "${estdir}/samples/${Tsample}/${Tchannel}"

*ADD PREFIX TO TABLES (SHOULD BE BLANK FOR MAIN TABLES)
global outprefix Gas_

* TABLE 1: 
do "${repodir}\code\offline\subcodeFECompTables.do"

* TABLE 2: 

global Trivals Rship R1av_Nshav

do "${repodir}\code\offline\subcodeRivalTables.do"
			
** DIST TABLES ******************************************************************
global Tprod D
global Tpnum 4
global Testdir "${estdir}/samples/${Tsample}/${Tchannel}"

*ADD PREFIX TO TABLES (SHOULD BE BLANK FOR MAIN TABLES)
global outprefix Dist_

* TABLE 1: 
do "${repodir}\code\offline\subcodeFECompTables.do"

* TABLE 2: 

global Trivals Rship R1av_Nshav

do "${repodir}\code\offline\subcodeRivalTables.do"

** OTHER TABLES ******************************************************************
global Tprod O
global Tpnum 5
global Testdir "${estdir}/samples/${Tsample}/${Tchannel}"

*ADD PREFIX TO TABLES (SHOULD BE BLANK FOR MAIN TABLES)
global outprefix Other_

* TABLE 1: 
do "${repodir}\code\offline\subcodeFECompTables.do"

* TABLE 2: 

global Trivals Rship R1av_Nshav

do "${repodir}\code\offline\subcodeRivalTables.do"

** TOTAL PRICE TABLES ******************************************************************
global Tsample main
global Tchannel total
global Testdir "${estdir}/samples/${Tsample}/${Tchannel}"
global Tprod T
global Tpnum 1

*ADD PREFIX TO TABLES (SHOULD BE BLANK FOR MAIN TABLES)
global outprefix Total_

* TABLE 1: 
do "${repodir}\code\offline\subcodeFECompTables.do"

* TABLE 2: 
global Trivals Rship R1av_Nshav
do "${repodir}\code\offline\subcodeRivalTables.do"
						
** TOTAL PRICE TABLES ******************************************************************
global Tsample balanced 
global Tchannel wholesale
global Testdir "${estdir}/samples/${Tsample}/${Tchannel}"
global Tprod T
global Tpnum 1

*ADD PREFIX TO TABLES (SHOULD BE BLANK FOR MAIN TABLES)
global outprefix Balanced_

* TABLE 1: 
do "${repodir}\code\offline\subcodeFECompTables.do"

* TABLE 2: 
global Trivals Rship R1av_Nshav
do "${repodir}\code\offline\subcodeRivalTables.do"

*remove temp files created
shell rm *.dta
