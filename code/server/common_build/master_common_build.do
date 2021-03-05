clear
global repodir "/home/sweeneri/ms_pt_clean"
do "$repodir/code/setup.do"

* no dependencies
do "$repodir/code/common_build/readin14data.do"

*depends on files from desktop
do "$repodir/code/common_build/readin782Data.do" 
do "$repodir/code/common_build/clean820data.do"

*810 is cleaned in two steps
do "$repodir/code/common_build/readin810Data.do" // reads  in each of the surveys
do "$repodir/code/common_build/clean810data.do" // transposes and combines them

* final cleanup 
do "$repodir/code/common_build/clean_data_and_corpids.do" // standardizes ids across surveys 
do "$repodir/code/common_build/clean_shipping_costs.do" 
do "$repodir/code/common_build/clean_ghg_data.do" 

do "$repodir/code/common_build/clean_public_crude_price_data.do" 
