/***********************
This file imports and rearanges EIA-810 data
***********************/
clear
global repodir "/home/sweeneri/ms_pt_clean"
do "$repodir/code/setup.do"

*set working directory
cd "$commondir/temp"

*******************************************************************************

/*******************************************************************************
START WITH 782A DATA

- data comes in sevaral differet formats. groups are 
   - 94-01
	- these files have numerical vars for product description and sales type
   - 02-11_05
   	- these files ONLY have text vars for product description and sales type
   - 11_06-12
	- these files have both text and numerical descriptions
	- using numerical
   - 13_15
	- same as 11_06-12 data, but some of the variable names changed again


***************************/
import excel using "$eiadir/eia782a_94.xlsm", firstrow clear
rename ProductDesc pcode
rename SalesType scode
drop Survey Status Response ADJWT
save apdata, replace

foreach x in 95 96 97 98 99 00 01 {
	import excel using "$eiadir/eia782a_`x'.xlsm", firstrow clear
	rename ProductDesc pcode
	rename SalesType scode
	drop Survey Status Response ADJWT

	append using apdata
	save apdata, replace 
} 


*import code descriptions
import excel using "$publicdir/Manual/782 labels - updated pre 94.xlsx", sheet("prod_code") firstrow clear
destring code, generate(pcode)
drop code
save pbridge, replace

merge 1:m pcode using apdata
drop if _merge == 1
drop _merge
save tdata, replace

import excel using "$publicdir/Manual/782 labels - updated pre 94.xlsx", sheet("sales_type") firstrow clear
destring code, generate(scode)
drop code
save sbridge, replace

merge 1:m scode using tdata
drop if _merge == 1
drop _merge
save group_94_01, replace


*now do post 2001 files with text desc
import excel using "$eiadir/eia782a_02.xlsx", firstrow clear
drop Survey Status Response ADJWT
save apdata, replace

foreach x in 03 04 05 06 07 08 09 10 11_01_05 {
	import excel using "$eiadir/eia782a_`x'.xlsx", firstrow clear
	drop Survey Status Response ADJWT

	append using apdata
	save apdata, replace 
}

use pbridge, clear
drop if ProductDesc == ""
merge 1:m ProductDesc using apdata, nogen keep(match)
save tdata, replace

use sbridge, clear
drop if SalesType == ""
merge 1:m  SalesType using tdata,  nogen keep(match)
save group_02_1105, replace

**** Bring in post 11_05 data
import excel using "$eiadir/harvard1106_1212_782a.xlsx", firstrow clear
rename Date ReportDate
rename State ReportState
rename TypeName SalesType
rename ProdCode pcode
rename TypeCode scode
drop Survey
save apdata, replace

*APPEND 13-15 DATA
import excel using "$eiadir/782A_2013_2015_BOSTON.xlsx", firstrow clear
rename DATE ReportDate
rename STATE ReportState
rename STYPENAME SalesType
rename STYPE scode
drop SURVEY
rename VOLUME Volume
rename PRICE Price
rename PRODNAME ProdName
rename PRODCODE pcode
rename CIN ID

append using apdata
save apdata, replace 	
	
use apdata, clear
tostring ReportDate, replace
gen yt = substr(ReportDate,1,4)
gen mt = substr(ReportDate,5,2)

rename Volume Vol000gallons
rename Price Price000gal
destring yt, gen(Year)
destring mt, gen(Month)
drop yt mt
destring ReportDate, replace
merge m:1 pcode using pbridge
drop if _merge == 2
drop _merge

merge m:1 scode using sbridge
drop if _merge == 2
drop _merge

save group_post1105, replace


*** BRING IN PRE-1994 FILES 
import excel using "$publicdir/Manual/782 labels - updated pre 94.xlsx", sheet("A_pre94") firstrow clear
save Abridge, replace

*** PRE94 FILES ARE IN ONE EXCEL FILE WITH ONE SHEET PER YEAR
local i = 1986
import excel using "$eiadir/Annual_782A.xlsm", sheet("year=`i'") firstrow clear
save apdata, replace

forval i = 1987/1993  {
	import excel using "$eiadir/Annual_782A.xlsm", sheet("year=`i'") firstrow clear
	
	append using apdata
	save apdata, replace 
}



use apdata, clear
merge m:1 prod using Abridge, nogen keep(match)
tostring date, gen(te)
gen month = substr(te,5,2)
destring month, replace
drop te
rename year Year
rename month Month
rename STATE ReportState
rename price Price000gal
rename VOLUME Vol000gallons
rename prod ProdName_pre94
rename date ReportDate
drop survey PADD

save group_pre94, replace



*** APPEND ALL YEARS TOGETHER
use group_post1105, clear
append using group_94_01
append using group_02_1105
append using group_pre94

*So now ProdDesc and SalesType exist for every ob

/*clean corporate id numbers
all of the corporate IDs in the 810 and 782 data should be 10-digits, 
and that the first 6 digits should uniquely identify the parent company
*/

