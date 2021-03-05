/*This file just reads in EPA GHG data, keep relevant variables and stacks the years

- sites manually matched to GHGRPTID and included in 
*/

clear
global repodir "/home/sweeneri/ms_pt_clean"
do "$repodir/code/setup.do"

*set working directory
cd "$commondir/temp"

clear
gen year = .
save tempdat, replace

forval y = 2010/2015 {
	import excel using "$publicdir\EIA\epa_ghgdata.xls", firstrow clear sheet("`y'") cellrange(A7)
	gen year = `y'
	append using tempdat
	save tempdat, replace
}

save ghgdat, replace


use ghgdat, replace
replace GHGRPID = 1007923 if GHGRPID == 1004362 // ALON CA
replace GHGRPID = 1006843 if GHGRPID == 1001964 // Phillips LA CA 
replace GHGRPID = 1007972 if GHGRPID == 1007771 // Holly NM
replace GHGRPID = 1009067 if GHGRPID == 1009066 // Koch Corpus East/ West
replace GHGRPID = 1002970 if GHGRPID == 1007965 // Citgo Corpus East/ West
replace GHGRPID = 1006959 if GHGRPID == 1008110 // Valero Corpus East/ West
keep year GHGRPID GHGQUANTITYMETRICTONSCO2e SUBPARTS
rename GHGQUANTITYMETRICTONSCO2e GHG
rename SUB Subparts_GHG
collapse (sum) GHG (first) Su, by(year GHGRP)
la var GHG "GHG (metric tons CO2e)"
la var Sub "Subparts GHG"
save $generated_dir/ghgdata_clean, replace
exit
