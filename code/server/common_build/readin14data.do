/***********************
This file imports and rearanges raw EIA-14 confidential data
***********************/
clear
global repodir "/home/sweeneri/ms_pt_clean"
do "$repodir/code/setup.do"

*set working directory
cd "$commondir/temp"

/*****************************
START WITH EIA-14 DATA
***************************/
import excel using "$eiadir/Data_Request_EIA14_200201_201107_BC_02Aug2016.xlsx", sheet("YEAR=2002") clear
local size = _N
display `size'

import excel using "$eiadir/Data_Request_EIA14_200201_201107_BC_02Aug2016.xlsx", firstrow sheet("YEAR=2002") cellrange(A2:I`size') clear

save itdat, replace

forval i = 2003/2011 {
	import excel using "$eiadir/Data_Request_EIA14_200201_201107_BC_02Aug2016.xlsx", sheet("YEAR=`i'") clear
	local size = _N

	import excel using "$eiadir/Data_Request_EIA14_200201_201107_BC_02Aug2016.xlsx", firstrow sheet("YEAR=`i'") cellrange(A2:I`size') clear
	tostring ID, replace
	append using itdat
	save itdat, replace
}

drop if YEAR == .

save olddat, replace

forval i = 2011/2012 {
	import excel using "$eiadir/Data_Request_EIA14_201106_201212_Harvard_21MAY2013.xlsx", sheet("YEAR=`i'") clear
	local size = _N

	import excel using "$eiadir/Data_Request_EIA14_201106_201212_Harvard_21MAY2013.xlsx", firstrow sheet("YEAR=`i'") cellrange(A2:I`size') clear
	tostring ID, replace
	append using itdat
	save itdat, replace
}

drop if YEAR == .

forval i = 2013/2015 {
	import excel using "$eiadir/Data_Request_EIA14_201301_201512_BC_02Aug2016.xlsx", sheet("YEAR=`i'") clear
	local size = _N

	import excel using "$eiadir/Data_Request_EIA14_201301_201512_BC_02Aug2016.xlsx", firstrow sheet("YEAR=`i'") cellrange(A2:I`size') clear
	tostring ID, replace
	
	rename TotalDomesticCostThousandso TotalDomesticCost 
	rename TotalDomesticVolumeThousands TotalDomesticVolume 
	rename TotalImportCostThousandsof TotalImportCost 
	rename TotalImportVolumeThousandso TotalImportVolume
	append using itdat
	save itdat, replace
}

drop if YEAR == .

save indat, replace


use indat, clear
gen padd = 99
replace padd = 1 if PADDistrict == "PAD District 1 (East Coast)"
replace padd = 2 if PADDistrict == "PAD District 2 (Midwest)"
replace padd = 3 if PADDistrict == "PAD District 3 (Gulf Coast)"
replace padd = 4 if PADDistrict == "PAD District 4 (Rocky Mountain)"
replace padd = 5 if PADDistrict == "PAD District 5 (West Coast)"
replace padd = 6 if PADDistrict == "OTHER"

destring TotalDomesticCost TotalDomesticVolume, replace
gen DomPrice = TotalDomesticCost/TotalDomesticVolume

destring TotalImportCost TotalImportVolume, replace
gen ImpPrice = TotalImportCost/TotalImportVolume

*CREATE CORPORATE ID
gen len = length(ID)
gen corp_id = substr(ID,1,6)
replace corp_id = substr(ID,1,5) if len ==9
replace corp_id = substr(ID,1,4) if len ==8
replace corp_id = substr(ID,1,3) if len ==7
destring corp_id, replace
rename YEAR year
rename RptMonth  month

drop Survey PADDistrict len 

*there are a bunch of duplicates in 2011
by ID padd year month, sort: gen te = _n
drop if te > 1
drop te
save tempdat, replace

use tempdat, clear

*dropping extreme outliers

drop if DomPrice > 200 & DomPrice != .
drop if DomPrice < 10 & DomPrice != .

drop if ImpPrice > 200 & ImpPrice != .
drop if ImpPrice < 10 & ImpPrice != .

bys corp_id padd year month: gen te = _N
tab te

*COLLAPSING TO CORPID
collapse (sum) TotalDomesticCost TotalDomesticVolume TotalImportCost TotalImportVolume, by(corp_id year month padd)
gen cru_price_dom = TotalDomesticCost/TotalDomesticVolume
gen cru_price_for = TotalImportCost/TotalImportVolume
gen cru_price_tot = (TotalImportCost +TotalDomesticCost) /(TotalImportVolume + TotalDomesticVolume)
rename TotalDomesticVolume Q14_dom
rename TotalImportVolume Q14_for
gen Q14_tot = Q14_dom + Q14_for
save "$generated_dir/clean_confidential_data/EIA14data", replace

*remove temp files created
shell rm *.dta

