******* CREATE SOME INTERACTIONS *****************************************

gen Intflag_av_HHI = cond(av_HHI > .17 & prod == "_T",1,0)
replace Intflag_av_HHI = 1 if av_HHI > .18 & prod == "_TP"
replace Intflag_av_HHI = 1 if av_HHI > .17 & prod == "_G"
replace Intflag_av_HHI = 1 if av_HHI > .19 & prod == "_D"
replace Intflag_av_HHI = 1 if av_HHI > .24 & prod == "_O"

gen Intflag_totcap = cond(totcap > 200000,1,0)

gen Intflag_capPadd = cond(capshare_padd > .1,1,0)

gen Intflag_capUS = cond(capshare_us > .05,1,0)

gen av_nfirms_pc = av_nfirms / _X_pop

gen Intflag_nfirmspc = cond(av_nfirms_pc > 3,1,0)

