/* SETTINGS FOR OFFLINE CODE (POST SERVER ESTIMATION) */

set seed 123456
set more off, permanently
set excelxlsxlargefile on

* FIND WHERE THE REPO IS STORED ON THIS COMPUTER
local reponame ms_pt_clean // fill in local directory name (public_ms_passthrough if downloaded from github)
global repodir = substr("`c(pwd)'",1,length("`c(pwd)'") - ///
		(strpos(reverse("`c(pwd)'"),reverse("`reponame'"))) + 1)
di "$repodir'"

*set working directory
cd "$repodir/temp"

exit

*NECESSARY PACKAGES 
*local github "https://raw.githubusercontent.com"
*net install gtools, from(`github'/mcaceresb/stata-gtools/master/build/)