gen len = length(ID)
gen corp_id = substr(ID,1,6)
replace corp_id = substr(ID,1,5) if len ==9
replace corp_id = substr(ID,1,4) if len ==8
replace corp_id = substr(ID,1,3) if len ==7

gen tes = subinstr(SalesType," ","",.)
replace SalesType = tes
drop tes

tostring ReportDate, gen(te) format("%4.0f")
gen year = substr(te,1,4)
destring year, replace
rename Month month
rename Price price
label var price "$/gal"
rename Vol volume
label var volume "K gal"
drop te ReportDate

drop Year len

save "$generated_dir/clean_confidential_data/782Adata_all_pre94", replace


/*****************************
NOW DO 782C DATA
***************************/
import excel using "$eiadir/eia782c_94.xlsm", firstrow clear
rename ProductDesc pcode
rename SalesType scode
save apdata, replace

foreach x in 95 96 97 98 99 00 01 {
	import excel using "$eiadir/eia782c_`x'.xlsm", firstrow clear
	rename ProductDesc pcode
	rename SalesType scode

	append using apdata
	save apdata, replace 
} 

use pbridge, clear
merge 1:m pcode using apdata
drop if _merge == 1
drop _merge

rename rpt_date ReportDate
save group_94_01_c, replace

*now do post 2001 files with text desc

import excel using "$eiadir/eia782c_02.xlsx", firstrow clear
save apdata, replace

foreach x in 03 04 05 06 07 08 09 10 11_01_05 {
	import excel using "$eiadir/eia782c_`x'.xlsx", firstrow clear

	append using apdata
	save apdata, replace 
}

use pbridge, clear
drop if ProductDesc == ""
merge 1:m ProductDesc using apdata
replace pcode = 211 if ProductDesc == "211"
replace ProductDesc = "NATPHTA - JET" if ProductDesc == "211"
replace prod_label = "Nap-jet" if pcode == 211
drop _merge

rename rpt_date ReportDate
save group_02_1105_c, replace

**** Bring in post 11_05 data
import excel using "$eiadir/harvard1106_1212_782c.xlsx", firstrow clear
rename Date ReportDate
rename State ReportState
rename TypeName SalesType
rename ProdCode pcode
rename TypeCode scode
drop Survey
save apdata, replace

*APPEND 13-15 DATA
import excel using "$eiadir/782C_2013_2015_BOSTON.xlsx", firstrow clear

rename DATE ReportDate
rename STATE ReportState
rename STYPE scode
drop SURVEY
rename VOLUME Volume
rename PRODNAME ProdName
rename PRODCODE pcode
rename CIN ID
drop I
append using apdata
save apdata, replace 	

	
use apdata, clear

tostring ReportDate, replace
gen yt = substr(ReportDate,1,4)
gen mt = substr(ReportDate,5,2)

rename Volume Vol000gallons
destring yt, gen(Year)
destring mt, gen(Month)
drop yt mt
destring ReportDate, replace
merge m:1 pcode using pbridge
drop if _merge == 2
drop _merge

save group_post1105_c, replace


*** BRING IN PRE-1994 FILES *
import excel using "$publicdir/Manual/782 labels - updated pre 94.xlsx", sheet("C_pre94") firstrow clear
save Cbridge, replace

*** PRE94 FILES ARE IN ONE EXCEL FILE WITH ONE SHEET PER YEAR
local i = 1986
import excel using "$eiadir/Annual_782C.xlsm", sheet("year=`i'") firstrow clear
save apdata, replace

*782C not available in 1991

foreach i in 1987 1988 1989 1990 1992 1993 {
	import excel using "$eiadir/Annual_782C.xlsm", sheet("year=`i'") firstrow clear
	
	append using apdata
	save apdata, replace 
}



use apdata, clear
merge m:1 prod using Cbridge, nogen keep(match)

drop if Prod == "drop"
rename date ReportDate

rename STATE ReportState
rename volume Vol000gallons
rename prod ProdName_pre94

save group_pre94_c, replace




*** APPEND ALL YEARS TOGETHER
use group_post1105_c, clear
append using group_94_01_c
append using group_02_1105_c
append using group_pre94_c
drop if Vol000gallons == .
drop Year Month

tostring ReportDate, gen(rpt_date)
gen yt = substr(rpt_date,1,4)
gen mt = substr(rpt_date,5,2)
destring yt, gen(Year)
destring mt, gen(Month)

gen len = length(ID)
gen corp_id = substr(ID,1,6)
replace corp_id = substr(ID,1,5) if len ==9
replace corp_id = substr(ID,1,4) if len ==8
replace corp_id = substr(ID,1,3) if len ==7
tab len


drop survey padd yt mt len Status Response Survey rpt_date scode SalesT
save "$generated_dir/clean_confidential_data/782Cdata_all_pre94", replace

*remove temp files created
shell rm *.dta
