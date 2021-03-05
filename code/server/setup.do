* SETUP FOR CODE USED ON SERVER WITH CONFIDENTIAL EIA DATA 

set seed 123456
set more off, permanently
set excelxlsxlargefile on

* FIND WHERE THE REPO IS STORED ON THIS COMPUTER
local reponame ms_pt_clean // fill in local directory name (public_ms_passthrough if downloaded from github)
global repodir = substr("`c(pwd)'",1,length("`c(pwd)'") - ///
		(strpos(reverse("`c(pwd)'"),reverse("`reponame'"))) + 1)
di "$repodir'"

*common build setup.do
global publicdir "$repodir/data/public_data" // public files (posted)
global commondir "$repodir/code/server/common_build"
global generated_dir "$repodir/generated_data"
global outdir "$repodir/output/from_server"

global eiadir "/home/sweeneri/refinery_main/confidential_eia_data" // confidenial files

*set working directory
cd "$repodir/temp"

exit

*NECESSARY PACKAGES 
*local github "https://raw.githubusercontent.com"
*net install gtools, from(`github'/mcaceresb/stata-gtools/master/build/)
